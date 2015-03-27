package com.iblsoft.flexiweather.ogc.editable.data
{
	import com.iblsoft.flexiweather.ogc.data.ReflectionData;
	import com.iblsoft.flexiweather.utils.wfs.FeatureSplitter;

	import flash.geom.Rectangle;
	import flash.utils.Dictionary;
	import flash.utils.getTimer;

	import spark.primitives.Rect;

	public class FeatureData
	{
		public static var fd_uid: int = 0;
		public var uid: int;

		[ArrayElementType("com.iblsoft.flexiweather.ogc.editable.data.FeatureDataReflection")]
		public var reflections: Array;
		private var _reflectionsIDs: Array;

		[ArrayElementType("com.iblsoft.flexiweather.ogc.editable.data.FeatureDataLine")]
		public var lines: Array;

		private var _center: FeatureDataPoint;
		private var _startPoint: FeatureDataPoint;

		private var _clippingRectangle: Rectangle;

		private var _points: Array;

		private var m_closed: Boolean;



		public function get featureSplitter():FeatureSplitter
		{
			return _featureSplitter;
		}

		public function set featureSplitter(value:FeatureSplitter):void
		{
			_featureSplitter = value;
		}

		public function get reflectionDelta():int
		{
			return m_reflectionDelta;
		}

		public function set reflectionDelta(value:int):void
		{
			m_reflectionDelta = value;
		}

		public function get clippingRectangle():Rectangle
		{
			return _clippingRectangle;
		}

		public function set clippingRectangle(value:Rectangle):void
		{
			_clippingRectangle = value;
		}

		public function get closed():Boolean
		{
			return m_closed;
		}

		public function set closed(value:Boolean):void
		{
			m_closed = value;
		}

		public function get reflectionsIDs():Array
		{
			if (_reflectionsIDs.length != reflections.length)
				updateIDs();

			return _reflectionsIDs;
		}

		public function set reflectionsIDs(value:Array):void
		{
			_reflectionsIDs = value;
		}

		public function get points(): Array
		{
			return _points;
		}

		/**
		 * Reflection in which is feature drawn. If feature is drawn across dateline, it's counted separately, but afterwards joined and draw as inside reflection.
		 */
		private var m_reflectionDelta: int;

		public function get reflectionsLength(): int
		{
			if (reflections)
			{
				//we need to enumerate via reflections, because length does not work with negative indicies
				return reflectionsIDs.length;
			}
			return 0;
		}
		public function get linesLength(): int
		{
			var total: int = reflectionsLength;
			var reflectionIDs: Array = reflectionsIDs;

			var linesCount: int = 0;
			for (var i: int = 0; i < total; i++)
			{
				var refl: FeatureDataReflection = getReflectionAt(reflectionIDs[i]);
				linesCount += refl.linesLength;
			}

			return linesCount;
		}

		public var name: String;

		public var forceViewBBoxClipping: Boolean;
		private var _featureSplitter: FeatureSplitter;

		public function FeatureData(name: String)
		{
			uid = fd_uid++;

			this.name = name;
			_points = new Array();
			lines = [];
			reflections = [];
			reflectionsIDs = [];

			reflectionDelta = 0;
			debug("FeatureData created: " + this);

			forceViewBBoxClipping = true;
		}

		private function debug(txt: String): void
		{
//			trace(this + ": " + txt);
		}
		public function debugData(): void
		{
			debug("FeatureData: " + name);
			debug("\tLines: " + lines.length);
			debug("\tReflections: " + reflectionsLength);

			var total: int = reflectionsLength;
			var reflectionIDs: Array = reflectionsIDs;

			for (var i: int = 0; i < total; i++)
			{
				var refl: FeatureDataReflection = getReflectionAt(reflectionIDs[i]);
				debug("\t\tLines: " + refl.lines.length);
				refl.debug();
			}
		}

		/**
		 * Feature data always draw just one feature and it's reflections. Feature can be drawn in one reflection, or it can be splitted on dateline.
		 * For continues drawing, features points after reflections are counted need to be joined together again (on dateline) to correctly draw features without gaps
		 * This function will join them. It needs to check if there will be one polyline or more (more reflection visible on screen...e.g feature starts at right side and continues on the left side of screen)
		 *
		 */
		public function joinLinesFromReflections(): void
		{
			joinLinesFromReflectionsNew();
			//when you want to use OLD solution, go to compute() method and also uncomment computeOld
//			joinLinesFromReflectionsOld();
		}

		public function joinLinesFromReflectionsNew(): void
		{
			var currTime: Number = getTimer();
			var total: int = reflectionsLength;
			if (total == 0)
				return;

			var tempLines: Array = [];

			var startingID: int = int.MAX_VALUE;
			var lastID: int = int.MIN_VALUE;
			var currentReflection: FeatureDataReflection;
			var oldReflection: FeatureDataReflection;
			var helper: ReflectionHelper;

			var lineID: int = 0;

			var reflectionIDs: Array = reflectionsIDs;
			var refl: FeatureDataReflection;
			var firstRefl: FeatureDataReflection;

			if (total == 1)
			{
				reflectionDelta = reflectionIDs[0];
				refl = getReflectionAt(reflectionDelta);
				lines = refl.lines;
				compute();
				return;
			}

			var helperMaxLines: int = 0;

			//1st step - Find first and last ID and set reflection list

			var tempDict: Dictionary = new Dictionary();
			for (var i: int = 0; i < total; i++)
			{
				refl = getReflectionAt(reflectionIDs[i]);

				var linesCount: int = refl.linesLength;
				if (linesCount > 0)
				{
					if (linesCount > helperMaxLines)
					{
						helperMaxLines = linesCount;
						reflectionDelta = reflectionIDs[i];
					}
					if (!firstRefl)
						firstRefl = refl;

					helper = new ReflectionHelper(refl);
					tempDict[refl] = helper;
					helper.previousReflection = oldReflection;

					if (helper.startID < startingID)
					{
						startingID = helper.startID;
						currentReflection = refl;
					}
					if (helper.lastID > lastID)
					{
						lastID = helper.lastID;
					}

					oldReflection = refl;
				} else {
					debug("Reflection: " + refl + " has no points");
				}
			}


			if (oldReflection && oldReflection != firstRefl)
			{
				//update first reflection "previous reflection"
				(tempDict[firstRefl] as ReflectionHelper).previousReflection = oldReflection;
			}

			debug("Join lines 1st step - startingID: " + startingID + " lastID: " + lastID);

			//algorithm start
			var cnt: int = startingID;

			for each (helper in tempDict)
			{
				for each (var splineInfo: SplineInfo in helper.splines)
				{
					var fromID: int = splineInfo.startID;
					var toID: int = splineInfo.endID;
					currentReflection = helper.reflection;
					debug("Spline from: " + fromID + " to : " + toID + " reflection: " + currentReflection.reflectionDelta);
					for (i = fromID; i <= toID; i++)
					{
						tempLines.push(currentReflection.getLineAt(i));
					}
					tempLines.push(null);
				}
			}

			lines = tempLines;
			compute();
//			debug(this + " has computed LINES - Time:" + (getTimer() - currTime) + "ms.");
		}

		public function joinLinesFromReflectionsOld(): void
		{
			var currTime: Number = getTimer();
			var total: int = reflectionsLength;
			if (total == 0)
				return;

			var tempLines: Array = [];

			var startingID: int = int.MAX_VALUE;
			var lastID: int = int.MIN_VALUE;
			var currentReflection: FeatureDataReflection;
			var oldReflection: FeatureDataReflection;
			var helper: ReflectionHelper;

			var lineID: int = 0;

			var reflectionIDs: Array = reflectionsIDs;
			var refl: FeatureDataReflection;
			var firstRefl: FeatureDataReflection;

			if (total == 1)
			{
				reflectionDelta = reflectionIDs[0];
				refl = getReflectionAt(reflectionDelta);
				lines = refl.lines;
				compute();
				return;
			}

			var helperMaxLines: int = 0;

			//1st step - Find first and last ID and set reflection list

			var tempDict: Dictionary = new Dictionary();
			for (var i: int = 0; i < total; i++)
			{
				refl = getReflectionAt(reflectionIDs[i]);

				var linesCount: int = refl.linesLength;
				if (linesCount > 0)
				{
					if (linesCount > helperMaxLines)
					{
						helperMaxLines = linesCount;
						reflectionDelta = reflectionIDs[i];
					}
					if (!firstRefl)
						firstRefl = refl;

					helper = new ReflectionHelper(refl);
					tempDict[refl] = helper;
					helper.previousReflection = oldReflection;

					if (helper.startID < startingID)
					{
						startingID = helper.startID;
						currentReflection = refl;
					}
					if (helper.lastID > lastID)
					{
						lastID = helper.lastID;
					}

					oldReflection = refl;
				} else {
					debug("Reflection: " + refl + " has no points");
				}
			}


			if (oldReflection && oldReflection != firstRefl)
			{
				//update first reflection "previous reflection"
				(tempDict[firstRefl] as ReflectionHelper).previousReflection = oldReflection;
			}

			debug("Join lines 1st step - startingID: " + startingID + " lastID: " + lastID);

			//algorithm start
			var cnt: int = startingID;

			//check if there is problematic lines
			while(cnt <= lastID)
			{
				var totalLinesForCnt: int = 0;
				for each (helper in tempDict)
				{
					if (helper.reflection.hasLineAt(cnt))
					{
						totalLinesForCnt++;
					}
				}
				if (totalLinesForCnt == 0)
				{
					debug("There is no lines at position: " + cnt);
				}
				if (totalLinesForCnt > 1)
				{
					debug("More than 1 line at position: " + cnt + " lines: " + totalLinesForCnt);
				}
				cnt++;
			}


			cnt = startingID;
			var tempRefl: FeatureDataReflection;

			currTime = getTimer();
			while(cnt <= lastID)
			{
				if ((getTimer() - currTime) > 5000)
				{
					debug("	joinLinesFromReflections 1 infinite loop");
				}
				if (currentReflection.hasLineAt(cnt))
				{
					tempLines.push(currentReflection.getLineAt(cnt));
					cnt++;
				} else {
					debug("\t 	joinLinesFromReflections No line in current reflection on position: " + cnt);
					//find different reflection with correct line ID
					tempRefl = currentReflection;
					var ok: Boolean = true;
					while(ok)
					{
						if ((getTimer() - currTime) > 5000)
						{
							debug("	joinLinesFromReflections 2 infinite loop");
						}
						helper = tempDict[currentReflection] as ReflectionHelper;
						currentReflection = helper.previousReflection;
						if (currentReflection)
						{
							if (currentReflection == tempRefl)
							{
								//went through all reflection, nothing found, insert "NULL" gap
								var bWriteNull: Boolean = true;

								if (tempLines.length > 0 && tempLines[tempLines.length - 1] == null)
									bWriteNull = false;

								if (bWriteNull)
									tempLines.push(null);
								else
									debug("Do not write null, previous item is null");

								ok = false;
								cnt++;
							} else {
								if (currentReflection.hasLineAt(cnt))
								{
									tempRefl = null;
									ok = false;
								} else {
									//search next reflection
								}
							}
						} else {
							currentReflection = tempRefl;
							tempRefl = null;
							ok = false;
							cnt++;
						}
					}
				}
			}

			lines = tempLines;
			compute();
			debug(this + " has computed LINES - Time:" + (getTimer() - currTime) + "ms.");
		}

		public function get ids(): Array
		{
			var _ids: Array = [];
			for (var lineID: String in lines)
				_ids.push(parseInt(lineID));

			_ids.sort(Array.NUMERIC)

			return _ids;
		}

		/**
		 * When line is added or removed, everything is computed to do not recompute everything when e.g. center point is requested
		 *
		 */
		private function compute(): void
		{
			computeNew();

			//when you want to use OLD solution, go to joinLinesFromReflections() method and also uncomment joinLinesFromReflectionsOld
//			computeOld();
		}

		private function debugLinesForOrderProblem(): void
		{
			var totalLines: int = lines.length;
			var str: String = "for loop: ";
			for (var i: int = 0; i < totalLines; i++)
			{
				var line: FeatureDataLine = lines[i] as FeatureDataLine;
				if (line)
					str +=	line.id + ", ";
				else
					str +=	"null, ";
			}
			trace(str);
			var str: String = "for each: ";
			for each (line in lines)
			{
				if (line)
					str +=	line.id + ", ";
				else
					str +=	"null, ";
			}
			trace(str);
		}
		private function computeNew(): void
		{
			var currTime: Number = getTimer();
			//			debug("********************************************************");
			//			debug("\t COMPUTE START" + this);
			if (_points.length > 0)
				_points.splice(0, _points.length);
			var cnt: int = 0;
			var oldPoint: FeatureDataPoint;

			var oldLineID: Number = -1;
			var bNewLineInserted: Boolean;

			var _ids: Array = ids;

			var totalLines: int = lines.length;
			var visibleLines: int = 0;
			var visiblePoints: int = 0;
			var totalLinePoints: int = 0;
			var totalNulls: int = 0;

			var previousNotValidPoint: Boolean;

			//just for debugging, to test that for each loop has wrong order of lines
//			debugLinesForOrderProblem();

			for (var i: int = 0; i < totalLines; i++)
			{
				var line: FeatureDataLine = lines[i] as FeatureDataLine;
				if (line)
				{
					var totalLineSegments: int = line.lineSegments.length;
					for (var s: int = 0 ; s < totalLineSegments; s++)
					{
						var lineSegment: FeatureDataLineSegment = line.lineSegments[s] as FeatureDataLineSegment;
						if (!lineSegment)
						{
							if (visiblePoints > 0)
							{
								if (totalNulls == 0)
								{
									addPoint(null);
									totalNulls++;
								}
							}
							visiblePoints = 0;
							previousNotValidPoint = true;
							continue;
						}

						var lineSegmentVisible: Boolean = lineSegment.visible;

						if (!lineSegmentVisible)
						{
							if (visiblePoints > 0)
							{
								if (totalNulls == 0)
								{
									addPoint(null);
									totalNulls++;
								}
							}
							visiblePoints = 0;
							previousNotValidPoint = true;
							continue;
						}
						//						debug("line segment:  lineID = " + line.id + " s: " + s + " Segment: " + lineSegment);
						var p1: FeatureDataPoint = new FeatureDataPoint(lineSegment.x1, lineSegment.y1);
						var p2: FeatureDataPoint = new FeatureDataPoint(lineSegment.x2, lineSegment.y2);
						//						debug("\t\t compute p1: " + p1 + " p2: " + p2);

						if (!oldPoint) {
							addPoint(p1);
							visiblePoints++;
							totalNulls = 0;
							totalLinePoints++;
						} else if (oldPoint.x != p1.x || oldPoint.y != p1.y) {
//							debug("old and new points are not equal: lineID = " + line.id + " s: " + s);
							if (previousNotValidPoint)
							{
								if (visiblePoints > 0)
								{
									if (totalNulls == 0)
									{
										addPoint(null);
										totalNulls++;
									}
								}
								visiblePoints = 0;
							}
							addPoint(p1);
							visiblePoints++;
							totalNulls = 0;
							totalLinePoints++;
						}

						//check if line has defined second point
						if (!isNaN(p2.x) && !isNaN(p2.y))
						{
							addPoint(p2);
							visiblePoints++;
							totalNulls = 0;
							totalLinePoints++;
							oldPoint = p2.clone() as FeatureDataPoint;
						} else {
							oldPoint = p1.clone() as FeatureDataPoint;
							//if there is no second point, add NULL (split line)
							if (visiblePoints > 0)
							{
								if (totalNulls == 0)
								{
									addPoint(null);
									totalNulls++;
								}
							}
							visiblePoints = 0;
						}

						if (cnt == 0)
							_startPoint = p1.clone() as FeatureDataPoint;

						cnt++;
						//						debug("\t Old point: lineID = " + line.id + " s: " + s + " point: " + oldPoint);
					}

					if (totalLinePoints > 0)
						visibleLines++;

					previousNotValidPoint = false;
				} else {
					if (visibleLines > 0 && totalNulls == 0)
						addPoint(null);
					visibleLines = 0;
				}

//				oldLineID = iLineID;
			}

			//			debug("STEP 2");
			var newPoint: FeatureDataPoint = checkClipping(_points, 0, _points.length - 1);
			if (newPoint)
				addPoint(newPoint);


			//			debug("STEP 3");
			cnt = 0;
			_center = new FeatureDataPoint();
			var total: int = 0;
//			for each (var ptr: FeatureDataPoint in _points)
			var pointsLen: int = _points.length;
			for (i = 0; i < pointsLen; i++)
			{
				var ptr: FeatureDataPoint = _points[i] as FeatureDataPoint;
				if (ptr)
				{
					//					debug("\t\t\t Point["+cnt+"] " + ptr);
					_center.addPoint(ptr);
					total++;
				} else {
					//					debug("\t\t\t Point["+cnt+"] NULL");

					//check, if there needs to added point on edge of the screen
					newPoint = checkClipping(_points, cnt+1, cnt-1);

					if (newPoint)
					{
						//there is NULL on "cnt" position, remove it and insert newPoint there
						_points.splice(cnt, 1, newPoint);
						cnt++;
					}
				}
				oldPoint = ptr;
				cnt++;
			}
			_center.x /= total;
			_center.y /= total;

			//			debug("\t COMPUTE END avg: " + _center + " > " + this);
			//			debug("compute took " + (getTimer() - currTime) + "ms.");
		}

		private function addPoint(point: FeatureDataPoint): void
		{
			_points.push(point);
		}


		/**
		 * Check points if there are outside of viewBBox and there needs to be inserted another point to correctly draw feature when it is clipped
		 * @param _points
		 * @param firstPointPosition
		 * @param lastPoinPositiont
		 * @param newPosition
		 * @return
		 *
		 */
		private function checkClipping(_points: Array, firstPointPosition: int, lastPoinPositiont: int): FeatureDataPoint
		{
			var firstPoint: FeatureDataPoint = _points[firstPointPosition] as FeatureDataPoint;
			var lastPoint: FeatureDataPoint = _points[lastPoinPositiont] as FeatureDataPoint;

			if (!firstPoint || !lastPoint)
				return null;

			var newPoint: FeatureDataPoint;
			var left: Number = clippingRectangle.left;
			var right: Number = clippingRectangle.right;
			var top: Number = clippingRectangle.top;
			var bottom: Number = clippingRectangle.bottom;

			//check - top left corner
			if (firstPoint.y < top && lastPoint.x < left)
				newPoint = new FeatureDataPoint(lastPoint.x, firstPoint.y);
			if (firstPoint.x < left && lastPoint.y < top)
				newPoint = new FeatureDataPoint(firstPoint.x, lastPoint.y);

			//check - top right corner
			if (firstPoint.y < top && lastPoint.x > right)
				newPoint = new FeatureDataPoint(lastPoint.x, firstPoint.y);
			if (firstPoint.x > right && lastPoint.y < top)
				newPoint = new FeatureDataPoint(firstPoint.x, lastPoint.y);

			//check - top bottom corner
			if (firstPoint.y > bottom && lastPoint.x > right)
				newPoint = new FeatureDataPoint(lastPoint.x, firstPoint.y);
			if (firstPoint.x > right && lastPoint.y > bottom)
				newPoint = new FeatureDataPoint(firstPoint.x, lastPoint.y);

			//check - top bottom corner
			if (firstPoint.y > bottom && lastPoint.x < left)
				newPoint = new FeatureDataPoint(lastPoint.x, firstPoint.y);
			if (firstPoint.x < left && lastPoint.y > bottom)
				newPoint = new FeatureDataPoint(firstPoint.x, lastPoint.y);

			return newPoint;
		}

		public function get startPoint(): FeatureDataPoint
		{
			return _startPoint
		}
		public function get center(): FeatureDataPoint
		{
			if (!_center)
			{
				//				debug("Center is not computed");
				if (lines && lines.length > 0)
				{
					compute();
					if (!_center)
						return new FeatureDataPoint(0,0);
				}
			}
			return _center;
		}

		/**
		 * Call clear method before reusing FeatureData. E.g. recompute data
		 *
		 */
		public function clear(): void
		{
			var total: int = reflectionsLength;
			var reflectionIDs: Array = reflectionsIDs;

			for (var i: int = 0; i < total; i++)
			{
				var refl: FeatureDataReflection = getReflectionAt(reflectionIDs[i]);
				refl.clear();
			}
			reflectionsIDs = [];
		}

		public function getLineAt(reflectionDelta: int, position: int): FeatureDataLine
		{
			var refl: FeatureDataReflection = getReflectionAt(reflectionDelta);
			var line: FeatureDataLine = refl.getLineAt(position);
			return line;
		}
		public function createReflection(): FeatureDataReflection
		{
			return createReflectionAt(reflectionsLength);
		}

		protected function createFeatureDataReflectionInstance(position: int): FeatureDataReflection
		{
			return new FeatureDataReflection(position);
		}
		public function createReflectionAt(position: int): FeatureDataReflection
		{
			var reflection: FeatureDataReflection = createFeatureDataReflectionInstance(position);
			reflection.parentFeatureData = this;
			reflections[position] = reflection;
			updateIDs();
			return reflection;
		}

		public function updateReflectionIDsWith(newIDs: Array): Array
		{
			for each (var newID: int in newIDs)
			{
				if (_reflectionsIDs.indexOf(newID) == -1)
				{
					_reflectionsIDs.push(newID);
					getReflectionAt(newID);
				}
			}

			return _reflectionsIDs;
		}
		private function updateIDs(): void
		{
			_reflectionsIDs = [];
			for (var id: Object in reflections)
			{
				if (id is String)
					id = parseInt(id as String);

				_reflectionsIDs.push(id);
			}
		}

		/**
		 *Returns reflection data at given position.
		 *
		 * @param position reflectionDelta parameter from FeatureDataReflection class
		 * @return FeatureDataReflection
		 *
		 */
		public function getReflectionAt(position: int): FeatureDataReflection
		{
//			if (reflections.length <= position)
			if (reflections[position] == null)
			{
				return createReflectionAt(position);
			}

			if (!(reflections[position] is FeatureDataReflection))
				return createReflectionAt(position);

			updateIDs();
			return reflections[position] as FeatureDataReflection;
		}

		public function toString(): String
		{
			return "FeatureData ["+uid+"]" + reflectionsLength + " name: " +  name;
		}
	}
}
import com.iblsoft.flexiweather.ogc.editable.data.FeatureDataReflection;

