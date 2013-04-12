package com.iblsoft.flexiweather.ogc.cache
{
	import com.iblsoft.flexiweather.ogc.BBox;
	import com.iblsoft.flexiweather.ogc.data.viewProperties.IViewProperties;
	
	import flash.display.Bitmap;
	import flash.display.DisplayObject;
	import flash.events.IEventDispatcher;
	import flash.net.URLRequest;

	public interface ICache extends IEventDispatcher
	{
		/**
		 * Debug function for getting information about cache
		 * @return
		 *
		 */
		function debugCache(): String;
		function destroyCache(): void;
		/**
		 * Clear whole cache
		 *
		 */
		function clearCache(): void;
		function setAnimationModeEnable(value: Boolean): void;
		function invalidate(s_crs: String, bbox: BBox, validity: Date = null): void;
		function addCacheNoDataItem(viewProperties: IViewProperties): void;
		function addCacheItem(img: DisplayObject, viewProperties: IViewProperties, associatedData: Object): void;
		function deleteCacheItem(cacheItem: CacheItem, b_disposeDisplayed: Boolean = false): Boolean;
		function deleteCacheItemByKey(s_key: String, b_disposeDisplayed: Boolean = false): Boolean;
		function getItemCacheKey(viewProperties: IViewProperties): String;			
		function isItemCached(viewProperties: IViewProperties, b_checkNoDataCache: Boolean = false): Boolean;
		function cacheItemLoadingCanceled(viewProperties: IViewProperties): void;
		function get length(): uint;
		function getCacheItems(): Array;
		function getCacheItem(viewProperties: IViewProperties): CacheItem;
		function getCacheItemBitmap(viewProperties: IViewProperties): DisplayObject;
	}
}
