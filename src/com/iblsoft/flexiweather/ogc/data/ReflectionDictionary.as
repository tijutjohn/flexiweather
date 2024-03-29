package com.iblsoft.flexiweather.ogc.data
{
	import com.iblsoft.flexiweather.ogc.events.ReflectionEvent;
	import com.iblsoft.flexiweather.proj.Coord;
	import com.iblsoft.flexiweather.widgets.InteractiveWidget;
	
	import flash.events.EventDispatcher;
	import flash.utils.Dictionary;

	[Event(name = "reflectionCollectionChanged", type = "com.iblsoft.flexiweather.ogc.events.ReflectionEvent")]
	public class ReflectionDictionary extends EventDispatcher
	{
		protected var _dictionary: Dictionary;
		protected var _iw: InteractiveWidget;
		protected var _totalReflections: int;

		public function get totalReflections(): int
		{
			return _totalReflections;
		}

		public function get reflectionIDs(): Array
		{
			var arr: Array = [];
			for each (var reflectionData: ReflectionData in _dictionary)
			{
				arr.push(reflectionData.reflectionDelta);
			}
			return arr;
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

		public function destroy(): void
		{
			for each (var reflection: ReflectionData in _dictionary)
			{
				reflection.remove();
			}
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
			notifyCollectionChange(ReflectionEvent.REMOVE_REFLECTION, reflection);
		}

		public function removeReflection(reflections: int): void
		{
			var reflection: ReflectionData = getReflection(reflections);
			reflection.remove();
			delete _dictionary[reflections];
			notifyCollectionChange(ReflectionEvent.REMOVE_REFLECTION, reflection);
		}

		public function getReflectionByReflectionID(reflectionID: int): ReflectionData
		{
			for each (var reflectionData: ReflectionData in _dictionary)
			{
				if (reflectionData.reflectionDelta == reflectionID)
					return reflectionData;
			}
			return null;
		}
		public function getReflection(reflectionDelta: int): ReflectionData
		{
			return _dictionary[reflectionDelta] as ReflectionData;
		}

		protected function notifyCollectionChange(kind: String, reflection: ReflectionData): void
		{
			var re: ReflectionEvent = new ReflectionEvent(kind, true);
			re.reflection = reflection;
			dispatchEvent(re);
		}

		public function testCreateReflection(reflectionDelta: int): ReflectionData
		{
			return createReflection(reflectionDelta);
		}
		
		protected function createReflection(reflectionDelta: int): ReflectionData
		{
			if (!_dictionary[reflectionDelta])
			{
				var refl: ReflectionData = createNewReflectionData();
				_dictionary[reflectionDelta] = refl;
				_totalReflections++; //= Math.max(_totalReflections, reflections);
				notifyCollectionChange(ReflectionEvent.ADD_REFLECTION, refl);
				return refl;
			}
			return getReflection(reflectionDelta);
		}

		public function updateReflectedCoordAt(coord: Coord, position: int, reflectionDelta: int, isEdgePoint: Boolean = false, iw: InteractiveWidget = null): void
		{
			var reflection: ReflectionData = createReflection( reflectionDelta );
			reflection.reflectionDelta = reflectionDelta;
			reflection.updateCoordAt(coord, position, isEdgePoint, iw);
			
		}
		public function removeReflectedCoordAt(position: int): void
		{
			for each (var reflection: ReflectionData in _dictionary)
			{
				reflection.removeItemAt(position);
			}
		}
		public function addReflectedCoordAt(coord: Coord, position: int, reflectionDelta: int, isEdgePoint: Boolean = false, iw: InteractiveWidget = null): void
		{
			var reflection: ReflectionData = createReflection(reflectionDelta);
			reflection.reflectionDelta = reflectionDelta;
			reflection.addCoordAt(coord, position, isEdgePoint, iw);
		}

		public function addReflectedCoord(coord: Coord, reflectionDelta: int, isEdgePoint: Boolean = false, iw: InteractiveWidget = null): void
		{
			var reflection: ReflectionData = createReflection(reflectionDelta);
			if (reflection)
			{
				var pos: int = reflection.length;
				addReflectedCoordAt(coord, pos, reflectionDelta, isEdgePoint, iw);
			}
		}
	}
}