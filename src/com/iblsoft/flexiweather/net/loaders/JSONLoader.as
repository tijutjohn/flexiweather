package com.iblsoft.flexiweather.net.loaders
{
	import com.iblsoft.flexiweather.net.UniURLLoaderFormat;
	import com.iblsoft.flexiweather.net.loaders.errors.URLLoaderError;
	
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
				errorCallback("JSON Loader error: Expected JSON", URLLoaderError.UNSPECIFIED_ERROR, rawData, urlRequest, urlLoader.associatedData);
		}

		static public function getJSON(data: Object): Object
		{
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
			if (data is ByteArray)
			{
				var ba: ByteArray = data as ByteArray;
				data = ba.readUTFBytes(ba.length);
				ba.position = 0;
			}
			var jsonObject: Object = getJSON(data);
			//return (jsonObject != null); // Note that this does not handle a valid JSON string "null" properly.
			if (jsonObject != null)
			{
				return true;
			}
			if (data == "null")
			{
				return true;
			}
			return false;
		}
	}
}
