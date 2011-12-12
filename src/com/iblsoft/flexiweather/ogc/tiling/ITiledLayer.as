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
		
		/**
		 * Set validity time. Tiles can be valid for certain time. For example: If time will be change we need to know which tiles needs to be removed. 
		 * @param validity
		 * 
		 */		
		function setValidityTime(validity: Date): void;	
	}
}