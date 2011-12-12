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
		public var name: String;
		
		/**
		 * Expiration check interval. How ofter will be expiration checked 
		 */		
		private var mf_expirationCheckTime: int = 10 * 1000; 
		/**
		 * Expiration time. How long will tile be valid (in seconds). 
		 * Value "0" means no expiration will be done.
		 */	
		private var mf_expirationTime: int = 0;
		private var m_expirationTimer: Timer;
		
		private var _animationModeEnabled: Boolean;
		
		private var mi_cacheItemCount: int = 0;
		protected var md_cache: Dictionary = new Dictionary();
		protected var md_cacheLoading: Dictionary = new Dictionary();
		
		public function WMSCache()
		{
			startExpirationTimer();
		}
		
		private function startExpirationTimer(): void
		{
			if (mf_expirationTime > 0)
			{
				m_expirationTimer = new Timer(mf_expirationCheckTime);
				m_expirationTimer.addEventListener(TimerEvent.TIMER, onExpiration);
				m_expirationTimer.start();
			}
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
			if (_animationModeEnabled || mf_expirationTime == 0)
			{
				//do not remove any cached data, animation is running or expirationTime is set to 0
				return;
			}
			var currTime: Date = new Date();
			for (var s_key: String in md_cache)
			{
				var cacheItem: CacheItem = md_cache[s_key] as CacheItem;
				
				var lastUsed: Date = cacheItem.lastUsed as Date;
				if (lastUsed)
				{
					var diff: Number = currTime.time - lastUsed.time;
					if (diff > (mf_expirationTime * 1000))
					{
//						debug("WMSCache.onExpiration(): Image from cache is expired, will be removed");
						if (!cacheItem.isImageOnDisplayList())
						{
							deleteCacheItemByKey(s_key);
						}
//						else {
//							debug("WMSCache.onExpiration(): image is on displalist");
//						}
					}
//					debug("WMSCache.onExpiration(): diff=" + diff);
				}
			}
			debugCache();
		}
		
		
		public function deleteCacheItem(cacheItem: CacheItem, b_disposeDisplayed: Boolean = false): Boolean
		{
			if (cacheItem && cacheItem.cacheKey)
			{
				return deleteCacheItemByKey(cacheItem.cacheKey.key, b_disposeDisplayed);
			}
			return false;
		}
		
		/**
		 * Delete cached item 
		 * @param s_key Item key
		 * @param b_disposeDisplayed dispose item even if it is displayed. Default value is false, because we do not want dispose displayed items, but you can force it by setting this property to true (e.g. receiving data for same CRS and BBox)
		 * @return true if item was deleted, false if it was not
		 * 
		 */		
		public function deleteCacheItemByKey(s_key: String, b_disposeDisplayed: Boolean = false): Boolean
		{
//			return;

			var cacheItem: CacheItem = md_cache[s_key] as CacheItem;
			
			// dispose bitmap data, just for bitmaps which are not currently displayed
			if (cacheItem && (!cacheItem.displayed || (cacheItem.displayed && b_disposeDisplayed) ))
			{
//				debug("\t deleteCacheItem " + cacheItem);
				var bmp: Bitmap = cacheItem.image;
			
				bmp.bitmapData.dispose();
				mi_cacheItemCount--;
				delete md_cache[s_key];
				return true;
			} else {
//				debug("\t deleteCacheItem: DO NOT DELETE IT " + cacheItem);
			}
			return false;
		}
		
		public function getCacheItemsCount(): int
		{
			return mi_cacheItemCount;
		}
		
		public function getCacheItems(): Array
		{
			var arr: Array = [];
			for each (var cacheItem: CacheItem in md_cache)
			{
				arr.push(cacheItem);
			}
			return arr;
		}
		
		private function getKey(s_crs: String, bbox: BBox, url: URLRequest, validity: Date = null): String
		{
			var ck: WMSCacheKey = new WMSCacheKey(s_crs, bbox, url, validity);
			var s_key: String = ck.toString(); 
			return s_key;			
		}
		
//		public function isImageCached(metadata: CacheItemMetadata): Boolean
		public function isItemCached(metadata: CacheItemMetadata): Boolean
		{
			var s_crs: String = metadata.crs as String;
			var  bbox: BBox = metadata.bbox as BBox;
			var  url: URLRequest = metadata.url;
			
			var s_key: String = getKey(s_crs, bbox, url, metadata.validity);
			return md_cache[s_key] || md_cacheLoading[s_key];
		}
		