class ReflectionHelper
{
	public var reflection: FeatureDataReflection;
	public var previousReflection: FeatureDataReflection;
	public function get startID(): int
	{
		if (splines.length > 0)
			return (splines[0] as SplineInfo).startID;

		return -1;
	}
	public function get lastID(): int
	{
		if (splines.length > 0)
			return (splines[splines.length - 1] as SplineInfo).endID;

		return -1;
	}
	public var ids: Array;
	public var splines: Array

	public function ReflectionHelper(reflection: FeatureDataReflection)
	{
		this.reflection = reflection;
		this.ids = reflection.ids;
		splines = [];
		analyseIDs();
	}

	private function analyseIDs(): void
	{
//		if (ids && ids.length > 0)
//		{
//			startID = ids[0];
//			lastID = ids[ids.length - 1];
//		}

		var oldID: int = -1;
		var currSplineInfo: SplineInfo = new SplineInfo();
		for each (var id: int in ids)
		{
			if (currSplineInfo.startID == -1)
				currSplineInfo.startID = id;
			else {
				if ((id - oldID) > 1)
				{
					currSplineInfo.endID = oldID;
					splines.push(currSplineInfo);
					currSplineInfo = new SplineInfo();
					currSplineInfo.startID = id;
				}
			}
			oldID = id;
		}
		if (currSplineInfo.endID == -1)
			currSplineInfo.endID = id;

		splines.push(currSplineInfo);

	}

	public function addSpline(startID: int, endID: int): void
	{
		splines.push(new SplineInfo(startID, endID));
	}
}

class SplineInfo
{
	public var startID: int;
	public var endID: int;

	public function SplineInfo(startID: int = -1, endID: int = -1)
	{
		this.startID = startID;
		this.endID = endID;
	}
}