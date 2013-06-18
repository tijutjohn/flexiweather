package com.iblsoft.flexiweather.proj
{
	import flash.geom.Point;
	import flash.geom.Vector3D;
	
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

		public function distanceInCRSTo(c: Coord): Number
		{
			if (c.crs != this.crs)
				c = c.convertToProjection(Projection.getByCRS(crs));
			var dx: Number = c.x - this.x;
			var dy: Number = c.y - this.y;
			return Math.sqrt(dx * dx + dy * dy);
		}

		public static function interpolateGreatArc(c1: Coord, c2: Coord, distanceValidator: Function, bIncludeDiscontinuation: Boolean = false): Array
		{
			var origC1: Coord = c1.cloneCoord();
			var origC2: Coord = c2.cloneCoord();
			
			var lp1: Coord = c1.toLaLoCoord();
			var lp2: Coord = c2.toLaLoCoord();
			var projection: Projection = Projection.getByCRS(c1.crs);
			c1 = c1.convertToProjection(projection);
			c2 = c2.convertToProjection(projection);
			
			var t1: Coord = convertCoordOnSphere(c1, projection);
			var t2: Coord = convertCoordOnSphere(c2, projection);
			
			var a: Array = [t1];
			
			bisectGreatArc(lp1, t1, lp2, t2, a, projection, distanceValidator, bIncludeDiscontinuation);
			
//			var total: int = a.length;
//			trace("\n\ninterpolateGreatArc");
//			for (var i: int = 0; i < total; i++)
//			{
//				var interpolatedCoord: Coord = a[i] as Coord;
////				var fixedCoord: Coord = checkedArray[i] as Coord;
//				if (interpolatedCoord)
//					trace("interpolateGreatArc ["+interpolatedCoord.toString()+"]");
//				else
//					trace("interpolateGreatArc [NULL]");
////				trace("interpolateGreatArc ["+interpolatedCoord.toString()+"] fixed: ["+fixedCoord.toString()+"]");
//			}
//			trace("interpolateGreatArc orig " + c1.toString() + " , " + c2.toString());
//			trace("interpolateGreatArc converted " + t1.toString() + " , " + t2.toString());
			return a;
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
		private static function bisect2GreatArc(sp1: SpherePointWithLalo, sp2: SpherePointWithLalo, a: Array, projection: Projection): Array
		{
			var distance: Function = function(sp1: SpherePointWithLalo, sp2: SpherePointWithLalo): Number
			{
				var dist: Number = sp1.x * sp2.x + sp1.y * sp2.y + sp1.z * sp2.z;
				dist = Math.acos(dist);
				return dist;
			}
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
				
			var max: Number = 0.000001;
			var signsChange: Boolean = sp1.signsAreSame(sp2);
			var currentDistance: Number = distance(sp1, sp2);
//			trace("currentDistance: " + currentDistance);
				
			if (currentDistance < max && !signsChange)
			{
				return [sp1, sp2];
			}
			if (signsChange)
			{
				return null;
			}
			
			
			var lp1X: Number = toRadians(sp1.longitude);
			var lp1Y: Number = toRadians(sp1.latitude);
			var lp2X: Number = toRadians(sp2.longitude);
			var lp2Y: Number = toRadians(sp2.latitude);
			
			var x1: Number = Math.cos(lp1Y) * Math.cos(lp1X);
			var y1: Number = Math.cos(lp1Y) * Math.sin(lp1X);
			var z1: Number = Math.sin(lp1Y);
			
			var x2: Number = Math.cos(lp2Y) * Math.cos(lp2X);
			var y2: Number = Math.cos(lp2Y) * Math.sin(lp2X);
			var z2: Number = Math.sin(lp2Y);
			
			var xTotal: Number = x1 + x2;
			var yTotal: Number = y1 + y2;
			var zTotal: Number = z1 + z2;
			
			var l: Number = Math.sqrt(xTotal * xTotal + yTotal * yTotal + zTotal * zTotal);
			
			xTotal /= l;
			yTotal /= l;
			zTotal /= l;
			
			var lpM: Coord = new Coord(Projection.CRS_GEOGRAPHIC, toDegrees(Math.atan2(yTotal, xTotal)), toDegrees(Math.atan2(zTotal, Math.sqrt(xTotal * xTotal + yTotal * yTotal))));
			var cM: Coord = lpM.convertToProjection(projection);
			
			var c: SpherePointWithLalo = new SpherePointWithLalo(xTotal, yTotal, zTotal, cM.x, cM.y);
			
			var points: Array;
			
			points = bisect2GreatArc(sp1, c, a, projection);
			if (points)  
				return points;
			
			points = bisect2GreatArc(c, sp2, a, projection);
			if (points)  
				return points;
			
			return null;
		}
		
		private static function areSameSigns(c1: Coord, c2: Coord): Boolean
		{
			if (c1.x < 0 && c2.x > 0)	return false;
			if (c1.x > 0 && c2.x < 0)	return false;
			
			return true;
		}
		
		private static function bisectGreatArc(lp1: Coord, c1: Coord, lp2: Coord, c2: Coord, a: Array, projection: Projection, distanceValidator: Function, bIncludeDiscontinuation: Boolean): void
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
				
			var lp1X: Number = toRadians(lp1.x);
			var lp1Y: Number = toRadians(lp1.y);
			var lp2X: Number = toRadians(lp2.x);
			var lp2Y: Number = toRadians(lp2.y);
			var x1: Number = Math.cos(lp1Y) * Math.cos(lp1X);
			var y1: Number = Math.cos(lp1Y) * Math.sin(lp1X);
			var z1: Number = Math.sin(lp1Y);
			var x2: Number = Math.cos(lp2Y) * Math.cos(lp2X);
			var y2: Number = Math.cos(lp2Y) * Math.sin(lp2X);
			var z2: Number = Math.sin(lp2Y);
			var xTotal: Number = x1 + x2;
			var yTotal: Number = y1 + y2;
			var zTotal: Number = z1 + z2;
			var l: Number = Math.sqrt(xTotal * xTotal + yTotal * yTotal + zTotal * zTotal);
			xTotal /= l;
			yTotal /= l;
			zTotal /= l;
			var lpM: Coord = new Coord(Projection.CRS_GEOGRAPHIC, toDegrees(Math.atan2(yTotal, xTotal)), toDegrees(Math.atan2(zTotal, Math.sqrt(xTotal * xTotal + yTotal * yTotal))));
			var cM: Coord = lpM.convertToProjection(projection);
			
			var points: Array;
			
//			trace("bisectGreatArc c1: " + c1.toString() + " cM: " + cM.toString() + " c2: " + c2.toString());
			if (!areSameSigns(c1, cM))
			{
				var sp1: SpherePointWithLalo = new SpherePointWithLalo(x1, y1, z1, c1.x, c1.y);
				var spM1: SpherePointWithLalo = new SpherePointWithLalo(xTotal, yTotal, zTotal, cM.x, cM.y);
				
				//do bisect2
				points = bisect2GreatArc(sp1, spM1, a, projection);
				if (points && points.length == 2)
				{
					var spLeft1: SpherePointWithLalo = points[0] as SpherePointWithLalo;
					var spRight1: SpherePointWithLalo = points[1] as SpherePointWithLalo;
					var cLeft1: Coord = new Coord(c1.crs, spLeft1.longitude, spLeft1.latitude);
					var cRight1: Coord = new Coord(c2.crs, spRight1.longitude, spRight1.latitude);
					
					if (!distanceValidator(c1, cLeft1)) {
						
						var lLeft1: Coord = cLeft1.toLaLoCoord();
						bisectGreatArc(lp1, c1, lLeft1, cLeft1, a, projection, distanceValidator, bIncludeDiscontinuation);
						
					} else {
						a.push(cLeft1);
					}
					
					a.push(cLeft1);
					a.push(null);
					a.push(cRight1);
					
					if (!distanceValidator(cRight1, cM)) {
						
						var lRight1: Coord = cRight1.toLaLoCoord();
						bisectGreatArc(lRight1, cRight1, lpM, cM, a, projection, distanceValidator, bIncludeDiscontinuation);
						
					} else {
						a.push(cM);
					}
					
				}
				
			} else if (!distanceValidator(c1, cM)) {
				
				bisectGreatArc(lp1, c1, lpM, cM, a, projection, distanceValidator, bIncludeDiscontinuation);
				
			} else {
//				if (isDiscontinuation(a, cM))
//					a.push(null);
				a.push(cM);
			}
			
			if (!areSameSigns(c2, cM))
			{
				var sp2: SpherePointWithLalo = new SpherePointWithLalo(x2, y2, z2, c2.x, c2.y);
				var spM2: SpherePointWithLalo = new SpherePointWithLalo(xTotal, yTotal, zTotal, cM.x, cM.y);
				
				//do bisect2
				points = bisect2GreatArc(spM2, sp2, a, projection);
				if (points && points.length == 2)
				{
					var spLeft2: SpherePointWithLalo = points[0] as SpherePointWithLalo;
					var spRight2: SpherePointWithLalo = points[1] as SpherePointWithLalo;
					var cLeft2: Coord = new Coord(c1.crs, spLeft2.longitude, spLeft2.latitude);
					var cRight2: Coord = new Coord(c2.crs, spRight2.longitude, spRight2.latitude);
					
					if (!distanceValidator(cM, cLeft2)) {
						
						var lLeft2: Coord = cLeft2.toLaLoCoord();
						bisectGreatArc(lpM, cM, lLeft2, cLeft2, a, projection, distanceValidator, bIncludeDiscontinuation);
						
					} else {
						a.push(cLeft2);
					}
					
					a.push(cLeft2);
					a.push(null);
					a.push(cRight2);
					
					
					if (!distanceValidator(cRight2, c2)) {
						
						var lRight2: Coord = cRight2.toLaLoCoord();
						bisectGreatArc(lRight2, cRight2, lp2, c2, a, projection, distanceValidator, bIncludeDiscontinuation);
						
					} else {
						a.push(c2);
					}
					
				}
				
			} else if (!distanceValidator(c2, cM))
			{
				bisectGreatArc(lpM, cM, lp2, c2, a, projection, distanceValidator, bIncludeDiscontinuation);
			}
			else {
//				if (isDiscontinuation(a, c2))
//					a.push(null);
				a.push(c2);
			}
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
			if (prj == null)
				return null;
			return prj.prjXYToLaLoCoord(x, y);
		}

		public function toNiceString(): String
		{
			if (Projection.equalCRSs(crs, "CRS:84"))
			{
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
			return new Coord(projection.crs, p.x, p.y);
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

		/**
		 *
		 */
		public function toCRS84(): Coord
		{
			// IN THE FUTURE, WE NEED TO MAKE REAL CONVERSION FROM CRS TO CRS:84
			return (new Coord(crs, x, y));
		}
	}
}

class SpherePointWithLalo
{
	public var x: Number;
	public var y: Number;
	public var z: Number;
	public var latitude: Number;
	public var longitude: Number;
	
	public function SpherePointWithLalo(x: Number, y: Number, z: Number, longitude: Number, latitude: Number)
	{
		this.x = x;
		this.y = y;
		this.z = z;
		this.latitude = latitude;
		this.longitude = longitude;
	}
	
	public function signsAreSame(sp: SpherePointWithLalo): Boolean
	{
		if (longitude < 0 && sp.longitude > 0)	return false;
		if (longitude > 0 && sp.longitude < 0)	return false;
		
		return true;
	}
}