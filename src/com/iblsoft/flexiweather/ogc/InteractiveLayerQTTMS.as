package com.iblsoft.flexiweather.ogc
{
	import com.iblsoft.flexiweather.ogc.cache.WMSTileCache;
	import com.iblsoft.flexiweather.ogc.tiling.TileIndex;
	import com.iblsoft.flexiweather.utils.UniURLLoaderEvent;
	import com.iblsoft.flexiweather.widgets.InteractiveLayer;
	import com.iblsoft.flexiweather.widgets.InteractiveWidget;
	
	import flash.display.Bitmap;
	import flash.display.Graphics;
	import flash.geom.Matrix;
	import flash.net.URLRequest;
	
	import mx.logging.Log;
	
	public class InteractiveLayerQTTMS extends InteractiveLayerMSBase
	{
		public function InteractiveLayerQTTMS(container: InteractiveWidget, cfg: WMSLayerConfiguration)
		{
			super(container, cfg);
			
			m_cache = new WMSTileCache();
		}

		private var _zoom: uint = 3;
		
		override public function updateData(b_forceUpdate: Boolean): void
		{
			super.updateData(b_forceUpdate);
			
			var xPartsMax: int = Math.pow(2, _zoom);	
			var yPartsMax: int = xPartsMax;
			
			var mapWidth: int = width;
			var mapHeight: int = height;
			
			var xParts: int = Math.min(xPartsMax, Math.ceil(mapWidth / 256));
			var yParts: int = Math.min(yPartsMax, Math.ceil(mapHeight / 256));
				
			trace("xParts: " + xParts + " yParts: " + yParts);
			
			var request: URLRequest;
			for(var i_row: uint = 0; i_row < yParts; ++i_row) 
			{
				for(var i_col: uint = 0; i_col < xParts; ++i_col) {
					
					request = m_cfg.toGetGTileRequest(
							container.getCRS(), _zoom, i_row, i_col, 
							getWMSStyleListString());
							
					m_loader.load(request, {
						requestedCRS: container.getCRS(),
						requestedTileIndex: new TileIndex(_zoom, i_row, i_col)
					});
				}
			}
		}
		
		override public function draw(graphics: Graphics): void
		{
			super.draw(graphics);
			
			var tilingBBox: BBox = getGTileBBoxForWholeCRS(container.getCRS()); // extent of tile z=0/r=0/c=0
//			_zoom = 3;

			var matrix: Matrix;
			var wmsTileCache: WMSTileCache = m_cache as WMSTileCache;
			
			var a_tiles: Array = wmsTileCache.getTiles(container.getCRS(), _zoom);
			trace("draw tiles: " + a_tiles.length);
			
			for each(var t_tile: Object in a_tiles.reverse()) {
				var tileIndex: TileIndex = t_tile.tileIndex;
				
				trace("\ttile ["+name+"]: " + tileIndex.mi_tileCol + " , " + tileIndex.mi_tileRow + " zoom: " + tileIndex.mi_tileZoom);
//				trace("\ttile ["+name+"]: " + (tileIndex.mi_tileCol * 256) + " , " + ( tileIndex.mi_tileRow * 256));
				
				matrix = new Matrix();
				matrix.translate(tileIndex.mi_tileCol * 256, tileIndex.mi_tileRow * 256);
				graphics.beginBitmapFill(t_tile.image.bitmapData, matrix, false, true);
				graphics.drawRect(tileIndex.mi_tileCol * 256, tileIndex.mi_tileRow * 256, m_image.width, m_image.height);
				graphics.endFill();
			}
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

			var f_yMin: Number = extent.yMax - tileIndex.mi_tileCol * f_tileHeight;

			return new BBox(f_xMin, f_yMin, f_xMin + f_tileWidth, f_yMin + f_tileHeight);
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