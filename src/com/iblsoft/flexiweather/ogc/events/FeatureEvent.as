package com.iblsoft.flexiweather.ogc.events
{
	import flash.events.Event;

	public class FeatureEvent extends Event
	{
		public static const PRESENCE_IN_VIEW_BBOX_CHANGED: String = 'presenceInViewBBoxChanged';
		public var insideViewBBox: Boolean;

		public function FeatureEvent(type: String, bubbles: Boolean = false, cancelable: Boolean = false)
		{
			super(type, bubbles, cancelable);
		}
	}
}
