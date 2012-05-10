package com.iblsoft.flexiweather.ogc.data
{
	import com.iblsoft.flexiweather.ogc.editable.MoveablePoint;
	import com.iblsoft.flexiweather.proj.Coord;
	import com.iblsoft.flexiweather.widgets.InteractiveWidget;
	
	import flash.utils.Dictionary;

	public class MoveablePointsDictionary
	{
		private var _dictionary: Dictionary;
		private var _iw: InteractiveWidget;
		private var _totalReflections: int;
		public function get totalMoveablePoints(): int
		{
			if (_dictionary && _dictionary[0])
				return (_dictionary[0] as ReflectionData).moveablePoints.length;
			
			return 0;
		}
		public function get totalReflections(): int
		{
			return _totalReflections;
		}
		
		public function MoveablePointsDictionary(iw: InteractiveWidget) 
		{
			_dictionary = new Dictionary();
			_iw = iw;
			_totalReflections = 0;
		}
		
		public function cleanup(): void
		{
			for each (var reflection: ReflectionData in _dictionary)
			{
				reflection.cleanup();
			}
		}
		
		public function removeReflection(reflections: int): void
		{
			getReflection(reflections).remove();
			delete _dictionary[reflections];
		}
		
		public function getReflection(reflections: int): ReflectionData
		{
			return _dictionary[reflections] as ReflectionData;
		}
		
		public function addMoveablePoint(mp: MoveablePoint, reflections: int, pointer: int): void
		{
			(_dictionary[reflections] as ReflectionData).addMoveablePoint(mp, pointer);
		}
		
		public function addReflectedCoord(coord: Coord, reflections: int, reflectionDelta: int): void
		{
			if (!_dictionary[reflections])
			{
				_dictionary[reflections] = new ReflectionData(_iw);
				_totalReflections = Math.max(_totalReflections, reflections);
			}
			(_dictionary[reflections] as ReflectionData).reflectionDelta = reflectionDelta;
			(_dictionary[reflections] as ReflectionData).addCoord(coord);
		}
	}
}