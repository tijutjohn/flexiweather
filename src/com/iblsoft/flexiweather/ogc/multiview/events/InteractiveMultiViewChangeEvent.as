package com.iblsoft.flexiweather.ogc.multiview.events
{
	import com.iblsoft.flexiweather.widgets.InteractiveWidget;
	
	import flash.events.Event;
	
	public class InteractiveMultiViewChangeEvent extends Event
	{
		public static const SELECTION_CHANGE: String = 'multiViewSelectionChange';
		
		public var oldInteractiveWidget: InteractiveWidget;
		public var newInteractiveWidget: InteractiveWidget;
		
		public function InteractiveMultiViewChangeEvent(type:String, bubbles:Boolean=false, cancelable:Boolean=false)
		{
			super(type, bubbles, cancelable);
		}
	}
}