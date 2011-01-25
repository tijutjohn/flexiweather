package com.iblsoft.flexiweather.ogc
{
	import com.iblsoft.flexiweather.ogc.cache.WMSTileCache;
	import com.iblsoft.flexiweather.ogc.tiling.TileIndex;
	import com.iblsoft.flexiweather.ogc.tiling.TiledArea;
	import com.iblsoft.flexiweather.ogc.tiling.TilingUtils;
	import com.iblsoft.flexiweather.proj.Coord;
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
	
	import mx.logging.Log;
	
	public class InteractiveLayerQTTMS extends InteractiveLayerMSBase
	{
		public static var imageSmooth: Boolean = true;
		
		private var _tilingUtils: TilingUtils;
		
		public function InteractiveLayerQTTMS(container: InteractiveWidget, cfg: WMSLayerConfiguration)
		{
			super(container, cfg);
			
			m_cache = new WMSTileCache();
			_tilingUtils = new TilingUtils();
		}

		private var _zoom: uint = 1;
		public var tileScaleX: Number;
		public var tileScaleY: Number;
		
		public function get layerZoom(): uint
		{
			return _zoom;
		}
		
		override public function updateData(b_forceUpdate: Boolean): void
		{
			super.updateData(b_forceUpdate);
			
			var crs: String = container.getCRS();
			_tilingUtils.onAreaChanged(crs, getGTileBBoxForWholeCRS(crs));
			var tiledArea: TiledArea = _tilingUtils.getTiledArea(container.getViewBBox(), _zoom);
			
			var tiledCache: WMSTileCache = m_cache as WMSTileCache;
			trace("updateData ["+name+"]: tiledArea : " + tiledArea.leftCol + ", " + tiledArea.topRow + " size: " + tiledArea.colTilesCount + " , " + tiledArea.rowTilesCount);
			
			var request: URLRequest;
			var tileIndex: TileIndex = new TileIndex(_zoom);
			
			for(var i_row: uint = tiledArea.topRow; i_row <= tiledArea.bottomRow; ++i_row) 
			{
				for(var i_col: uint = tiledArea.leftCol; i_col <= tiledArea.rightCol; ++i_col) {
					
					
					request = m_cfg.toGetGTileRequest(
							crs, _zoom, i_row, i_col, 
							getWMSStyleListString());
					
					tileIndex = new TileIndex(_zoom, i_row, i_col );
					
					if (!tiledCache.isTileCached(crs, tileIndex, request))
					{	
						m_loader.load(request, {
							requestedCRS: container.getCRS(),
							requestedTileIndex: tileIndex
						});
					} 
				}
			}
		}
		
		private function checkBBoxTiles(bbox: BBox): void
		{
			var crs: String = container.getCRS();
			
			//getGTileBBox(crs, 
		}
		private function getZoomForBBox(bbox: BBox): int
		{
//			var left: Number = bbox.xMin;
//			var top: Number = bbox.yMax;
//			var right: Number = bbox.xMax;
//			var bottom: Number = bbox.yMin;
			
//			var topLeftTileIndex: TileIndex = _tilingUtils.getTileIndexForPosition(left, top);	
//			var topRightTileIndex: TileIndex = _tilingUtils.getTileIndexForPosition(right, top);	
//			var bottomRightTileIndex: TileIndex = _tilingUtils.getTileIndexForPosition(right, bottom);	
//			var bottomLeftTileIndex: TileIndex = _tilingUtils.getTileIndexForPosition(left, bottom);	
//			
//			trace("new zoom tiles for zoom level: " + _zoom)
//			trace("left top: " + topLeftTileIndex);
//			trace("right top: " + topRightTileIndex);
//			trace("right bottom: " + bottomRightTileIndex);
//			trace("left bottom: " + bottomLeftTileIndex);
			
			var crs: String = container.getCRS();
			_zoom = _tilingUtils.getZoom(container.getViewBBox(), new Point(width, height));
			return _zoom;
		}
		override public function draw(graphics: Graphics): void
		{
			super.draw(graphics);
			
			var crs: String = container.getCRS();
			
			var currentBBox: BBox = container.getViewBBox();
			var tilingBBox: BBox = getGTileBBoxForWholeCRS(crs); // extent of tile z=0/r=0/c=0

			var matrix: Matrix;
			var wmsTileCache: WMSTileCache = m_cache as WMSTileCache;
			
			var a_tiles: Array = wmsTileCache.getTiles(container.getCRS(), _zoom);
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
//				graphics.lineStyle(1, 0xff0000,0.3);
//				graphics.drawRect(xx, yy, newWidth , newHeight);
					
//				drawText(xx + ", " + yy + "\n" + topLeftCoord.toNiceString(), graphics, new Point(xx + 10, yy + 5));
//				drawText(tileIndex.mi_tileCol + ", " + tileIndex.mi_tileRow, graphics, new Point(xx + 10, yy + 5));
//				trace("********************************");
			}
			
			tileScaleX = sx;
			tileScaleY = sy;
			trace("QTTMS "+name+" scale: " + sx + " , " + sy);
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
			gr.lineStyle(0);
			gr.beginBitmapFill(_tfBD, m, false);
			gr.drawRect(pos.x, pos.y, tfWidth, tfHeight);
			gr.endFill();
		}
		
		
		override public function onAreaChanged(b_finalChange: Boolean): void
		{
			super.onAreaChanged(b_finalChange);
			
			var crs: String = container.getCRS();
			_tilingUtils.onAreaChanged(crs, getGTileBBoxForWholeCRS(crs));
			
			if(b_finalChange) {
				
				var oldZoom: int = _zoom;
				
				var currentBBox: BBox = container.getViewBBox();
				//TODO find out new zoom and position
				_zoom = getZoomForBBox(currentBBox);
				if (_zoom != oldZoom)
				{
					m_cache.invalidate(ms_imageCRS, m_imageBBox);
				}
				trace("find out new zoom and position: " + currentBBox);
				
				updateData(false);
			}
			else
				invalidateDynamicPart();
		}
		
		override protected function onDataLoaded(event: UniURLLoaderEvent): void
		{
			super.onDataLoaded(event);
			
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

			ExceptionUtils.logError(Log.getLogger("WMS"), result, "Error accessing layers '" + m_cfg.ma_layerNames.join(","))
			onDataLoadFailed(null);
		}
		
		public function getGTileBBoxForWholeCRS(s_crs: String): BBox
		{
			if(s_crs == "EPSG:4326")
				return new BBox(-180, -90, 180, 90);
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
		
		override public function clone(): InteractiveLayer
		{
			var newLayer: InteractiveLayerQTTMS = new InteractiveLayerQTTMS(container, m_cfg);
			newLayer.alpha = alpha
			newLayer.zOrder = zOrder;
			newLayer.visible = visible;
					
			var styleName: String = getWMSStyleName(0)
			newLayer.setWMSStyleName(0, styleName);
			trace("\n\n CLONE InteractiveLayerQTTMS ["+newLayer.name+"] alpha: " + newLayer.alpha + " zOrder: " +  newLayer.zOrder);
			
			return newLayer;
			
		}
	}
}