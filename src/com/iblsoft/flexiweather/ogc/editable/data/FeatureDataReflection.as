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
		
		[ArrayElementType("com.iblsoft.flexiweather.ogc.editable.data.FeatureDataPoint")]
		private var _points: Array;
		
		public var reflectionDelta: int;
		
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
		
		public function FeatureDataReflection(i_reflectionData: int)
		{
			_lines = new Array();
			_points = new Array();
			reflectionDelta = i_reflectionData;
			_stage = (FlexGlobals.topLevelApplication as DisplayObject).stage;
				
		}
		
		public function debug(): void
		{
			trace("\t FeatureDataReflection: " + reflectionDelta);
			trace("\t Lines: " + _lines.length);
			
			var total: int = _lines.length;
			for (var i: int = 0; i < total; i++)
			{
				var line: FeatureDataLine = getLineAt(i);
				trace("\t\t :" + line);
			}
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
			if (_lines.length <= position)
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
		
		private var _center: FeatureDataPoint;
		private var _startPoint: FeatureDataPoint;
		
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
			var oldPoint: FeatureDataPoint;
			for each (var line: FeatureDataLine in _lines)
			{
				for each (var lineSegment: LineSegment in line.lineSegments)
				{
					var p1: FeatureDataPoint = new FeatureDataPoint(lineSegment.x1, lineSegment.y1);
					var p2: FeatureDataPoint = new FeatureDataPoint(lineSegment.x2, lineSegment.y2);
					
					
					if (!oldPoint)
						_points.push(p1);
					else if (oldPoint.x != p1.x || oldPoint.y != p1.y) {
						_points.push(null);
						_points.push(p1);
					}
						
					_points.push(p2);
					
					if (cnt == 0)
						_startPoint = p1.clone() as FeatureDataPoint;
					
					oldPoint = p2.clone() as FeatureDataPoint;
					cnt++;
				}
			}
			
			_center = new FeatureDataPoint();
			var total: int = 0;
			for each (var ptr: FeatureDataPoint in _points)
			{
				if (ptr)
				{
					_center.addPoint(ptr);
					total++;
				}
			}
			_center.x /= total;
			_center.y /= total;
		}
		
		public function get startPoint(): FeatureDataPoint
		{
			return _startPoint
		}
		public function get center(): FeatureDataPoint
		{
			if (!_center)
			{
//				trace("Center is not computed");
				if (lines && lines.length > 0)
				{
					compute();
					if (!_center)
						return new FeatureDataPoint(0,0);
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