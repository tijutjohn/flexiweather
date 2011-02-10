package com.iblsoft.flexiweather.ogc.cache
{
	import com.iblsoft.flexiweather.ogc.BBox;
	
	import flash.display.Bitmap;
	import flash.net.URLRequest;
	import flash.utils.Dictionary;
	
	public class WMSCache implements ICache
	{
		protected var md_cache: Dictionary = new Dictionary();
		protected var md_cache_loading: Dictionary = new Dictionary();
		
		public function WMSCache()
		{
		}
		
		private function getKey(s_crs: String, bbox: BBox, url: URLRequest): String
		{
			var ck: WMSCacheKey = new WMSCacheKey(s_crs, bbox, url);
			var s_key: String = ck.toString(); 
			return s_key;			
		}
		
		public function isImageCached(s_crs: String, bbox: BBox, url: URLRequest): Boolean
		{
			var s_key: String = getKey(s_crs, bbox, url);
			
			return (md_cache[s_key] || md_cache_loading[s_key])
		}
		
		public function getImage(s_crs: String, bbox: BBox, url: URLRequest): Bitmap
		{
			var s_key: String = getKey(s_crs, bbox, url);
			
			if(s_key in md_cache) {
				md_cache[s_key].lastUsed = new Date();
				return md_cache[s_key].image;
			}
			return null;
		}
	
		/**
		 * function will notify cache that image is loading, but not loaded yet. 
		 * It will be used for not to load same request ,if it is already loaing. 
		 * @param s_crs
		 * @param bbox
		 * @param url
		 * 
		 */		
		public function startImageLoading(s_crs: String, bbox: BBox, url: URLRequest): void
		{
			var s_key: String = getKey(s_crs, bbox, url);
			
			md_cache_loading[s_key] = true;
		}
		
		public function addImage(img: Bitmap, s_crs: String, bbox: BBox, url: URLRequest): void
		{
			var ck: WMSCacheKey = new WMSCacheKey(s_crs, bbox, url);
			var s_key: String = getKey(s_crs, bbox, url);
			
			md_cache[s_key] = {
				cacheKey: ck,
				lastUsed: new Date(),
				image: img
			};
			
			delete md_cache_loading[s_key];
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