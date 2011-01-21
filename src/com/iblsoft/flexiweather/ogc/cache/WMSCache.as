package com.iblsoft.flexiweather.ogc.cache
{
	import com.iblsoft.flexiweather.ogc.BBox;
	
	import flash.display.Bitmap;
	import flash.net.URLRequest;
	import flash.utils.Dictionary;
	
	public class WMSCache implements ICache
	{
		protected var md_cache: Dictionary = new Dictionary();
		
		public function WMSCache()
		{
		}
		
		public function getImage(s_crs: String, bbox: BBox, url: URLRequest): Bitmap
		{
			var ck: WMSCacheKey = new WMSCacheKey(s_crs, bbox, url);
			var s_key: String = ck.toString(); 
			if(s_key in md_cache) {
				md_cache[s_key].lastUsed = new Date();
				return md_cache[s_key].image;
			}
			return null;
		}
	
		public function addImage(img: Bitmap, s_crs: String, bbox: BBox, url: URLRequest): void
		{
			var ck: WMSCacheKey = new WMSCacheKey(s_crs, bbox, url);
			var s_key: String = ck.toString(); 
			md_cache[s_key] = {
				cacheKey: ck,
				lastUsed: new Date(),
				image: img
			};
		}
		
		public function invalidate(s_crs: String, bbox: BBox): void
		{
			var a: Array = [];
			for(var s_key: String in md_cache) {
				var ck: WMSCacheKey = md_cache[s_key].cacheKey; 
				if(ck.ms_crs == s_crs && ck.m_bbox.equals(bbox))
					a.push(s_key);
			}
			for each(s_key in a) {
	//			trace("WMSCache.invalidate(): removing image with key: " + md_cache[s_key].toString());
				delete md_cache[s_key];
			}
		}

	}
}