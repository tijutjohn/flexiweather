package com.iblsoft.flexiweather.ogc.editable.data
{
	import com.iblsoft.flexiweather.proj.Coord;
	import com.iblsoft.flexiweather.utils.geometry.LineSegment;

	import flash.display.DisplayObject;
	import flash.display.Stage;
	import flash.events.Event;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.utils.Dictionary;
	import flash.utils.getTimer;

	import mx.core.FlexGlobals;

	public class FeatureDataReflection
	{
		public static var fdr_uid: int = 0;
		public var uid: int;

		[ArrayElementType("com.iblsoft.flexiweather.ogc.editable.data.FeatureDataLine")]
		private var _lines: Array;

		[ArrayElementType("com.iblsoft.flexiweather.ogc.editable.data.FeatureDataPoint")]
		private var _points: Array;

//		[ArrayElementType("com.iblsoft.flexiweather.ogc.editable.data.FeatureDataPoint")]
		/**
		 * Editable points are filtered from _points array in compute() method. So be sure they are computed before you access this array
		 */
		private var _editablePoints: Array;

		public var reflectionDelta: int;

		public function get lines(): Array
		{
			return _lines;
		}

		public function get linesLength(): int
		{
			var cnt: int = 0;
			for (var obj: Object in _lines)
				cnt++;

			return cnt;
		}

		public function get points(): Array
		{
			return _points;
		}
		public function get editablePoints(): Array
		{
			return _editablePoints;
		}

		public  var parentFeatureData: FeatureData;

		private var _stage: Stage;
		private var _listening: Boolean;

		public function FeatureDataReflection(i_reflectionData: int)
		{
			uid = fdr_uid++;

			_lines = new Array();
			_points = new Array();
			_editablePoints = new Array();
			reflectionDelta = i_reflectionData;
			_stage = (FlexGlobals.topLevelApplication as DisplayObject).stage;

			//trace("FeatureDataReflection created: " + this);

		}

		public function setEditablePoints(editablePoints: Array): void
		{
			_editablePoints = editablePoints;
		}

		public function debug(): void
		{
			trace("\t FeatureDataReflection: " + reflectionDelta);
			trace("\t Lines: " + linesLength);

			var total: int = linesLength;
			for (var lineID: String in _lines)
			{
				var line: FeatureDataLine = getLineAt(parseInt(lineID));
				trace("\t\t :" + line);
			}
		}

		public function get ids(): Array
		{
			var _ids: Array = [];
			for (var lineID: String in _lines)
				_ids.push(parseInt(lineID));

			_ids.sort(Array.NUMERIC)

			return _ids;
		}

		public function clear(): void
		{
			if (_points.length > 0)
				_points.splice(0, _points.length);
//			if (_lines.length > 0)
//				_lines.splice(0, _lines.length);

			var total: int = linesLength;
			var _ids: Array = ids;

			for each (var iLineID: int in _ids)
			{
				deleteLineAt(iLineID);

//				var line: FeatureDataLine = getLineAt(parseInt(lineID));
//				line.clear();
//				//trace("\t\t :" + line);
			}

//			var total: int = _lines.length;
//			for (var i: int = 0; i < total; i++)
//			{
//				var line: FeatureDataLine = getLineAt(i);
//				line.clear();
//			}
		}

		public function createLine(): FeatureDataLine
		{
			return createLineAt(_lines.length);
		}

		public function deleteLineAt(position: int): void
		{
			var line: FeatureDataLine = _lines[position] as FeatureDataLine;

			line.removeEventListener(FeatureDataLine.LINE_SEGMENT_ADDED, onLineSegmentsChanged);
			line.removeEventListener(FeatureDataLine.LINE_SEGMENT_REMOVED, onLineSegmentsChanged);

			line.parentFeatureData = null;
			line.parentFeatureReflection = null
			delete _lines[position];

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

		public function hasLineAt(position: int): Boolean
		{
			return (_lines[position] is FeatureDataLine);
		}
		public function getLineAt(position: int): FeatureDataLine
		{
//			if (_lines.length <= position)
//			{
//				return createLineAt(position);
//			}

			if (!hasLineAt(position))
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
//			trace("\t" + this + " VALIDATE");
			compute();
			stopListenForNextFrame();
		}

		/**
		 * When line is added or removed, everything is computed to do not recompute everything when e.g. center point is requested
		 *
		 */
		private function compute(): void
		{
			//trace("\t COMPUTE START" + this);
			var currTime: Number = getTimer();

			if (_points.length > 0)
				_points.splice(0, _points.length);
			var cnt: int = 0;
			var oldPoint: FeatureDataPoint;
//			_editablePoints = [];

			var _ids: Array = ids;

			for each (var iLineID: int in _ids)
			{
				var line: FeatureDataLine = _lines[iLineID] as FeatureDataLine;
				var totalLineSegments: int = line.lineSegments.length;
				for (var s: int = 0 ; s < totalLineSegments; s++)
				{
					var lineSegment: FeatureDataLineSegment = line.lineSegments[s] as FeatureDataLineSegment;
					if (!lineSegment)
						continue;
					if (!lineSegment.visible)
						continue;

//					trace("line segment:  lineID = " + iLineID + " s: " + s + " Segment: " + lineSegment);
					var p1: FeatureDataPoint = new FeatureDataPoint(lineSegment.x1, lineSegment.y1);
					var p2: FeatureDataPoint = new FeatureDataPoint(lineSegment.x2, lineSegment.y2);


					if (!oldPoint)
						_points.push(p1);
					else if (oldPoint.x != p1.x || oldPoint.y != p1.y) {
//						trace("old and new points are not equal: lineID = " + iLineID + " s: " + s);
						_points.push(null);
						_points.push(p1);
					}

					//check if line has defined second point
					if (!isNaN(p2.x) && !isNaN(p2.y))
					{
						_points.push(p2);
						oldPoint = p2.clone() as FeatureDataPoint;
					} else {
						oldPoint = p1.clone() as FeatureDataPoint;
						//if there is no second point, add NULL (split line)
						_points.push(null);
					}

					if (cnt == 0)
						_startPoint = p1.clone() as FeatureDataPoint;

					cnt++;
//					trace("\t Old point: lineID = " + iLineID + " s: " + s + " point: " + oldPoint);
				}
			}

			//fix last point for null
			var ok: Boolean = _points.length > 0;
			cnt = _points.length - 1;
			while (ok)
			{
				oldPoint = _points[cnt] as FeatureDataPoint;
				if (!oldPoint)
				{
					_points.splice(cnt,1);
					cnt--;
					if (_points.length == 0)
						ok = false;
				} else {
					ok = false;
				}
			}
			if (_points.length > 1)
				_points = clipData(_points);

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

			//trace("\t COMPUTE END took: " + (getTimer() - currTime) + "ms. > " + this);
		}

		private function clipData(points: Array): Array
		{
			if (parentFeatureData.forceViewBBoxClipping)
			{
				var clipRect: Rectangle = parentFeatureData.clippingRectangle;
				if (clipRect)
				{
					var margin: int = -15;
					var rightMargin: int = 15;

					var left: int = clipRect.left + margin;
					var right: int = clipRect.right + rightMargin;
					var top: int = clipRect.top + margin;
					var bottom: int = clipRect.bottom + rightMargin;

					var clipPolygon: Array = [new Point(left,top), new Point(right,top), new Point(right, bottom), new Point(left, bottom)];

					points = parentFeatureData.featureSplitter.polygonClipppingSutherlandHodgman(points, clipPolygon, FeatureDataPoint);
				}
			}
			return points;
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
			var str: String = "FeatureDataReflection ["+uid+"] lines: " + _lines.length + " points: " + _points.length;
//			if (_lines.length > 0)
//			{
//				str += " (";
//				for each (var line: FeatureDataLine in _lines)
//				{
//					str += line.id + " ";
//				}
//				str += ")";
//			}
			return str;
		}
	}
}