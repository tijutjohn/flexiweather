package com.iblsoft.flexiweather.ogc
{
	import com.iblsoft.flexiweather.proj.Coord;
	import com.iblsoft.flexiweather.proj.Projection;
	
	import flash.geom.Point;
	import flash.geom.Rectangle;

	/**
	 * Representation of a contants (non-changable) rectangular 2D bounding box.
	 * Intanstances can be safely stored in container or passed to external code without
	 * worrying that anybody else will modify them (comparing to flash.geom.Rectangle).
	 * This class provides basic rectangle manipulation methods.
	 **/
	public class BBox
	{
		private var mf_xMin: Number;
		private var mf_yMin: Number;
		private var mf_xMax: Number;
		private var mf_yMax: Number;

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
			if (other == null)
				return false;
			return mf_xMin == other.mf_xMin
					&& mf_yMin == other.mf_yMin
					&& mf_xMax == other.mf_xMax
					&& mf_yMax == other.mf_yMax;
		}

		public function toRectangle(): Rectangle
		{
			return new Rectangle(mf_xMin, mf_yMin, mf_xMax - mf_xMin, mf_yMax - mf_yMin);
		}

		public static function fromRectangle(r: Rectangle): BBox
		{
			return new BBox(r.x, r.y, r.x + r.width, r.y + r.height);
		}

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

		public function forProjection(crs: String): BBox
		{
			var prj: Projection = Projection.getByCRS(crs);
			if (prj == null)
				return null;
			var minLalo: Coord = prj.prjXYToLaLoCoord(mf_xMin, mf_yMin);
			var maxLalo: Coord = prj.prjXYToLaLoCoord(mf_xMax, mf_yMax);
			var bbox: BBox = new BBox(minLalo.x, minLalo.y, maxLalo.x, maxLalo.y);
			return bbox;
		}

		public function getBBoxMaximumDistance(crs: String): Number
		{
			var prj: Projection = Projection.getByCRS(crs);
			if (prj == null)
				return Number.MAX_VALUE;
			var minLalo: Coord = prj.prjXYToLaLoCoord(mf_xMin, mf_yMin);
			var maxLalo: Coord = prj.prjXYToLaLoCoord(mf_xMax, mf_yMax);
			if (minLalo)
				return minLalo.distanceTo(maxLalo);
			return 0;
		}

		public function coordInside(coord: Coord): Boolean
		{
			var bInside: Boolean = false;
			if (coord.x >= mf_xMin && coord.x <= mf_xMax && coord.y >= mf_yMin && coord.y <= mf_yMax)
				bInside = true;
			
//			trace("BBox coordInside coord: " + coord.toNiceString() + " => " + bInside + " : " + this);
			return bInside;
		}

		public function toBBOXString(): String
		{
			return String(mf_xMin) + "," + String(mf_yMin) + ","
					+ String(mf_xMax) + "," + String(mf_yMax);
		}

		public function get center(): Point
		{
			return new Point(mf_xMin + (mf_xMax - mf_xMin) / 2, mf_yMin + (mf_yMax - mf_yMin) / 2)
		}

		public function scaled(sx: Number, sy: Number): BBox
		{
			var p: Point = center;
			var rect: Rectangle = toRectangle();
			return new BBox(p.x - rect.width * sx / 2, p.y - rect.height * sy / 2, p.x + rect.width * sx / 2, p.y + rect.height * sy / 2);
		}

		public function translated(dx: Number, dy: Number): BBox
		{
			return new BBox(mf_xMin + dx, mf_yMin + dy, mf_xMax + dx, mf_yMax + dy);
		}

		/** Returns new BBox which is union of this and other BBox. */
		public function extendedWith(other: BBox): BBox
		{
			return new BBox(
					Math.min(mf_xMin, other.mf_xMin),
					Math.min(mf_yMin, other.mf_yMin),
					Math.max(mf_xMax, other.mf_xMax),
					Math.max(mf_yMax, other.mf_yMax));
		}

		/** Checks in this BBox contains other BBox. By definition this contains this. */
		public function contains(other: BBox): Boolean
		{
			return other.mf_xMin >= mf_xMin && other.mf_xMin <= mf_xMax
					&& other.mf_xMax >= mf_xMin && other.mf_xMax <= mf_xMax
					&& other.mf_yMin >= mf_yMin && other.mf_yMin <= mf_yMax
					&& other.mf_yMax >= mf_yMin && other.mf_yMax <= mf_yMax;
		}

		/**
		 * Returns new BBox which is intersection of this and other BBox.
		 * If the intersection does not exists, returns null! Both BBox'es have to be normalize on input.
		 * */
		public function intersected(other: BBox): BBox
		{
			var intersected: BBox = new BBox(mf_xMin, mf_yMin, mf_xMax, mf_yMax);
			if (other.mf_xMin > intersected.mf_xMin)
				intersected.mf_xMin = other.mf_xMin;
			if (other.mf_xMax < intersected.mf_xMax)
				intersected.mf_xMax = other.mf_xMax;
			if (other.mf_yMin > intersected.mf_yMin)
				intersected.mf_yMin = other.mf_yMin;
			if (other.mf_yMax < intersected.mf_yMax)
				intersected.mf_yMax = other.mf_yMax;
			if (intersected.mf_xMin > intersected.mf_xMax || intersected.mf_yMin > intersected.mf_yMax)
				return null;
			return intersected;
		}

		public function intersects(other: BBox): Boolean
		{
			return intersected(other) != null;
		}
		
		/**
		 * Return coverage ratio of area intersection between 2 BBoxes. If whole "other" BBox is inside this BBox it returns 1  
		 * @param other - other BBox must be normalized (moved to extent BBox of its projection)
		 * @return 
		 * 
		 */		
		public function coverageRatio(other: BBox): Number
		{
			var intersectedBBox: BBox = intersected(other);
			if (intersectedBBox)
			{
				var otherBBoxArea: Number = other.width * other.height;
				var intersectedBBoxArea: Number = intersectedBBox.width * intersectedBBox.height;
				
				var percentage: Number = intersectedBBoxArea / otherBBoxArea;
				
				return percentage;
			}
			return 0;
		}
		

		public function get isValid(): Boolean
		{
			return !isNaN(xMin) && !isNaN(xMax) && !isNaN(yMin) && !isNaN(yMax) ;
		}
		public function get isEmpty(): Boolean
		{
			return width == 0 || height == 0;
		}

		public function get surface(): Number
		{
			return width * height;
		}

		public function get xMin(): Number
		{
			return mf_xMin;
		}

		public function get yMin(): Number
		{
			return mf_yMin;
		}

		public function get xMax(): Number
		{
			return mf_xMax;
		}

		public function get yMax(): Number
		{
			return mf_yMax;
		}

		public function get width(): Number
		{
			return mf_xMax - mf_xMin;
		}

		public function get height(): Number
		{
			return mf_yMax - mf_yMin;
		}

		public function toString(): String
		{
			return 'BBox ' + xMin + ", " + yMin + ", " + xMax + ", " + yMax;
		}

		public function clone(): BBox
		{
			var bbox: BBox = new BBox(xMin, yMin, xMax, yMax);
			return bbox;
		}
	}
}
