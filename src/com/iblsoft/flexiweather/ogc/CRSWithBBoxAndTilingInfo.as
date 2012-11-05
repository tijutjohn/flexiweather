package com.iblsoft.flexiweather.ogc
{

	public class CRSWithBBoxAndTilingInfo extends CRSWithBBox
	{
		private var m_tilingExtent: BBox;
		private var mi_tileSize: int;

		public function CRSWithBBoxAndTilingInfo(
				s_crs: String, bbox: BBox /*= null*/,
				tilingExtent: BBox, i_tileSize: uint)
		{
			super(s_crs, bbox);
			m_tilingExtent = tilingExtent;
			mi_tileSize = i_tileSize;
		}

		override public function destroy(): void
		{
			super.destroy();
			m_tilingExtent = null;
		}

		public function get tileSize(): int
		{
			return mi_tileSize;
		}

		public function get tilingExtent(): BBox
		{
			return m_tilingExtent;
		}
	}
}
