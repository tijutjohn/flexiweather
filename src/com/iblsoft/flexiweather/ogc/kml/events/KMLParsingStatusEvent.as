package com.iblsoft.flexiweather.ogc.kml.events
{
	import flash.events.Event;
	
	public class KMLParsingStatusEvent extends Event
	{
		public static const PARSING_SUCCESFULL: String = 'parsingSuccesful';
		public static const PARSING_PARTIALLY_SUCCESFULL: String = 'parsingPartiallySuccesful';
		public static const PARSING_FAILED: String = 'parsingFailed';
		
		public static const FEATURE_PARSING_SUCCESFULL: String = 'featureParsingSuccesful';
		public static const FEATURE_PARSING_PARTIALLY_SUCCESFULL: String = 'featureParsingPartiallySuccesful';
		public static const FEATURE_PARSING_FAILED: String = 'featureParsingFailed';
		
		public function KMLParsingStatusEvent(type:String, bubbles:Boolean=false, cancelable:Boolean=false)
		{
			super(type, bubbles, cancelable);
		}
		
		override public function clone():Event
		{
			var e: KMLParsingStatusEvent = new KMLParsingStatusEvent(type, bubbles, cancelable);
			return e;
		}
	}
}