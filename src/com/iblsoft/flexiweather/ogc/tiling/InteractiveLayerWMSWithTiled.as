package com.iblsoft.flexiweather.ogc.tiling
{
	import com.iblsoft.flexiweather.ogc.BBox;
	import com.iblsoft.flexiweather.ogc.InteractiveLayerQTTMS;
	import com.iblsoft.flexiweather.ogc.InteractiveLayerWMS;
	import com.iblsoft.flexiweather.ogc.cache.ICachedLayer;
	import com.iblsoft.flexiweather.ogc.configuration.layers.WMSLayerConfiguration;
	import com.iblsoft.flexiweather.widgets.InteractiveWidget;

	public class InteractiveLayerWMSWithTiled extends InteractiveLayerWMS implements ICachedLayer, ITiledLayer
	{
		public function InteractiveLayerWMSWithTiled(container: InteractiveWidget, cfg: WMSLayerConfiguration)
		{
			super(container, cfg);
		}

		public function getTiledLayer(): InteractiveLayerTiled
		{
			// TODO Auto Generated method stub
			return null;
		}

		public function getTiledArea(viewBBox: BBox, zoomLevel: String, tileSize: int): TiledArea
		{
			return null;
		}
	}
}
