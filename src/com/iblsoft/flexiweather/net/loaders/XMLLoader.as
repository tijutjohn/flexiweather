package com.iblsoft.flexiweather.net.loaders
{
	import com.iblsoft.flexiweather.net.UniURLLoaderFormat;
	import com.iblsoft.flexiweather.net.loaders.errors.URLLoaderError;
	
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
				errorCallback("XML Loader error: Expected XML", URLLoaderError.UNSPECIFIED_ERROR, rawData, urlRequest, urlLoader.associatedData);
		}

		public static function getXML(data: Object): XML
		{
			if (data is XML)
				return data as XML;
			if (data is ByteArray)
			{
				var ba: ByteArray = data as ByteArray;
				data = ba.readUTFBytes(ba.length);
				ba.position = 0;
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
			if (data is ByteArray)
			{
				
				var ba: ByteArray = data as ByteArray;
				var b0: int = ba.length > 0 ? ba.readUnsignedByte() : -1;
				var b1: int = ba.length > 1 ? ba.readUnsignedByte() : -1;
				var b2: int = ba.length > 2 ? ba.readUnsignedByte() : -1;
				var b3: int = ba.length > 3 ? ba.readUnsignedByte() : -1;
				var b4: int = ba.length > 4 ? ba.readUnsignedByte() : -1;
				
//				0x3c 0x3f 0x78 0x6d 0x6c
				var isXML: Boolean = b0 == 0x3c && b1 == 0x3f && b2 == 0x78 && b3 == 0x6d && b4 == 0x6c;
				
				ba.position = 0;
				
				if (isXML)
					return true;
			} 
			
			
			return getXML(data) != null;
		}
	}
}
