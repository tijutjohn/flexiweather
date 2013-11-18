package com.iblsoft.flexiweather.ogc.data
{
	import com.iblsoft.flexiweather.ogc.editable.MoveablePoint;
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
		}

		public function get points(): Array
		{
			return _points;
		}

		public function remove(): void
		{
			_coords = null;
			_points = null;
			displaySprite = null;
		}

		public function cleanup(): void
		{
			_coords = [];
			_points = [];
		}

		public function removeItemAt(pointer: int): void
		{
			_points.splice(pointer, 1);
			_coords.splice(pointer, 1);
		}

		public function updateCoordAt(coord: Coord, position: int, iw: InteractiveWidget = null): void
		{
			addCoordAt(coord, position, iw);
		}
		
		public function addCoordAt(coord: Coord, position: int, iw: InteractiveWidget = null): void
		{
			if (iw)
				_iw = iw;
			
			_coords[position] = coord;
			_points[position] = _iw.coordToPoint(coord);
		}

		public function addCoord(coord: Coord, iw: InteractiveWidget = null): void
		{
			addCoordAt(coord, _coords.length, iw);
//			_coords.push(coord);
//			_points.push(_iw.coordToPoint(coord));
		}
	}
}
