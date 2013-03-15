package com.iblsoft.flexiweather.utils
{
	import mx.utils.URLUtil;

	public class URLUtils
	{
		public function URLUtils()
		{
		}

		static public function isAbsolutePath(url: String): Boolean
		{
			if (url.indexOf('http') == 0)
				return true;
			return false;
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
		
		static public function getURLGetParameterValue(url: String, parameterName: String): String
		{
			url = encodeURI(url);
			if (url.indexOf('?') > 0)
			{
				var arr: Array = url.split('?');
				if (arr.length == 2)
				{					
					if (url.indexOf('&') > 0)
					{
						var arr2: Array = (arr[1] as String).split('&');
						for each (var parameter: String in arr2)
						{
							if (parameter.indexOf(parameterName) == 0)
							{
								var parameterArray: Array = parameter.split('=');
								if (parameterArray.length == 2)
								{
									return parameterArray[1] as String;
								}
							}
						}
					} else {
						var paramsString: String = arr[1] as String;
						if (paramsString.indexOf(parameterName) == 0)
						{
							var paramsStringArray: Array = paramsString.split('=');
							if (paramsStringArray.length == 2)
							{
								return paramsStringArray[1] as String;
							}
						}
						
					}
				}
			}
			return null;
		}

		/**
		 * Function will join path parts. Check if there is "/" between and add it if it's missing
		 *
		 * @param url
		 * @return
		 *
		 */
		public static function pathJoiner(path1: String, path2: String): String
		{
			var last1: String = path1.substr(path1.length - 1, 1);
			var first2: String = path2.substr(0, 1);
			if (last1 != '/' && first2 != '/')
				return path1 + "/" + path2;
			else if (last1 == '/' && first2 == '/')
				return path1.substr(0, path1.length - 1) + path2;
			return path1 + path2;
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
				urlArr[0] = replaceDomainURLString(urlArr[0], '//', '/');
				url = urlArr.join('?');
				return url;
			}
			url = replaceDomainURLString(url, '//', '/');
			return url;
		}

		private static function replaceDomainURLString(url: String, originString: String, newString: String): String
		{
			var protocol: String = URLUtil.getProtocol(url);
			//remove protocol from url
			if (protocol.length > 0)
				url = url.substring(protocol.length + 3, url.length);
			if (url.indexOf(originString) >= 0)
				url = url.split(originString).join(newString);
			if (protocol.length > 0)
				url = protocol + '://' + url;
			return url;
		}
	}
}
