package com.iblsoft.flexiweather.air.loading
{
	import com.iblsoft.flexiweather.net.data.UniURLLoaderData;
	import com.iblsoft.flexiweather.net.interfaces.IURLLoaderBasicAuth;
	import com.iblsoft.flexiweather.net.interfaces.IURLLoaderBasicAuthListener;
	
	import flash.events.HTTPStatusEvent;
	import flash.net.URLLoader;
	import flash.net.URLRequest;
	import flash.net.URLRequestHeader;

	public class UniURLLoaderBasicAuth implements IURLLoaderBasicAuthListener
	{
		private var _basicAuthLoader: IURLLoaderBasicAuth;
		private var _loader: URLLoader;
		private var _data: UniURLLoaderData;
		
		public function UniURLLoaderBasicAuth()
		{
		}
		
		public function destroy(): void
		{
			removeBasicAuthListeners();
			_loader = null;
			_data.destroy();
			_data = null;
			_basicAuthLoader = null;
		}
		public function addBasicAuthListeners(basicAuthLoader: IURLLoaderBasicAuth, urlLoader: URLLoader, data: UniURLLoaderData):void
		{
			_basicAuthLoader = basicAuthLoader;
			_loader = urlLoader;
			_data = data;
			_loader.addEventListener(HTTPStatusEvent.HTTP_RESPONSE_STATUS, onHttpResponseStatus);
			
		}
		
		public function removeBasicAuthListeners():void
		{
			if (_loader)
				_loader.removeEventListener(HTTPStatusEvent.HTTP_RESPONSE_STATUS, onHttpResponseStatus);
			
		}
		
		public function getData(): UniURLLoaderData
		{
			return _data;
		}
		
		private function onHttpResponseStatus(event: HTTPStatusEvent): void
		{
			/*
			trace("onHttpResponseStatus: " + event.responseURL);
			for each( var header: URLRequestHeader in event.responseHeaders )  {
				trace( "name: " + header.name + "\nvalue: " + header.value + "\n" ); 
			}
			*/
			_basicAuthLoader.setResponseHeaders(event.responseHeaders, event.responseURL, event.status, event.currentTarget);
		}
		
		public function toString(): String
		{
			return "UniURLLoaderBasicAuth data:  " + _data;
		}
	}
}