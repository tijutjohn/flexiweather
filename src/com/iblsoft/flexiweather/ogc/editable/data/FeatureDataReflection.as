package com.iblsoft.flexiweather.ogc.editable.data
{
	import com.iblsoft.flexiweather.proj.Coord;
	import com.iblsoft.flexiweather.utils.geometry.LineSegment;
	
	import flash.display.DisplayObject;
	import flash.display.Stage;
	import flash.events.Event;
	import flash.geom.Point;
	
	import mx.core.FlexGlobals;

	public class FeatureDataReflection
	{
		[ArrayElementType("com.iblsoft.flexiweather.ogc.editable.data.FeatureDataLine")]
		private var _lines: Array;
		
		[ArrayElementType("flash.geom.Point")]
		private var _points: Array;
		
		public function get lines(): Array
		{
			return _lines;
		}
		
		public function get points(): Array
		{
			return _points;
		}
		
		public  var parentFeatureData: FeatureData;
		
		private var _stage: Stage;
		private var _listening: Boolean;
		
		public function FeatureDataReflection()
		{
			_lines = new Array();
			_points = new Array();
			_stage = (FlexGlobals.topLevelApplication as DisplayObject).stage
				
		}
		
		public function createLine(): FeatureDataLine
		{
			return createLineAt(_lines.length);
		}
		
		public function createLineAt(position: int): FeatureDataLine
		{
			var line: FeatureDataLine = new FeatureDataLine(position);
			
			line.addEventListener(FeatureDataLine.LINE_SEGMENT_ADDED, onLineSegmentsChanged);
			line.addEventListener(FeatureDataLine.LINE_SEGMENT_REMOVED, onLineSegmentsChanged);
			
			line.parentFeatureData = parentFeatureData;
			line.parentFeatureReflection = this;
			_lines[position] = line;
			return line;
		}
		
		public function getLineAt(position: int): FeatureDataLine
		{
			if (_lines.length >= 0)
			{
				return createLineAt(position);
			}
			
			if (!(_lines[position] is FeatureDataLine))
				return createLineAt(position);
			
			return _lines[position] as FeatureDataLine;
		}
		
		private function stopListenForNextFrame(): void
		{
			_listening = false;
			_stage.removeEventListener(Event.ENTER_FRAME, onNextFrame);
			
		}
		private function listenForNextFrame(): void
		{
			_listening = true;
			_stage.addEventListener(Event.ENTER_FRAME, onNextFrame);
		}
		
		private function onNextFrame(event: Event): void
		{
			stopListenForNextFrame();
			compute();
		}
		
		private function onLineSegmentsChanged(event: Event): void
		{
			if (!_listening)
			{
				listenForNextFrame();	
			}
			
		}
		
		public function get computingScheduled(): Boolean
		{
			return _listening;
		}
		
		private var _center: Point;
		private var _startPoint: Point;
		
		/**
		 * Will recompute everything 
		 * 
		 */		
		public function validate(): void
		{
			compute();
			stopListenForNextFrame();
		}
		
		/**
		 * When line is added or removed, everything is computed to do not recompute everything when e.g. center point is requested 
		 * 
		 */		
		private function compute(): void
		{
			_points = [];
			var cnt: int = 0;
			var oldPoint: Point;
			for each (var line: FeatureDataLine in _lines)
			{
				for each (var lineSegment: LineSegment in line.lineSegments)
				{
					var p1: Point = new Point(lineSegment.x1, lineSegment.y1);
					var p2: Point = new Point(lineSegment.x2, lineSegment.y2);
					
					
					if (!oldPoint)
						_points.push(p1);
					else if (oldPoint.x != p1.x || oldPoint.y != p1.y)
						_points.push(p1);
						
					_points.push(p2);
					
					if (cnt == 0)
						_startPoint = p1.clone();
					
					oldPoint = p2.clone();
					cnt++;
				}
			}
			
			_center = new Point();
			for each (var ptr: Point in _points)
			{
				_center = _center.add(ptr);
			}
			_center.x /= _points.length;
			_center.y /= _points.length;
		}
		
		public function get startPoint(): Point
		{
			return _startPoint
		}
		public function get center(): Point
		{
			if (!_center)
			{
//				trace("Center is not computed");
				if (lines && lines.length > 0)
				{
					compute();
					if (!_center)
						return new Point(0,0);
				}
			}
			return _center;
		}
		
		public function toString(): String
		{
			var str: String = "FeatureDataReflection lines: " + _lines.length + " poins: " + _points.length;
			if (_lines.length > 0)
			{
				str += " (";
				for each (var line: FeatureDataLine in _lines)
				{
					str += line.id + " ";
				}
				str += ")";
			}
			return str;
		}
	}
}