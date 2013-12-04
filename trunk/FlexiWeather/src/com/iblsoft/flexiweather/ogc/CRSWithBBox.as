package com.iblsoft.flexiweather.ogc
{
	import com.iblsoft.flexiweather.proj.Coord;
	import com.iblsoft.flexiweather.proj.Projection;
	import com.iblsoft.flexiweather.utils.Serializable;
	import com.iblsoft.flexiweather.utils.Storage;
	import flash.geom.Point;

	/**
	 * Object representing a reference system (CRS) with optional rectangular bounding box (BBox).
	 * Object is constant.
	 **/
	public class CRSWithBBox implements Serializable
	{
		protected var ms_crs: String;
		protected var m_bbox: BBox = null;

		public function CRSWithBBox(
				s_crs: String = '', bbox: BBox = null)
		{
			if (s_crs == '')
				s_crs = Projection.CRS_GEOGRAPHIC;
			//FIXME fix this, BBox with width and height cause problems (e.g. Zoom to layer extent)
			if (!bbox)
			{
				//get maxExtent for crs
//				var extent: BBox = ProjectionConfigurationManager.getInstance().getMaxExtentForCRS(s_crs);
//				if (extent)
//					bbox = extent;
//				else
//					bbox = new BBox(0, 0, 0, 0);
				bbox = new BBox(0, 0, 0, 0);
			}
			ms_crs = s_crs;
			m_bbox = bbox;
		}

		public function destroy(): void
		{
			m_bbox = null;
		}

		public function equals(other: CRSWithBBox): Boolean
		{
			if (other == null)
				return false;
			if (!ms_crs == other.ms_crs)
				return false;
			if (m_bbox == null && other.m_bbox == null)
				return true;
			if (m_bbox == null && other.m_bbox != null)
				return false;
			return m_bbox.equals(other.m_bbox);
		}

		public function serialize(storage: Storage): void
		{
			ms_crs = storage.serializeString("crs", ms_crs);
			var xMin: Number = NaN;
			var yMin: Number = NaN;
			var xMax: Number = NaN;
			var yMax: Number = NaN;
			if (storage.isStoring() || m_bbox != null)
			{
				xMin = storage.serializeNumber("min-x", m_bbox.xMin);
				yMin = storage.serializeNumber("min-y", m_bbox.yMin);
				xMax = storage.serializeNumber("max-x", m_bbox.xMax);
				yMax = storage.serializeNumber("max-y", m_bbox.yMax);
			}
			if (storage.isLoading())
			{
				if (isNaN(xMin) && isNaN(yMin) && isNaN(xMax) && isNaN(yMax))
					m_bbox = null;
				else
					m_bbox = new BBox(xMin, yMin, xMax, yMax);
			}
		}

		public function coordInside(coord: Coord): Boolean
		{
			if (coord.crs == ms_crs)
				return m_bbox.coordInside(coord);
			return false;
		}

		public function bboxInCRS(crs: String): BBox
		{
			if (ms_crs != crs)
			{
				var currPrj: Projection = Projection.getByCRS(ms_crs);
				var prj: Projection = Projection.getByCRS(crs);
				if (prj == null)
					return null;
//				var minCoord: Coord = new Coord(ms_crs, m_bbox.xMin, m_bbox.yMin);
//				var maxCoord: Coord = new Coord(ms_crs, m_bbox.xMax, m_bbox.yMax);
				var north: Number = Number.NEGATIVE_INFINITY;
				var south: Number = Number.POSITIVE_INFINITY;
				var east: Number = Number.NEGATIVE_INFINITY;
				var west: Number = Number.POSITIVE_INFINITY;
				var xMin: Number = m_bbox.xMin;
				var xMax: Number = m_bbox.xMax;
				var yMin: Number = m_bbox.yMin;
				var yMax: Number = m_bbox.yMax;
				var x: Number;
				var y: Number;
				var xStep: Number = (xMax - xMin) / 10;
				var yStep: Number = (yMax - yMin) / 10;
				var pt: Point;
				for (x = xMin; x <= xMax; x += xStep)
				{
					for (y = yMin; y <= yMax; y += yStep)
					{
						pt = currPrj.prjXYToOtherPrjPt(x, y, prj);
						north = Math.max(pt.y, north);
						south = Math.min(pt.y, south);
						east = Math.max(pt.x, east);
						west = Math.min(pt.x, west);
					}
				}
				var bbox: BBox = new BBox(west, south, east, north);
				return bbox;
			}
			return m_bbox;
		}

		private function formatNumber(num: Number): Number
		{
			return int(num * 100) / 100;
		}

		public function toLaLoString(): String
		{
			var prj: Projection = Projection.getByCRS(ms_crs);
			if (prj == null)
				return null;
			var minLalo: Coord = prj.prjXYToLaLoCoord(m_bbox.xMin, m_bbox.yMin);
			var maxLalo: Coord = prj.prjXYToLaLoCoord(m_bbox.xMax, m_bbox.yMax);
			return String(formatNumber(minLalo.y)) + "," + String(formatNumber(minLalo.x)) + ","
					+ String(formatNumber(maxLalo.y)) + "," + String(formatNumber(maxLalo.x));
		}

		public function hasBBox(): Boolean
		{
			return m_bbox != null;
		}

		public function get crs(): String
		{
			return ms_crs;
		}

		public function get bbox(): BBox
		{
			return m_bbox;
		}

		public function clone(): Object
		{
			var crsBBox: CRSWithBBox = new CRSWithBBox(crs, bbox.clone());
			return crsBBox;
		}
	}
}
