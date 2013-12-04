package com.iblsoft.flexiweather
{
	/**
	 * Main configuration for FlexiWeather library.
	 * Here are some settings, which can be set for whole library at once  
	 * @author fkormanak
	 * 
	 */	
	public class FlexiWeatherConfiguration
	{
		public static var FLEXI_WEATHER_LOADS_GET_CAPABILITIES: Boolean = true;
		
		
		/**
		 * If true InteractiveLayerMap will do periodic check of FRAME changes
		 */
		public static var INTERACTIVE_LAYER_MAP_PERIODIC_CHECK: Boolean = true;
		
		/**
		 * How often is periodic check in InteractiveLayerMap executed (in seconds
		 */
		public static var INTERACTIVE_LAYER_MAP_PERIODIC_CHECK_INTERVAL: int = 10;
		
		public function FlexiWeatherConfiguration()
		{
		}
	}
}