package com.iblsoft.flexiweather.ogc
{
	import com.iblsoft.flexiweather.proj.Projection;
	
	/**
	 * Object representing a reference system (CRS) with optional rectangular bounding box (BBox).
	 * Object is constant.
	 **/
	public class CRSWithBBox
	{
		internal var ms_crs: String;
		internal var m_bbox: BBox = null;
		
		public function CRSWithBBox(
				s_crs: String = '', bbox: BBox = null)
		{
			if (s_crs == '')
				s_crs = Projection.CRS_GEOGRAPHIC;
			if (!bbox)
				bbox = new BBox(0, 0, 0, 0);
				
			ms_crs = s_crs;
			m_bbox = bbox;
		}
		
		public function equals(other: CRSWithBBox): Boolean
		{
			if(other == null)
				return false;
			if(!ms_crs == other.ms_crs)
				return false;
			if(m_bbox == null && other.m_bbox == null)
				return true;
			if(m_bbox == null && other.m_bbox != null)
				return false;
			return m_bbox.equals(other.m_bbox);
		}
		
		public function hasBBox(): Boolean
		{ return m_bbox != null; }

		public function get crs(): String
		{ return ms_crs; }

		public function get bbox(): BBox
		{ return m_bbox; }
		
		public function set crs(value: String): void
		{ ms_crs = value; }

		public function set bbox(value: BBox): void
		{ m_bbox = value; }
		
		public function clone(): Object
		{
			var crsBBox: CRSWithBBox = new CRSWithBBox();
			crsBBox.crs = crs;
			crsBBox.bbox = bbox.clone();
			
			return crsBBox;
		}
	}
}