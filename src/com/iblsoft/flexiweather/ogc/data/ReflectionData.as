package com.iblsoft.flexiweather.ogc.data
{
	import com.iblsoft.flexiweather.ogc.editable.data.MoveablePoint;
	import com.iblsoft.flexiweather.proj.Coord;
	import com.iblsoft.flexiweather.utils.AnnotationBox;
	import com.iblsoft.flexiweather.widgets.InteractiveWidget;
	
	import flash.display.Sprite;

	public class ReflectionData
	{
		public var displaySprite: Sprite;
		public var reflectionDelta: int;
		protected var _coords: Array;
		protected var _points: Array;
		protected var _isEdgePoint: Array;
		
		private var _iw: InteractiveWidget;

		public function get length(): int
		{
			if (_coords)
				return _coords.length;
			return 0;
		}

		public function ReflectionData(iw: InteractiveWidget): void
		{
			_iw = iw;
			_coords = [];
			_points = [];
			_isEdgePoint = [];
		}

		public function get points(): Array
		{
			return _points;
		}

		public function remove(): void
		{
			_coords = null;
			_points = null;
			_isEdgePoint = null;
			displaySprite = null;
		}

		public function cleanup(): void
		{
			_coords = [];
			_points = [];
			_isEdgePoint = [];
		}

		public function removeItemAt(pointer: int): void
		{
			_points.splice(pointer, 1);
			_isEdgePoint.splice(pointer, 1);
			_coords.splice(pointer, 1);
		}

		public function updateCoordAt(coord: Coord, position: int, isEdgePoint: Boolean = false, iw: InteractiveWidget = null): void
		{
			addCoordAt(coord, position, isEdgePoint, iw);
		}
		
		public function addCoordAt(coord: Coord, position: int, isEdgePoint: Boolean = false, iw: InteractiveWidget = null): void
		{
			if (iw)
				_iw = iw;
			
			_coords[position] = coord;
			_points[position] = _iw.coordToPoint(coord);
			_isEdgePoint[position] = isEdgePoint;
		}

		public function addCoord(coord: Coord, isEdgePoint: Boolean = false, iw: InteractiveWidget = null): void
		{
			addCoordAt(coord, _coords.length, isEdgePoint, iw);
//			_coords.push(coord);
//			_points.push(_iw.coordToPoint(coord));
		}
	}
}
