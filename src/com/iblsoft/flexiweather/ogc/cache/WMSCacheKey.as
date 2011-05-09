package com.iblsoft.flexiweather.ogc.cache
{
	import com.iblsoft.flexiweather.ogc.BBox;
	
	import flash.net.URLRequest;
	
	public class WMSCacheKey
	{
		internal var ms_key: String;
		internal var ms_crs: String;
		internal var m_bbox: BBox;
		
		public function WMSCacheKey(s_crs: String, bbox: BBox, url: URLRequest)
		{
			ms_crs = s_crs;
			m_bbox = bbox;
			ms_key = s_crs + "|" + bbox.toBBOXString();
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