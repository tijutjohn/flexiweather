package com.iblsoft.flexiweather.ogc
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
		{ return ms_name; }

	}
}