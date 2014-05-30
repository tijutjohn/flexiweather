package com.iblsoft.flexiweather.events
{
	import flash.events.Event;
	
	public class WFSFeatureEditorServiceEvent extends Event
	{
		public static const IMPORT_DATA_RECEIVED: String = "importDataReceived"; 
		public static const LOAD_DATA_RECEIVED: String = "loadDataReceived"; 
		public static const REFRESH_DATA_RECEIVED: String = "refreshDataReceived"; 
		
		public var xml: XML;
		
		public function WFSFeatureEditorServiceEvent(type:String, bubbles:Boolean=false, cancelable:Boolean=false)
		{
			super(type, bubbles, cancelable);
		}
	}
}