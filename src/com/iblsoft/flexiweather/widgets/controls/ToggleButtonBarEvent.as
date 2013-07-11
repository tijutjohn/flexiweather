package com.iblsoft.flexiweather.widgets.controls
{
	import flash.events.Event;
	
	public class ToggleButtonBarEvent extends Event
	{
		public static const CLICK: String = 'toggleBarButtonClick';
		public static const SELECT: String = 'toggleBarButtonSelect';
		public static const UNSELECT: String = 'toggleBarButtonUnselect';
		public static const SELECT_EXCLUSIVE: String = 'toggleBarButtonSelectExclusive';
		public static const UNSELECT_EXCLUSIVE: String = 'toggleBarButtonUnselectExclusive';
		
		public var data: ToggleButtonBarItemData;
		
		public function ToggleButtonBarEvent(type:String, data: ToggleButtonBarItemData, bubbles:Boolean=false, cancelable:Boolean=false)
		{
			super(type, bubbles, cancelable);
			
			this.data = data;
		}
		
		override public function clone():Event
		{
			var e: ToggleButtonBarEvent = new ToggleButtonBarEvent(type, data);
			return e;
		}
	}
}