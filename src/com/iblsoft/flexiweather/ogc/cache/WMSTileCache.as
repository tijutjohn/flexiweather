package com.iblsoft.flexiweather.ogc.cache
{
	import com.iblsoft.flexiweather.ogc.BBox;
	import com.iblsoft.flexiweather.ogc.tiling.TileIndex;
	import com.iblsoft.flexiweather.ogc.tiling.TiledArea;
	
	import flash.display.Bitmap;
	import flash.events.TimerEvent;
	import flash.geom.Point;
	import flash.net.URLRequest;
	import flash.utils.Dictionary;
	import flash.utils.Timer;
	
	public class WMSTileCache implements ICache
	{
		public var maxCachedItems: int = 300;
		
		/**
		 * Expiration time in seconds 
		 */		
		private var _checkExpirationTime: int = 10 * 1000; 
		private var _expirationTime: int = 60; 
		private var _expirationTimer: Timer;
		
		private var _animationModeEnabled: Boolean;
		
		protected var md_cache: Dictionary = new Dictionary();
		private var _itemCount: int = 0;
		private var _items: Array = [];
		
		public function get cachedTilesCount(): int
		{
			return _items.length;
		}
		
		public function WMSTileCache()
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
//						debug("TILE from cache is expired, will be removed");
						if (!isTileOnDisplayList(s_key))
						{
							deleteTile(s_key);
//						} else {
//							debug("TILE IS DISPLAY LIST, DO NOT DELETE IT");
						}
					}
//					debug("diff: " + diff);
				}
			}
		}
		
		private function isTileOnDisplayList(s_key: String): Boolean
		{
			var object: Object = md_cache[s_key];
			var bitmap: Bitmap = object.image as Bitmap;
			
			return (bitmap.parent != null);
		}
		
		public function getTile(request: URLRequest, specialStrings: Array): Object
		{
			var s_crs: String = request.data.CRS;
			var tileIndex: TileIndex = new TileIndex(request.data.TILEZOOM, request.data.TILEROW, request.data.TILECOL);
			
			var ck: WMSTileCacheKey = new WMSTileCacheKey(s_crs, null, tileIndex, request, specialStrings);
			var s_key: String = ck.toString(); 
			return md_cache[s_key];
		}
		
		/**
		 * Function return all cached tiles with same CRS and tileZoom and specialString (e.g. same RUN and FORECAST) 
		 * @param s_crs
		 * @param i_tileZoom
		 * @param specialStrings
		 * @return 
		 * 
		 */		
		public function getTiles(s_crs: String, i_tileZoom: uint, specialStrings: Array): Array
		{
			var a: Array = [];
			for each(var cacheRecord: Object in md_cache) 
			{
				var cacheKey: WMSTileCacheKey = cacheRecord.cacheKey;
				if(cacheKey.m_tileIndex == null)
					continue;
				if(cacheKey.ms_crs != s_crs)
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
					
//					debug("specialStringsFound: " + specialStringsFound + " specialStringsLength: " + specialStringsLength);
					if (specialStringsFound != specialStringsLength)
					{
						//not all special strings were inside
						continue;
					}
					//TODO all special strings must be in key
					if (!specialStringInside)
						continue;
				}
				cacheRecord.lastUsed = new Date();
				a.push({
					tileIndex: cacheKey.m_tileIndex,
					image: cacheRecord.image
				});
			}
//			debug("GET TILES: " + a.length);
			return a;
		}
	
		
		public function isTileCached(s_crs: String, tileIndex: TileIndex, url: URLRequest, specialStrings: Array): Boolean
		{
			var ck: WMSTileCacheKey = new WMSTileCacheKey(s_crs, null, tileIndex, url, specialStrings);
			var s_key: String = ck.toString(); 
			var data: Object =  md_cache[s_key]; 
//			debug("isTileCached check for undefined: " + (data != undefined) + " for null: " + (data != null) + " KEY: " + s_key);
			return data != null;			
		}
		public function addTile(img: Bitmap, s_crs: String, tileIndex: TileIndex, url: URLRequest, specialStrings: Array, tiledArea: TiledArea, viewPart: BBox): void
		{
			var ck: WMSTileCacheKey = new WMSTileCacheKey(s_crs, null, tileIndex, url, specialStrings);
			var s_key: String = decodeURI(ck.toString()); 
//			debug("WMSTileCache addTile: " + s_key);
			md_cache[s_key] = {
				cacheKey: ck,
				lastUsed: new Date(),
				image: img
			};
			
			_items.push(s_key);
			
			if (_items.length > maxCachedItems)
			{
				s_key = getCachedTileKeyOutsideTiledArea(tiledArea);
				
//				debug("REMOVE TILE : " +s_key);
				
				deleteTile(s_key);
			}
//			debug("cache item removed: " + _items.length);
		}
		
		public function deleteTile(s_key: String): void
		{
//			debug("deleteTile: " + s_key);
			disposeTileBitmap(s_key);
			delete md_cache[s_key];
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
			var data: Object = md_cache[s_key];
			if (data)
			{
				var img:  Bitmap = data.image;
				img.bitmapData.dispose();
			}
		}
	
		public function invalidate(s_crs: String, bbox: BBox): void
		{
			var a: Array = [];
			for(var s_key: String in md_cache) {
				var ck: WMSTileCacheKey = md_cache[s_key].cacheKey; 
//				if(ck.ms_crs == s_crs && ck.m_bbox.equals(bbox))
				if(ck.ms_key == s_key && !isTileOnDisplayList(s_key))
					a.push(s_key);
			}
			for each(s_key in a) {
				var id: int = _items.indexOf(s_key);
				if (id >= 0)
				{
					_items.splice(id, 1);
				}
//				debug("WMSCache.invalidate(): removing image with key: " + md_cache[s_key].toString());
//				debug("WMSCache.invalidate(): removing image with key: " + s_key + " cache tiles count: " + cachedTilesCount);
				deleteTile(s_key);
			}
			
//			debug("\n invalidate cache tiles count: " + cachedTilesCount);
		
		}

		private function debug(str: String): void
		{
			trace("WMSTileCache: " + str)
		}
	}
}