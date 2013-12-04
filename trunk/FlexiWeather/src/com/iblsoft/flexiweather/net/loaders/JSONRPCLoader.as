package com.iblsoft.flexiweather.net.loaders
{
	import com.iblsoft.flexiweather.net.loaders.errors.URLLoaderError;
	
	import flash.net.URLRequest;
	import flash.utils.ByteArray;
	
	import json.JParser;

	/**
	 * Implemented JSON RPC specification. ( http://json-rpc.org/wiki/specification )
	 * @author fkormanak
	 *
	 */
	public class JSONRPCLoader extends JSONLoader
	{
		public static const ERROR_MESSAGE_MAXIMUM_LENGTH: int = 256;
		public function JSONRPCLoader()
		{
			super();
		}

		/**
		 * Decode JSON RPC response
		 *  
		 * @param rawData
		 * @param urlLoader
		 * @param urlRequest
		 * @param resultCallback
		 * @param errorCallback
		 * 
		 */		
		override protected function decodeResult(rawData: ByteArray, urlLoader: URLLoaderWithAssociatedData, urlRequest: URLRequest, resultCallback: Function, errorCallback: Function): void
		{
			var data: String = cloneByteArrayToString(rawData);
			var isValid: Boolean = JSONLoader.isValidJSON(data);
			if (isValid)
			{
				var json: Object = JParser.decode(data);
				var isStrict: Boolean = JSONRPCLoader.isRPCStrict(json);
				if (isStrict)
				{
					var isError: Boolean = JSONRPCLoader.isError(json);
					if (!isError)
						resultCallback(json['result'], urlRequest, urlLoader.associatedData);
					else {
						var error: Object = json['error'];
						var errorMessage: String = (json['error'])['message'];
						var errorCode: int = (json['error'])['code'];
						if (errorMessage.length > ERROR_MESSAGE_MAXIMUM_LENGTH)
						{
							errorMessage = errorMessage.substr(0, ERROR_MESSAGE_MAXIMUM_LENGTH - 3) + "...";
						}
//						errorCallback("JSON Loader error: Result is RPC strict JSON, but error was returned: " + errorMessage, errorCode, json['error'], urlRequest, urlLoader.associatedData);
						errorCallback(errorMessage, errorCode, json['error'], urlRequest, urlLoader.associatedData);
					}
				}
				else
					errorCallback("JSON Loader error: Result is JSON, but it's not RPC strict", (json['error'])['code'], json['error'], urlRequest, urlLoader.associatedData);
			}
			else
				errorCallback("JSON Loader error: Expected JSON", URLLoaderError.UNSPECIFIED_ERROR, rawData, urlRequest, urlLoader.associatedData);
		}

		static public function isError(jsonObj: Object): Boolean
		{
			if (jsonObj && jsonObj.hasOwnProperty('error') && jsonObj['error'] != null)
				return true;
			return false;
		}

		static public function isRPCStrict(jsonObj: Object): Boolean
		{
			if (jsonObj && jsonObj.hasOwnProperty('error'))
				return true;
			return false;
		}
	}
}
