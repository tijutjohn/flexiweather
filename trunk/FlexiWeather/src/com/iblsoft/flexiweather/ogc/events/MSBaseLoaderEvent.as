package com.iblsoft.flexiweather.ogc.events
{
	import flash.events.Event;

	public class MSBaseLoaderEvent extends Event
	{
		public static const LOADING_FINISHED: String = 'loadingFinished';
		public static const LEGEND_LOADED: String = 'legendLoaded';
		public var data: Object;

		public function MSBaseLoaderEvent(type: String, bubbles: Boolean = false, cancelable: Boolean = false)
		{
			super(type, bubbles, cancelable);
		}
	}
}
