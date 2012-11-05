package com.iblsoft.flexiweather.ogc.data
{
	import com.iblsoft.flexiweather.ogc.editable.MoveablePoint;
	import com.iblsoft.flexiweather.proj.Coord;
	import com.iblsoft.flexiweather.widgets.InteractiveWidget;
	import flash.utils.Dictionary;

	public class WFSEditableReflectionDictionary extends ReflectionDictionary
	{
		public function get totalMoveablePoints(): int
		{
			if (_dictionary && _dictionary[0])
				return (_dictionary[0] as WFSEditableReflectionData).moveablePoints.length;
			return 0;
		}

		public function WFSEditableReflectionDictionary(iw: InteractiveWidget)
		{
			super(iw);
		}

		public function addMoveablePoint(mp: MoveablePoint, reflections: int, pointer: int, data: Object = null): void
		{
			var reflectionData: WFSEditableReflectionData = getReflection(reflections) as WFSEditableReflectionData;
			reflectionData.addMoveablePoint(mp, pointer);
		}

		override protected function createNewReflectionData(): ReflectionData
		{
			return new WFSEditableReflectionData(_iw);
		}
	}
}
