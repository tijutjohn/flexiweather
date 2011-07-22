package com.iblsoft.flexiweather.ogc
{
	import com.iblsoft.flexiweather.utils.Serializable;
	import com.iblsoft.flexiweather.utils.Storage;

	public class QTTilingInfo implements Serializable
	{
//		public function set crs(value: String): void
//		{
//			createDataIfNeeded();
//			crsWithBBox.crs = value;
//		}
//		public function set bbox(value: BBox): void
//		{
//			createDataIfNeeded();
//			crsWithBBox.bbox = value;
//		}
		
		public var urlPattern: String;
		private var _crsWithBBox: CRSWithBBox;
		public var minimumZoomLevel: uint = 1;
		public var maximumZoomLevel: uint = 12;
		
		public function get crsWithBBox(): CRSWithBBox
		{
			return _crsWithBBox;
		}
		
		public function QTTilingInfo(_urlPattern: String = '', crsWithBBox: CRSWithBBox = null)
		{
			urlPattern = _urlPattern;
			_crsWithBBox = crsWithBBox;
		}
		
//		private function createDataIfNeeded(): void
//		{
//			if (!crsWithBBox)
//			{
//				crsWithBBox = new CRSWithBBox();
//			}
//		}
		public function updateCRSWithBBox(value: CRSWithBBox)
		{
			_crsWithBBox = value;
		}
		public function serialize(storage: Storage): void
		{
//			if(storage.isStoring() || m_bbox != null) {
//				xMin = storage.serializeNumber("min-x", m_bbox.xMin);
//				yMin = storage.serializeNumber("min-y", m_bbox.yMin);
//				xMax = storage.serializeNumber("max-x", m_bbox.xMax);
//				yMax = storage.serializeNumber("max-y", m_bbox.yMax);
//			}
//			if(storage.isLoading()) {
//				if(isNaN(xMin) && isNaN(yMin) && isNaN(xMax) && isNaN(yMax))
//					m_bbox = null;
//				else
//					m_bbox = new BBox(xMin, yMin, xMax, yMax);
//			}
			urlPattern = storage.serializeString("url-pattern", urlPattern);
			if(storage.isLoading()) {
				_crsWithBBox = new CRSWithBBox();	
			}
			_crsWithBBox.serialize(storage);// = storage.serialize("crs-with-bbox", _crsWithBBox );
			
			minimumZoomLevel = storage.serializeUInt("minimum-zoom-level", minimumZoomLevel, 1);
			maximumZoomLevel = storage.serializeUInt("maximum-zoom-level", maximumZoomLevel, 12);
		}
	}
}