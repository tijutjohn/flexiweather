package com.iblsoft.flexiweather.ogc.editable.data
{
	import com.iblsoft.flexiweather.ogc.data.ReflectionData;

	public class FeatureData
	{
		public static var fd_uid: int = 0;
		public var uid: int;
		
		[ArrayElementType("com.iblsoft.flexiweather.ogc.editable.data.FeatureDataReflection")]
		public var reflections: Array;
		public var reflectionsIDs: Array;
		
		[ArrayElementType("com.iblsoft.flexiweather.ogc.editable.data.FeatureDataLine")]
		public var lines: Array;
		
		public function get reflectionsLength(): int
		{
			if (reflections)
			{
				//we need to enumerate via reflections, because length does not work with negative indicies
				return reflectionsIDs.length;
//				var cnt: int = 0;
//				for each (var refl: FeatureDataReflection in reflections)
//					cnt++
//						
//				return cnt;
			}
			return 0;
		}
		public function get linesLength(): int
		{
			if (lines)
				return lines.length;
			
			return 0;
		}
		
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
			trace("\tReflections: " + reflectionsLength);
			
			var total: int = reflectionsLength;
			var reflectionIDs: Array = reflectionsIDs;
			
			for (var i: int = 0; i < total; i++)
			{
				var refl: FeatureDataReflection = getReflectionAt(reflectionIDs[i]);
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
			var total: int = reflectionsLength;
			var reflectionIDs: Array = reflectionsIDs;
			
			for (var i: int = 0; i < total; i++)
			{
				var refl: FeatureDataReflection = getReflectionAt(reflectionIDs[i]);
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
			return createReflectionAt(reflectionsLength);
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
//			if (reflections.length <= position)
			if (reflections[position] == null)
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
			return "FeatureData ["+uid+"]" + reflectionsLength + " name: " +  name;
		}
	}
}