package com.iblsoft.flexiweather.ogc
{
	public class CRSWithBBoxAndTilingInfo extends CRSWithBBox
	{
		private var m_tileWidth: int;
		private var m_tileHeight: int;
		
		public function CRSWithBBoxAndTilingInfo(s_crs:String='', bbox:BBox=null, tileWidth: int = 0, tileHeight: int = 0)
		{
			super(s_crs, bbox);
			
			m_tileWidth = tileWidth;
			m_tileHeight = tileHeight;
		}
		
		public function fromCRSWithBBox(crsWithBBox: CRSWithBBox): void
		{
//			bbox = crsWithBBox.bbox;
//			crs = crsWithBBox.crs;
			setCRSAndBBox(crsWithBBox.crs, crsWithBBox.bbox);
		}
		
		public function get tileWidth(): int
		{
			return m_tileWidth;
		}
		
		public function get tileHeight(): int
		{
			return m_tileHeight;
		}
		
	}
}