package com.iblsoft.flexiweather.ogc.cache
{
	import com.iblsoft.flexiweather.ogc.BBox;
	import com.iblsoft.flexiweather.ogc.tiling.TileIndex;
	
	import flash.net.URLRequest;
	
	public class WMSTileCacheKey extends CacheKey
	{
		public var m_tileIndex: TileIndex;
		public var m_validity: Date;
	
		public function WMSTileCacheKey(s_crs: String, bbox: BBox, tileIndex: TileIndex, url: URLRequest, validity:Date, specialStrings: Array = null)
		{
			super(s_crs, bbox, url, validity);
			
			key = s_crs;
			m_tileIndex = tileIndex;
			m_validity = validity;
			if(bbox != null)
				key +=  "|" + bbox.toBBOXString();
			if(tileIndex != null)
				key +=  "|" + tileIndex.toString();
			if(m_validity != null)
				key +=  "|validity:" + m_validity.toString();
//			else {
//				trace("WMSTileCacheKey validity is null");
//			}
			var a: Array = []
//			if(url.url != null) {
//				key += url.url;
//			} 
			
				/*
			var getVars: Array;
			var s: String;
			var obj: Object;
			
			if(url != null) 
			{
				for(s in url.data) {
					a.push({type:'data',name:s});
				}
				if (url.url.indexOf('?'))
				{
					var paramsArray: Array = url.url.split('?');
					if (paramsArray.length > 1)
					{
						getVars = (paramsArray[1] as String).split('&');
						for each (s in getVars) {
							if (s.length > 0)
							{
								a.push({type:'get',name:getURLParameterName(s), string: s});
							}
						}	
					}
				}
				a.sort();
				var type: String;
				for each(obj in a) 
				{
					type = obj.type as String;
					s = obj.name;
					
					if (type == 'data')
						key += "|" + s + "=" + url.data[s]; 
					if (type == 'get')
						key += "|" + s + "=" + getURLParameterValue(obj.string);
				}
			} 
			*/
				
			if (specialStrings && specialStrings.length > 0)
			{
				var specialStringInside: Boolean = true;
				for each (var str: String in specialStrings)
				{
					key +=  "|" + str;
				}
			}
			trace("new WMSTileCacheKey before : " + key);
			
			sortCacheKeyString();
				
			trace("new WMSTileCacheKey after  : " + key);
		}
		
		private function getURLParameterName(str: String): String
		{
			var arr: Array = str.split('=');
			arr.pop();
			
			return arr.join('=');
		}
		private function getURLParameterValue(str: String): String
		{
			var arr: Array = str.split('=');
			var value: String = arr.pop();
			return value;
		}
	
	}
}