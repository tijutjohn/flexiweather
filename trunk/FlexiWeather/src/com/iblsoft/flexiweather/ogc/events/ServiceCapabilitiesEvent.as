package com.iblsoft.flexiweather.ogc.events
{
	import com.iblsoft.flexiweather.ogc.configuration.services.OGCServiceConfiguration;
	
	import flash.events.Event;
	
	public class ServiceCapabilitiesEvent extends Event
	{
		public static const CAPABILITIES_LOADED: String = "serviceCapabilitiesLoaded";
		public static const CAPABILITIES_UPDATE_FAILED: String = "serviceCapabilitiesUpdateFailed";
		public static const CAPABILITIES_UPDATED: String = "serviceCapabilitiesUpdated";
		public static const ALL_CAPABILITIES_UPDATED: String = "allServicesCapabilitiesUpdated";
		
		public var errorString: String;
		
		public var service: OGCServiceConfiguration;
		public var xml: XML;
		
		public function ServiceCapabilitiesEvent(type:String, bubbles:Boolean=false, cancelable:Boolean=false)
		{
			super(type, bubbles, cancelable);
		}
		
		override public function clone():Event
		{
			var e: ServiceCapabilitiesEvent = new ServiceCapabilitiesEvent(type, bubbles, cancelable);
			e.errorString = errorString;
			e.service = service;
			e.xml = xml;	
			return e;
		}
	}
}