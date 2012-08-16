package com.iblsoft.flexiweather.ogc.cache
{
	import com.iblsoft.flexiweather.ogc.WMSLayerConfiguration;
	
	import flash.utils.Dictionary;

	/**
	 * Class which handle shared WMS Cache for each layer 
	 * @author fkormanak
	 * 
	 */	
	public class WMSCacheManager
	{
		private var _wmsCacheDictionary:  Dictionary;
		
		public function WMSCacheManager()
		{
			_wmsCacheDictionary = new Dictionary();
		}
		
		
		public function getWMSCacheForConfiguration(configuration: WMSLayerConfiguration): WMSCache
		{
			var layerNames: String = configuration.layerNames.join('_');
			
			if (!_wmsCacheDictionary[layerNames])
			{
				_wmsCacheDictionary[layerNames] = new WMSCache();
			} else {
				trace("cache for layer " + layerNames + " already exists");
			}
			return _wmsCacheDictionary[layerNames] as WMSCache;
		}
	}
}