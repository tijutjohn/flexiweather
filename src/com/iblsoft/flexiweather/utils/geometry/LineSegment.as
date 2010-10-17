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