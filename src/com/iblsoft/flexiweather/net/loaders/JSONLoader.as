package com.iblsoft.flexiweather.net.loaders
{
	import com.iblsoft.flexiweather.net.UniURLLoaderFormat;
	import flash.net.URLRequest;
	import flash.utils.ByteArray;
	import json.JParser;
	import mx.utils.ObjectUtil;

	public class JSONLoader extends UniURLLoader
	{
		public function JSONLoader()
		{
			super();
			allowedFormats = [UniURLLoaderFormat.JSON_FORMAT];
		}

		override protected function decodeResult(rawData: ByteArray, urlLoader: URLLoaderWithAssociatedData, urlRequest: URLRequest, resultCallback: Function, errorCallback: Function): void
		{
			var data: String = cloneByteArrayToString(rawData);
			var isValid: Boolean = JSONLoader.isValidJSON(data);
			if (isValid)
			{
				var json: Object = JParser.decode(data);
				resultCallback(json, urlRequest, urlLoader.associatedData);
			}
			else
				errorCallback("JSON Loader error: Expected JSON", rawData, urlRequest, urlLoader.associatedData);
		}

		static public function getJSON(data: Object): Object
		{
			if (data is ByteArray)
			{
				var clonedBA: ByteArray = ObjectUtil.clone(data) as ByteArray;
				data = clonedBA.readUTFBytes(clonedBA.length);
			}
			if (data is String)
			{
				try
				{
					var json: Object = JParser.decode(data as String);
					if (json != null)
						return json;
				}
				catch (error: Error)
				{
					return null;
				}
			}
			return null;
		}

		static public function isValidJSON(data: Object): Boolean
		{
			var jsonObject: Object = getJSON(data);
			return (jsonObject != null);
		}
	}
}
