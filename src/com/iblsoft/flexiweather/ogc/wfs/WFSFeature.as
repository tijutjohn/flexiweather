package com.iblsoft.flexiweather.ogc.wfs
{
	import com.iblsoft.flexiweather.proj.Coord;
	import mx.collections.ArrayCollection;

	public class WFSFeature
	{
		internal var ms_name: String;
		public var location: Coord;
		public var values: ArrayCollection;

		/**
		 *
		 */
		public function WFSFeature(_name: String)
		{
			ms_name = _name;
		}

		/**
		 *
		 */
		public function get name(): String
		{
			return ms_name;
		}

		public function elementsToString(): String
		{
			var str: String = '';
			for each (var elementObject: Object in values)
			{
				str += elementObject.name + ": " + elementObject.value.toString() + "\n";
			}
			return str;
		}

		public function getElementValue(element: String): Object
		{
			if (values && values.length > 0)
			{
				for each (var elementObject: Object in values)
				{
					if (elementObject.name == element)
						return elementObject.value;
				}
			}
			return null;
		}
	}
}
