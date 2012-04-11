package com.iblsoft.flexiweather.ogc.cache
{
	import com.iblsoft.flexiweather.ogc.BBox;
	import com.iblsoft.flexiweather.ogc.tiling.TileIndex;
	import com.iblsoft.flexiweather.ogc.tiling.TiledArea;
	import com.iblsoft.flexiweather.plugins.IConsole;
	
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
		public static var debugConsole: IConsole;
		
		public var maxCachedItems: int = 300;
		
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
		
//		protected var md_cache: Dictionary = new Dictionary();
		private var _itemCount: int = 0;
		private var _items: Array = [];
		
		public function get cachedTilesCount(): int
		{
			return _items.length;
		}
		
		public function WMSTileCache()
		{
			startExpirationTimer();
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
			var str: String = 'WMSTileCache';
			str += '\t cache items count: ' + _itemCount;
			
			var cnt: int = 0;
			for(var s_key: String in md_cache) 
			{
				cnt++;
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
				var obj: CacheItem  = md_cache[s_key] as CacheItem;
				
				var lastUsed: Date = obj.lastUsed as Date;
				if (lastUsed)
				{
					var diff: Number = currTime.time - lastUsed.time;
					if (diff > (_expirationTime * 1000))
					{
						debug("TILE from cache is expired, will be removed");
						if (!isTileOnDisplayList(s_key))
						{
							deleteCacheItemByKey(s_key);
						} else {
							debug("TILE IS DISPLAY LIST, DO NOT DELETE IT");
						}
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
		
//		public function getTile(request: URLRequest, time: Date, specialStrings: Array): CacheItem
		override public function getCacheItem(metadata: CacheItemMetadata): CacheItem
		{
			var request: URLRequest = metadata.url;
			var time: Date = metadata.validity;
			var specialStrings: Array = metadata.specialStrings as Array;
			
			var s_crs: String = request.data.CRS;
			var tileIndex: TileIndex = new TileIndex(request.data.TILEZOOM, request.data.TILEROW, request.data.TILECOL);
			
			var ck: WMSTileCacheKey = new WMSTileCacheKey(s_crs, null, tileIndex, request, time, specialStrings);
			var s_key: String = ck.toString(); 
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
		public function getTiles(s_crs: String, i_tileZoom: uint, specialStrings: Array, validity: Date): Array
		{
			var a: Array = [];
			for each(var cacheRecord: CacheItem in md_cache) 
			{
				var cacheKey: WMSTileCacheKey = cacheRecord.cacheKey as WMSTileCacheKey;
				if(cacheKey.m_tileIndex == null)
					continue;
				if(cacheKey.crs != s_crs)
					continue;
				if(cacheKey.validity && cacheKey.validity.time != validity.time)
					continue;
				if(cacheKey.m_tileIndex.mi_tileZoom != i_tileZoom)
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
					debug("add tile: ["+cacheKey.m_tileIndex.toString()+"] " + cacheKey.validity.time + " last time usedL : " + cacheRecord.lastUsed)
				cacheRecord.lastUsed = new Date();
				a.push({
					tileIndex: cacheKey.m_tileIndex,
					image: cacheRecord.image
				});
			}
			debug("GET TILES: " + a.length);
			return a;
		}
	
		
//		public function isTileCached(s_crs: String, tileIndex: TileIndex, url: URLRequest, time: Date, specialStrings: Array): Boolean
		override public function isItemCached(metadata: CacheItemMetadata): Boolean
		{
			var s_crs: String = metadata.crs as String;
			var tileIndex: TileIndex = metadata.tileIndex as TileIndex;
			var time: Date = metadata.validity;
			var specialStrings: Array = metadata.specialStrings as Array;
			var url: URLRequest = metadata.url;
			
			var ck: WMSTileCacheKey = new WMSTileCacheKey(s_crs, null, tileIndex, url, time, specialStrings);
			var s_key: String = ck.toString(); 
			var item: CacheItem =  md_cache[s_key] as CacheItem; 
			debug("isTileCached check  for null: " + (item != null) + " KEY: " + s_key);
			return item != null;			
		}
		
//		public function addTile(img: Bitmap, s_crs: String, tileIndex: TileIndex, url: URLRequest, specialStrings: Array, tiledArea: TiledArea, viewPart: BBox, time: Date): void
//		override public function addCacheItem(img: Bitmap, s_crs: String, bbox: BBox, url: URLRequest, associatedCacheData: Object = null): void
		
		override public function addCacheItem(img: DisplayObject, metadata: CacheItemMetadata): void
		{
			var s_crs: String = metadata.crs as String;
			var  bbox: BBox = metadata.bbox as BBox;
			var  url: URLRequest = metadata.url;
		
			var tileIndex: TileIndex = metadata.tileIndex;
			var specialStrings: Array = metadata.specialStrings;
			var tiledArea: TiledArea = metadata.tiledArea;
			var viewPart: BBox = metadata.viewPart;
			var time: Date = metadata.validity;
			
			var ck: WMSTileCacheKey = new WMSTileCacheKey(s_crs, null, tileIndex, url, time, specialStrings);
			var s_key: String = decodeURI(ck.toString()); 
			debug("addCacheItem: " + s_key);
			
			var item: CacheItem = new CacheItem();
			item.cacheKey = ck as CacheKey;
			item.displayed = true;
			item.lastUsed = new Date();
			
			
			updateImage(img as Bitmap, metadata.validity, 0x000000, 20,20);
			updateImage(img as Bitmap, metadata.validity, 0xffffff, 21,21);
			
			item.image = img;
			
			/**
			 * we need to delete cache item with same "key" before we add new item.
			*/
			deleteCacheItemByKey(s_key);
			
			md_cache[s_key] = item;
			
			_items.push(s_key);
			
			if (_items.length > maxCachedItems)
			{
				s_key = getCachedTileKeyOutsideTiledArea(tiledArea);
				
				debug("REMOVE TILE : " +s_key);
				
				deleteCacheItemByKey(s_key);
			}
			debug("cache item removed: " + _items.length);
		}
		
		private function updateImage(img: Bitmap, validity: Date, clr: uint, x: int, y: int): void
		{
			//debug
			var txt: TextField = new TextField();
			if (validity)
			{
				txt.text = validity.getHours() + ":"+validity.getMinutes();
			} else {
				txt.text = 'no validity';
			}
			var frm: TextFormat = txt.getTextFormat();
			frm.size = 20;
			frm.color = clr;
			txt.setTextFormat(frm);
			if (img is  Bitmap)
			{
				var m: Matrix = new Matrix();
				m.translate(x,y);
				(img as Bitmap).bitmapData.draw(txt, m);
			}
		}
		override public function deleteCacheItemByKey(s_key: String, b_disposeDisplayed: Boolean = false): Boolean
		{
			debug("deleteCacheItemByKey: " + s_key);
			
			var cacheItem: CacheItem = md_cache[s_key] as CacheItem;
			
			// dispose bitmap data, just for bitmaps which are not currently displayed
			if (cacheItem && (!cacheItem.displayed || (cacheItem.displayed && b_disposeDisplayed) ))
			{
				disposeTileBitmap(s_key);
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
			
			var dist1: Number = Point.distance( _tiledAreaCenter, new Point(tileIndex1.mi_tileCol, tileIndex1.mi_tileRow) )
			var dist2: Number = Point.distance( _tiledAreaCenter, new Point(tileIndex1.mi_tileCol, tileIndex1.mi_tileRow) )
			
//			debug(dist1 + "  , " + dist2);
//			debug(tileIndex1 + "  , " + tileIndex2);
			if (dist1 > dist1) {
				return -1
			} else {
				if (dist1 < dist1) {
					return 1;
				} 
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
					var img:  Bitmap = item.image as Bitmap;
					img.bitmapData.dispose();
				} else {
					//FIXME dispose tile if it's not bitmap (e.g. AVM1Movie)
				}
			}
		}
	
		override public function invalidate(s_crs: String, bbox: BBox, validity: Date = null): void
		{
			var a: Array = [];
			for(var s_key: String in md_cache) {
				var ck: WMSTileCacheKey = (md_cache[s_key] as CacheItem).cacheKey as WMSTileCacheKey; 
//				if(ck.ms_crs == s_crs && ck.m_bbox.equals(bbox))
				var needToRemoveItem: Boolean = ck.crs == s_crs && ck.bbox == bbox;
				if (validity)
					needToRemoveItem = needToRemoveItem && validity == ck.validity;
				
				needToRemoveItem = needToRemoveItem && isTileOnDisplayList(s_key);
				
				if(needToRemoveItem)
					a.push(s_key);
			}
			for each(s_key in a) {
				var id: int = _items.indexOf(s_key);
				if (id >= 0)
				{
					_items.splice(id, 1);
				}
				debug("WMSCache.invalidate(): removing image with key: " + md_cache[s_key].toString());
				debug("WMSCache.invalidate(): removing image with key: " + s_key + " cache tiles count: " + cachedTilesCount);
				deleteCacheItemByKey(s_key);
			}
			
			debug("\n invalidate cache tiles count: " + cachedTilesCount);
		
		}

		protected function debug(txt: String): void
		{
			if (debugConsole)
			{
				debugConsole.print("WMSTileCache: " + txt,'Info','WMSTileCache');
			}
		}
	}
}