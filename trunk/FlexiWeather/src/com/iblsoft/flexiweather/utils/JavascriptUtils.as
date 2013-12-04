package com.iblsoft.flexiweather.utils
{
	import flash.external.ExternalInterface;

	public class JavascriptUtils
	{
		public static function getJavascriptResult(javascript: String): String
		{
			var result:* = ExternalInterface.call(javascript);
			
			return result;
		}
		
		public static function getPageURL(): String
		{
			var pageURL:String=getJavascriptResult('window.location.href.toString');
			return pageURL;				
		}
		
		public static function getBaseURLFromPageURL(): String
		{
			return getParameterValueFromPageURL('baseURL');
		}
		
		public static function getParameterValueFromPageURL(parameterName: String): String
		{
			var pageURL: String = getPageURL();
			var id: String = URLUtils.getURLGetParameterValue(pageURL,parameterName);
			return id;
		}
	}
}