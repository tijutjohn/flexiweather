package com.iblsoft.flexiweather.ogc
{
	import com.iblsoft.flexiweather.ogc.cache.WMSTileCache;
	import com.iblsoft.flexiweather.ogc.tiling.TileIndex;
	import com.iblsoft.flexiweather.ogc.tiling.TiledArea;
	import com.iblsoft.flexiweather.ogc.tiling.TilingUtils;
	import com.iblsoft.flexiweather.proj.Coord;
	import com.iblsoft.flexiweather.utils.UniURLLoader;
	import com.iblsoft.flexiweather.utils.UniURLLoaderEvent;
	import com.iblsoft.flexiweather.widgets.InteractiveLayer;
	import com.iblsoft.flexiweather.widgets.InteractiveWidget;
	
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.Graphics;
	import flash.geom.Matrix;
	import flash.geom.Point;
	import flash.net.URLRequest;
	import flash.text.TextField;
	import flash.text.TextFormat;
	import flash.utils.Timer;
	
	public class InteractiveLayerQTTMS extends InteractiveLayer
	{
		public static var imageSmooth: Boolean = true;
		public static var drawBorders: Boolean = false;
		public static var drawDebugText: Boolean = false;
		
		protected var m_loader: UniURLLoader = new UniURLLoader();
		protected var m_image: Bitmap = null;
		
		protected var m_cache: WMSTileCache;
		
		protected var m_timer: Timer = new Timer(10000);
		
		protected var m_request: URLRequest;

		public var minimumZoom: int = 0;
		public var maximumZoom: int = 10;
		
		private var ms_baseURL: String;
		private var ms_tilePattern: String;
		private var ms_postURL: String;
		private var ms_crs: String;
		private var m_viewBBox: BBox = null;
		
		public function get crs(): String
		{
			return container.getCRS();
			//return ms_crs;
		}
		
		public function get viewBBox(): BBox
		{
			return container.getViewBBox();
//			return m_viewBBox;
		}
		
		private var _tilingUtils: TilingUtils;
		
		public function InteractiveLayerQTTMS(container: InteractiveWidget, s_baseURL: String, s_tilePattern: String,  s_postURL: String,  s_crs: String, bbox: BBox, minimumZoom: int = 0, maximumZoom: int = 10)
		{
			super(container);
			
			ms_crs = s_crs;
			m_viewBBox = bbox;
			ms_baseURL = s_baseURL;
			ms_tilePattern = s_tilePattern;
			ms_postURL = s_postURL;
			
			this.minimumZoom = minimumZoom;
			this.maximumZoom = maximumZoom;
			
			m_cache = new WMSTileCache();
			_tilingUtils = new TilingUtils();
			_tilingUtils.minimumZoom = minimumZoom;
			_tilingUtils.maximumZoom = maximumZoom;
			
			m_loader.addEventListener(UniURLLoader.DATA_LOADED, onDataLoaded);
			m_loader.addEventListener(UniURLLoader.DATA_LOAD_FAILED, onDataLoadFailed);
		}

		private var _zoom: uint = 1;
		public var tileScaleX: Number;
		public var tileScaleY: Number;
		
		public function get layerZoom(): uint
		{
			return _zoom;
		}
		
		private var _currentTilesRequests: Array = [];
		public function get currentTilesRequests(): Array
		{
			return _currentTilesRequests;
		}
		
		private function getTileFromPattern(tileIndex: TileIndex): String
		{
			var ret: String = ms_tilePattern;
			var arr: Array = ret.split('%COL%');
			ret = arr.join(tileIndex.mi_tileCol);
			arr = ret.split('%ROW%');
			ret = arr.join(tileIndex.mi_tileRow);
			arr = ret.split('%ZOOM%');
			ret = arr.join(tileIndex.mi_tileZoom);
			
			return ret;
		}
		public function updateData(b_forceUpdate: Boolean): void
		{
//			super.updateData(b_forceUpdate);
			
//			var crs: String = container.getCRS();
			_tilingUtils.onAreaChanged(crs, getGTileBBoxForWholeCRS(crs));
			var tiledArea: TiledArea = _tilingUtils.getTiledArea(container.getViewBBox(), _zoom);
			
			var tiledCache: WMSTileCache = m_cache as WMSTileCache;
//			trace("updateData ["+name+"]: tiledArea : " + tiledArea.leftCol + ", " + tiledArea.topRow + " size: " + tiledArea.colTilesCount + " , " + tiledArea.rowTilesCount);
			
			var request: URLRequest;
			var tileIndex: TileIndex = new TileIndex(_zoom);
			
			_currentTilesRequests = [];
			for(var i_row: uint = tiledArea.topRow; i_row <= tiledArea.bottomRow; ++i_row) 
			{
				for(var i_col: uint = tiledArea.leftCol; i_col <= tiledArea.rightCol; ++i_col) 
				{
					tileIndex = new TileIndex(_zoom, i_row, i_col );
					
					
					request = new URLRequest(ms_baseURL + getTileFromPattern(tileIndex) + ms_postURL);
					
					_currentTilesRequests.push(request);
					
					trace("col: " + i_col + " i_row: " + i_row + " url = " + request.url);
					
					if (!tiledCache.isTileCached(crs, tileIndex, request))
					{	
						m_loader.load(request, {
							requestedCRS: crs,
							requestedTileIndex: tileIndex
						});
					} 
				}
			}
		}
		
		public function getTileFromCache(request: URLRequest): Object
		{
			var tiledCache: WMSTileCache = m_cache as WMSTileCache;
			
			return tiledCache.getTile(request); 
		}
		
		private function findZoom(): void
		{
//			var crs: String = container.getCRS();
			var extent: BBox = getGTileBBoxForWholeCRS(crs);
			_tilingUtils.onAreaChanged(crs, extent);
			
			_zoom = _tilingUtils.getZoom(viewBBox, new Point(width, height));
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
//			var crs: String = container.getCRS();
			
			var currentBBox: BBox = viewBBox;
			var tilingBBox: BBox = getGTileBBoxForWholeCRS(crs); // extent of tile z=0/r=0/c=0

			var matrix: Matrix;
			var wmsTileCache: WMSTileCache = m_cache as WMSTileCache;
			
			var a_tiles: Array = wmsTileCache.getTiles(crs, _zoom);
//			trace("draw tiles ["+name+"]: " + a_tiles.length);
			
			var topLeftCoord: Coord;
			var topRightCoord: Coord;
			var bottomLeftCoord: Coord;
			var bottomRightCoord: Coord;
			
			var topLeftPoint: Point;
			var topRightPoint: Point;
			var bottomLeftPoint: Point;
			var bottomRightPoint: Point;
			
			var dump_tiles: Array = [];
			
			graphics.clear();
			graphics.lineStyle(0,0,0);
//			trace("y: " + this.y + " cont: " + container.y);
			
			for each(var t_tile: Object in a_tiles.reverse()) {
				
				var tileIndex: TileIndex = t_tile.tileIndex;
				
				var tileBBox: BBox = getGTileBBox(crs, tileIndex);
//				topLeftCoord = new Coord(crs, tileBBox.xMin, tileBBox.yMax);
				topLeftPoint = container.coordToPoint(new Coord(crs, tileBBox.xMin, tileBBox.yMax));
				topRightPoint = container.coordToPoint(new Coord(crs, tileBBox.xMax, tileBBox.yMax));
				bottomLeftPoint = container.coordToPoint(new Coord(crs, tileBBox.xMin, tileBBox.yMin));
//				bottomRightPoint = container.coordToPoint(new Coord(crs, tileBBox.xMax, tileBBox.yMin));
				
				var newWidth: int = Math.ceil( topRightPoint.x - topLeftPoint.x);
				var newHeight: int = Math.ceil( bottomLeftPoint.y - topLeftPoint.y);
				var sx: Number = int(100 * newWidth / 256)/100;
				var sy: Number = int(100 * newHeight / 256)/100;
				
				var xx: int = Math.floor(topLeftPoint.x);
				var yy: int = Math.floor(topLeftPoint.y);
				matrix = new Matrix();
				matrix.scale( sx, sy );
				matrix.translate(xx, yy);
					
				graphics.beginBitmapFill(t_tile.image.bitmapData, matrix, false, imageSmooth);
				graphics.drawRect(xx, yy, newWidth , newHeight);
				graphics.endFill();
					
				//draw tile border 
				if (drawBorders || redrawBorder)
				{
					graphics.lineStyle(1, 0xff0000,0.3);
					graphics.drawRect(xx, yy, newWidth , newHeight);
				}
//				trace("tile: " + tileIndex + " pos: " + xx + " , " + yy + " size: " + newWidth + " , " + newHeight);
				
				dump_tiles.push({key: tileIndex.mi_tileRow + tileIndex.mi_tileCol / 10,  x: tileIndex.mi_tileCol, y: tileIndex.mi_tileRow, left: xx, top: yy, right: xx + newWidth, bottom: yy + newHeight });
//				drawText(xx + ", " + yy + "\n" + topLeftCoord.toNiceString(), graphics, new Point(xx + 10, yy + 5));
				if (drawDebugText)
				{
					drawText(tileIndex.mi_tileCol + ", " + tileIndex.mi_tileRow, graphics, new Point(xx + 10, yy + 5));
				}
//				trace("********************************");
			}
			
			tileScaleX = sx;
			tileScaleY = sy;
			
//			dump_tiles.sortOn('key', Array.NUMERIC);
//			for each (var tileObj: Object in dump_tiles)
//			{
//				trace("Tile: " + tileObj.x + "," + tileObj.y + " rect: " + tileObj.left + ", " + tileObj.top + " | " + tileObj.right + "," + tileObj.bottom);
//			}
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
		
		
		override public function onAreaChanged(b_finalChange: Boolean): void
		{
			super.onAreaChanged(b_finalChange);
			
			_tilingUtils.onAreaChanged(crs, getGTileBBoxForWholeCRS(crs));
			
			if(b_finalChange) {
				
				var oldZoom: int = _zoom;
				
				findZoom();
				if (_zoom != oldZoom)
				{
					m_cache.invalidate(crs, viewBBox);
				}
				updateData(false);
			}
			else
				invalidateDynamicPart();
		}
		
		protected function onDataLoaded(event: UniURLLoaderEvent): void
		{
			m_request = null;
//			if(m_cfg.mi_autoRefreshPeriod > 0) {
//				m_timer.reset();
//				m_timer.delay = m_cfg.mi_autoRefreshPeriod * 1000.0;
//				m_timer.start();
//			}
			
			
			var result: * = event.result;
			var wmsTileCache: WMSTileCache = m_cache as WMSTileCache;
			
			if(result is Bitmap) {
				m_image = result;

				wmsTileCache.addTile(
					m_image,
					event.associatedData.requestedCRS,
					event.associatedData.requestedTileIndex,
					event.request);
				invalidateDynamicPart();
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
			return _tilingUtils;
		}
		
		public function get dataLoader(): UniURLLoader
		{ return m_loader; } 
		
		override public function clone(): InteractiveLayer
		{
			var newLayer: InteractiveLayerQTTMS = new InteractiveLayerQTTMS(container, ms_baseURL, ms_tilePattern, ms_postURL, crs, viewBBox, minimumZoom, maximumZoom);
			newLayer.alpha = alpha
			newLayer.zOrder = zOrder;
			newLayer.visible = visible;
					
//			trace("\n\n CLONE InteractiveLayerQTTMS ["+newLayer.name+"] alpha: " + newLayer.alpha + " zOrder: " +  newLayer.zOrder);
			
			return newLayer;
			
		}
	}
}