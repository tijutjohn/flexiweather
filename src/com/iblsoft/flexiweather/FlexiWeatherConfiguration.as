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

		/**
		 * Panning of InteractiveLayerKML layers will be done just with bitmap representation of kml layer, because of boosting CPU performance.
		 */
		public static var USE_KML_BITMAP_PANNING: Boolean = false;

		/**
		 * Time interval in miliseconds for checking if 2 requests are same when called in "SAME_REQUEST_TIME_INTERVAL" miliseconds.
		 */
		public static var SAME_REQUEST_TIME_INTERVAL: int = 1000;

	}
}