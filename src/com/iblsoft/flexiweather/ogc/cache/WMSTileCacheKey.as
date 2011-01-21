package com.iblsoft.flexiweather.ogc.cache
{
	import com.iblsoft.flexiweather.ogc.BBox;
	import com.iblsoft.flexiweather.ogc.tiling.TileIndex;
	
	import flash.net.URLRequest;
	
	public class WMSTileCacheKey
	{
		internal var ms_key: String;
		internal var ms_crs: String;
		internal var m_bbox: BBox;
		public var m_tileIndex: TileIndex;
	
		public function WMSTileCacheKey(s_crs: String, bbox: BBox, tileIndex: TileIndex, url: URLRequest)
		{
			ms_crs = s_crs;
			m_bbox = bbox;
			ms_key = s_crs;
			m_tileIndex = tileIndex;
			if(bbox != null)
				ms_key +=  "|" + bbox.toBBOXString();
			if(tileIndex != null)
				ms_key +=  "|" + tileIndex.toString();
			var a: Array = []
			if(url != null) {
				for(var s: String in url.data) {
					a.push(s);
				}
				a.sort();
				for each(s in a) {
					ms_key += "|" + s + "=" + url.data[s]; 
				}
			} 
		}
	
		public function toString(): String
		{ return ms_key; }

	}
}