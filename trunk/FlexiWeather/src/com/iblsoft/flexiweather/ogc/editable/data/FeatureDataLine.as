package com.iblsoft.flexiweather.ogc.editable.data
{
	import com.iblsoft.flexiweather.utils.geometry.LineSegment;
	
	import flash.events.Event;
	import flash.events.EventDispatcher;

	[Event(name="name", type="flash.events.Event")]
	public class FeatureDataLine extends EventDispatcher
	{
		public static const LINE_SEGMENT_ADDED: String = 'lineSegmentAdded';
		public static const LINE_SEGMENT_REMOVED: String = 'lineRemoved';
		
		[ArrayElementType("com.iblsoft.flexiweather.utils.geometry.LineSegment")]
		public var lineSegments: Array;
		
		public var id: int;
		
		public  var parentFeatureData: FeatureData;
		public  var parentFeatureReflection: FeatureDataReflection; 
		
		public function FeatureDataLine(position: int)
		{
			id = position;
			lineSegments = new Array();
		}
		
		private function notify(type: String): void
		{
			dispatchEvent(new Event(type));
		}
		
		public function addLineSegment(lineSegment: LineSegment): void
		{
			addLineSegmentAt(lineSegment, lineSegments.length);
		}
		
		public function addLineSegmentAt(lineSegment: LineSegment, position: int): void
		{
			lineSegments[position] = lineSegment;
			notify(LINE_SEGMENT_ADDED);
		}
		
		public function getReflectionAt(position: int): LineSegment
		{
			if (lineSegments.length >= 0)
			{
				return null;
			}
			
			return lineSegments[position] as LineSegment;
		}
		
		override public function toString(): String
		{
			return "FeatureDataLine " + id;
		}
	}
}