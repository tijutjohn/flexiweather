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
		
		public function addCoord(coord: Coord): void
		{
			_coords.push(coord);
			_points.push(_iw.coordToPoint(coord));
		}
	}
}