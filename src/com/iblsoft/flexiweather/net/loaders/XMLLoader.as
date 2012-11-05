package com.iblsoft.flexiweather.net.loaders
{
	import com.iblsoft.flexiweather.net.UniURLLoaderFormat;
	import flash.net.URLRequest;
	import flash.utils.ByteArray;
	import flashx.textLayout.debug.assert;
	import mx.utils.ObjectUtil;

	public class XMLLoader extends UniURLLoader
	{
		public function XMLLoader()
		{
			super();
			allowedFormats = [UniURLLoaderFormat.XML_FORMAT];
		}

		override protected function decodeResult(rawData: ByteArray, urlLoader: URLLoaderWithAssociatedData, urlRequest: URLRequest, resultCallback: Function, errorCallback: Function): void
		{
			if (XMLLoader.isValidXML(rawData))
			{
				var xml: XML = getXML(rawData);
				resultCallback(xml, urlRequest, urlLoader.associatedData);
			}
			else
				errorCallback("XML Loader error: Expected XML", rawData, urlRequest, urlLoader.associatedData);
		}

		public static function getXML(data: Object): XML
		{
			if (data is XML)
				return data as XML;
			if (data is ByteArray)
			{
				var clonedBA: ByteArray = ObjectUtil.clone(data) as ByteArray;
				data = clonedBA.readUTFBytes(clonedBA.length);
			}
			if (data is String)
			{
				try
				{
					var xml: XML = new XML(data);
					var qname: QName = xml.name();
					if (xml && qname && qname.localName)
						return xml;
				}
				catch (error: Error)
				{
					return null;
				}
			}
			return null;
		}

		public static function isValidXML(data: Object): Boolean
		{
			return getXML(data) != null;
		}
	}
}
