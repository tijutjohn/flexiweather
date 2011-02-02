package com.iblsoft.flexiweather.ogc.cache
{
	import com.iblsoft.flexiweather.ogc.BBox;
	import com.iblsoft.flexiweather.ogc.tiling.TileIndex;
	
	import flash.display.Bitmap;
	import flash.net.URLRequest;
	import flash.utils.Dictionary;
	
	public class WMSTileCache implements ICache
	{
		public var maxCachedItems: int = 300;
		
		protected var md_cache: Dictionary = new Dictionary();
		private var _itemCount: int = 0;
		private var _items: Array = [];
		
		public function get cachedTilesCount(): int
		{
			return _items.length;
		}
		
		public function WMSTileCache()
		{
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
			for each(var cacheRecord: Object in md_cache) {
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
					for each (var str: String in specialStrings)
					{
						if (key.indexOf(str) == -1)
						{
							//special string is not in key, do not return this tile
							 specialStringInside = false;
							 break;
						}
					}
					if (!specialStringInside)
						continue;
				}
				cacheRecord.lastUsed = new Date();
				a.push({
					tileIndex: cacheKey.m_tileIndex,
					image: cacheRecord.image
				});
			}
			return a;
		}
	
		
		public function isTileCached(s_crs: String, tileIndex: TileIndex, url: URLRequest, specialStrings: Array): Boolean
		{
			var ck: WMSTileCacheKey = new WMSTileCacheKey(s_crs, null, tileIndex, url, specialStrings);
			var s_key: String = ck.toString(); 
			var data: Object =  md_cache[s_key]; 
//			trace("isTileCached check for undefined: " + (data != undefined) + " for null: " + (data != null) + " KEY: " + s_key);
			return data != undefined;			
		}
		public function addTile(img: Bitmap, s_crs: String, tileIndex: TileIndex, url: URLRequest, specialStrings: Array): void
		{
			var ck: WMSTileCacheKey = new WMSTileCacheKey(s_crs, null, tileIndex, url, specialStrings);
			var s_key: String = decodeURI(ck.toString()); 
//			trace("WMSTileCache addTile: " + s_key);
			md_cache[s_key] = {
				cacheKey: ck,
				lastUsed: new Date(),
				image: img
			};
			
			_items.push(s_key);
			
			if (_items.length > maxCachedItems)
			{
				s_key = _items.shift();
				disposeTileBitmap(s_key);
				
				delete md_cache[s_key];
			}
//			trace("cache item removed: " + _items.length);
		}
		
		private function disposeTileBitmap(s_key: String): void
		{
			var data: Object = md_cache[s_key];
			var img:  Bitmap = data.image;
			img.bitmapData.dispose();
		}
	
		public function invalidate(s_crs: String, bbox: BBox): void
		{
			var a: Array = [];
			for(var s_key: String in md_cache) {
				var ck: WMSTileCacheKey = md_cache[s_key].cacheKey; 
//				if(ck.ms_crs == s_crs && ck.m_bbox.equals(bbox))
				if(ck.ms_key == s_key)
					a.push(s_key);
			}
			for each(s_key in a) {
				var id: int = _items.indexOf(s_key);
				if (id >= 0)
				{
					_items.splice(id, 1);
				}
//				trace("WMSCache.invalidate(): removing image with key: " + md_cache[s_key].toString());
				trace("WMSCache.invalidate(): removing image with key: " + s_key + " cache tiles count: " + cachedTilesCount);
				disposeTileBitmap(s_key);
				delete md_cache[s_key];
			}
			
			trace("\n invalidate cache tiles count: " + cachedTilesCount);
		
		}

	}
}