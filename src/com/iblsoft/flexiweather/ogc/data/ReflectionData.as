package com.iblsoft.flexiweather.ogc.data
{
	import com.iblsoft.flexiweather.ogc.editable.MoveablePoint;
	import com.iblsoft.flexiweather.proj.Coord;
	import com.iblsoft.flexiweather.utils.AnnotationBox;
	import com.iblsoft.flexiweather.widgets.InteractiveWidget;
	
	import flash.display.Sprite;

	public class ReflectionData
	{
		public function ReflectionData(iw: InteractiveWidget): void
		{
			_coords = [];
			_points = [];
			_annotations = [];
			_moveablePoints = [];
			
			_iw = iw;
		}
		
		public var displaySprite: Sprite;
		
		public var reflectionDelta: int;
		
		private var _coords: Array;
		private var _points: Array;
		private var _moveablePoints: Array;
		private var _annotations: Array;
		
		private var _iw: InteractiveWidget;
		
		public function get moveablePoints(): Array
		{
			return _moveablePoints;
		}
		
		public function get points(): Array
		{
			return _points;
		}
		public function get annotations(): Array
		{
			return _annotations;
		}
		
		public function remove(): void
		{
			_coords = null;
			_points = null;
			_moveablePoints = null;
			_annotations = null;
		}
		public function cleanup(): void
		{
			_coords = [];	
			_points = [];	
		}
		
		public function addMoveablePoint(mp: MoveablePoint, pointer: int): void
		{
			_moveablePoints[pointer] = mp;	
		}
		
		public function addAnnotation(annotation: AnnotationBox, pointer: int): void
		{
			_annotations[pointer] = annotation;	
		}
		
		public function addCoord(coord: Coord): void
		{
			_coords.push(coord);
			_points.push(_iw.coordToPoint(coord));
		}
	}
}