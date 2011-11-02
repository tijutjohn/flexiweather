package com.iblsoft.flexiweather.ogc.cache
{
	import com.iblsoft.flexiweather.ogc.BBox;
	
	import flash.net.URLRequest;
	
	public class WMSCacheKey
	{
		internal var ms_key: String;
		internal var ms_crs: String;
		internal var m_bbox: BBox;
		
		public function WMSCacheKey(s_crs: String, bbox: BBox, url: URLRequest)
		{
			ms_crs = s_crs;
			m_bbox = bbox;
			ms_key = s_crs + "|" + bbox.toBBOXString();
			var a: Array = [];
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
						ms_key += "|" + s + "=" + url.data[s]; 
					if (type == 'get')
						ms_key += "|" + s + "=" + getURLParameterValue(obj.string);
				}
			} 
			
		}
		
		public function toString(): String
		{ return ms_key; }
		
		
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
