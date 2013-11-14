package com.iblsoft.flexiweather.events
{
	import flash.events.Event;

	public class WMSViewPropertiesEvent extends Event
	{
		public static var WMS_DIMENSION_VALUE_SET: String = 'wmsDimensionValueSet';
		public var dimension: String;
		public var value: String;

		public function WMSViewPropertiesEvent(type: String, bubbles: Boolean = false, cancelable: Boolean = false)
		{
			super(type, bubbles, cancelable);
		}

		override public function clone(): Event
		{
			var e: WMSViewPropertiesEvent = new WMSViewPropertiesEvent(type, bubbles, cancelable);
			e.dimension = dimension;
			e.value = value;
			return e;
		}
	}
}
