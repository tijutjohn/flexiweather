package com.iblsoft.flexiweather.ogc.cache.event
{
	import com.iblsoft.flexiweather.ogc.cache.CacheItem;
	
	import flash.events.Event;

	public class WMSCacheEvent extends Event
	{
		public static const ITEM_ADDED: String = 'itemAdded';
		public static const BEFORE_DELETE: String = 'beforeDelete';
		
		public var item: CacheItem;

		public var associatedData: Object;
		
		public function WMSCacheEvent(type: String, cacheItem: CacheItem, bubbles: Boolean = false, cancelable: Boolean = false)
		{
			super(type, bubbles, cancelable);
			item = cacheItem;
		}

		override public function clone(): Event
		{
			return new WMSCacheEvent(type, item);
		}
	}
}
