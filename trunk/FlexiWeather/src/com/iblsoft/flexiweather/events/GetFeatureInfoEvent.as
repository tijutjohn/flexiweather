package com.iblsoft.flexiweather.events
{
	import flash.events.Event;

	public class GetFeatureInfoEvent extends Event
	{
		public static const FEATURE_INFO_RECEIVED: String = 'featureInfoReceived';
		public var text: String;
		/**
		 * get feature info is called for many layers. set this to true in case it is first feature info
		 */
		public var firstFeatureInfo: Boolean;
		/**
		 * get feature info is called for many layers. set this to true in case it is first feature info
		 */
		public var lastFeatureInfo: Boolean;

		public function GetFeatureInfoEvent(type: String, bubbles: Boolean = false, cancelable: Boolean = false)
		{
			super(type, bubbles, cancelable);
		}
	}
}
