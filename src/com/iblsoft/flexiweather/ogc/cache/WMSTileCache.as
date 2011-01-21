package com.iblsoft.flexiweather.ogc.cache
{
	import com.iblsoft.flexiweather.ogc.BBox;
	import com.iblsoft.flexiweather.ogc.tiling.TileIndex;
	
	import flash.display.Bitmap;
	import flash.net.URLRequest;
	import flash.utils.Dictionary;
	
	public class WMSTileCache implements ICache
	{
		protected var md_cache: Dictionary = new Dictionary();
		
		public function WMSTileCache()
		{
		}

		public function getTiles(s_crs: String, i_tileZoom: uint): Array
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
				cacheRecord.lastUsed = new Date();
				a.push({
					tileIndex: cacheKey.m_tileIndex,
					image: cacheRecord.image
				});
			}
			return a;
		}
	
		public function addTile(img: Bitmap, s_crs: String, tileIndex: TileIndex, url: URLRequest): void
		{
			var ck: WMSTileCacheKey = new WMSTileCacheKey(s_crs, null, tileIndex, url);
			var s_key: String = ck.toString(); 
			md_cache[s_key] = {
				cacheKey: ck,
				lastUsed: new Date(),
				image: img
			};
		}
	
		public function invalidate(s_crs: String, bbox: BBox): void
		{
			var a: Array = [];
			for(var s_key: String in md_cache) {
				var ck: WMSTileCacheKey = md_cache[s_key].cacheKey; 
				if(ck.ms_crs == s_crs && ck.m_bbox.equals(bbox))
					a.push(s_key);
			}
			for each(s_key in a) {
	//			trace("WMSCache.invalidate(): removing image with key: " + md_cache[s_key].toString());
				delete md_cache[s_key];
			}
		}

	}
}