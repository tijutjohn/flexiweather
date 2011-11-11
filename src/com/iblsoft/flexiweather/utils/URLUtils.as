package com.iblsoft.flexiweather.utils
{
	import mx.utils.URLUtil;

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
		
		/**
		 * Function will check URL for //, which can be created by replacing tag ${BASE_URL}
		 *  
		 * @param url
		 * @return 
		 * 
		 */		
		public static function urlSanityCheck(url: String): String
		{
			if (url.indexOf('?') > 0)
			{
				var urlArr: Array = url.split('?');
				urlArr[0] = replaceDomainURLString(urlArr[0], '//','/');
				url = urlArr.join('?');
				return url;
			}
			
			url = replaceDomainURLString(url,  '//','/');
			return url;
		}
		
		private static function replaceDomainURLString(url: String, originString: String, newString: String): String
		{
			var protocol: String = URLUtil.getProtocol(url);
			//remove protocol from url
			if (protocol.length > 0)
				url = url.substring(protocol.length + 3, url.length);
			
			if (url.indexOf(originString) >= 0)
			{
				url = url.split(originString).join(newString);
			}
			if (protocol.length > 0)
				url = protocol + '://'+url;
			
			return url;
		}
	}
}