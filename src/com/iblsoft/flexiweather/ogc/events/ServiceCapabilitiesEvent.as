package com.iblsoft.flexiweather.ogc.events
{
	import flash.events.Event;
	
	public class ServiceCapabilitiesEvent extends Event
	{
		public static const CAPABILITIES_UPDATE_FAILED: String = "serviceCapabilitiesUpdateFailed";
		public static const CAPABILITIES_UPDATED: String = "serviceCapabilitiesUpdated";
		public static const ALL_CAPABILITIES_UPDATED: String = "allServicesCapabilitiesUpdated";
		
		public var errorString: String;
		
		public function ServiceCapabilitiesEvent(type:String, bubbles:Boolean=false, cancelable:Boolean=false)
		{
			super(type, bubbles, cancelable);
		}
		
		override public function clone():Event
		{
			var e: ServiceCapabilitiesEvent = new ServiceCapabilitiesEvent(type, bubbles, cancelable);
			e.errorString = errorString;
			
			return e;
		}
	}
}