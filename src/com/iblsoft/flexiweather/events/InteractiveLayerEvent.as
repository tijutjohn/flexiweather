package com.iblsoft.flexiweather.events
{
	import flash.events.Event;

	public class InteractiveLayerEvent extends Event
	{
		public  static const FEATURE_INFO_RECEIVED: String = 'featureInfoReceived';
		
		public var text: String;
		
		public function InteractiveLayerEvent(type:String, bubbles:Boolean=false, cancelable:Boolean=false)
		{
			super(type, bubbles, cancelable);
		}
		
	}
}