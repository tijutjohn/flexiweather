package com.iblsoft.flexiweather.ogc.cache
{
	import com.iblsoft.flexiweather.ogc.BBox;
	
	import flash.display.Bitmap;
	import flash.net.URLRequest;
	
	public interface ICache
	{
		/**
		 * Debug function for getting information about cache 
		 * @return 
		 * 
		 */		
		function debugCache(): String;
		
		function setAnimationModeEnable(value: Boolean): void;
		function invalidate(s_crs: String, bbox: BBox): void;
		
//		function addCacheItem(img: Bitmap, s_crs: String, bbox: BBox, url: URLRequest, associatedCacheData: Object = null): void
		function addCacheItem(img: Bitmap, metadata: CacheItemMetadata): void

		function deleteCacheItem(cacheItem: CacheItem, b_disposeDisplayed: Boolean = false): Boolean
		function deleteCacheItemByKey(s_key: String, b_disposeDisplayed: Boolean = false): Boolean
			
		function isItemCached(metadata: CacheItemMetadata): Boolean;
		
		function getCacheItemsCount(): int;
		function getCacheItems(): Array;
		
		function getCacheItem(metadata: CacheItemMetadata): CacheItem;
		function getCacheItemBitmap(metadata: CacheItemMetadata): Bitmap;
	}
}