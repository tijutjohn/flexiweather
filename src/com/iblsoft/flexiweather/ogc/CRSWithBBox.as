package com.iblsoft.flexiweather.ogc
{
	import com.iblsoft.flexiweather.utils.Serializable;
	import com.iblsoft.flexiweather.utils.Storage;
	
	/**
	 * Object representing a reference system (CRS) with optional rectangular bounding box (BBox).
	 * Object is constant.
	 **/
	public class CRSWithBBox implements Serializable
	{
		internal var ms_crs: String;
		internal var m_bbox: BBox = null;
		 
		public function CRSWithBBox(
				s_crs: String = '', bbox: BBox = null)
		{
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
		
		public function serialize(storage: Storage): void
		{
			if(storage.isLoading())
			{
				m_bbox = new BBox(0,0,0,0);
			}
			
			crs = storage.serializeString("crs", crs, null);
			
			m_bbox.mf_xMin = storage.serializeInt("min-x", m_bbox.mf_xMin, 0);
			m_bbox.mf_xMax = storage.serializeInt("max-x", m_bbox.mf_xMax, 0);
			m_bbox.mf_yMin = storage.serializeInt("min-y", m_bbox.mf_yMin, 0);
			m_bbox.mf_yMax = storage.serializeInt("max-y", m_bbox.mf_yMax, 0);
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
	}
}