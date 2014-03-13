package com.iblsoft.flexiweather.ogc.editable.data.jetstream
{
	import com.iblsoft.flexiweather.ogc.data.ReflectionData;
	import com.iblsoft.flexiweather.ogc.data.WFSEditableReflectionDictionary;
	import com.iblsoft.flexiweather.ogc.editable.features.curves.WFSFeatureEditableJetStreamWindBarb;
	import com.iblsoft.flexiweather.proj.Coord;
	import com.iblsoft.flexiweather.widgets.InteractiveWidget;
	
	public class WindMoveablePointsDictionary extends WFSEditableReflectionDictionary
	{
		public function WindMoveablePointsDictionary(iw:InteractiveWidget)
		{
			super(iw);
		}
		
		override public function getReflection(reflections: int): ReflectionData
		{
			return _dictionary[reflections] as WindReflectionData;
		}
		
		override protected function createNewReflectionData(): ReflectionData
		{
			return new WindReflectionData(_iw);
		}
		
		
		public function updateWindbarbAt(windbarb: WindBarb, position: int, reflections: int, reflectionDelta: int): void
		{
//			trace(this + " updateWindbarbAt at : " + position + " reflections: " + reflections + " delta: " + reflectionDelta);
			var reflection: WindReflectionData = createReflection( reflections ) as WindReflectionData;
			reflection.updateWindbarbAt(windbarb, position);
			
		}
		public function addWindbarbAt(windbarb: WindBarb, position: int, reflections: int, reflectionDelta: int): void
		{
//			trace(this + " addWindbarbAt at : " + position + " reflections: " + reflections + " delta: " + reflectionDelta);
			var reflection: WindReflectionData = createReflection( reflections ) as WindReflectionData;
			reflection.addWindbarbAt(windbarb, position);
		}
		public function addWindbarb(windbarb: WindBarb, reflections: int, reflectionDelta: int): void
		{
//			trace(this + " addWindbarb reflections: " + reflections + " delta: " + reflectionDelta);
			var reflection: WindReflectionData = createReflection( reflections ) as WindReflectionData;
			reflection.addWindbarb(windbarb);
		}
		
		public function addWindMoveablePoint(mp: MoveableWindPoint, pointer: int, cp: WFSFeatureEditableJetStreamWindBarb): void
		{
//			trace("addWindMoveablePoint: " + pointer);
			(_dictionary[pointer] as WindReflectionData).addWindMoveablePoint(mp, pointer, cp);
		}
		
		override public function toString(): String
		{
			return "WindMoveablePointsDictionary: ";
		}
	}
}