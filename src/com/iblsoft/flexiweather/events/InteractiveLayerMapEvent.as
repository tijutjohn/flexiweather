package com.iblsoft.flexiweather.events
{
	import flash.events.Event;
	
	public class InteractiveLayerMapEvent extends Event
	{
		public static const FIRST_FRAME_CHANGED: String = "firstFrameChanged";
		[Event(name = FIRST_FRAME_CHANGED, type = "com.iblsoft.flexiweather.events.InteractiveLayerMapEvent")]
		
		public static const LAST_FRAME_CHANGED: String = "lastFrameChanged";
		[Event(name = LAST_FRAME_CHANGED, type = "com.iblsoft.flexiweather.events.InteractiveLayerMapEvent")]
		
		public static const NOW_FRAME_CHANGED: String = "nowFrameChanged";
		[Event(name = NOW_FRAME_CHANGED, type = "com.iblsoft.flexiweather.events.InteractiveLayerMapEvent")]
		
		public static const MAP_LOADED: String = "mapLoaded";
		
		public var frameDate: Date;
		
		public function InteractiveLayerMapEvent(type:String, bubbles:Boolean=false, cancelable:Boolean=false)
		{
			super(type, bubbles, cancelable);
		}
	}
}