package com.iblsoft.flexiweather.net.loaders
{
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
		public function JSONRPCLoader()
		{
			super();
		}
		 	
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
					else
						errorCallback("JSON Loader error: Result is RPC strict JSON, but error was returned: " + json['error'], json['error'], urlRequest, urlLoader.associatedData);
				} else
					errorCallback("JSON Loader error: Result is JSON, but it's not RPC strict", json['error'], urlRequest, urlLoader.associatedData);
			} else {
				errorCallback("JSON Loader error: Expected JSON", rawData, urlRequest, urlLoader.associatedData);
			}
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