package com.iblsoft.flexiweather.ogc.events
{
	import flash.events.Event;

	public class MSBaseLoaderEvent extends Event
	{
		public static const LOADING_FINISHED: String = 'loadingFinished';
		public static const LEGEND_LOADED: String = 'legendLoaded';
		public static const LEGEND_NOT_AVAILABLE: String = 'legendNotAvailable';
		public static const LEGEND_LOAD_ERROR: String = 'legendLoadError';
		
		public var data: Object;

		public function MSBaseLoaderEvent(type: String, bubbles: Boolean = false, cancelable: Boolean = false)
		{
			super(type, bubbles, cancelable);
		}
		
		override public function clone():Event
		{
			var mble: MSBaseLoaderEvent = new MSBaseLoaderEvent(type, bubbles, cancelable);
			mble.data = data;
			return mble;
		}
	}
}
