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
	import flash.geom.Matrix;
	import flash.geom.Point;
	import flash.net.URLRequest;
	import flash.text.TextField;
	import flash.text.TextFormat;
	import flash.utils.Timer;
	
	[Event(name='drawTiles', type='')]
	public class InteractiveLayerQTTMS extends InteractiveLayer
	{
		public static const DRAW_TILES: String = 'drawTiles';
		public static const START_TILES_LOADING: String = 'startTilesLoading';
		public static const ALL_TILES_LOADED: String = 'onAllTilesLoaded';
		
		public static var imageSmooth: Boolean = true;
		public static var drawBorders: Boolean = false;
		public static var drawDebugText: Boolean = false;
		
		protected var m_loader: UniURLLoader = new UniURLLoader();
		protected var m_image: Bitmap = null;
		
		protected var m_tiledArea: TiledArea;
		
		protected var m_cache: WMSTileCache;

		public function get cache(): WMSTileCache
		{
			return m_cache;
		}
		
		private var _specialCacheStrings: Array;
		
		protected var m_timer: Timer = new Timer(10000);
		
		protected var m_request: URLRequest;

		public var minimumZoom: int = 0;
		public var maximumZoom: int = 10;
		
		private var ms_baseURL: String;
		private var ms_crs: String;
		private var m_viewBBox: BBox = null;
		
		public function get baseURL(): String
		{ return ms_baseURL; }

		public function set baseURL(s_baseURL: String): void
		{ ms_baseURL = s_baseURL; }
				
		private var _oldCRS: String;

		public function get crs(): String
		{
			var _crs: String =  container.getCRS();
			_oldCRS = _crs;
			return _crs;
		}
		
		public function get viewBBox(): BBox
		{
			return container.getViewBBox();
		}
		
		private var m_tilingUtils: TilingUtils;
		
		public function InteractiveLayerQTTMS(container: InteractiveWidget, s_baseURL: String, s_crs: String, bbox: BBox, minimumZoom: int = 0, maximumZoom: int = 10)
		{
			super(container);
			
			ms_crs = s_crs;
			m_viewBBox = bbox;
			ms_baseURL = s_baseURL;
			
			this.minimumZoom = minimumZoom;
			this.maximumZoom = maximumZoom;
			
			m_cache = new WMSTileCache();
			m_tilingUtils = new TilingUtils();
			m_tilingUtils.minimumZoom = minimumZoom;
			m_tilingUtils.maximumZoom = maximumZoom;
			
			m_loader.addEventListener(UniURLLoader.DATA_LOADED, onDataLoaded);
			m_loader.addEventListener(UniURLLoader.DATA_LOAD_FAILED, onDataLoadFailed);
		}

		private var mi_zoom: int = -1;

		public function get zoom(): int
		{
			return mi_zoom;
		}

		public var tileScaleX: Number;
		public var tileScaleY: Number;
		
		public function get layerZoom(): uint
		{
			return mi_zoom;
		}
		
		private var ma_currentTilesRequests: Array = [];

		public function get currentTilesRequests(): Array
		{
			return ma_currentTilesRequests;
		}
		
		private function getExpandedURL(tileIndex: TileIndex): String
		{
			var ret: String = ms_baseURL;
			ret = ret.replace('%COL%', String(tileIndex.mi_tileCol));
			ret = ret.replace('%ROW%', String(tileIndex.mi_tileRow));
			ret = ret.replace('%ZOOM%', String(tileIndex.mi_tileZoom));
			return ret;
		}

		private var mi_totalVisibleTiles: int;
		
		public function invalidateCache(): void
		{
			m_cache.invalidate(crs, getGTileBBoxForWholeCRS(crs));
		}

		public function updateData(b_forceUpdate: Boolean): void
		{
//			super.updateData(b_forceUpdate);
			
			if(mi_zoom <= 0)
			{
				//wrong zoom, do not continue
				return;
			}
//			var crs: String = container.getCRS();
			m_tilingUtils.onAreaChanged(crs, getGTileBBoxForWholeCRS(crs));
			m_tiledArea = m_tilingUtils.getTiledArea(container.getViewBBox(), mi_zoom);
			
//			trace("QTTMS updateData: " + _zoom + " m_tiledArea: " + m_tiledArea);
			var tiledCache: WMSTileCache = m_cache as WMSTileCache;
//			trace("updateData ["+name+"]: m_tiledArea : " + m_tiledArea.leftCol + ", " + m_tiledArea.topRow + " size: " + m_tiledArea.colTilesCount + " , " + m_tiledArea.rowTilesCount);
			
			var request: URLRequest;
			var tileIndex: TileIndex = new TileIndex(mi_zoom);
			
			ma_currentTilesRequests = [];
			
			var loadRequests: Array = new Array();
			
//			var rowMax: int = Math.min(m_tiledArea.bottomRow, Math.pow(2, _zoom) - 1);
//			var colMax: int = Math.min(m_tiledArea.rightCol, Math.pow(2, _zoom) - 1);
			var rowMax: int = m_tiledArea.bottomRow;
			var colMax: int = m_tiledArea.rightCol;
			
//			if(rowMax < m_tiledArea.bottomRow || colMax < m_tiledArea.rightCol)
//			{
//				trace("wrong max tiles");
//			}
			mi_totalVisibleTiles = (rowMax - m_tiledArea.topRow + 1) * (colMax - m_tiledArea.leftCol + 1);
//			trace("ROWS: " + m_tiledArea.topRow + " , " + rowMax);
//			trace("COLS: " + m_tiledArea.leftCol + " , " + colMax);
//			trace("_totalVisibleTiles: " + _totalVisibleTiles);
			for(var i_row: uint = m_tiledArea.topRow; i_row <= rowMax; ++i_row) 
			{
				for(var i_col: uint = m_tiledArea.leftCol; i_col <= colMax; ++i_col) 
				{
					tileIndex = new TileIndex(mi_zoom, i_row, i_col);
					request = new URLRequest(getExpandedURL(tileIndex));
					//need to convert ${BASE_URL} because it's used in cachKey
					request.url = UniURLLoader.fromBaseURL(request.url);
					
					ma_currentTilesRequests.push(request);
					
//					trace("col: " + i_col + " i_row: " + i_row + " url = " + request.url);
					if(!tiledCache.isTileCached(crs, tileIndex, request, _specialCacheStrings))
					{	
						loadRequests.push({request: request, requestedCRS: crs, requestedTileIndex: tileIndex});
					} 
				}
			}
			
			if(loadRequests.length > 0)
			{
				dispatchEvent(new Event(START_TILES_LOADING));
				
				loadRequests.sort(sortTiles);
				
				var bkJobManager: BackgroundJobManager = BackgroundJobManager.getInstance();
				var job: BackgroundJob;
				_tileCurrentlyLoading = loadRequests.length;
				for each(var requestObj: Object in loadRequests)
				{
//					trace("\t load QTTMS request: " + requestObj.requestedTileIndex);
					
					job = bkJobManager.startJob("Rendering tile " + requestObj.requestedTileIndex + " for layer: " + name);
					
					m_loader.load(requestObj.request, {
						job: job,
						requestedCRS: requestObj.requestedCRS,
						requestedTileIndex:  requestObj.requestedTileIndex
					});
				}
			} else {
				//all tiles was cached, draw them
				draw(graphics);
				
				dispatchEvent(new Event(ALL_TILES_LOADED));
			}
		}
		
		private var _tileCurrentlyLoading: int;
		
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
			
			return tiledCache.getTile(request, _specialCacheStrings); 
		}
		
		private function findZoom(): void
		{
//			var crs: String = container.getCRS();
			var extent: BBox = getGTileBBoxForWholeCRS(crs);
			m_tilingUtils.onAreaChanged(crs, extent);
			
			mi_zoom = m_tilingUtils.getZoom(viewBBox, new Point(width, height));
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
			
			if(mi_zoom == -1)
			{
				trace("something is wrong, zoom is -1");
				return;
			}
			customDraw(graphics);
		}
		
		private function customDraw(graphics: Graphics, redrawBorder: Boolean = false): void
		{
				
			var currentBBox: BBox = viewBBox;
			var tilingBBox: BBox = getGTileBBoxForWholeCRS(crs); // extent of tile z=0/r=0/c=0

			var matrix: Matrix;
			var wmsTileCache: WMSTileCache = m_cache as WMSTileCache;
			
			var a_tiles: Array = wmsTileCache.getTiles(crs, mi_zoom, _specialCacheStrings);
			var allTiles: Array = a_tiles.reverse();
			
			
//			trace("customDraw TILES: " + allTiles.length);
			
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
			for each(t_tile in allTiles) {
				
				tileIndex = t_tile.tileIndex;
				
				var tileBBox: BBox = getGTileBBox(crs, tileIndex);
				topLeftPoint = container.coordToPoint(new Coord(crs, tileBBox.xMin, tileBBox.yMax));
				topRightPoint = container.coordToPoint(new Coord(crs, tileBBox.xMax, tileBBox.yMax));
				bottomLeftPoint = container.coordToPoint(new Coord(crs, tileBBox.xMin, tileBBox.yMin));
			
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
					drawText(tileIndex.mi_tileCol + ", " + tileIndex.mi_tileRow, graphics, new Point(xx + 10, yy + 5));
				}
					
			}
			
			tileScaleX = sx;
			tileScaleY = sy;
			
			m_cache.sortCache(m_tiledArea);
			dispatchEvent(new Event(DRAW_TILES));
		}
		
		private var _tf:TextField = new TextField();
		private var _tfBD:BitmapData;
		private function drawText(txt: String, gr: Graphics, pos: Point): void
		{
			var tfWidth: int = 100;
			var tfHeight: int = 30;
			var format: TextFormat = _tf.getTextFormat();
			format.size = 18;
			_tf.setTextFormat(format)
			_tf.text = txt;

			_tfBD = new BitmapData(tfWidth, tfHeight, true, 0xffbbbbbb);
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
			if(_oldViewBBox.equals(viewBBox) &&!b_finalChange)
			{
				trace(" view BBOX is not changed");
				return;
			}
			m_tilingUtils.onAreaChanged(crs, getGTileBBoxForWholeCRS(crs));
			
			if(b_finalChange) {
				
				var oldZoom: int = mi_zoom;
				
				findZoom();
				if(mi_zoom != oldZoom)
				{
					m_cache.invalidate(crs, viewBBox);
				}
				updateData(false);
			}
			else
				invalidateDynamicPart();
				
			_oldViewBBox = viewBBox.clone();
		}
		
		private function checkIfAllTilesAreLoaded(): void
		{
			if(_tileCurrentlyLoading == 0)
			{
				dispatchEvent(new Event(ALL_TILES_LOADED));
			}
		}
		
		protected function onDataLoaded(event: UniURLLoaderEvent): void
		{
			_tileCurrentlyLoading--;
			checkIfAllTilesAreLoaded();
			
			m_request = null;
			
			var result: * = event.result;
			var wmsTileCache: WMSTileCache = m_cache as WMSTileCache;
			
			onJobFinished(event.associatedData.job);
			
			if(result is Bitmap) {
				m_image = result;

				wmsTileCache.addTile(
					m_image,
					event.associatedData.requestedCRS,
					event.associatedData.requestedTileIndex,
					event.request,
					_specialCacheStrings, m_tiledArea);
				draw(graphics);
				return;

			}

//			ExceptionUtils.logError(Log.getLogger("WMS"), result, "Error accessing layers '" + m_cfg.ma_layerNames.join(","))
			onDataLoadFailed(null);
		}
		
		protected function onDataLoadFailed(event: UniURLLoaderEvent): void
		{
			
			m_request = null;
//			if(m_cfg.mi_autoRefreshPeriod > 0) {
//				m_timer.reset();
//				m_timer.delay = m_cfg.mi_autoRefreshPeriod * 1000.0;
//				m_timer.start();
//			}
//			if(event != null) {
//				ExceptionUtils.logError(Log.getLogger("WMS"), event,
//						"Error accessing layers '" + m_cfg.ma_layerNames.join(","))
//			}
			m_image = null;
//			mb_imageOK = false;
//			ms_imageCRS = null;
//			m_imageBBox = null;
//			onJobFinished();

			_tileCurrentlyLoading--;
			checkIfAllTilesAreLoaded();
		}
		
		public function getGTileBBoxForWholeCRS(s_crs: String): BBox
		{
			if(s_crs == "EPSG:4326")
				return new BBox(-180, -90, 180, 90);
			if(s_crs == "EPSG:900913")
				return new BBox(-20037508,-20037508,20037508,20037508.34);
			if(s_crs == "EPSG:54004")
				return new BBox(0, -130000, 36000000, 13000000);

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
			_specialCacheStrings = arr;
		}
	}
		
}