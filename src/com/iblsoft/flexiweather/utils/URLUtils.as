package com.iblsoft.flexiweather.utils
{
	public class URLUtils
	{
		public function URLUtils()
		{
		}
		
		/**
		 * URL params which have get parameters in different param orders will be returned sorted byt param name, so it will be always same if there is same parameters and same parameters values 
		 * @param url
		 * @return 
		 * 
		 */		
		static public function repairURLWithGetParameters(url: String): String
		{
			url = encodeURI(url);
			
			if (url.indexOf('&') > 0)
			{
				var arr: Array = url.split('?');
				if (arr.length == 2)
				{
					var arr2: Array = (arr[1] as String).split('&');
					arr2.sort();
					
					url = arr[0] + "?" + arr2.join('&');
				}
			}
			return url;
		}
	}
}