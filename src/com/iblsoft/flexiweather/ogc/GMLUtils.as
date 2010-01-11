package com.iblsoft.flexiweather.ogc
{
	import com.iblsoft.flexiweather.proj.Coord;
	import com.iblsoft.flexiweather.proj.Projection;
	
	public class GMLUtils
	{
		public static function parseGMLCoordinates2D(xml: XML): Array
		{
			var a_coords: Array = [];
			var s_coords: String = String(xml);
			var a_bits: Array = s_coords.split(/\s/);
			for each(var s: String in a_bits) {
				var a_coordBits: Array = s.split(",", 2);
				a_coords.push(new Coord(Projection.CRS_GEOGRAPHIC, Number(a_coordBits[0]), Number(a_coordBits[1]))); 
			}
			return a_coords;
		}
	}
}