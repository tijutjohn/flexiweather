package com.iblsoft.flexiweather.ogc.cache
{
	import com.iblsoft.flexiweather.ogc.BBox;
	import com.iblsoft.flexiweather.ogc.tiling.TileIndex;
	
	import flash.net.URLRequest;
	
	public class WMSTileCacheKey extends CacheKey
	{
		public var m_tileIndex: TileIndex;
		public var m_time: Date;
	
		public function WMSTileCacheKey(s_crs: String, bbox: BBox, tileIndex: TileIndex, url: URLRequest, m_time:Date, specialStrings: Array = null)
		{
			super(s_crs, bbox, url);
			
			key = s_crs;
			m_tileIndex = tileIndex;
			if(bbox != null)
				key +=  "|" + bbox.toBBOXString();
			if(tileIndex != null)
				key +=  "|" + tileIndex.toString();
			if(m_time != null)
				key +=  "|time:" + m_time.toString();
			var a: Array = []
//			if(url.url != null) {
//				key += url.url;
//			} 
			
			if (specialStrings && specialStrings.length > 0)
			{
				var specialStringInside: Boolean = true;
				for each (var str: String in specialStrings)
				{
					key +=  "|" + str;
				}
			}
				
//			trace("new WMSTileCacheKey : " + key);
		}
	
	}
}