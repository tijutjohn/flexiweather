package com.iblsoft.flexiweather.ogc
{
	import com.iblsoft.flexiweather.ogc.cache.WMSTileCache;
	import com.iblsoft.flexiweather.ogc.tiling.TileIndex;
	import com.iblsoft.flexiweather.ogc.tiling.TiledArea;
	import com.iblsoft.flexiweather.ogc.tiling.TilingUtils;
	import com.iblsoft.flexiweather.proj.Coord;
	import com.iblsoft.flexiweather.utils.Serializable;
	import com.iblsoft.flexiweather.utils.Storage;
	import com.iblsoft.flexiweather.utils.UniURLLoader;
	import com.iblsoft.flexiweather.utils.UniURLLoaderEvent;
	import com.iblsoft.flexiweather.widgets.BackgroundJob;
	import com.iblsoft.flexiweather.widgets.BackgroundJobManager;
	import com.iblsoft.flexiweather.widgets.IConfigurableLayer;
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
	
	import spark.primitives.Graphic;
	
	[Event(name='drawTiles', type='')]
	
	/**
	 * Generic Quad Tree (like Google Maps) tiling layer
	 **/
	public class InteractiveLayerQTTMS extends InteractiveLayer implements IConfigurableLayer, Serializable
	{
		public static const UPDATE_TILING_PATTERN: String = 'updateTilingPattern';
		
		public static const DRAW_TILES: String = 'drawTiles';
		public static const START_TILES_LOADING: String = 'startTilesLoading';
		public static const ALL_TILES_LOADED: String = 'onAllTilesLoaded';
		
		public static var imageSmooth: Boolean = true;
		public static var drawBorders: Boolean = false;
		public static var drawDebugText: Boolean = false;
		
		protected var m_loader: UniURLLoader = new UniURLLoader();
		
		protected var m_tiledArea: TiledArea;
		
		


		private var _avoidTiling: Boolean;
		public function set avoidTiling(value:Boolean):void
		{
			_avoidTiling = value;
		}

		protected var m_cache: WMSTileCache;
		public function get cache(): WMSTileCache
		{
			return m_cache;
		}
		
		private var ma_specialCacheStrings: Array;
		
		protected var m_timer: Timer = new Timer(10000);
		
		
		
		protected var m_cfg: QTTMSLayerConfiguration;
		public function get configuration():ILayerConfiguration
		{
			return m_cfg;
		}
		
		/** This is used only if overriding using the setter, otherwise the value from m_cfg is used. */ 
		protected var ms_explicitBaseURLPattern: String;
		
		
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
				container: InteractiveWidget,
				cfg: QTTMSLayerConfiguration,
				s_baseURLPattern: String = null, s_primaryCRS: String = null, primaryCRSTilingExtent: BBox = null,
				minimumZoomLevel: uint = 0, maximumZoomLevel: uint = 10)
		{
			super(container);
			
			var tilingInfo: QTTilingInfo
			if(cfg == null) {
				cfg = new QTTMSLayerConfiguration();
				tilingInfo = new QTTilingInfo(s_baseURLPattern, new CRSWithBBox(s_primaryCRS, primaryCRSTilingExtent));
//				cfg.urlPattern = s_baseURLPattern;
//				if(s_primaryCRS != null && primaryCRSTilingExtent != null)
//						cfg.tilingCRSsAndExtents.push(new CRSWithBBox(s_primaryCRS, primaryCRSTilingExtent));
				tilingInfo.minimumZoomLevel = minimumZoomLevel;
				tilingInfo.maximumZoomLevel = maximumZoomLevel;
				cfg.addQTTilingInfo(tilingInfo);
			}
			m_cfg = cfg;
			
			/*
			for each(var crsWithBBox: CRSWithBBox in cfg.tilingCRSsAndExtents) {
				md_crsToTilingExtent[crsWithBBox.crs] = crsWithBBox.bbox;
			}
			*/
			
			m_cache = new WMSTileCache();
			m_tilingUtils = new TilingUtils();
			m_tilingUtils.minimumZoom = minimumZoomLevel;
			m_tilingUtils.maximumZoom = maximumZoomLevel;
			
			m_loader.addEventListener(UniURLLoader.DATA_LOADED, onDataLoaded);
			m_loader.addEventListener(UniURLLoader.DATA_LOAD_FAILED, onDataLoadFailed);
			
			m_jobs = new TileJobs();
		}

		public function serialize(storage: Storage): void
		{
			trace("InteractiveLayerQTTMS serialize");
			
			if (storage.isLoading())
			{
				var newAlpha: Number = storage.serializeNumber("transparency", alpha);
				if (newAlpha < 1)
				{
					alpha = newAlpha;
				}
			} else {
				if (alpha < 1) 
				{
					storage.serializeNumber("transparency", alpha);
				}
			}
		}
		
		public override function invalidateSize(): void
		{
			super.invalidateSize();
			if (container != null)
			{
				width = container.width;
				height = container.height;
			}
		}
		
		public override function validateSize(b_recursive: Boolean = false): void
		{
			super.validateSize(b_recursive);
			
			
			var i_oldZoom: int = mi_zoom;
			findZoom();
			if (i_oldZoom != mi_zoom)
			{
				/**
				 * check if tiling pattern has been update with all data needed 
				 * (default pattern is just InteractiveLayerWMSWithQTT.WMS_TILING_URL_PATTERN ('&TILEZOOM=%ZOOM%&TILECOL=%COL%&TILEROW=%ROW%') without any WMS data)
				 */ 
				notifyTilingPatternUpdate();
				updateData(false);
			}
		}
		
		private function notifyTilingPatternUpdate(): void
		{
			dispatchEvent(new Event(UPDATE_TILING_PATTERN));
		}

		public static function expandURLPattern(s_url: String, tileIndex: TileIndex): String
		{
			if (s_url)
			{
				s_url = s_url.replace('%COL%', String(tileIndex.mi_tileCol));
				s_url = s_url.replace('%ROW%', String(tileIndex.mi_tileRow));
				s_url = s_url.replace('%ZOOM%', String(tileIndex.mi_tileZoom));
			} else {
				trace("expandURLPattern problem with url");
			}
			return s_url;
		}

		private function getExpandedURL(tileIndex: TileIndex): String
		{
			return expandURLPattern(baseURLPattern, tileIndex);
		}

		public function invalidateCache(): void
		{
			m_cache.invalidate(container.crs, getGTileBBoxForWholeCRS(container.crs));
		}

		
		public function clearCRSWithTilingExtents(): void
		{
			m_cfg.removeAllTilingInfo();
			//md_crsToTilingExtent = new Dictionary(); 
		}

		public function addCRSWithTilingExtent(s_urlPattern: String, s_tilingCRS: String, crsTilingExtent: BBox): void
		{
			var crsWithBBox: CRSWithBBox = new CRSWithBBox(s_tilingCRS, crsTilingExtent);
			var tilingInfo: QTTilingInfo = new QTTilingInfo(s_urlPattern, crsWithBBox);
			
			m_cfg.addQTTilingInfo(tilingInfo);
			
			//md_crsToTilingExtent[s_tilingCRS] = crsTilingExtent;
		}

		/**
		 * Function which loadData. It's good habit to call this function when you want to load your data to have one channel for loading data.
		 * It's easier to testing and it's one place for checking requests
		 *  
		 * @param urlRequest
		 * @param associatedData
		 * @param s_backgroundJobName
		 * 
		 */	
		public function loadData(
			urlRequest: URLRequest,
			associatedData: Object = null,
			s_backgroundJobName: String = null): void
		{
			var url: String = urlRequest.url;
			m_loader.load(urlRequest, associatedData, s_backgroundJobName);
			
			//check associated data
			/*
			if (associatedData)
			{
				for (var item: String in associatedData)
				{
					trace("InteractiveLayerQTTMS loadData : " + item + "=" + associatedData[item]);
				}
			}*/
			
		}
		
		public function updateData(b_forceUpdate: Boolean): void
		{
			if (_avoidTiling)
			{
				//tiling for this layer is for now avoided, do not update data
				return;
			}
			
			if(mi_zoom < 0)
			{
				// wrong zoom, do not continue
				return;
			}
			var s_crs: String = container.crs;
			
			m_tilingUtils.onAreaChanged(s_crs, getGTileBBoxForWholeCRS(s_crs));
			m_tiledArea = m_tilingUtils.getTiledArea(container.getViewBBox(), mi_zoom);
			
			if (!m_tiledArea)
				return;
			
			var tiledCache: WMSTileCache = m_cache as WMSTileCache;
			
			var request: URLRequest;
			var tileIndex: TileIndex = new TileIndex(mi_zoom);
			
			ma_currentTilesRequests = [];
			
			var loadRequests: Array = new Array();
			
			var rowMax: int = m_tiledArea.bottomRow;
			var colMax: int = m_tiledArea.rightCol;
			
			mi_totalVisibleTiles = (rowMax - m_tiledArea.topRow + 1) * (colMax - m_tiledArea.leftCol + 1);

			if (baseURLPattern)
			{
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
			} else {
				trace("baseURLpattern is NULL");
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
					
					loadData(requestObj.request, {
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
			var viewBBox: BBox = container.getViewBBox();
			
			//new Jozef tiling zoom equation
			var newZoomLevel2: Number = 1;
			if (tilingExtent)
			{
				var test: Number = (tilingExtent.width * width) / (viewBBox.width * 256);
				var newZoomLevel2: Number = Math.log(test) * Math.LOG2E;
				trace("New Jozef' zoom:  " + newZoomLevel2);
			}
			
			mi_zoom = Math.round(newZoomLevel2);
			//mi_zoom = m_tilingUtils.getZoom(viewBBox, new Point(width, height));
			trace("FIND ZOOM:  zoom = " + mi_zoom + " new zoom: " + newZoomLevel2);
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

			
			var newCRS: String = container.crs;
			var tilingInfo: QTTilingInfo = m_cfg.getQTTilingInfoForCRS(newCRS);
			if (!tilingInfo)
			{
				//crs is not supported
				graphics.lineStyle(2, 0xcc0000, 0.7, true);
				graphics.moveTo(0, 0);
				graphics.lineTo(f_width - 1, f_height - 1);
				graphics.moveTo(0, f_height - 1);
				graphics.lineTo(f_width - 1, 0);
				
				return;
			}
			
			
			
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
		
		public function getGTileBBoxForWholeCRS(s_crs: String): BBox
		{
			var tilingInfo: QTTilingInfo = m_cfg.getQTTilingInfoForCRS(s_crs);
			if (tilingInfo)
				return tilingInfo.crsWithBBox.bbox;
			
//			if(s_crs in md_crsToTilingExtent)
//				return md_crsToTilingExtent[s_crs];
			
			return null;
		}
		
		private function hideMap(): void
		{
			var gr: Graphics = graphics; 
			gr.clear();
		}
		private function isZoomCompatible(newZoom: int): Boolean
		{
			var newCRS: String = container.crs;
			var tilingInfo: QTTilingInfo = m_cfg.getQTTilingInfoForCRS(newCRS);
			if (!tilingInfo)
			{
				hideMap();
				return false;
			}
			if (newZoom < tilingInfo.minimumZoomLevel || newZoom > tilingInfo.maximumZoomLevel)
			{
				hideMap();
				return false;
			}
			
			return true;
			
		}
		private function isCRSCompatible(): Boolean
		{
			var newCRS: String = container.crs;
			var tilingInfo: QTTilingInfo = m_cfg.getQTTilingInfoForCRS(newCRS);
			if (!tilingInfo)
			{
				//crs is not supported
				hideMap();
				return false;
			}
			return true;
			
		}
		override public function onAreaChanged(b_finalChange: Boolean): void
		{
			super.onAreaChanged(b_finalChange);
			
			var newCRS: String = container.crs;
			
			//check if CRS is supported
			if (!isCRSCompatible())
			{
				return;
			}
			var newBBox: BBox = getGTileBBoxForWholeCRS(newCRS);
			var viewBBox: BBox = container.getViewBBox();
			
//			trace("onAreaChanged newBBox: " + newBBox);
//			trace("onAreaChanged viewBBox: " + viewBBox);
			
			m_tilingUtils.onAreaChanged(newCRS, newBBox);
			
			if(b_finalChange || mi_zoom < 0) {
				var i_oldZoom: int = mi_zoom;
				
				findZoom();
				if (!isZoomCompatible(mi_zoom))
					return;
					
				if(mi_zoom != i_oldZoom)
				{
					m_cache.invalidate(newCRS, viewBBox);
				}
				updateData(false);
			}
			else
				invalidateDynamicPart();
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
			var newLayer: InteractiveLayerQTTMS = new InteractiveLayerQTTMS(container, m_cfg);
			newLayer.alpha = alpha
			newLayer.zOrder = zOrder;
			newLayer.visible = visible;
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

		public function get baseURLPattern(): String
		{
			if(ms_explicitBaseURLPattern == null)
			{
				var tilingInfo: QTTilingInfo;
				//TODO get current CRS 
				var crs: String = container.getCRS();
//				var tilingInfo: QTTilingInfo = m_cfg.getQTTilingInfoForCRS(crs);
				if (m_cfg.tilingCRSsAndExtents && m_cfg.tilingCRSsAndExtents.length > 0)
					tilingInfo = m_cfg.getQTTilingInfoForCRS(crs);
				
				if (tilingInfo && tilingInfo.urlPattern)
					return tilingInfo.urlPattern;
			}
			return ms_explicitBaseURLPattern;
		}
		
		/*
		public function set baseURLPattern(s_baseURL: String): void
		{ ms_explicitBaseURLPattern = s_baseURL; }
		*/
		
		public function get zoomLevel(): int
		{ return mi_zoom; }
		
		override public function toString(): String
		{
			return "InteractiveLayerQTTMS " + name  ;
		}
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