package com.iblsoft.flexiweather.ogc
{
	import com.iblsoft.flexiweather.ogc.cache.WMSTileCache;
	import com.iblsoft.flexiweather.ogc.tiling.TileIndex;
	import com.iblsoft.flexiweather.ogc.tiling.TiledArea;
	import com.iblsoft.flexiweather.ogc.tiling.TilingUtils;
	import com.iblsoft.flexiweather.proj.Coord;
	import com.iblsoft.flexiweather.utils.UniURLLoader;
	import com.iblsoft.flexiweather.utils.UniURLLoaderEvent;
	import com.iblsoft.flexiweather.widgets.BackgroundJob;
	import com.iblsoft.flexiweather.widgets.BackgroundJobManager;
	import com.iblsoft.flexiweather.widgets.InteractiveLayer;
	import com.iblsoft.flexiweather.widgets.InteractiveWidget;
	
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.Graphics;
	import flash.events.Event;
	import flash.filters.GlowFilter;
	import flash.geom.Matrix;
	import flash.geom.Point;
	import flash.net.URLRequest;
	import flash.text.TextField;
	import flash.text.TextFormat;
	import flash.utils.Dictionary;
	import flash.utils.Timer;
	
	[Event(name='drawTiles', type='')]
	
	/**
	 * Generic Quad Tree (like Google Maps) tiling layer
	 **/
	public class InteractiveLayerQTTMS extends InteractiveLayer
	{
		public static const DRAW_TILES: String = 'drawTiles';
		public static const START_TILES_LOADING: String = 'startTilesLoading';
		public static const ALL_TILES_LOADED: String = 'onAllTilesLoaded';
		
		public static var imageSmooth: Boolean = true;
		public static var drawBorders: Boolean = false;
		public static var drawDebugText: Boolean = false;
		
		protected var m_loader: UniURLLoader = new UniURLLoader();
		
		protected var m_tiledArea: TiledArea;
		
		protected var m_cache: WMSTileCache;

		public function get cache(): WMSTileCache
		{
			return m_cache;
		}
		
		private var ma_specialCacheStrings: Array;
		
		protected var m_timer: Timer = new Timer(10000);
		
		public var minimumZoom: int = 0;
		public var maximumZoom: int = 10;
		
		private var ms_baseURL: String;
		private var md_crsToTilingExtent: Dictionary = new Dictionary();
		private var ms_oldCRS: String;
		private var m_tilingUtils: TilingUtils;
		private var m_jobs: TileJobs;
		private var mi_zoom: int = -1;
		public var tileScaleX: Number;
		public var tileScaleY: Number;
		private var ma_currentTilesRequests: Array = [];
		private var mi_totalVisibleTiles: int;
		private var mi_tilesCurrentlyLoading: int;
		
		public function InteractiveLayerQTTMS(
				container: InteractiveWidget, s_baseURL: String,
				s_primaryCRS: String, primaryCRSTilingExtent: BBox,
				minimumZoom: int = 0, maximumZoom: int = 10)
		{
			super(container);
			
			ms_baseURL = s_baseURL;

			if(s_primaryCRS != null && primaryCRSTilingExtent != null) {
				md_crsToTilingExtent[s_primaryCRS] = primaryCRSTilingExtent;
			}
			
			this.minimumZoom = minimumZoom;
			this.maximumZoom = maximumZoom;
			
			m_cache = new WMSTileCache();
			m_tilingUtils = new TilingUtils();
			m_tilingUtils.minimumZoom = minimumZoom;
			m_tilingUtils.maximumZoom = maximumZoom;
			
			m_loader.addEventListener(UniURLLoader.DATA_LOADED, onDataLoaded);
			m_loader.addEventListener(UniURLLoader.DATA_LOAD_FAILED, onDataLoadFailed);
			
			m_jobs = new TileJobs();
		}

		private function getExpandedURL(tileIndex: TileIndex): String
		{
			var ret: String = ms_baseURL;
			ret = ret.replace('%COL%', String(tileIndex.mi_tileCol));
			ret = ret.replace('%ROW%', String(tileIndex.mi_tileRow));
			ret = ret.replace('%ZOOM%', String(tileIndex.mi_tileZoom));
			return ret;
		}

		public function invalidateCache(): void
		{
			m_cache.invalidate(container.crs, getGTileBBoxForWholeCRS(container.crs));
		}

		public function clearCRSWithTilingExtents(): void
		{
			md_crsToTilingExtent = new Dictionary(); 
		}

		public function addCRSWithTilingExtent(s_tilingCRS: String, crsTilingExtent: BBox): void
		{
			md_crsToTilingExtent[s_tilingCRS] = crsTilingExtent;
		}

		public function updateData(b_forceUpdate: Boolean): void
		{
			if(mi_zoom < 0)
			{
				// wrong zoom, do not continue
				return;
			}
			var s_crs: String = container.crs;
			
			m_tilingUtils.onAreaChanged(s_crs, getGTileBBoxForWholeCRS(s_crs));
			m_tiledArea = m_tilingUtils.getTiledArea(container.getViewBBox(), mi_zoom);
			
			var tiledCache: WMSTileCache = m_cache as WMSTileCache;
			
			var request: URLRequest;
			var tileIndex: TileIndex = new TileIndex(mi_zoom);
			
			ma_currentTilesRequests = [];
			
			var loadRequests: Array = new Array();
			
			var rowMax: int = m_tiledArea.bottomRow;
			var colMax: int = m_tiledArea.rightCol;
			
			mi_totalVisibleTiles = (rowMax - m_tiledArea.topRow + 1) * (colMax - m_tiledArea.leftCol + 1);

			for(var i_row: uint = m_tiledArea.topRow; i_row <= rowMax; ++i_row) 
			{
				for(var i_col: uint = m_tiledArea.leftCol; i_col <= colMax; ++i_col) 
				{
					tileIndex = new TileIndex(mi_zoom, i_row, i_col);
					request = new URLRequest(getExpandedURL(tileIndex));
					// need to convert ${BASE_URL} because it's used in cachKey
					request.url = UniURLLoader.fromBaseURL(request.url);
					
					ma_currentTilesRequests.push(request);
					
					if(!tiledCache.isTileCached(s_crs, tileIndex, request, ma_specialCacheStrings))
					{	
						loadRequests.push({
							request: request,
							requestedCRS: container.crs,
							requestedTileIndex: tileIndex
						});
					} 
				}
			}
			
			if(loadRequests.length > 0)
			{
				dispatchEvent(new Event(START_TILES_LOADING));
				
				loadRequests.sort(sortTiles);
				
				var bkJobManager: BackgroundJobManager = BackgroundJobManager.getInstance();
				var jobName: String;
				mi_tilesCurrentlyLoading = loadRequests.length;
				for each(var requestObj: Object in loadRequests)
				{
					jobName = "Rendering tile " + requestObj.requestedTileIndex + " for layer: " + name
					// this already cancel previou job for current tile
					m_jobs.addNewTileJobRequest(requestObj.requestedTileIndex.mi_tileCol, requestObj.requestedTileIndex.mi_tileRow, m_loader, requestObj.request);
					
					m_loader.load(requestObj.request, {
						requestedCRS: requestObj.requestedCRS,
						requestedTileIndex:  requestObj.requestedTileIndex
					}, jobName);
				}
			} else {
				// all tiles were cached, draw them
				draw(graphics);
				
				dispatchEvent(new Event(ALL_TILES_LOADED));
			}
		}
		
		private function sortTiles(reqObject1: Object, reqObject2: Object): int
		{
			var tileIndex1: TileIndex = reqObject1.requestedTileIndex;
			var tileIndex2: TileIndex = reqObject2.requestedTileIndex;
			
			var layerCenter: Point = new Point(width / 2, height / 2);//container.getViewBBox().center;
			
			var tileCenter1: Point = getTilePosition(reqObject1.requestedCRS, tileIndex1);
			var tileCenter2: Point = getTilePosition(reqObject2.requestedCRS, tileIndex2);
			
			var dist1: int = Point.distance(layerCenter, tileCenter1);
			var dist2: int = Point.distance(layerCenter, tileCenter2);
			
			if(dist1 > dist2)
			{
				return 1;
			} else {
				if(dist1 < dist2)
					return -1;
			}
			return 0;
		} 
		private function getTilePosition(crs: String, tileIndex: TileIndex): Point
		{
			var tileBBox: BBox = getGTileBBox(crs, tileIndex);
			var topLeftPoint: Point = container.coordToPoint(new Coord(crs, tileBBox.xMin, tileBBox.yMax));
			
			topLeftPoint.x = Math.floor(topLeftPoint.x);
			topLeftPoint.y = Math.floor(topLeftPoint.y);
			
			return topLeftPoint;
		}
		
		public function getTileFromCache(request: URLRequest): Object
		{
			var tiledCache: WMSTileCache = m_cache as WMSTileCache;
			
			return tiledCache.getTile(request, ma_specialCacheStrings); 
		}
		
		private function findZoom(): void
		{
			var tilingExtent: BBox = getGTileBBoxForWholeCRS(container.crs);
			m_tilingUtils.onAreaChanged(container.crs, tilingExtent);
			mi_zoom = m_tilingUtils.getZoom(container.getViewBBox(), new Point(width, height));
		}
		
		override public function refresh(b_force: Boolean): void
		{
			findZoom();
			super.refresh(b_force);
			updateData(b_force);
		}
		
		override public function draw(graphics: Graphics): void
		{
			super.draw(graphics);
			customDraw(graphics);
		}
		
		private function customDraw(graphics: Graphics, redrawBorder: Boolean = false): void
		{
			if(mi_zoom == -1)
			{
				trace("InteractiveLayerQTTMS.customDraw(): Isomething is wrong, tile zoom is -1");
				return;
			}

			var currentBBox: BBox = container.getViewBBox();
			var tilingBBox: BBox = getGTileBBoxForWholeCRS(container.crs); // extent of tile z=0/r=0/c=0
			if(tilingBBox == null) {
				trace("InteractiveLayerQTTMS.customDraw(): No tiling extent for CRS " + container.crs);
				return;
			}

			var matrix: Matrix;
			var wmsTileCache: WMSTileCache = m_cache as WMSTileCache;
			
			var a_tiles: Array = wmsTileCache.getTiles(container.crs, mi_zoom, ma_specialCacheStrings);
			var allTiles: Array = a_tiles.reverse();
			
			var topLeftCoord: Coord;
			var topRightCoord: Coord;
			var bottomLeftCoord: Coord;
			
			var topLeftPoint: Point;
			var topRightPoint: Point;
			var bottomLeftPoint: Point;
			
			graphics.clear();
			graphics.lineStyle(0,0,0);
			
			var t_tile: Object;
			var tileIndex: TileIndex;
			
			var newWidth: Number;
			var newHeight: Number;
			var sx: Number;
			var sy: Number;
			var xx: Number;
			var yy: Number;
				
			var cnt: int = 0;
			var s_crs: String = container.crs;
			for each(t_tile in allTiles) {
				
				tileIndex = t_tile.tileIndex;
				
				var tileBBox: BBox = getGTileBBox(s_crs, tileIndex);
				topLeftPoint = container.coordToPoint(new Coord(s_crs, tileBBox.xMin, tileBBox.yMax));
				topRightPoint = container.coordToPoint(new Coord(s_crs, tileBBox.xMax, tileBBox.yMax));
				bottomLeftPoint = container.coordToPoint(new Coord(s_crs, tileBBox.xMin, tileBBox.yMin));
			
				var origNewWidth: Number = topRightPoint.x - topLeftPoint.x;
				var origNewHeight: Number = bottomLeftPoint.y - topLeftPoint.y;

				newWidth = origNewWidth;
				newHeight = origNewHeight;
				sx = newWidth / 256;
				sy = newHeight / 256;
				xx = topLeftPoint.x;
				yy = topLeftPoint.y;
				
				matrix = new Matrix();
				matrix.scale(sx, sy);
				matrix.translate(xx, yy);
				
				graphics.beginBitmapFill(t_tile.image.bitmapData, matrix, false, imageSmooth);
				graphics.drawRect(xx, yy, newWidth , newHeight);
				graphics.endFill();
					
				//draw tile border 
				if(drawBorders || redrawBorder)
				{
					graphics.lineStyle(1, 0xff0000,0.3);
					graphics.drawRect(xx, yy, newWidth , newHeight);
				}
				
				if(drawDebugText)
				{
					drawText(tileIndex.mi_tileZoom + ", "
							+ tileIndex.mi_tileCol + ", "
							+ tileIndex.mi_tileRow,
							graphics, new Point(xx + 10, yy + 5));
				}
					
			}
			
			tileScaleX = sx;
			tileScaleY = sy;
			
			m_cache.sortCache(m_tiledArea);
			dispatchEvent(new Event(DRAW_TILES));
		}
		
		public override function hasPreview(): Boolean
		{ return mi_zoom != -1; }
		
		public override function renderPreview(graphics: Graphics, f_width: Number, f_height: Number): void
		{
			if(!width || !height)
				return;
			var matrix: Matrix  = new Matrix();
			matrix.translate(-f_width / 3, -f_width / 3);
			matrix.scale(3, 3);
			matrix.translate(width / 3, height / 3);
			matrix.invert();
			var bd: BitmapData = new BitmapData(width, height, true, 0x00000000);
			bd.draw(this);
			
			graphics.beginBitmapFill(bd, matrix, false, true);
			graphics.drawRect(0, 0, f_width, f_height);
			graphics.endFill();
		}
		
		private var _tf:TextField = new TextField();
		private var _tfBD:BitmapData;
		private function drawText(txt: String, gr: Graphics, pos: Point): void
		{
			if(!_tf.filters || !_tf.filters.length) {
				_tf.filters = [new GlowFilter(0xffffffff)];
			}
			var tfWidth: int = 100;
			var tfHeight: int = 30;
			var format: TextFormat = _tf.getTextFormat();
			format.size = 18;
			_tf.setTextFormat(format);
			_tf.text = txt;

			_tfBD = new BitmapData(tfWidth, tfHeight, true, 0);
			_tfBD.draw(_tf);
			
			var m: Matrix = new Matrix();
			m.translate(pos.x, pos.y)
			gr.lineStyle(0,0,0);
			gr.beginBitmapFill(_tfBD, m, false);
			gr.drawRect(pos.x, pos.y, tfWidth, tfHeight);
			gr.endFill();
		}
		
		private var _oldViewBBox: BBox = new BBox(0,0,0,0);
		
		override public function onAreaChanged(b_finalChange: Boolean): void
		{
			super.onAreaChanged(b_finalChange);
			if(_oldViewBBox.equals(container.getViewBBox()) &&!b_finalChange)
			{
				trace(" view BBOX is not changed");
				return;
			}
			m_tilingUtils.onAreaChanged(container.crs, getGTileBBoxForWholeCRS(container.crs));
			
			if(b_finalChange) {
				
				var oldZoom: int = mi_zoom;
				
				findZoom();
				if(mi_zoom != oldZoom)
				{
					m_cache.invalidate(container.crs, container.getViewBBox());
				}
				updateData(false);
			}
			else
				invalidateDynamicPart();
				
			_oldViewBBox = container.getViewBBox();
		}
		
		private function checkIfAllTilesAreLoaded(): void
		{
			if(mi_tilesCurrentlyLoading == 0)
			{
				dispatchEvent(new Event(ALL_TILES_LOADED));
			}
		}
		
		protected function onDataLoaded(event: UniURLLoaderEvent): void
		{
			mi_tilesCurrentlyLoading--;
			checkIfAllTilesAreLoaded();
			
			var result: * = event.result;
			var wmsTileCache: WMSTileCache = m_cache as WMSTileCache;
			
			onJobFinished(event.associatedData.job);
			
			if(result is Bitmap) {
				wmsTileCache.addTile(
					Bitmap(result),
					event.associatedData.requestedCRS,
					event.associatedData.requestedTileIndex,
					event.request,
					ma_specialCacheStrings, m_tiledArea);
				draw(graphics);
				return;

			}

			onDataLoadFailed(null);
		}
		
		protected function onDataLoadFailed(event: UniURLLoaderEvent): void
		{
			mi_tilesCurrentlyLoading--;
			checkIfAllTilesAreLoaded();
		}
		
		public function getGTileBBoxForWholeCRS(s_crs: String): BBox
		{
			if(s_crs in md_crsToTilingExtent)
				return md_crsToTilingExtent[s_crs];
			if(s_crs == "EPSG:4326")
				return new BBox(-180, -180, 180, 180);
			if(s_crs == "EPSG:900913")
				return new BBox(-20037508,-20037508,20037508,20037508.34);
			return null;
		}

		public function getGTileBBox(s_crs: String, tileIndex: TileIndex): BBox
		{
			var extent: BBox = getGTileBBoxForWholeCRS(s_crs);
			if(extent == null)
				return null;

			var i_tilesInSerie: uint = 1 << tileIndex.mi_tileZoom;
			var f_tileWidth: Number = extent.width / i_tilesInSerie;
			var f_tileHeight: Number = extent.height / i_tilesInSerie;
			var f_xMin: Number = extent.xMin + tileIndex.mi_tileCol * f_tileWidth; 

			// note that tile row numbers increase in the opposite way as the Y-axis

			var f_yMin: Number = extent.yMax - (tileIndex.mi_tileRow + 1) * f_tileHeight;

			var tileBBox: BBox = new BBox(f_xMin, f_yMin, f_xMin + f_tileWidth, f_yMin + f_tileHeight);
			
			return tileBBox;
		}
		
		
		public function get tilingUtils(): TilingUtils
		{
			return m_tilingUtils;
		}
		
		public function get dataLoader(): UniURLLoader
		{ return m_loader; } 
		
		override public function clone(): InteractiveLayer
		{
			var newLayer: InteractiveLayerQTTMS = new InteractiveLayerQTTMS(
					container, ms_baseURL, crs, viewBBox.clone(), minimumZoom, maximumZoom);
			newLayer.alpha = alpha
			newLayer.zOrder = zOrder;
			newLayer.visible = visible;
					
//			trace("\n\n CLONE InteractiveLayerQTTMS ["+newLayer.name+"] alpha: " + newLayer.alpha + " zOrder: " +  newLayer.zOrder);
			
			return newLayer;
			
		}
		
		protected function onJobFinished(job: BackgroundJob): void
		{
			if(job != null) {
				job.finish();
				job = null;
			}
			invalidateDynamicPart();
		}
		
		public function setSpecialCacheStrings(arr: Array): void
		{
			ma_specialCacheStrings = arr;
		}

		public function get baseURL(): String
		{ return ms_baseURL; }
		
		public function set baseURL(s_baseURL: String): void
		{ ms_baseURL = s_baseURL; }
		
		public function get zoomLevel(): int
		{ return mi_zoom; }
	}
}
import com.iblsoft.flexiweather.utils.UniURLLoader;
import com.iblsoft.flexiweather.widgets.BackgroundJob;

