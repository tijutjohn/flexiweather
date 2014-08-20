package com.iblsoft.flexiweather.ogc.data
{
	import com.iblsoft.flexiweather.proj.Coord;
	import com.iblsoft.flexiweather.widgets.InteractiveWidget;
	
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.geom.Point;
	import flash.utils.Dictionary;

	public class FeatureEditablePoints extends EventDispatcher
	{
		public static const CHANGED: String = 'changed';
		
		private var m_points: Array;
		private var m_reflectedPoints: Dictionary;
		
		public function get length(): int
		{
			return m_points.length;
		}
		
		public var container: InteractiveWidget;
		
		public function FeatureEditablePoints()
		{
			initializePoints();
		}
		
		public function getPointsForReflection(reflectionID: int): Array
		{
			if (m_reflectedPoints[reflectionID])
				return m_reflectedPoints[reflectionID];
			
			trace("FeatureEditablePoints reflection does not exist");
			return m_points;
		}
		
		public function setPoint(newPt: Point, i_pointIndex: uint, reflectionID: int = 0): void
		{
			m_points[i_pointIndex] = newPt;
			notifyPointsChanged();
		}
		public function getPoint(i_pointIndex: uint, reflectionID: int = 0): Point
		{
			var points: Array = getPointsForReflection(reflectionID);
			if (points && points.length > i_pointIndex)
				return points[i_pointIndex];
			return null;
		}
		
		public function addPointAt(point: Point, index: uint, reflectionID: int = 0): void
		{
			m_points.splice(index, 0, point);
			notifyPointsChanged();
		}
		
		public function addPoint(point: Point, reflectionID: int = 0): void
		{
			m_points.push(point);
			notifyPointsChanged();
		}
		
		public function insertPointBefore(i_pointIndex: uint, pt: Point, reflectionID: int = 0): void
		{
			m_points.splice(i_pointIndex, 0, pt);
			notifyPointsChanged();
		}
		
		public function removePointAt(i_pointIndex: uint, reflectionID: int = 0): void
		{
			m_points.splice(i_pointIndex, 1);
		}
		public function removeAllPoints(reflectionID: int = 0): void
		{
			m_points.splice(0, m_points.length);
		}
		
		
		public function getAveragePoint(reflectionID: int = 0):Point
		{
			var ret:Point = new Point();
			var points: Array = getPointsForReflection(reflectionID);
			
			var len: int = points.length;
			for (var i:int = 0; i < len; i++) {
				ret.x = ret.x + points[i].x;
				ret.y = ret.y + points[i].y;
			}
			ret.x = ret.x / len;
			ret.y = ret.y / len;
			
			return ret;
		}
		
		public function initializePoints(): void
		{
			m_points = [];
			m_reflectedPoints = new Dictionary();
		}
		
		private function notifyPointsChanged(): void
		{
			updateReflectedPoints();
			dispatchEvent(new Event(CHANGED));
		}
		
		private function updateReflectedPoints(): void
		{
			if (container)
			{
				var deltas: Array = [0,1,-1,2,-2];
				
				m_reflectedPoints = new Dictionary();
				for each (var delta: int in deltas)
				{
					m_reflectedPoints[delta] = [];
				}
				
				var crs: String = container.crs;
				for each (var p: Point in m_points)
				{
					var coord: Coord = container.pointToCoord(p.x, p.y);
					var reflPoints: Array = container.mapCoordInCRSToViewReflectionsForDeltas(new Point(coord.x, coord.y), deltas);
					for each (var reflPoint: Object in reflPoints)
					{
						var newP: Point = container.coordToPoint(new Coord(crs, reflPoint.point.x, reflPoint.point.y));
						(m_reflectedPoints[reflPoint.reflection] as Array).push(newP);
					}
				}
			}
		}
	}
}