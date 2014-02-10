package com.iblsoft.flexiweather.ogc.cache
{
	import com.iblsoft.flexiweather.ogc.BBox;
	import com.iblsoft.flexiweather.ogc.tiling.TileIndex;
	import com.iblsoft.flexiweather.utils.ISO8601Parser;
	import flash.net.URLRequest;

	public class WMSTileCacheKey extends CacheKey
	{
		public var m_tileIndex: TileIndex;
//		public var m_validity: Date;
		
		public var dimensions: Array;

//		public function WMSTileCacheKey(s_crs: String, tileIndex: TileIndex, url: URLRequest, validity: Date, specialStrings: Array = null)
		public function WMSTileCacheKey(s_crs: String, tileIndex: TileIndex, url: URLRequest, dimensions: Array, validity: Date = null, serviceBaseURL: String = null)
		{
			super(s_crs, null, url, validity);
			
//			if (!serviceBaseURL)
//			{
//				trace("Check missing serviceBaseURL");
//			}
			
			m_tileIndex = tileIndex;
			this.dimensions = dimensions;
//			m_validity = validity;
			
			key = s_crs;
//			if (tileIndex != null)
//				key += "|" + tileIndex.toString();
//			if (m_validity != null)
//			{
//				var timeStr: String = ISO8601Parser.dateToString(m_validity);
//				key += "|validity:" + timeStr;
//			}
//			if (specialStrings && specialStrings.length > 0)
//			{
//				var specialStringInside: Boolean = true;
//				for each (var str: String in specialStrings)
//				{
//					key += "|" + str;
//				}
//			}
				
			var a: Array = [];
			var getVars: Array;
			var s: String;
			var obj: Object;
			if (url != null)
			{
				a.push({type: 'tile', name: 'TILE', string: tileIndex.toString()});
				
				if (serviceBaseURL)
				{
					//					a.push({type:'url', name: url.url});
					a.push({type:'url', name: serviceBaseURL});
				}
				
				for (s in url.data)
				{
					a.push({type: 'data', name: s});
				}
				if (url.url.indexOf('?'))
				{
					var paramsArray: Array = url.url.split('?');
					if (paramsArray.length > 1)
					{
						getVars = (paramsArray[1] as String).split('&');
						for each (s in getVars)
						{
							if (s.length > 0) 
							{
								var paramName: String = getURLParameterName(s);
								if (paramName == 'BBOX' || paramName == "CRS")
									continue;
								
								a.push({type: 'get', name: paramName, string: s});
							}
						}
					}
				}
				a.sort(sortKeysArray);
				var type: String;
				for each (obj in a)
				{
					type = obj.type as String;
					s = obj.name;
					if (type == 'tile')
						key += "|TILE=" + getURLParameterValue(obj.string);
					if (type == 'url')
						key += "|URL=" + s;
					if (type == 'data')
						key += "|" + s + "=" + url.data[s];
					if (type == 'get')
						key += "|" + s + "=" + getURLParameterValue(obj.string);
				}
			}
			sortCacheKeyString();
		}

		override public function destroy(): void
		{
			super.destroy();
			dimensions = null;
			m_tileIndex = null;
//			m_validity = null;
		}
	}
}
