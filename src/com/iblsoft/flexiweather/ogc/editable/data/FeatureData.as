package com.iblsoft.flexiweather.ogc.editable.data
{
	public class FeatureData
	{
		public static var fd_uid: int = 0;
		public var uid: int;
		
		[ArrayElementType("com.iblsoft.flexiweather.ogc.editable.data.FeatureDataReflection")]
		public var reflections: Array;
		public var reflectionsIDs: Array;
		
		[ArrayElementType("com.iblsoft.flexiweather.ogc.editable.data.FeatureDataLine")]
		public var lines: Array;
		
		public var name: String;
		
		public function FeatureData(name: String)
		{
			uid = fd_uid++;
			
			this.name = name;
			lines = [];
			reflections = [];
			reflectionsIDs = [];
			
			trace("FeatureData created: " + this);
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
				refl.debug(); 
			}
		}
		
		/**
		 * Call clear method before reusing FeatureData. E.g. recompute data 
		 * 
		 */		
		public function clear(): void
		{
			var total: int = reflections.length;
			for (var i: int = 0; i < total; i++)
			{
				var refl: FeatureDataReflection = getReflectionAt(i);
				refl.clear();
			}
			reflectionsIDs = [];
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
		
		protected function createFeatureDataReflectionInstance(position: int): FeatureDataReflection
		{
			return new FeatureDataReflection(position);
		}
		public function createReflectionAt(position: int): FeatureDataReflection
		{
			var reflection: FeatureDataReflection = createFeatureDataReflectionInstance(position);
			reflection.parentFeatureData = this;
			reflections[position] = reflection;
			updateIDs();
			return reflection;
		}
		
		private function updateIDs(): void
		{
			reflectionsIDs = [];
			for (var id: Object in reflections)
			{
				reflectionsIDs.push(id);	
			}
		}
		
		/**
		 *Returns reflection data at given position. 
		 *  
		 * @param position reflectionDelta parameter from FeatureDataReflection class
		 * @return FeatureDataReflection 
		 * 
		 */		
		public function getReflectionAt(position: int): FeatureDataReflection
		{
			if (reflections.length <= position)
			{
				return createReflectionAt(position);
			}
			
			if (!(reflections[position] is FeatureDataReflection))
				return createReflectionAt(position);
			
			updateIDs();
			return reflections[position] as FeatureDataReflection;
		}
		
		public function toString(): String
		{
			return "FeatureData ["+uid+"]" + reflections.length + " name: " +  name;
		}
	}
}