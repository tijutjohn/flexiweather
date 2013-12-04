package com.iblsoft.flexiweather.ogc.cache
{
	import com.iblsoft.flexiweather.ogc.BBox;
	import com.iblsoft.flexiweather.ogc.cache.event.WMSCacheEvent;
	import com.iblsoft.flexiweather.ogc.data.viewProperties.IViewProperties;
	import com.iblsoft.flexiweather.ogc.data.viewProperties.WMSViewProperties;
	
	import flash.display.Bitmap;
	import flash.display.DisplayObject;
	import flash.events.EventDispatcher;
	import flash.events.TimerEvent;
	import flash.net.URLRequest;
	import flash.utils.Dictionary;
	import flash.utils.Timer;

	public class WMSCache extends EventDispatcher implements ICache
	{
		public static var supportCaching: Boolean = true;
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
		
		protected var md_cache: Dictionary = new Dictionary();
		protected var md_noDataCache: Dictionary = new Dictionary();
		protected var md_cacheLoading: Dictionary = new Dictionary();
		
		protected var mi_cacheItemCount: int = 0;
		protected var mi_noDataCacheItemsLength: int = 0;
		protected var mi_cacheLoadingItemsLength: int = 0;
		
		public function get length(): uint
		{
			return mi_cacheItemCount;			
		}
		public function get noDataItemsLengths(): int
		{
			return mi_noDataCacheItemsLength;			
		}
		public function get loadingItemsLength(): int
		{
			return mi_cacheLoadingItemsLength;			
		}

		public function clearCache(): void
		{
			for each (var cacheItem: CacheItem in md_cache)
			{
				deleteCacheItem(cacheItem, true);
			}
			for (var s_key: String in md_noDataCache)
			{
				if (md_noDataCache[s_key])
				{
					delete md_noDataCache[s_key];
					mi_noDataCacheItemsLength--;
				}
			}
		}

		public function WMSCache()
		{
			startExpirationTimer();
		}

		public function destroyCache(): void
		{
			if (m_expirationTimer)
			{
				m_expirationTimer.stop();
				m_expirationTimer.removeEventListener(TimerEvent.TIMER, onExpiration);
				m_expirationTimer = null;
			}
			clearCache();
			var cnt: int = 0;
			var obj: Object
			for each (obj in md_cache)
			{
				cnt++;
			}
			for each (obj in md_noDataCache)
			{
				cnt++;
			}
			for each (obj in md_cacheLoading)
			{
				cnt++;
			}
			md_cache = null;
			md_noDataCache = null;
			md_cacheLoading = null;
			
			mi_cacheItemCount = 0;
			mi_cacheLoadingItemsLength = 0;
			mi_noDataCacheItemsLength = 0;
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
				_animationModeEnabled = value;
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
							deleteCacheItemByKey(s_key);
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
				return deleteCacheItemByKey(cacheItem.cacheKey.key, b_disposeDisplayed);
			return false;
		}

		protected function notifyBitmapDelete(cacheItem: CacheItem): void
		{
			dispatchEvent( new WMSCacheEvent(WMSCacheEvent.BEFORE_DELETE, cacheItem, true) );
		}
		/**
		 * Delete cached item
		 *
		 * @param s_key Item key
		 * @param b_disposeDisplayed dispose item even if it is displayed. Default value is false, because we do not want dispose displayed items, but you can force it by setting this property to true (e.g. receiving data for same CRS and BBox)
		 * @return true if item was deleted, false if it was not
		 *
		 */
		public function deleteCacheItemByKey(s_key: String, b_disposeDisplayed: Boolean = false): Boolean
		{
			var cacheItem: CacheItem = md_cache[s_key] as CacheItem;
			// dispose bitmap data, just for bitmaps which are not currently displayed
			if (cacheItem && (!cacheItem.displayed || (cacheItem.displayed && b_disposeDisplayed)))
			{
				
				notifyBitmapDelete(cacheItem);
				if (cacheItem.image is Bitmap)
				{
//					debug("\t deleteCacheItem " + cacheItem);
					var bmp: Bitmap = cacheItem.image as Bitmap;
					bmp.bitmapData.dispose();
				}
				else
				{
					//FIXME deleteCacheItemByKey - delete tile if it's not bitmap (e.g. AVM1Movie)
				}
				cacheItem.destroy();
				delete md_cache[s_key];
				mi_cacheItemCount--;
				return true;
			}
			else
			{
//				debug("\t deleteCacheItem: DO NOT DELETE IT " + cacheItem);
			}
			return false;
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

		public function getItemCacheKey(viewProperties: IViewProperties): String
		{
			var wmsViewProperties: WMSViewProperties = viewProperties as WMSViewProperties;
			if (!wmsViewProperties)
				return null;
			
			return qetWMSViewCacheKey(wmsViewProperties);
		}
		
		private function getKey(s_crs: String, bbox: BBox, url: URLRequest, dimensions: Array, validity: Date = null, wmsViewProperties: WMSViewProperties = null): String
		{
			var ck: WMSCacheKey = new WMSCacheKey(s_crs, bbox, url, dimensions, validity, wmsViewProperties.m_cfg.wmsService.baseURL);
			var s_key: String = ck.toString();
			return s_key;
		}

		private function qetWMSViewCacheKey(wmsViewProperties: WMSViewProperties): String
		{
			var s_crs: String = wmsViewProperties.crs as String;
			var bbox: BBox = wmsViewProperties.getViewBBox() as BBox;
			var url: URLRequest = wmsViewProperties.url;
			var dimensions: Array = wmsViewProperties.dimensions;
			var validity: Date = wmsViewProperties.validity;
			var s_key: String = getKey(s_crs, bbox, url, dimensions, validity, wmsViewProperties);
			return s_key;
		}

		public function isNoDataItemCached(viewProperties: IViewProperties): Boolean
		{
			var wmsViewProperties: WMSViewProperties = viewProperties as WMSViewProperties;
			if (!wmsViewProperties)
				return false;
			var s_key: String = qetWMSViewCacheKey(wmsViewProperties);
			return (md_noDataCache && md_noDataCache[s_key] == true);
		}

		/**
		 * Function just check if this item is currently loading and not if it is cached.
		 * @param viewProperties
		 * @param b_checkNoDataCache
		 * @return
		 *
		 */
		public function isItemLoading(viewProperties: IViewProperties, b_checkNoDataCache: Boolean = false): Boolean
		{
			var wmsViewProperties: WMSViewProperties = viewProperties as WMSViewProperties;
			if (!wmsViewProperties)
				return false;
			var s_key: String = qetWMSViewCacheKey(wmsViewProperties);
			if (b_checkNoDataCache)
			{
				if (md_noDataCache && md_noDataCache[s_key])
					return true;
			}
			return md_cacheLoading[s_key];
		}

		public function isItemCached(viewProperties: IViewProperties, b_checkNoDataCache: Boolean = false): Boolean
		{
			var wmsViewProperties: WMSViewProperties = viewProperties as WMSViewProperties;
			if (!wmsViewProperties)
				return false;
			var s_key: String = qetWMSViewCacheKey(wmsViewProperties);
			if (b_checkNoDataCache)
			{
				if (md_noDataCache && md_noDataCache[s_key])
					return true;
			}
			
//			var temp: String = debugCache();
//			trace("isItemCached for " + s_key);
//			trace(temp);
			
			return md_cache[s_key] || md_cacheLoading[s_key];
		}

		public function getCacheItem(viewProperties: IViewProperties): CacheItem
		{
			var wmsViewProperties: WMSViewProperties = viewProperties as WMSViewProperties;
			if (!wmsViewProperties)
				return null;
			var s_key: String = qetWMSViewCacheKey(wmsViewProperties);
			if (s_key in md_cache)
			{
				var item: CacheItem = md_cache[s_key] as CacheItem;
				item.lastUsed = new Date();
				item.displayed = true;
				return item;
			}
			return null;
		}

		public function getCacheItemBitmap(viewProperties: IViewProperties): DisplayObject
		{
			var item: CacheItem = getCacheItem(viewProperties);
			if (item)
			{
				var bmp: Bitmap = item.image as Bitmap;
				if (bmp && bmp.bitmapData)
					return new Bitmap(bmp.bitmapData.clone());
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
		public function startImageLoading(viewProperties: IViewProperties): void
		{
			var wmsViewProperties: WMSViewProperties = viewProperties as WMSViewProperties;
			if (!wmsViewProperties)
				return;
			var s_key: String = qetWMSViewCacheKey(wmsViewProperties);
			md_cacheLoading[s_key] = true;
			mi_cacheLoadingItemsLength++;
		}

		public function addCacheNoDataItem(viewProperties: IViewProperties): void
		{
			if (!supportCaching)
				return;
			var wmsViewProperties: WMSViewProperties = viewProperties as WMSViewProperties;
			if (!wmsViewProperties)
				return;
			var s_key: String = qetWMSViewCacheKey(wmsViewProperties);
			md_noDataCache[s_key] = true;
			mi_noDataCacheItemsLength++;
		}

		public function addCacheItem(img: DisplayObject, viewProperties: IViewProperties, associatedData: Object): void
		{
			if (!supportCaching)
				return;
			var wmsViewProperties: WMSViewProperties = viewProperties as WMSViewProperties;
			if (!wmsViewProperties)
				return;
			var s_crs: String = wmsViewProperties.crs as String;
			var bbox: BBox = wmsViewProperties.getViewBBox() as BBox;
			var url: URLRequest = wmsViewProperties.url;
			var dimensions: Array = wmsViewProperties.dimensions;
			var validity: Date = wmsViewProperties.validity;
			var ck: WMSCacheKey = new WMSCacheKey(s_crs, bbox, url, dimensions, validity, wmsViewProperties.m_cfg.wmsService.baseURL);
			var s_key: String = qetWMSViewCacheKey(wmsViewProperties);
			var b_deleted: Boolean = deleteCacheItemByKey(s_key, true);
			var item: CacheItem = new CacheItem();
			item.cacheKey = ck;
			item.displayed = true;
			item.lastUsed = new Date();
			item.image = img;
			
			md_cache[s_key] = item;
			mi_cacheItemCount++;
			
			debugCache();
			
			if (md_cacheLoading[s_key])
			{
				delete md_cacheLoading[s_key];
				mi_cacheLoadingItemsLength--;
//			} else {
//				trace("addCacheItem: Can not delete item from 'loading cache' for key: " + s_key);
			}
			
			var wce: WMSCacheEvent = new WMSCacheEvent(WMSCacheEvent.ITEM_ADDED, item, true);
			wce.associatedData = associatedData;
			dispatchEvent(wce);
		}

		public function cacheItemLoadingCanceled(viewProperties: IViewProperties): void
		{
			if (!supportCaching)
				return;
			
			var wmsViewProperties: WMSViewProperties = viewProperties as WMSViewProperties;
			if (!wmsViewProperties)
				return;
			
			var s_key: String = qetWMSViewCacheKey(wmsViewProperties);
			
			if (s_key && md_cacheLoading[s_key])
			{
				delete md_cacheLoading[s_key];
				mi_cacheLoadingItemsLength--;
//			} else {
//				trace("cacheItemLoadingCanceled: Can not delete item from 'loading cache' for key: " + s_key);
			}
		}
		
		public function debugCache(): String
		{
			var str: String = 'WMSCache';
			str += '\t cache items count: ' + mi_cacheItemCount;
			var cnt: int = 0;
			var keys: String = '';
			for (var s_key: String in md_cache)
			{
				cnt++;
				keys += s_key+"\n";
			}
			str += '\t cache items count [dictionary]: ' + cnt;
			str += '\n'+keys;
			return str;
		}

		public function removeFromScreen(): void
		{
			debug("WMSCache.removeFromScreen(): WMS CACHE removeFromScreen");
			for (var s_key: String in md_cache)
			{
				debug("\t WMS CACHE removeFromScreen key: " + s_key);
				var item: CacheItem = md_cache[s_key] as CacheItem;
				if (!item.isImageOnDisplayList())
					item.displayed = false;
				else
					debug("WMSCache.removeFromScreen(): ATTENTION image is on displayList");
			}
		}

		/**
		 * Remove cache items with same CRS and BBox
		 *
		 * @param s_crs
		 * @param bbox
		 * @param validity
		 *
		 */
		public function invalidate(s_crs: String, bbox: BBox, validity: Date = null): void
		{
			debug("WMSCache.invalidate(): WMS CACHE invalidate s_crs: " + s_crs + " bbox : " + bbox);
			var a: Array = [];
			for (var s_key: String in md_cache)
			{
				var item: CacheItem = md_cache[s_key] as CacheItem;
				if (!item.isImageOnDisplayList())
				{
					var ck: WMSCacheKey = item.cacheKey as WMSCacheKey;
					item.displayed = false;
					if (ck.crs == s_crs && ck.bbox.equals(bbox))
						a.push(s_key);
				}
				else
					debug("WMSCache.invalidate(): ATTENTION iamge is on displayList");
			}
			for each (s_key in a)
			{
//				debug("WMSCache.invalidate(): removing image with key: " + md_cache[s_key].toString());
				deleteCacheItemByKey(s_key);
			}
			debugCache();
		}

		private function debug(str: String): void
		{
		}
		
		override public function toString(): String
		{
			return "WMSCache: len: " + length + " noData len: " + noDataItemsLengths + " loading len: " + loadingItemsLength;
		}
	}
}
