package com.iblsoft.flexiweather.events
{
	import flash.events.Event;
	
	public class InteractiveLayerWMSEvent extends Event
	{
		public static const WMS_STYLE_CHANGED: String = 'wmsStyleChanged';
		public static const LEVEL_CHANGED: String = 'levelChanged';
		public static const RUN_CHANGED: String = 'runChanged';
		
		public function InteractiveLayerWMSEvent(type:String, bubbles:Boolean=false, cancelable:Boolean=false)
		{
			super(type, bubbles, cancelable);
		}
		
		override public function clone():Event
		{
			return new InteractiveLayerWMSEvent(type, bubbles, cancelable);
		}
	}
}