//		public function getCacheItem(s_crs: String, bbox: BBox, url: URLRequest): CacheItem
		public function getCacheItem(metadata: CacheItemMetadata): CacheItem
		{
			var s_crs: String = metadata.crs as String;
			var  bbox: BBox = metadata.bbox as BBox;
			var  url: URLRequest = metadata.url;
			
			var s_key: String = getKey(s_crs, bbox, url, metadata.validity);
			if(s_key in md_cache) {
				var item: CacheItem = md_cache[s_key] as CacheItem; 
				item.lastUsed = new Date();
				item.displayed = true;
				return item;
			}
			return null;
			
		}
//		public function getCacheItemBitmap(s_crs: String, bbox: BBox, url: URLRequest): Bitmap
		public function getCacheItemBitmap(metadata: CacheItemMetadata): Bitmap
		{
			var item: CacheItem = getCacheItem(metadata);
			if (item)
				return item.image;
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
		public function startImageLoading(s_crs: String, bbox: BBox, url: URLRequest, validity: Date = null): void
		{
			var s_key: String = getKey(s_crs, bbox, url, validity);
			
			md_cacheLoading[s_key] = true;
		}
		
//		public function addCacheItem(img: Bitmap, s_crs: String, bbox: BBox, url: URLRequest, associatedCacheData: Object = null): void
		public function addCacheItem(img: Bitmap, metadata: CacheItemMetadata): void
		{
			var s_crs: String = metadata.crs as String;
			var  bbox: BBox = metadata.bbox as BBox;
			var  url: URLRequest = metadata.url;
			var  validity: Date = metadata.validity;
			
			var ck: WMSCacheKey = new WMSCacheKey(s_crs, bbox, url, validity);
			var s_key: String = getKey(s_crs, bbox, url, validity);
			
			var b_deleted: Boolean = deleteCacheItemByKey(s_key, true);
			
			var item: CacheItem = new CacheItem();
			item.cacheKey = ck;
			item.displayed = true;
			item.lastUsed = new Date();
			item.image = img;
			
			md_cache[s_key] = item;
			mi_cacheItemCount++;
			debugCache();
			
			delete md_cacheLoading[s_key];
		}
		
		public function debugCache(): String
		{
			var str: String = 'WMSCache';
			str += '\t cache items count: ' + mi_cacheItemCount;
			
			var cnt: int = 0;
			for(var s_key: String in md_cache) 
			{
				cnt++;
			}
			str += '\t cache items count [dictionary]: ' + cnt;
			
			return str;
		}

		public function removeFromScreen(): void
		{
			debug("WMSCache.removeFromScreen(): WMS CACHE removeFromScreen");
			for(var s_key: String in md_cache) 
			{
				debug("\t WMS CACHE removeFromScreen key: " + s_key);
				var item: CacheItem = md_cache[s_key] as CacheItem; 
				
				if (!item.isImageOnDisplayList()) 
				{
					item.displayed = false;
				} else {
					debug("WMSCache.removeFromScreen(): ATTENTION image is on displayList");
				}
			}
		}
		
		public function invalidate(s_crs: String, bbox: BBox, validity: Date = null): void
		{
			debug("WMSCache.invalidate(): WMS CACHE invalidate s_crs: " + s_crs + " bbox : " + bbox);
			
			var a: Array = [];
			for(var s_key: String in md_cache) 
			{
				var item: CacheItem = md_cache[s_key] as CacheItem; 
				if (!item.isImageOnDisplayList())
				{
					var ck: WMSCacheKey = item.cacheKey as WMSCacheKey; 
					item.displayed = false;
					if(ck.crs == s_crs && ck.bbox.equals(bbox))
						a.push(s_key);
				} else {
					debug("WMSCache.invalidate(): ATTENTION iamge is on displayList");
				}
			}
			for each(s_key in a) {
//				debug("WMSCache.invalidate(): removing image with key: " + md_cache[s_key].toString());
				deleteCacheItemByKey(s_key);
			}
			debugCache();
		}

		private function debug(str: String): void
		{
			return;
			trace(str);
		}
	}
}
