package com.iblsoft.flexiweather.ogc.editable.data
{
	import com.iblsoft.flexiweather.utils.geometry.LineSegment;

	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.utils.Dictionary;
	import flash.utils.getTimer;

	[Event(name="name", type="flash.events.Event")]
	public class FeatureDataLine extends EventDispatcher
	{
		public static const LINE_SEGMENT_ADDED: String = 'lineSegmentAdded';
		public static const LINE_SEGMENT_REMOVED: String = 'lineRemoved';

		[ArrayElementType("com.iblsoft.flexiweather.utils.geometry.LineSegment")]
		public var lineSegments: Array;

		private var _reflectionEdgePointsDictionary: Dictionary;

		public var id: int;

		public  var parentFeatureData: FeatureData;
		public  var parentFeatureReflection: FeatureDataReflection;

		public function FeatureDataLine(position: int)
		{
			id = position;
			lineSegments = new Array();
			_reflectionEdgePointsDictionary = new Dictionary();
		}

		public function clear(): void
		{
			_reflectionEdgePointsDictionary = new Dictionary();

			var total: int = lineSegments.length;
			lineSegments.splice(0, total);
		}

		private function notify(type: String): void
		{
			dispatchEvent(new Event(type));
		}

		public function addLineSegment(lineSegment: LineSegment, firstPointOnEdge: Boolean = false, secondPointOnEdge: Boolean = false): void
		{
			addLineSegmentAt(lineSegment, lineSegments.length, firstPointOnEdge, secondPointOnEdge);
		}

		public function addLineSegmentAt(lineSegment: LineSegment, position: int, firstPointOnEdge: Boolean = false, secondPointOnEdge: Boolean = false): void
		{
//			var currTime: Number = getTimer();

			_reflectionEdgePointsDictionary[lineSegment] = {line: lineSegment, firstEdge: firstPointOnEdge, secondEdge: secondPointOnEdge};
//			trace("addLineSegmentAt["+position+"]1 took " + (getTimer() - currTime) + "ms");

//			var currTime: Number = getTimer();
			lineSegments[position] = lineSegment;
//			trace("addLineSegmentAt["+position+"]2 took " + (getTimer() - currTime) + "ms");

//			var currTime: Number = getTimer();
			notify(LINE_SEGMENT_ADDED);
//			trace("addLineSegmentAt["+position+"]3 took " + (getTimer() - currTime) + "ms");
		}

		public function getLineSegmentAt(position: int): LineSegment
		{
			if (lineSegments.length >= 0)
			{
				return null;
			}

			return lineSegments[position] as LineSegment;
		}

		override public function toString(): String
		{
			var linesStr: String = "";
			for each (var line: LineSegment in lineSegments)
				linesStr += " " + line;

			return "FeatureDataLine " + id + " segments: " + lineSegments.length + "|" + linesStr;
		}
	}
}