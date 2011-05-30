package com.iblsoft.flexiweather.ogc
{
	public class CRSWithBBoxAndTilingInfo extends CRSWithBBox
	{
		private var m_tilingExtent: BBox;
		private var mi_tileWidth: int;
		private var mi_tileHeight: int;
		
		public function CRSWithBBoxAndTilingInfo(
			s_crs: String, bbox: BBox /*= null*/,
			tilingExtent: BBox, i_tileWidth: int, i_tileHeight: int)
		{
			super(s_crs, bbox);
			
			m_tilingExtent = tilingExtent;
			mi_tileWidth = tileWidth;
			mi_tileHeight = tileHeight;
		}
		
		public function get tileWidth(): int
		{
			return mi_tileWidth;
		}
		
		public function get tileHeight(): int
		{
			return mi_tileHeight;
		}
		
		public function get tilingExtent(): BBox
		{
			return m_tilingExtent;
		}
	}
}