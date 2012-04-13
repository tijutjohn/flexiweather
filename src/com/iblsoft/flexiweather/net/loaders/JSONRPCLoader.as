package com.iblsoft.flexiweather.net.loaders
{
	import com.iblsoft.flexiweather.net.events.UniURLLoaderErrorEvent;
	import com.iblsoft.flexiweather.net.events.UniURLLoaderEvent;
	
	import flash.net.URLRequest;
	import flash.net.URLRequestMethod;
	import flash.net.URLVariables;
	import flash.utils.ByteArray;
	
	import json.JParser;
	import json.JSerialize;
	
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
			addEventListener(UniURLLoaderEvent.DATA_LOADED, onCallDataLoaded); 
			addEventListener(UniURLLoaderErrorEvent.DATA_LOAD_FAILED, onCallDataLoadFailed);
		}
		 	
		public function call(s_serviceURL: String, s_methodName: String, params: Array,
				callback: Function, errorCallback: Function = null,
				s_backgroundJobName: String = null): void
		{
			var urlRequest: URLRequest = new URLRequest(s_serviceURL);
			urlRequest.method = URLRequestMethod.POST;
			urlRequest.data = new URLVariables();
			urlRequest.data.method = s_methodName;
			urlRequest.data.params = json.JParser.encode(params);
			load(urlRequest,
					{
						callbackFunction: callback,
						errorCallbackFunction: errorCallback
					},
					s_backgroundJobName);
		}
		
		protected function onCallDataLoaded(e: UniURLLoaderEvent): void
		{
			e.associatedData.callbackFunction(e.result);
		}
		
		protected function onCallDataLoadFailed(e: UniURLLoaderErrorEvent): void
		{
			if(e.associatedData.errorCallbackFunction)
				e.associatedData.errorCallbackFunction(e);
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