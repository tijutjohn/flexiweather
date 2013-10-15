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
		public var coordinateReflection: uint;

		public function FeatureEvent(type: String, bubbles: Boolean = false, cancelable: Boolean = false)
		{
			super(type, bubbles, cancelable);
		}
		
		override public function clone():Event
		{
			var fe: FeatureEvent = new FeatureEvent(type, bubbles, cancelable);
			fe.insideViewBBox = insideViewBBox;
			fe.coordinate = coordinate;
			fe.coordinateIndex = coordinateIndex;
			fe.coordinateReflection = coordinateReflection;
			
			return fe;
		}
	}
}
