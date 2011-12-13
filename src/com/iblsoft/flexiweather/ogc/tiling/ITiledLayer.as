package com.iblsoft.flexiweather.ogc.tiling
{
	import com.iblsoft.flexiweather.ogc.InteractiveLayerQTTMS;
	import com.iblsoft.flexiweather.widgets.InteractiveDataLayer;

	public interface ITiledLayer
	{
		/**
		 * returns InteractiveLayerQTTMS layer (for now only tiled layer we support) 
		 * @return 
		 * 
		 */		
		function getTiledLayer(): InteractiveLayerQTTMS;
		
	}
}