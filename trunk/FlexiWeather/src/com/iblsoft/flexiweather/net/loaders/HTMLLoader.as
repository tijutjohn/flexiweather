package com.iblsoft.flexiweather.net.loaders
{
	import com.iblsoft.flexiweather.net.loaders.errors.URLLoaderError;
	import com.iblsoft.flexiweather.utils.HTMLUtils;
	
	import flash.net.URLRequest;
	import flash.utils.ByteArray;
	
	import mx.utils.ObjectUtil;

	public class HTMLLoader extends XMLLoader
	{
		public function HTMLLoader()
		{
			super();
		}

		override protected function decodeResult(rawData: ByteArray, urlLoader: URLLoaderWithAssociatedData, urlRequest: URLRequest, resultCallback: Function, errorCallback: Function): void
		{
			if (HTMLLoader.isValidHTML(rawData))
			{
				var htmlSource: String = getHTMLSource(data);
				resultCallback(htmlSource, urlRequest, urlLoader.associatedData);
			}
			else
				errorCallback("HTML Loader error: Expected HTML", URLLoaderError.UNSPECIFIED_ERROR, rawData, urlRequest, urlLoader.associatedData);
		}

		public static function isValidHTML(data: Object): Boolean
		{
			var htmlSource: String = getHTMLSource(data);
			var validHTML: Boolean = HTMLUtils.isHTMLFormat(htmlSource);
			if (validHTML)
				return true;
			else
			{
				//check some html tags, very weak check
				var htmlPos: int = htmlSource.indexOf('<html');
				if (htmlPos >= 0)
				{
					var htmlEndPos: int = htmlSource.indexOf('</html', htmlPos + 6);
					if (htmlEndPos > htmlPos)
					{
						var bodyPos: int = htmlSource.indexOf('<body');
						if (bodyPos > htmlPos)
						{
							var bodyEndPos: int = htmlSource.indexOf('</body', bodyPos + 4);
							if (bodyEndPos > bodyPos)
								return true;
						}
					}
				}
			}
			var xml: XML = XMLLoader.getXML(data);
			if (xml)
				return true;
			return false;
		}

		public static function getHTMLSource(data: Object): String
		{
			if (data is XML)
				return (data as XML).toXMLString();
			if (data is ByteArray)
			{
				var ba: ByteArray = data as ByteArray;
				data = ba.readUTFBytes(ba.length);
				ba.position = 0;
			}
			if (data is String)
				return data as String;
			return null;
		}
	}
}
