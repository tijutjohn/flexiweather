package com.iblsoft.flexiweather.net.loaders
{
	import com.iblsoft.flexiweather.net.UniURLLoaderFormat;
	import flash.net.URLRequest;
	import flash.utils.ByteArray;

	public class BinaryLoader extends AbstractURLLoader
	{
		public function BinaryLoader()
		{
			super();
		}

		override protected function decodeResult(rawData: ByteArray, urlLoader: URLLoaderWithAssociatedData, urlRequest: URLRequest, resultCallback: Function, errorCallback: Function): void
		{
			//binary format is always valid
			dispatchResult(rawData, urlRequest, urlLoader.associatedData);
		}
	}
}
