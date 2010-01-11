package com.iblsoft.flexiweather.proj
{
	import flash.geom.Point;
	
	import mx.formatters.NumberFormatter;

	public class Coord extends Point
	{
		public var crs: String;
		
		public function Coord(s_crs: String, f_x: Number, f_y: Number)
		{
			super(f_x, f_y);
			crs = s_crs;
		}
		
		public function toNiceString(): String
		{
			if(Projection.equalCRSs(crs, "CRS:84")) {
				var f_loFrac: Number = x;
				var f_loEW: String = f_loFrac < 0 ? "W" : "E";
				f_loFrac = Math.abs(f_loFrac);
				var f_loDeg: Number = Math.floor(f_loFrac);
				f_loFrac = f_loFrac - f_loDeg;
				f_loFrac *= 60;
				var f_loMin: Number = Math.floor(f_loFrac);
				f_loFrac -= f_loMin;
				f_loFrac *= 60;
				var f_loSec: Number = Math.round(f_loFrac);
				
				var f_laFrac: Number = y;
				var f_laNS: String = f_laFrac < 0 ? "S" : "N";
				f_laFrac = Math.abs(f_laFrac);
				var f_laDeg: Number = Math.floor(f_laFrac);
				f_laFrac = f_laFrac - f_laDeg;
				f_laFrac *= 60;
				var f_laMin: Number = Math.floor(f_laFrac);
				f_laFrac -= f_laMin;
				f_laFrac *= 60;
				var f_laSec: Number = Math.round(f_laFrac);
				
				return f_laDeg + f_laNS + f_laSec + "'" + f_laSec + '"' + " "
						+ f_loDeg + f_loEW + f_loSec + "'" + f_loSec + '"'; 
			}
			var nf: NumberFormatter = new NumberFormatter();
			nf.precision = 2;
			return crs + ": [" + nf.format(x) + ", " + nf.format(y) + "]";
		}
		
		override public function toString(): String
		{
			return crs + "[" + x + ";" + y + "]";			
		} 
	}
}