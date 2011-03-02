package com.iblsoft.flexiweather.ogc.cache
{
	import com.iblsoft.flexiweather.ogc.BBox;
	
	import flash.display.Bitmap;
	import flash.events.TimerEvent;
	import flash.net.URLRequest;
	import flash.utils.Dictionary;
	import flash.utils.Timer;
	
	public class WMSCache implements ICache
	{
		/**
		 * Expiration time in seconds 
		 */		
		private var _checkExpirationTime: int = 10 * 1000; 
		private var _expirationTime: int = 60; 
		private var _expirationTimer: Timer;
		
		private var _animationModeEnabled: Boolean;
		
		protected var md_cache: Dictionary = new Dictionary();
		protected var md_cache_loading: Dictionary = new Dictionary();
		
		
		public function WMSCache()
		{
			_expirationTimer = new Timer(_checkExpirationTime);
			_expirationTimer.addEventListener(TimerEvent.TIMER, onExpiration);
			_expirationTimer.start();
		}
		
		public function setAnimationModeEnable(value: Boolean): void
		{
			if (_animationModeEnabled != value)
			{
				_animationModeEnabled = value;
			}
		}
		private function onExpiration(event: TimerEvent): void
		{
			if (_animationModeEnabled)
			{
				//do not remove any cached data, animation is running
				return;
			}
			var currTime: Date = new Date();
			for (var s_key: String in md_cache)
			{
				var obj: Object  = md_cache[s_key];
				
				var lastUsed: Date = obj.lastUsed as Date;
				if (lastUsed)
				{
					var diff: Number = currTime.time - lastUsed.time;
					if (diff > (_expirationTime * 1000))
					{
//						trace("Image from cache is expired, will be removed");
						deleteCacheItem(s_key);
					}
//					trace("diff: " + diff);
				}
			}
		}
		
		private function deleteCacheItem(s_key: String): void
		{
			var cacheItem: Object = md_cache[s_key];
			
			
			//dispose bitmap data, just for bitmaps which are not currently displayed
			if (!cacheItem.displayed)
			{
//				trace("\t deleteCacheItem " + cacheItem);
				var bmp: Bitmap = cacheItem.image;
			
				bmp.bitmapData.dispose();
				delete md_cache[s_key];
			} else {
//				trace("\t deleteCacheItem: DO NOT DELETE IT " + cacheItem);
				
			}
			
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
				md_cache[s_key].displayed = true;
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
				displayed: true,
				lastUsed: new Date(),
				image: img
			};
			
			delete md_cache_loading[s_key];
		}
		
		public function removeFromScreen(): void
		{
			for(var s_key: String in md_cache) 
			{
				md_cache[s_key].displayed = false;
			}
		}
		
		public function invalidate(s_crs: String, bbox: BBox): void
		{
			var a: Array = [];
			for(var s_key: String in md_cache) {
				var ck: WMSCacheKey = md_cache[s_key].cacheKey; 
				md_cache[s_key].displayed = false;
				if(ck.ms_crs == s_crs && ck.m_bbox.equals(bbox))
					a.push(s_key);
			}
			for each(s_key in a) {
	//			trace("WMSCache.invalidate(): removing image with key: " + md_cache[s_key].toString());
				deleteCacheItem(s_key);
			}
		}

	}
}