package com.iblsoft.flexiweather.ogc.cache
{
	import com.iblsoft.flexiweather.ogc.BBox;
	
	import flash.net.URLRequest;

	public class WMSCacheKey extends CacheKey
	{
		public var dimensions: Array;

		public function WMSCacheKey(s_crs: String, bbox: BBox, url: URLRequest, dimensions: Array, validity: Date = null, serviceBaseURL: String = null)
		{
			super(s_crs, bbox, url, validity);
			
			if (!serviceBaseURL)
			{
				trace("Check missing serviceBaseURL");
			}
			this.dimensions = dimensions;
			key = s_crs + "|" + bbox.toBBOXString();
			var a: Array = [];
			var getVars: Array;
			var s: String;
			var obj: Object;
			if (url != null)
			{
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
								a.push({type: 'get', name: getURLParameterName(s), string: s});
						}
					}
				}
				a.sort();
				var type: String;
				for each (obj in a)
				{
					type = obj.type as String;
					s = obj.name;
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

		override public function destroy(): void
		{
			super.destroy();
			dimensions = null;
		}
	}
}
