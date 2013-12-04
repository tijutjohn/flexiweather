package com.iblsoft.flexiweather.ogc.events
{
	import flash.events.Event;

	public class GetCapabilitiesEvent extends Event
	{
		public static const CAPABILITIES_UPDATED: String = "capabilitiesUpdated";
		public static const CAPABILITIES_RECEIVED: String = "capabilitiesReceived";

		public function GetCapabilitiesEvent(type: String, bubbles: Boolean = false, cancelable: Boolean = false)
		{
			super(type, bubbles, cancelable);
		}

		override public function clone(): Event
		{
			var gce: GetCapabilitiesEvent = new GetCapabilitiesEvent(type, bubbles, cancelable);
			return gce;
		}
	}
}
