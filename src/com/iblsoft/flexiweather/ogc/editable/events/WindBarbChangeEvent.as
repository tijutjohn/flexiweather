package com.iblsoft.flexiweather.ogc.editable.events
{
	import flash.events.Event;

	public class WindBarbChangeEvent extends Event
	{
		public static var WIND_BARB_CHANGE: String = 'windBarbChange';
		public static var WIND_BARB_SELECTION_CHANGE: String = 'windBarbSelectionChange';
		
		public var data: Object;
		
		/**
		 * 
		 */
		public function WindBarbChangeEvent(type:String, _data: Object, bubbles:Boolean=false, cancelable:Boolean=false)
		{
			super(type, bubbles, cancelable);
			
			data = _data;
		}
		
	}
}