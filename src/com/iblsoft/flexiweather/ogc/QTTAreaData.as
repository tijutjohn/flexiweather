package com.iblsoft.flexiweather.ogc
{
	import com.iblsoft.flexiweather.utils.Serializable;
	import com.iblsoft.flexiweather.utils.Storage;

	public class QTTAreaData implements Serializable
	{
		public var urlPattern: String;
		public var crsWithBBox: CRSWithBBox;
		public function QTTAreaData()
		{
		}
		
		public function serialize(storage: Storage): void
		{
			storage.serializeString("url-pattern", urlPattern);
			storage.serialize("crs-with-bbox", crsWithBBox);
		}
	}
}