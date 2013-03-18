package com.iblsoft.flexiweather.net.loaders
{
	import com.iblsoft.flexiweather.net.loaders.errors.URLLoaderError;
	
	import flash.events.IEventDispatcher;
	import flash.net.URLRequest;
	import flash.utils.ByteArray;

	public class KMLLoader extends AbstractURLLoader
	{
		public function KMLLoader(target: IEventDispatcher = null)
		{
			super(target);
		}

		override protected function decodeResult(rawData: ByteArray, urlLoader: URLLoaderWithAssociatedData, urlRequest: URLRequest, resultCallback: Function, errorCallback: Function): void
		{
			if (XMLLoader.isValidXML(rawData))
			{
				var xml: XML = XMLLoader.getXML(rawData);
				resultCallback(xml, urlRequest, urlLoader.associatedData);
			}
			else
				errorCallback("XML Loader error: Expected XML", URLLoaderError.UNSPECIFIED_ERROR, rawData, urlRequest, urlLoader.associatedData);
		}
	}
}
