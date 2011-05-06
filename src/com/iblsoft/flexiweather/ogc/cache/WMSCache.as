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
		 * Expiration time in seconds 
		 */		
		private var _checkExpirationTime: int = 10 * 1000; 
		private var _expirationTime: int = 60; 
		private var _expirationTimer: Timer;
		
		private var _animationModeEnabled: Boolean;
		
		private var md_cache_length: int = 0;
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
				var cacheItem: CacheItem = md_cache[s_key] as CacheItem;
				
				var lastUsed: Date = cacheItem.lastUsed as Date;
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
			debugCache();
		}
		
		private function deleteCacheItem(s_key: String): void
		{
//			return;
			
			var cacheItem: CacheItem = md_cache[s_key] as CacheItem;
			
			
			//dispose bitmap data, just for bitmaps which are not currently displayed
			if (!cacheItem.displayed)
			{
//				trace("\t deleteCacheItem " + cacheItem);
				var bmp: Bitmap = cacheItem.image;
			
				bmp.bitmapData.dispose();
				md_cache_length--;
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
				var item: CacheItem = md_cache[s_key] as CacheItem; 
				item.lastUsed = new Date();
				item.displayed = true;
				return item.image;
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
			
			var item: CacheItem = new CacheItem();
			item.cacheKey = ck;
			item.displayed = true;
			item.lastUsed = new Date();
			item.image = img;
			
			md_cache[s_key] = item;
			md_cache_length++;
			debugCache();
			
			delete md_cache_loading[s_key];
		}
		
		private function debugCache(): void
		{
//			trace("WMSCache ["+name+"] items: " + md_cache_length);
		}
		public function removeFromScreen(): void
		{
			for(var s_key: String in md_cache) 
			{
				var item: CacheItem = md_cache[s_key] as CacheItem; 
				item.displayed = false;
			}
		}
		
		public function invalidate(s_crs: String, bbox: BBox): void
		{
			var a: Array = [];
			for(var s_key: String in md_cache) 
			{
				var item: CacheItem = md_cache[s_key] as CacheItem; 
				var ck: WMSCacheKey = item.cacheKey; 
				item.displayed = false;
				if(ck.ms_crs == s_crs && ck.m_bbox.equals(bbox))
					a.push(s_key);
			}
			for each(s_key in a) {
	//			trace("WMSCache.invalidate(): removing image with key: " + md_cache[s_key].toString());
				deleteCacheItem(s_key);
			}
			debugCache();
		}

	}
}
import com.iblsoft.flexiweather.ogc.cache.WMSCacheKey;

import flash.display.Bitmap;

import mx.messaging.AbstractConsumer;

class CacheItem
{
	public static var CID: int = 0;
	
	private var _id: int;
	
	public var cacheKey: WMSCacheKey;
	public var lastUsed: Date;
	public var image: Bitmap;
	
	private var _displayed: Boolean;
	public function get displayed():Boolean 
	{
//		trace(this + " GET displayed = " + _displayed);
		return _displayed;
	}
	
	public function set displayed(value:Boolean):void 
	{
		_displayed = value;
//		trace(this + " SET displayed = " + _displayed);
	}
	
	public function CacheItem()
	{
		CID++;
		_id = CID
//		trace("New " + this);
	}
	
	public function toString(): String
	{
		return "CacheItem " + _id;
	}
		
}