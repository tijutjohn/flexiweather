package com.iblsoft.flexiweather.proj
{
	import flash.geom.Point;
	
	import mx.formatters.NumberFormatter;

	public class Coord extends Point
	{
		public var crs: String;
		
		private var toRadConst: Number = Math.PI / 180;
		
		/**
		 * 
		 * @param s_crs
		 * @param f_x - longitude
		 * @param f_y - latitude
		 * 
		 */		
		public function Coord(s_crs: String, f_x: Number, f_y: Number)
		{
			super(f_x, f_y);
			crs = s_crs;
		}
		
		private function toRad(degree: Number): Number
		{
			return degree * toRadConst;
		}
		/**
		 * Returns distance between 2 coordinates on Earth in kilometres. 
		 * @param c
		 * @return 
		 * 
		 */		
		public function distanceTo(c: Coord): Number
		{
			var r: Number = 6371; // km
			//be sure coords are in LatLong
			var dLat: Number = toRad(c.y - y);
			var dLon: Number = toRad(c.x - x);
			var lat1: Number = toRad(y);
			var lat2: Number = toRad(c.y);
			var a: Number = Math.sin(dLat / 2) * Math.sin(dLat / 2) +
					Math.sin(dLon / 2) * Math.sin(dLon / 2) * Math.cos(lat1) * Math.cos(lat2);
			var c2: Number = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
			var d: Number = r * c2;
			return d;
		}
		
		public static function convertCoordOnSphere(coord: Coord, projection: Projection): Coord
		{
			var toRadians: Function = function(degree: Number): Number
			{
				var toRadConst: Number = Math.PI / 180;
				return degree * toRadConst;
			}
			var toDegrees: Function = function(radians: Number): Number
			{
				var toDegConst: Number = 180 / Math.PI;
				return radians * toDegConst;
			}
			
			coord = coord.toLaLoCoord();
			
			var lp1X: Number = toRadians(coord.x);
			var lp1Y: Number = toRadians(coord.y);
			var x1: Number = Math.cos(lp1Y) * Math.cos(lp1X);
			var y1: Number = Math.cos(lp1Y) * Math.sin(lp1X);
			var z1: Number = Math.sin(lp1Y)
			
			var l: Number = Math.sqrt(x1 * x1 + y1 * y1 + z1 * z1);
			x1 /= l;
			y1 /= l;
			z1 /= l;
			var lpM: Coord = new Coord(Projection.CRS_GEOGRAPHIC, toDegrees(Math.atan2(y1, x1)), toDegrees(Math.atan2(z1, Math.sqrt(x1 * x1 + y1 * y1))));
			var cM: Coord = lpM.convertToProjection(projection);
			
			return cM;
		}
		private static function areSameSigns(c1: Coord, c2: Coord): Boolean
		{
			if (c1.x < 0 && c2.x > 0)	return false;
			if (c1.x > 0 && c2.x < 0)	return false;
			
			return true;
		}

		public function equalsCoord(c: Coord): Boolean
		{
			return crs === c.crs && equals(c);
		}

		override public function clone(): Point
		{
			return cloneCoord();
		}

		public function cloneCoord(): Coord
		{
			return new Coord(crs, x, y);
		}
		
		public function toLaLoCoord(): Coord
		{
			var prj: Projection = Projection.getByCRS(crs);
			if(prj == null)
				return null;
			return prj.prjXYToLaLoCoord(x, y);
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
				
				return f_laDeg + f_laNS + f_laMin + "'" + f_laSec + '"' + " "
						+ f_loDeg + f_loEW + f_loMin + "'" + f_loSec + '"'; 
			}
			var nf: NumberFormatter = new NumberFormatter();
			nf.precision = 2;
			return crs + ": [" + nf.format(x) + ", " + nf.format(y) + "]";
		}
		
		public function convertToProjection(projection: Projection): Coord
		{
			if (crs == projection.crs)
				return this;
			if (crs != 'CRS:84')
			{
				var proj1: Projection = Projection.getByCRS(crs);
				var laLoPtRad: Point = proj1.prjXYToLaLoPt(x, y);
				if (laLoPtRad)
				{
					var proj1Point: Point = projection.laLoPtToPrjPt(laLoPtRad);
					if (proj1Point)
						return new Coord(projection.crs, proj1Point.x, proj1Point.y);
				}
				return null;
			}
			var p: Point = projection.laLoToPrjPt(toRad(x), toRad(y));
			if (p)
				return new Coord(projection.crs, p.x, p.y);
			
			return null;
		}
		
		override public function toString(): String
		{
			return crs + "[" + x + ";" + y + "]";			
		} 
		
		public static function fromString(s: String): Coord
		{
			var i_leftBracketPos: int = s.indexOf("[");
			var i_rightBracketPos: int = s.indexOf("]");
			var i_semicolonPos: int = s.indexOf(";");
			if (i_leftBracketPos < 0 || i_rightBracketPos < 0 || i_semicolonPos < 0)
				throw new Error("Invalid coordinates format: " + s);
			var s_src: String = s.substring(0, i_leftBracketPos);
			var f_x: Number = new Number(s.substring(i_leftBracketPos + 1, i_semicolonPos));
			var f_y: Number = new Number(s.substring(i_semicolonPos + 1, i_rightBracketPos));
			return new Coord(s_src, f_x, f_y);
		}

		[Deprecated(replacement = toLaLoCoord)]
		public function toCRS84(): Coord
		{
			// IN THE FUTURE, WE NEED TO MAKE REAL CONVERSION FROM CRS TO CRS:84
			return (new Coord(crs, x, y));
		}
	}
}