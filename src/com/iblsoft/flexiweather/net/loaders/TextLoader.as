package com.iblsoft.flexiweather.net.loaders
{
	import com.iblsoft.flexiweather.net.UniURLLoaderFormat;
	import flash.net.URLRequest;
	import flash.utils.ByteArray;

	public class TextLoader extends UniURLLoader
	{
		public function TextLoader()
		{
			super();
			allowedFormats = [UniURLLoaderFormat.TEXT_FORMAT];
		}

		override protected function decodeResult(rawData: ByteArray, urlLoader: URLLoaderWithAssociatedData, urlRequest: URLRequest, resultCallback: Function, errorCallback: Function): void
		{
			var data: String = cloneByteArrayToString(rawData);
			resultCallback(data, urlRequest, urlLoader.associatedData);
		}
	}
}
