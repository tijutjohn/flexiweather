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

		/**
		 * Boolean constant whether to use optimization technique "suspend anticollision". Use it if you need it, it is not used by default
		 */
		public static var USE_SUSPEND_ANTICOLLISION: Boolean = false;

		/**
		 * Constant, which defined maximum distance betwenn points on Cubic Bezier (Hermit Spline), when counting spline.
		 * If there is need for smoother bezier curve, set smaller value. Higher value are for faster but not so precise curves.
		 */
		public static var BEZIER_POINTS_MAXIMUM_DISTANCE: int = 15;

		/**
		 * Constant, which defines whether loader can cancell previous requests, which were not finished, when new load request is required
		 */
		public static var CAN_CANCELL_REQUESTS: Boolean = true;

	}
}