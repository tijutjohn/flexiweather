package com.iblsoft.flexiweather.utils
{
	import com.iblsoft.flexiweather.net.loaders.AbstractURLLoader;
	import com.iblsoft.flexiweather.net.loaders.UniURLLoader;
	import flash.net.URLRequest;
	import flash.net.URLVariables;
	import mx.utils.URLUtil;

	/**
	 * This class serves just for debugging functionality.
	 * Add your debug helper functions here
	 *
	 * @author fkormanak
	 *
	 */
	public class DebugUtils
	{
		public function DebugUtils()
		{
		}

		/**
		 * Debug URL string (decode it if needed)
		 * @param url
		 * @param debugString
		 *
		 */
		public static function debugURLString(url: String, debugString: String = null): void
		{
			trace("\n debug URL");
			url = AbstractURLLoader.fromBaseURL(url);
			trace("URL: " + url);
			var arr: Array = url.split('&');
			var arr2: Array;
			var cnt: int = 0;
			for each (var part: String in arr)
			{
				cnt++;
				try
				{
					part = decodeURIComponent(part);
				}
				catch (error: Error)
				{
					trace("\t\t\t Error decoding url part");
				}
				if (part.indexOf('image/png; mode') >= 0)
				{
					if (part.indexOf('8bit') == -1)
						trace("Stop, image format is processe");
				}
				if (part.indexOf('=') > 0)
				{
					arr2 = part.split('=');
					var varName: String = arr2.shift();
					var varValue: String = arr2.join('=');
					trace("\t\t [" + varName + "] " + varValue);
				}
				else
					trace("\t\t " + part);
			}
			if (cnt > 17)
				trace("debugURLString too many data variables");
		}

		/**
		 * Debug URLRequest to test data URLVariables
		 * @param request
		 * @param debugString add some debug info, which will be trace out at start of debug information if provided
		 *
		 */
		public static function debugURLRequest(request: URLRequest, debugString: String = null): void
		{
			trace("\n debug URLRequest");
			if (debugString)
				trace(debugString);
			trace("URL start ");
			debugURLString(request.url)
			trace("URL end ");
			trace("method: " + request.method);
			if (request.data)
			{
				trace("\t data");
				if (request.data is URLVariables)
				{
					var urlVars: URLVariables = request.data as URLVariables;
					var cnt: int = 0;
					for (var dataName: String in urlVars)
					{
						cnt++;
						trace("\t\t [" + dataName + "] " + urlVars[dataName]);
						if (dataName == "FORMAT")
						{
							if (urlVars[dataName].indexOf('image/png; mode') >= 0)
							{
								if (urlVars[dataName].indexOf('8bit') == -1)
									trace("Stop, image format is processe");
							}
						}
					}
					if (cnt > 17)
						trace("debugURLRequest too many data variables");
				}
			}
		}
	}
}
