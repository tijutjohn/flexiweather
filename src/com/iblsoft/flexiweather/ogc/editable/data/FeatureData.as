package com.iblsoft.flexiweather.ogc.editable.data
{
	import com.iblsoft.flexiweather.ogc.data.ReflectionData;

	import flash.utils.Dictionary;

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

		private var _points: Array;

		private var m_closed: Boolean;


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
		public var reflectionDelta: int;

		public function get reflectionsLength(): int
		{
			if (reflections)
			{
				//we need to enumerate via reflections, because length does not work with negative indicies
				return reflectionsIDs.length;
//				var cnt: int = 0;
//				for each (var refl: FeatureDataReflection in reflections)
//					cnt++
//
//				return cnt;
			}
			return 0;
		}
		public function get linesLength(): int
		{
//			if (lines)
//				return lines.length;

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

		public function FeatureData(name: String)
		{
			uid = fd_uid++;

			this.name = name;
			_points = new Array();
			lines = [];
			reflections = [];
			reflectionsIDs = [];

			reflectionDelta = 0;
			trace("FeatureData created: " + this);
		}

		public function debug(): void
		{
			trace("FeatureData: " + name);
			trace("\tLines: " + lines.length);
			trace("\tReflections: " + reflectionsLength);

			var total: int = reflectionsLength;
			var reflectionIDs: Array = reflectionsIDs;

			for (var i: int = 0; i < total; i++)
			{
				var refl: FeatureDataReflection = getReflectionAt(reflectionIDs[i]);
				trace("\t\tLines: " + refl.lines.length);
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
					trace("Reflection: " + refl + " has no points");
				}
			}

			if (oldReflection && oldReflection != firstRefl)
			{
				//update first reflection "previous reflection"
				(tempDict[firstRefl] as ReflectionHelper).previousReflection = oldReflection;
			}

			//algorithm start
			var cnt: int = startingID;
			var tempRefl: FeatureDataReflection;

			while(cnt <= lastID)
			{
				if (currentReflection.hasLineAt(cnt))
				{
					tempLines.push(currentReflection.getLineAt(cnt));
					cnt++;
				} else {
					//find different reflection with correct line ID
					tempRefl = currentReflection;
					var ok: Boolean = true;
					while(ok)
					{
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
									trace("Do not write null, previous item is null");

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
						}
					}
				}
			}

			lines = tempLines;
			compute();
			trace(this + " has computed LINES");
		}

		/**
		 * When line is added or removed, everything is computed to do not recompute everything when e.g. center point is requested
		 *
		 */
		private function compute(): void
		{
//			trace("********************************************************");
//			trace("\t COMPUTE START" + this);
			if (_points.length > 0)
				_points.splice(0, _points.length);
			var cnt: int = 0;
			var oldPoint: FeatureDataPoint;
			//			_editablePoints = [];

//			var _ids: Array = ids;

			for each (var line: FeatureDataLine in lines)
			{
				if (line)
				{
					var totalLineSegments: int = line.lineSegments.length;
					for (var s: int = 0 ; s < totalLineSegments; s++)
					{
						var lineSegment: FeatureDataLineSegment = line.lineSegments[s] as FeatureDataLineSegment;
						if (!lineSegment)
						{
							_points.push(null);
							continue;
						}

						var lineSegmentVisible: Boolean = lineSegment.visible;

						if (!lineSegmentVisible)
						{
							if (!closed)
							{
								_points.push(null);
								continue;
							}
						}
//						trace("line segment:  lineID = " + line.id + " s: " + s + " Segment: " + lineSegment);
						var p1: FeatureDataPoint = new FeatureDataPoint(lineSegment.x1, lineSegment.y1);
						var p2: FeatureDataPoint = new FeatureDataPoint(lineSegment.x2, lineSegment.y2);


						if (!oldPoint)
							_points.push(p1);
						else if (oldPoint.x != p1.x || oldPoint.y != p1.y) {
//							trace("old and new points are not equal: lineID = " + line.id + " s: " + s);
	//						_points.push(null);
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
//						trace("\t Old point: lineID = " + line.id + " s: " + s + " point: " + oldPoint);
					}
				} else {
					_points.push(null);
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

			//			trace("\t COMPUTE END avg: " + _center + " > " + this);
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

		private function updateIDs(): void
		{
			_reflectionsIDs = [];
			for (var id: Object in reflections)
			{
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
	public var startID: int;
	public var lastID: int;
	public var ids: Array;

	public function ReflectionHelper(reflection: FeatureDataReflection)
	{
		this.reflection = reflection;
		this.ids = reflection.ids;

		if (ids && ids.length > 0)
		{
			startID = ids[0];
			lastID = ids[ids.length - 1];
		}
	}
}