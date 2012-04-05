package com.iblsoft.flexiweather.ogc.kml.events
{
	import flash.events.Event;
	
	public class KMLEvent extends Event
	{
		public static const UNPACKING_STARTED: String = 'unpackingStarted';
		public static const UNPACKING_FINISHED: String = 'unpackingFinished';
		
		public static const PARSING_STARTED: String = 'parsingStarted';
		public static const PARSING_FINISHED: String = 'parsingFinished';
		
		public function KMLEvent(type:String, bubbles:Boolean=false, cancelable:Boolean=false)
		{
			super(type, bubbles, cancelable);
		}
		
		override public function clone(): Event
		{
			return new KMLEvent(type, bubbles, cancelable);
		}
	}
}