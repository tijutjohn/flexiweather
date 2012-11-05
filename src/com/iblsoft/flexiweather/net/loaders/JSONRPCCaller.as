package com.iblsoft.flexiweather.net.loaders
{
	import com.iblsoft.flexiweather.net.events.UniURLLoaderErrorEvent;
	import com.iblsoft.flexiweather.net.events.UniURLLoaderEvent;
	import flash.net.URLRequest;
	import flash.net.URLRequestMethod;
	import flash.net.URLVariables;
	import json.JParser;

	/**
	 * Helper class wrapping the JSONRPCLoader allowing simply calling JSON RPC methods.
	 **/
	public class JSONRPCCaller
	{
		protected var m_loader: JSONRPCLoader = new JSONRPCLoader();

		public function JSONRPCCaller()
		{
			m_loader.addEventListener(UniURLLoaderEvent.DATA_LOADED, onCallDataLoaded);
			m_loader.addEventListener(UniURLLoaderErrorEvent.DATA_LOAD_FAILED, onCallDataLoadFailed);
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
			m_loader.load(urlRequest,
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
			if (e.associatedData.errorCallbackFunction)
				e.associatedData.errorCallbackFunction(e);
		}
	}
}
