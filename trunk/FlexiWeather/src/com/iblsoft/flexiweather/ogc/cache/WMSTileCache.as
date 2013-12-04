package com.iblsoft.flexiweather.ogc.cache
{
	import com.iblsoft.flexiweather.ogc.BBox;
	import com.iblsoft.flexiweather.ogc.cache.event.WMSCacheEvent;
	import com.iblsoft.flexiweather.ogc.data.viewProperties.IViewProperties;
	import com.iblsoft.flexiweather.ogc.data.viewProperties.TiledTileViewProperties;
	import com.iblsoft.flexiweather.ogc.data.viewProperties.TiledViewProperties;
	import com.iblsoft.flexiweather.ogc.tiling.TileIndex;
	import com.iblsoft.flexiweather.ogc.tiling.TiledArea;
	import com.iblsoft.flexiweather.plugins.IConsole;
	import com.iblsoft.flexiweather.utils.ISO8601Parser;
	
	import flash.display.Bitmap;
	import flash.display.DisplayObject;
	import flash.events.TimerEvent;
	import flash.geom.Matrix;
	import flash.geom.Point;
	import flash.net.URLRequest;
	import flash.text.TextField;
	import flash.text.TextFormat;
	import flash.utils.Dictionary;
	import flash.utils.Timer;

	public class WMSTileCache extends WMSCache
	{
		private static var _uid: int = 0;
		public static var debugConsole: IConsole;
		public var maxCachedItems: int = 900;
		/**
		 * Expiration check interval. How ofter will be expiration checked
		 */
		private var _checkExpirationTime: int = 10 * 1000;
		/**
		 * Expiration time. How long will tile be valid (in seconds).
		 * Value "0" means no expiration will be done.
		 */
		private var _expirationTime: int = 0;
		private var _expirationTimer: Timer;
		private var _animationModeEnabled: Boolean;
		private var _itemCount: int = 0;
		private var _items: Array = [];

		public function get cachedTilesCount(): int
		{
			return _items.length;
		}
		private var _id: int;

		public function WMSTileCache()
		{
			_uid++;
			_id = _uid;
			startExpirationTimer();
		}

		override public function destroyCache(): void
		{
			super.destroyCache();
			_items = null;
		}

		private function startExpirationTimer(): void
		{
			if (_expirationTime > 0)
			{
				_expirationTimer = new Timer(_checkExpirationTime);
				_expirationTimer.addEventListener(TimerEvent.TIMER, onExpiration);
				_expirationTimer.start();
			}
		}

		override public function debugCache(): String
		{
			var str: String = 'WMSTileCache [' + _id + ']';
			str += '\t cache items count: ' + _itemCount;
			var cnt: int = 0;
			for (var s_key: String in md_cache)
			{
				cnt++;
				str += '\t\t cache key: ' + s_key;
			}
			str += '\t cache items count [dictionary]: ' + cnt;
			return str;
		}

		private function onExpiration(event: TimerEvent): void
		{
			if (_animationModeEnabled || _expirationTime == 0)
			{
				//do not remove any cached data, animation is running or expirationTime is set to 0
				return;
			}
			var currTime: Date = new Date();
			for (var s_key: String in md_cache)
			{
				var obj: CacheItem = md_cache[s_key] as CacheItem;
				var lastUsed: Date = obj.lastUsed as Date;
				if (lastUsed)
				{
					var diff: Number = currTime.time - lastUsed.time;
					if (diff > (_expirationTime * 1000))
					{
						debug("TILE from cache is expired, will be removed");
						if (!isTileOnDisplayList(s_key))
							deleteCacheItemByKey(s_key);
						else
							debug("TILE IS DISPLAY LIST, DO NOT DELETE IT");
					}
					debug("diff: " + diff);
				}
			}
		}

		private function isTileOnDisplayList(s_key: String): Boolean
		{
			var item: CacheItem = md_cache[s_key] as CacheItem;
			var bitmap: Bitmap = item.image as Bitmap;
			return (bitmap.parent != null);
		}

		override public function getCacheItem(viewProperties: IViewProperties): CacheItem
		{
			var qttTileViewProperties: TiledTileViewProperties = viewProperties as TiledTileViewProperties;
			if (!qttTileViewProperties)
				return null;
			var s_key: String = getQTTTileViewCacheKey(qttTileViewProperties);
			return md_cache[s_key] as CacheItem;
		}

		/**
		 * Function return all cached tiles with same CRS and tileZoom and specialString (e.g. same RUN and FORECAST)
		 * @param s_crs
		 * @param i_tileZoom
		 * @param specialStrings
		 * @return
		 *
		 */
		public function getTiles(s_crs: String, i_tileZoom: String, specialStrings: Array, validity: Date): Array
		{
//			trace("getTiles for crs: " + s_crs + " zoom: " + i_tileZoom + " specialStrinds: " + specialStrings + " validity: " + validity);
//			trace("getTiles cache size: " + cachedTilesCount);
			
			var a: Array = [];
			
			for each (var cacheRecord: CacheItem in md_cache)
			{
				var cacheKey: WMSTileCacheKey = cacheRecord.cacheKey as WMSTileCacheKey;
				if (cacheKey.m_tileIndex == null)
					continue;
				if (cacheKey.crs != s_crs)
					continue;
				if (cacheKey.validity && validity && cacheKey.validity.time != validity.time)
					continue;
//				if (cacheKey.validity)
//					trace("getTiles ["+cacheKey.m_tileIndex+"]: validity" + cacheKey.validity.toString()); 
				if (!cacheKey.validity && validity)
					continue;
				if (cacheKey.m_tileIndex.mi_tileZoom != i_tileZoom)
					continue;
				if (specialStrings && specialStrings.length > 0)
				{
					var key: String = decodeURI(cacheKey.toString());
					var specialStringInside: Boolean = true;
					var keyParts: Array = key.split('|');
					var specialStringsLength: int = 0;
					var specialStringsFound: int = 0;
					var currKeyPart: String
					for each (currKeyPart in specialStrings)
					{
						if (currKeyPart.indexOf("SPECIAL_") == -1)
							continue;
						specialStringsLength++;
					}
					for each (currKeyPart in keyParts)
					{
						if (currKeyPart.indexOf("SPECIAL_") == -1)
							continue;
						var id: int = specialStrings.indexOf(currKeyPart);
						if (id < 0)
						{
							specialStringInside = false;
							break;
						}
						specialStringsFound++;
					}
//					debug("getTiles specialStringsFound: " + specialStringsFound + " specialStringsLength: " + specialStringsLength);
					if (specialStringsFound != specialStringsLength)
					{
						//not all special strings were inside
						continue;
					}
					//TODO all special strings must be in key
					if (!specialStringInside)
						continue;
				}
				if (cacheKey.validity)
					debug("add tile: [" + cacheKey.m_tileIndex.toString() + "] " + cacheKey.validity.time + " last time usedL : " + cacheRecord.lastUsed)
				cacheRecord.lastUsed = new Date();
				a.push({
							tileIndex: cacheKey.m_tileIndex,
							image: cacheRecord.image,
							cacheKey: cacheKey
						});
			}
//			debug("GET TILES: " + a.length);
			testingTilesValidity(a)
			return a;
		}
		
		private function testingTilesValidity(tiles: Array): void
		{
			var validity: Date;
			for each (var tile: Object in tiles){
				var tileIndex: TileIndex = tile.tileIndex as TileIndex;
				var cacheKey: WMSTileCacheKey = tile.cacheKey as WMSTileCacheKey;
				if (!validity)
					validity = cacheKey.validity;
				else {
					if (validity.time != cacheKey.validity.time)
					{
						trace("WMSTileCache wrong validity: ");
					}
				}
				
			}
		}

		override public function getItemCacheKey(viewProperties: IViewProperties): String
		{
			var qttTileViewProperties: TiledTileViewProperties = viewProperties as TiledTileViewProperties;
			if (!qttTileViewProperties)
				return null;
			
			return getQTTTileViewCacheKey(qttTileViewProperties);
		}
		
		private function getQTTTileViewCacheKey(qttTileViewProperties: TiledTileViewProperties): String
		{
//			var parentQTT: TiledViewProperties = qttTileViewProperties.qttViewProperties;
//			var s_crs: String = parentQTT.crs as String;
//			var time: Date = parentQTT.validity;
//			var specialStrings: Array = parentQTT.specialCacheStrings as Array;
			var s_crs: String = qttTileViewProperties.crs as String;
			var time: Date = qttTileViewProperties.validity;
			var specialStrings: Array = qttTileViewProperties.specialCacheStrings as Array;
			
			var tileIndex: TileIndex = qttTileViewProperties.tileIndex as TileIndex;
			var url: URLRequest = qttTileViewProperties.url;
			var ck: WMSTileCacheKey = new WMSTileCacheKey(s_crs, null, tileIndex, url, time, specialStrings);
			var s_key: String = ck.toString();
			return s_key;
		}

		override public function isNoDataItemCached(viewProperties: IViewProperties): Boolean
		{
			var qttTileViewProperties: TiledTileViewProperties = viewProperties as TiledTileViewProperties;
			if (!qttTileViewProperties)
				return false;
			var s_key: String = getQTTTileViewCacheKey(qttTileViewProperties);
			var isCached: Boolean = md_noDataCache[s_key] == true;
			return isCached;
		}

		/**
		 * function will notify cache that image is loading, but not loaded yet.
		 * It will be used for not to load same request ,if it is already loaing.
		 * @param s_crs
		 * @param bbox
		 * @param url
		 *
		 */
		override public function startImageLoading(viewProperties: IViewProperties): void
		{
			var qttTileViewProperties: TiledTileViewProperties = viewProperties as TiledTileViewProperties;
			if (!qttTileViewProperties)
				return;
			var s_key: String = getQTTTileViewCacheKey(qttTileViewProperties);
			
			debug(this + " start iamge loading: " + s_key);
			md_cacheLoading[s_key] = true;
			mi_cacheLoadingItemsLength++;
		}
		
		/**
		 * Function needs to be called when item loading is cancelled 
		 * @param viewProperties
		 * 
		 */		
		override public function cacheItemLoadingCanceled(viewProperties: IViewProperties): void
		{
			if (!supportCaching)
				return;
			
			var qttTileViewProperties: TiledTileViewProperties = viewProperties as TiledTileViewProperties;
			if (!qttTileViewProperties)
				return;
			
			var s_key: String = getQTTTileViewCacheKey(qttTileViewProperties);
			
			
			delete md_cacheLoading[s_key];
			mi_cacheLoadingItemsLength--;
			mi_noDataCacheItemsLength--;
			
			trace(this + "cacheItemLoadingCanceled: " + s_key);
		}
		
		override public function addCacheNoDataItem(viewProperties: IViewProperties): void
		{
			var qttTileViewProperties: TiledTileViewProperties = viewProperties as TiledTileViewProperties;
			if (!qttTileViewProperties)
				return;
			var s_key: String = getQTTTileViewCacheKey(qttTileViewProperties);
			md_noDataCache[s_key] = true;
			mi_noDataCacheItemsLength++;
		}
			
		override public function isItemCached(viewProperties: IViewProperties, b_checkNoDataCache: Boolean = true): Boolean
		{
			var qttTileViewProperties: TiledTileViewProperties = viewProperties as TiledTileViewProperties;
			if (!qttTileViewProperties)
				return false;
			var s_key: String = getQTTTileViewCacheKey(qttTileViewProperties);
			var item: CacheItem = md_cache[s_key] as CacheItem;
			debug("isTileCached check  for null: " + (item != null) + " KEY: " + s_key);
			var bItemCached: Boolean = item != null || md_cacheLoading[s_key];
			if (b_checkNoDataCache && !bItemCached)
			{
				//check also NoData cache
				return isNoDataItemCached(qttTileViewProperties);
			}
			return bItemCached;
		}

		override public function addCacheItem(img: DisplayObject, viewProperties: IViewProperties, associatedData: Object): void
		{
			var qttTileViewProperties: TiledTileViewProperties = viewProperties as TiledTileViewProperties;
			if (!qttTileViewProperties)
				return;
			
			var s_crs: String = qttTileViewProperties.crs as String;
			var bbox: BBox = qttTileViewProperties.getViewBBox() as BBox;
			var time: Date = qttTileViewProperties.validity;
			var tiledAreas: Array = qttTileViewProperties.tiledAreas;
			var specialStrings: Array = qttTileViewProperties.specialCacheStrings;
			
			var url: URLRequest = qttTileViewProperties.url;
			var tileIndex: TileIndex = qttTileViewProperties.tileIndex;
			
			var ck: WMSTileCacheKey = new WMSTileCacheKey(s_crs, null, tileIndex, url, time, specialStrings);
			var s_key: String = decodeURI(ck.toString());
			var item: CacheItem = new CacheItem();
			item.viewProperties = qttTileViewProperties;
			item.cacheKey = ck as CacheKey;
			item.displayed = true;
			item.lastUsed = new Date();
			/**
			 * if you want add DEbug information about validity of cached bitmap uncomment next 2 lines
			 */
			//updateImage(img as Bitmap, metadata.validity, 0x000000, 20,20);
			//updateImage(img as Bitmap, metadata.validity, 0xffffff, 21,21);
			//updateImage(img as Bitmap, tileIndex.toString(), 0x000000, 20,20);
			//updateImage(img as Bitmap ,tileIndex.toString(), 0xffffff, 21,21);
			item.image = img;
			/**
			 * we need to delete cache item with same "key" before we add new item.
			*/
			var bWasDeleted: Boolean = deleteCacheItemByKey(s_key, true);
			
			//add item to cache
			md_cache[s_key] = item;
			_items.push(s_key);
			
			mi_cacheItemCount++;
			
			var wce: WMSCacheEvent = new WMSCacheEvent(WMSCacheEvent.ITEM_ADDED, item, true);
			wce.associatedData = associatedData;
			dispatchEvent(wce);
			
			delete md_cacheLoading[s_key];
			mi_cacheLoadingItemsLength--;
			
//			trace(this + "add item: " + s_key);
//			trace(this + "delete from loading items: " + s_key);
			
			if (_items.length > maxCachedItems)
			{
				for each (var tiledAreaObj: Object in tiledAreas)
				{
					var tiledArea: TiledArea = tiledAreaObj.tiledArea as TiledArea;
					s_key = getCachedTileKeyOutsideTiledArea(tiledArea);
					bWasDeleted = deleteCacheItemByKey(s_key);
				}
			}
		}

		/**
		 * This debug function for adding text to tiles for debugging purposes
		 * @param img
		 * @param text
		 * @param clr
		 * @param x
		 * @param y
		 *
		 */
		private function updateImage(img: Bitmap, text: String, clr: uint, x: int, y: int): void
		{
			//debug
			var txt: TextField = new TextField();
			txt.text = text;
			var frm: TextFormat = txt.getTextFormat();
			frm.size = 20;
			frm.color = clr;
			txt.setTextFormat(frm);
			if (img is Bitmap)
			{
				var m: Matrix = new Matrix();
				m.translate(x, y);
				(img as Bitmap).bitmapData.draw(txt, m);
			}
		}

		override public function deleteCacheItemByKey(s_key: String, b_disposeDisplayed: Boolean = false): Boolean
		{
			var cacheItem: CacheItem = md_cache[s_key] as CacheItem;
			// dispose bitmap data, just for bitmaps which are not currently displayed
			if (cacheItem && (!cacheItem.displayed || (cacheItem.displayed && b_disposeDisplayed)))
			{
				notifyBitmapDelete(cacheItem);
				
				disposeTileBitmap(s_key);
				cacheItem.destroy();
				cacheItem = null;
				mi_cacheItemCount--;
				delete md_cache[s_key];
				return true;
			}
			return false;
		}
		private var _tiledArea: TiledArea;
		private var _tiledAreaCenter: Point;

		public function sortCache(tiledArea: TiledArea): void
		{
			return;
			if (tiledArea)
			{
				_tiledArea = tiledArea;
				_tiledAreaCenter = _tiledArea.center;
				_items.sort(sortTileKeys);
//				debug(_items);
			}
		}

		private function sortTileKeys(tileKey1: String, tileKey2: String): int
		{
			var tileIndex1: TileIndex = TileIndex.createTileIndexFromString(tileKey1);
			var tileIndex2: TileIndex = TileIndex.createTileIndexFromString(tileKey2);
			var dist1: Number = Point.distance(_tiledAreaCenter, new Point(tileIndex1.mi_tileCol, tileIndex1.mi_tileRow))
			var dist2: Number = Point.distance(_tiledAreaCenter, new Point(tileIndex1.mi_tileCol, tileIndex1.mi_tileRow))
//			debug(dist1 + "  , " + dist2);
//			debug(tileIndex1 + "  , " + tileIndex2);
			if (dist1 > dist1)
				return -1
			else
			{
				if (dist1 < dist1)
					return 1;
			}
			return 0;
		}

		private function getCachedTileKeyOutsideTiledArea(tiledArea: TiledArea): String
		{
			var total: int = _items.length;
			for (var i: int = 0; i < total; i++)
			{
				var key: String = _items[i] as String;
				if (tiledArea.isTileOutside(TileIndex.createTileIndexFromString(key)))
				{
					//key is outside, return it
					_items.splice(key, 1);
					return key;
				}
			}
			return _items.shift();
		}

		private function disposeTileBitmap(s_key: String): void
		{
			var item: CacheItem = md_cache[s_key] as CacheItem;
			if (item)
			{
				if (item.image is Bitmap)
				{
					var img: Bitmap = item.image as Bitmap;
					img.bitmapData.dispose();
				}
				else
				{
					//FIXME dispose tile if it's not bitmap (e.g. AVM1Movie)
				}
			}
		}

		override public function invalidate(s_crs: String, bbox: BBox, validity: Date = null): void
		{
			var a: Array = [];
			for (var s_key: String in md_cache)
			{
				var ck: WMSTileCacheKey = (md_cache[s_key] as CacheItem).cacheKey as WMSTileCacheKey;
//				if(ck.ms_crs == s_crs && ck.m_bbox.equals(bbox))
				var needToRemoveItem: Boolean = ck.crs == s_crs && ck.bbox == bbox;
				if (validity)
					needToRemoveItem = needToRemoveItem && validity == ck.validity;
				needToRemoveItem = needToRemoveItem && isTileOnDisplayList(s_key);
				if (needToRemoveItem)
					a.push(s_key);
			}
			for each (s_key in a)
			{
				var id: int = _items.indexOf(s_key);
				if (id >= 0)
					_items.splice(id, 1);
				debug("WMSCache.invalidate(): removing image with key: " + md_cache[s_key].toString());
				debug("WMSCache.invalidate(): removing image with key: " + s_key + " cache tiles count: " + cachedTilesCount);
				deleteCacheItemByKey(s_key);
			}
			debug("\n invalidate cache tiles count: " + cachedTilesCount);
		}

		protected function debug(txt: String): void
		{
//			trace("WMSTileCache: " + txt);
			if (debugConsole)
				debugConsole.print("WMSTileCache: " + txt, 'Info', 'WMSTileCache');
		}
		
		override public function toString(): String
		{
			return "WMSTileCache: | len: " + length + " | noData len: " + noDataItemsLengths + " | loading len: " + loadingItemsLength + " | >> ";
		}
	}
}
