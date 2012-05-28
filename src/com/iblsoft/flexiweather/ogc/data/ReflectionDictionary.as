package com.iblsoft.flexiweather.ogc.data
{
	import com.iblsoft.flexiweather.proj.Coord;
	import com.iblsoft.flexiweather.widgets.InteractiveWidget;
	
	import flash.utils.Dictionary;

	public class ReflectionDictionary
	{
		protected var _dictionary: Dictionary;
		protected var _iw: InteractiveWidget;
		protected var _totalReflections: int;
		
		public function get totalReflections(): int
		{
			return _totalReflections;
		}
		
		public function ReflectionDictionary(iw: InteractiveWidget): void
		{
			_iw = iw;
			_dictionary = new Dictionary();
			_totalReflections = 0;
		}
		
		protected function createNewReflectionData(): ReflectionData
		{
			return new ReflectionData(_iw);
		}
		
		public function cleanup(): void
		{
			for each (var reflection: ReflectionData in _dictionary)
			{
				reflection.cleanup();
			}
		}
		
		public function removeReflectionItemAt(reflections: int, position: int): void
		{
			var reflection: ReflectionData = getReflection(reflections);
			reflection.removeItemAt(position);
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
		
		public function addReflectedCoord(coord: Coord, reflections: int, reflectionDelta: int): void
		{
			if (!_dictionary[reflections])
			{
				_dictionary[reflections] = createNewReflectionData();
				_totalReflections = Math.max(_totalReflections, reflections);
			}
			var reflection: ReflectionData = getReflection(reflections);
			reflection.reflectionDelta = reflectionDelta;
			reflection.addCoord(coord);
		}
	}
}