package com.iblsoft.flexiweather.utils
{
	import com.iblsoft.flexiweather.proj.Coord;

	public class Hemisphere
	{
		static public const NORTHERN_HEMISPHERE: String = "NorthernHemisphere";
		static public const SOUTHERN_HEMISPHERE: String = "SouthernHemisphere";
			
		static public function hemisphereForCoord(coord: Coord): String
		{
			if (coordIsOnSouthernHemisphere(coord))
				return SOUTHERN_HEMISPHERE;
			
			return NORTHERN_HEMISPHERE;
				
		}
		static public function coordIsOnSouthernHemisphere(coord: Coord): Boolean
		{
			return coord.toLaLoCoord().y < 0;
		}
		static public function coordIsOnNorthernHemisphere(coord: Coord): Boolean
		{
			return coord.toLaLoCoord().y >= 0;
		}
	}
}