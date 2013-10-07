package com.iblsoft.flexiweather.ogc.editable.data
{
	public class FeatureData
	{
		[ArrayElementType("com.iblsoft.flexiweather.ogc.editable.data.FeatureDataReflection")]
		public var reflections: Array;
		
		[ArrayElementType("com.iblsoft.flexiweather.ogc.editable.data.FeatureDataLine")]
		public var lines: Array;
		
		public var name: String;
		
		public function FeatureData(name: String)
		{
			this.name = name;
			lines = [];
			reflections = [];
		}
		
		public function debug(): void
		{
			trace("FeatureData: " + name);
			trace("\tLines: " + lines.length);
			trace("\tReflections: " + reflections.length);
			
			var total: int = reflections.length;
			for (var i: int = 0; i < total; i++)
			{
				var refl: FeatureDataReflection = getReflectionAt(i);
				trace("\t\tLines: " + refl.lines.length);
			}
		}
		public function getLineAt(position: int): FeatureDataLine
		{
			var refl: FeatureDataReflection = getReflectionAt(0);
			var line: FeatureDataLine = refl.getLineAt(position);			
			return line;
		}
		public function createReflection(): FeatureDataReflection
		{
			return createReflectionAt(reflections.length);
		}
		
		public function createReflectionAt(position: int): FeatureDataReflection
		{
			var reflection: FeatureDataReflection = new FeatureDataReflection();
			reflection.parentFeatureData = this;
			reflections[position] = reflection;
			return reflection;
		}
		
		public function getReflectionAt(position: int): FeatureDataReflection
		{
			if (reflections.length <= position)
			{
				return createReflectionAt(position);
			}
			
			if (!(reflections[position] is FeatureDataReflection))
				return createReflectionAt(position);
			
			return reflections[position] as FeatureDataReflection;
		}
		
		public function toString(): String
		{
			return "FeatureData" + reflections.length + " name: " +  name;
		}
	}
}