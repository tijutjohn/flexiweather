package com.iblsoft.flexiweather.ogc.events
{
	import com.iblsoft.flexiweather.proj.Coord;
	
	import flash.events.Event;

	public class FeatureEvent extends Event
	{
		public static const PRESENCE_IN_VIEW_BBOX_CHANGED: String = 'presenceInViewBBoxChanged';
		
		public static const COORDINATE_VISIBLE: String = 'coordinateVisible';
		public static const COORDINATE_INVISIBLE: String = 'coordinateInvisible';
		
		public var insideViewBBox: Boolean;
		
		public var coordinate: Coord;
		public var coordinateIndex: uint;

		public function FeatureEvent(type: String, bubbles: Boolean = false, cancelable: Boolean = false)
		{
			super(type, bubbles, cancelable);
		}
	}
}
