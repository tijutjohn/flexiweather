package com.iblsoft.flexiweather.ogc.multiview.events
{
	import flash.events.Event;
	
	public class InteractiveMultiViewEvent extends Event
	{
		public static const MULTI_VIEW_READY: String = 'multiViewReady';
		
		public function InteractiveMultiViewEvent(type:String, bubbles:Boolean=false, cancelable:Boolean=false)
		{
			super(type, bubbles, cancelable);
		}
	}
}