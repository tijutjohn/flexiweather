package com.iblsoft.flexiweather.ogc
{
	import flash.geom.Point;
	import flash.geom.Rectangle;
	
	/**
	 * Object representing a unchangable rectangular bounding box.
	 * Object is constant. 
	 **/
	public class BBox
	{
		internal var mf_xMin: Number;
		internal var mf_yMin: Number;
		internal var mf_xMax: Number;
		internal var mf_yMax: Number;

		public function BBox(
				f_xMin: Number, f_yMin: Number, f_xMax: Number, f_yMax: Number)
		{
			mf_xMin = f_xMin;
			mf_yMin = f_yMin;
			mf_xMax = f_xMax;
			mf_yMax = f_yMax;
		}
		
		public function equals(other: BBox): Boolean
		{
			if(other == null)
				return false;
			return mf_xMin == other.mf_xMin
					&&  mf_yMin == other.mf_yMin 
					&&  mf_xMax == other.mf_xMax 
					&&  mf_yMax == other.mf_yMax; 
		}
		
		public function toRectangle(): Rectangle
		{ return new Rectangle(mf_xMin, mf_yMin, mf_xMax - mf_xMin, mf_yMax - mf_yMin); }

		public static function fromRectangle(r: Rectangle): BBox
		{ return new BBox(r.x, r.y, r.x + r.width, r.y + r.height); }

		/** <BoundingBox minx="-180" miny="-90" maxx="180" maxy="90" ... /> */
		public static function fromXML_WMS(xml: XML): BBox
		{
			return new BBox(xml.@minx, xml.@miny, xml.@maxx, xml.@maxy);
		}

		/** EX_GeographicBoundingBox */
		public static function fromXML_WMSGeographic(xml: XML): BBox
		{
			return new BBox(xml.westBoundLongitude, xml.southBoundLatitude,
					xml.eastBoundLongitude, xml.northBoundLatitudey);
		}

		public function toBBOXString(): String
		{
        	return String(mf_xMin) + "," + String(mf_yMin) + ","
					+ String(mf_xMax) + "," + String(mf_yMax);
		}
		
		public function get center(): Point
		{
			return new Point( mf_xMin + (mf_xMax - mf_xMin) / 2, mf_yMin + (mf_yMax - mf_yMin) / 2)
		}
		
		public function scaled(sx: Number, sy: Number): BBox
		{
			var p: Point =  center;
			var rect: Rectangle = toRectangle();
			
			return new BBox(p.x - rect.width * sx / 2, p.y - rect.height * sy / 2, p.x + rect.width * sx / 2, p.y + rect.height * sy / 2);
		}
		
		public function translated(dx: Number, dy: Number): BBox
		{
			return new BBox(mf_xMin + dx, mf_yMin + dy, mf_xMax + dx, mf_yMax + dy);
		}
		
		public function extendedWith(other: BBox): BBox
		{
			return new BBox(
				Math.min(mf_xMin, other.mf_xMin),
				Math.min(mf_yMin, other.mf_yMin),
				Math.max(mf_xMax, other.mf_xMax),
				Math.max(mf_yMax, other.mf_yMax));
		}

		public function get xMin(): Number
		{ return mf_xMin; }

		public function get yMin(): Number
		{ return mf_yMin; }

		public function get xMax(): Number
		{ return mf_xMax; }

		public function get yMax(): Number
		{ return mf_yMax; }

		public function get width(): Number
		{ return mf_xMax - mf_xMin; }

		public function get height(): Number
		{ return mf_yMax - mf_yMin; }
		
		public function toString(): String
		{
			return 'BBox ' + xMin + " , " + yMin + " , " + xMax + " , " + yMax;
		}
		
		public function clone(): BBox
		{
			var bbox: BBox = new BBox(xMin, yMin, xMax, yMax);
			return bbox;
		}
	}
}