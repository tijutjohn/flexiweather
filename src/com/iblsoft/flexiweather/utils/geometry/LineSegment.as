package com.iblsoft.flexiweather.utils.geometry
{
	import flash.geom.Point;
	import flash.sampler.NewObjectSample;

	public class LineSegment
	{
		public var x1: Number;
		public var y1: Number;
		public var x2: Number;
		public var y2: Number;

		public function LineSegment(x1: Number, y1: Number, x2: Number, y2: Number)
		{
			this.x1 = x1;
			this.y1 = y1;
			this.x2 = x2;
			this.y2 = y2;
		}
		
		public static function fromPoints(s: Point, e: Point): LineSegment
		{ return new LineSegment(s.x, s.y, e.x, e.y); }

		/**
		 * Returns intersection point of "this" and "other" line segment, or null
		 * if it does not exist.
		 */
		public function intersectionWithLineSegment(
			other: LineSegment): Point
		{
			var adx: Number = this.x2 - this.x1; // this direction vector 
			var ady: Number = this.y2 - this.y1; 
			var bdx: Number = other.x2 - other.x1; // other direction vector
			var bdy: Number = other.y2 - other.y1;
			var D: Number = adx * bdy - ady * bdx;
			if(Math.abs(D) < 1e-6) // 0 - lines are parallel
				return null;
			var cdx: Number = this.x1 - other.x1; 
			var cdy: Number = this.y1 - other.y1;
			var s: Number = bdx * cdy - bdy * cdx;
			if(s < 0 || s > D)
				return null;
			var t: Number = adx * cdy - ady * cdx;
			if(t < 0 || t > D)
				return null;
			// intersectPt = a + u * (s/d); //or b + v * (t/d);
			var r: Number = s/D;
			return new Point(this.x1 + adx * r, this.y1 + ady * r); 
		}   
		
		/**
		 * Returns coordinates of closest point on the line segment.
		 **/
		public function closestPointToPoint(x: Number, y: Number): Point
		{
			var dirVector: Vector2D = directionVector;
			var f_keyProduct: Number = dirVector.dot(new Vector2D(x - this.x1, y - this.y1)); //key dot product
			var f_segLenSq: Number = dirVector.dot(dirVector); //Segment length squared
			
			if(f_keyProduct <= 0)
				return startPoint;  
			else if(f_keyProduct >= f_segLenSq)
				return endPoint;
			else 
			{
				var f_ratio: Number = f_keyProduct / f_segLenSq;
				return new Point(x1 + dirVector.x * f_ratio, y1 + dirVector.y * f_ratio);
			}
		}

		/**
		 * Returns distance between a point and "this" line segments
		 **/
		public function distanceToPoint(x: Number, y: Number): Number
		{
			var pt: Point = closestPointToPoint(x, y);
			return pt.subtract(new Point(x, y)).length;
		}

		/**
		 * Returns minimum distance between "this" and "other" line segments
		 **/
		public function minimumDistanceToLineSegment(other: LineSegment): Number
		{
			if(intersectionWithLineSegment(other) != null)
				return 0;
			return Math.min(
				distanceToPoint(other.x1, other.y1),
				distanceToPoint(other.x2, other.y2),
				other.distanceToPoint(x1, y1),
				other.distanceToPoint(x2, y2));
		}
		
		/**
		 * Returns shortest line segment which connects "this" and "other" line segments.
		 **/
		public function shortestConnectionToLineSegment(other: LineSegment): LineSegment
		{
			var closestToOtherS: Point = closestPointToPoint(other.x1, other.y1);
			var f_distanceToOtherS: Number = closestToOtherS.subtract(other.startPoint).length; 
			var closestToOtherE: Point = closestPointToPoint(other.x2, other.y2);
			var f_distanceToOtherE: Number = closestToOtherE.subtract(other.endPoint).length; 

			var closestToThisS: Point = other.closestPointToPoint(x1, other.y1);
			var f_distanceToThisS: Number = closestToThisS.subtract(startPoint).length; 
			var closestToThisE: Point = other.closestPointToPoint(x2, y2);
			var f_distanceToThisE: Number = closestToThisE.subtract(endPoint).length;
			
			var ptOther: Point = f_distanceToOtherS < f_distanceToOtherE ? closestToOtherS : closestToOtherE;
			var ptThis: Point = f_distanceToThisS < f_distanceToThisE ? closestToThisS : closestToThisE;
			return new LineSegment(ptThis.x, ptThis.y, ptOther.x, ptOther.y);
		}
		
		public function get length(): Number
		{ return new Point(x2 - x1, y2 - y1).length; }

		public function get startPoint(): Point
		{ return new Point(x1, y1); }

		public function get midPoint(): Point
		{ return new Point((x1 + x2) / 2.0, (y1 + y2) / 2.0); }

		public function get startVector(): Vector2D
		{ return new Vector2D(x1, y1); }
		
		public function get endPoint(): Point
		{ return new Point(x2, y2); }
		
		public function get directionVector(): Vector2D
		{ return new Vector2D(x2 - x1, y2 - y1); }
	}
}