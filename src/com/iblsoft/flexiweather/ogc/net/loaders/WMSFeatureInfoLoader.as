package com.iblsoft.flexiweather.ogc.net.loaders
{
	import com.iblsoft.flexiweather.net.UniURLLoaderFormat;
	import com.iblsoft.flexiweather.net.loaders.URLLoaderWithAssociatedData;
	import com.iblsoft.flexiweather.net.loaders.UniURLLoader;
	import com.iblsoft.flexiweather.net.loaders.XMLLoader;
	import com.iblsoft.flexiweather.net.loaders.errors.URLLoaderError;
	import com.iblsoft.flexiweather.utils.HTMLUtils;
	
	import flash.net.URLRequest;
	import flash.utils.ByteArray;
	
	import mx.utils.ObjectUtil;

	public class WMSFeatureInfoLoader extends UniURLLoader
	{
		public function WMSFeatureInfoLoader()
		{
			super();
			allowedFormats = [UniURLLoaderFormat.XML_FORMAT, UniURLLoaderFormat.HTML_FORMAT];
		}

		override protected function decodeResult(rawData: ByteArray, urlLoader: URLLoaderWithAssociatedData, urlRequest: URLRequest, resultCallback: Function, errorCallback: Function): void
		{
			//for now WMS Feature Info Loader check just is data is valid XML
			var data: String = cloneByteArrayToString(rawData);
			var validXML: Boolean = XMLLoader.isValidXML(data);
			if (validXML)
			{
				resultCallback(XMLLoader.getXML(data), urlRequest, urlLoader.associatedData);
				return;
			}
			if (data)
			{
				var validHTML: Boolean = HTMLUtils.isHTMLFormat(data);
				if (validHTML)
				{
					resultCallback(data, urlRequest, urlLoader.associatedData);
					return;
				}
				else
				{
					//check some html tags, very weak check
					var str: String = data as String;
					var htmlPos: int = str.indexOf('<html');
					if (htmlPos >= 0)
					{
						var htmlEndPos: int = str.indexOf('</html', htmlPos + 6);
						if (htmlEndPos > htmlPos)
						{
							var bodyPos: int = str.indexOf('<body');
							if (bodyPos > htmlPos)
							{
								var bodyEndPos: int = str.indexOf('</body', bodyPos + 4);
								if (bodyEndPos > bodyPos)
								{
									resultCallback(data, urlRequest, urlLoader.associatedData);
									return;
								}
							}
						}
					}
				}
			}
			errorCallback("WFS Feature Info Loader error: Result is not in expected format", URLLoaderError.UNSPECIFIED_ERROR, rawData, urlRequest, urlLoader.associatedData);
		}
	}
}