import flash.net.URLRequest;
import flash.utils.Dictionary;

import mx.messaging.AbstractConsumer;

class TileJobs
{
	private var m_jobs: Dictionary;
	
	public function TileJobs()
	{
		m_jobs = new Dictionary();	
	}
	public function addNewTileJobRequest(x: int, y: int, urlLoader: UniURLLoader, urlRequest: URLRequest): void
	{
		var _existingJob: TileJob = m_jobs[x+"_"+y] as TileJob;
		if (_existingJob)
		{
			_existingJob.cancelRequests();
			_existingJob.urlLoader = urlLoader;
			_existingJob.urlRequest = urlRequest;
		} else {
			m_jobs[x+"_"+y] = new TileJob(x,y,urlRequest, urlLoader);
		}
		
	}
}

class TileJob
{
	private var mi_x: int;
	private var mi_y: int;
	private var m_urlRequest: URLRequest;
	private var m_urlLoader: UniURLLoader;

	public function set urlRequest(value:URLRequest):void
	{
		m_urlRequest = value;
	}

	public function set urlLoader(value:UniURLLoader):void
	{
		m_urlLoader = value;
	}
	
	public function TileJob(x: int, y: int, request: URLRequest, loader: UniURLLoader)
	{
		mi_x = x;
		mi_y = y;
		m_urlRequest = request;
		m_urlLoader = loader;
	}

	public function cancelRequests(): void
	{
		m_urlLoader.cancel(m_urlRequest);
	}
}