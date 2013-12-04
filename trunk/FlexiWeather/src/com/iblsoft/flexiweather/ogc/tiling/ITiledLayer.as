package com.iblsoft.flexiweather.ogc.tiling
{
	import com.iblsoft.flexiweather.ogc.BBox;
	import com.iblsoft.flexiweather.widgets.InteractiveDataLayer;

	public interface ITiledLayer
	{
		/**
		 * returns InteractiveLayerTiled layer (for now only tiled layer we support)
		 * @return
		 *
		 */
		function getTiledLayer(): InteractiveLayerTiled;
		function getTiledArea(viewBBox: BBox, zoomLevel: String, tileSize: int): TiledArea;
	}
}
