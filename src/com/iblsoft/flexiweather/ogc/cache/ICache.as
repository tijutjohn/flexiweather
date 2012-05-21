package com.iblsoft.flexiweather.ogc.cache
{
	import com.iblsoft.flexiweather.ogc.BBox;
	import com.iblsoft.flexiweather.ogc.data.IViewProperties;
	
	import flash.display.Bitmap;
	import flash.display.DisplayObject;
	import flash.net.URLRequest;
	
	public interface ICache
	{
		/**
		 * Debug function for getting information about cache 
		 * @return 
		 * 
		 */		
		function debugCache(): String;
		
		/**
		 * Clear whole cache 
		 * 
		 */		
		function clearCache(): void;
		
		function setAnimationModeEnable(value: Boolean): void;
		function invalidate(s_crs: String, bbox: BBox, validity: Date = null): void;
		
		function addCacheItem(img: DisplayObject, viewProperties: IViewProperties): void

		function deleteCacheItem(cacheItem: CacheItem, b_disposeDisplayed: Boolean = false): Boolean
		function deleteCacheItemByKey(s_key: String, b_disposeDisplayed: Boolean = false): Boolean
			
		function isItemCached(viewProperties: IViewProperties): Boolean;
		
		function getCacheItemsCount(): int;
		function getCacheItems(): Array;
		
		function getCacheItem(viewProperties: IViewProperties): CacheItem;
		function getCacheItemBitmap(viewProperties: IViewProperties): DisplayObject;
	}
}