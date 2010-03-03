package com.iblsoft.flexiweather.utils
{
	import flash.display.Loader;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.IOErrorEvent;
	import flash.events.SecurityErrorEvent;
	import flash.net.URLLoader;
	import flash.net.URLLoaderDataFormat;
	import flash.net.URLRequest;
	import flash.utils.ByteArray;
	import flash.utils.Dictionary;
	
	import mx.logging.Log;
	import mx.rpc.Fault;
	
	public class UniURLLoader extends EventDispatcher
	{
		// FIXME: We should have multiple Loader's for images!
		protected var md_imageLoaderToRequestMap: Dictionary = new Dictionary();
		protected var md_urlLoaderToRequestMap: Dictionary = new Dictionary();
		
		public static const DATA_LOADED: String = "dataLoaded";
		public static const DATA_LOAD_FAILED: String = "dataLoadFailed";

		[Event(name = DATA_LOADED, type = "com.iblsoft.flexiweather.utils.UniURLLoaderEvent")]
		[Event(name = DATA_LOAD_FAILED, type = "com.iblsoft.flexiweather.utils.UniURLLoaderEvent")]
		
		public static const ERROR_BAD_IMAGE: String = "errorBadImage";
		public static const ERROR_IO: String = "errorIO";
		public static const ERROR_SECURITY: String = "errorSecurity";
		public static const ERROR_CANCELLED: String = "errorCancelled";
		
		public var data: Object; // user data
		
		public function UniURLLoader()
		{}
		
		public function load(urlRequest: URLRequest): void
		{
			trace("Requesting " + urlRequest.url + " " + urlRequest.data);
			var urlLoader: URLLoader = new URLLoader();
			urlLoader.dataFormat = URLLoaderDataFormat.BINARY;
			urlLoader.addEventListener(Event.COMPLETE, onDataComplete);
			urlLoader.addEventListener(IOErrorEvent.IO_ERROR, onDataIOError);
			urlLoader.addEventListener(SecurityErrorEvent.SECURITY_ERROR, onSecurityError);
			urlLoader.load(urlRequest);
			md_urlLoaderToRequestMap[urlLoader] = urlRequest;
		}
		
		/*
		public function cancel(urlRequest: URLRequest): void
		{
			// TODO: We need a map from urlRequest to urlLoader
		}
		*/
		
		protected function onDataComplete(event: Event): void
		{
			var urlLoader: URLLoader = URLLoader(event.target);
			var urlRequest: URLRequest = disconnectURLLoader(urlLoader);

			var rawData: ByteArray = event.target.data as ByteArray;
			//Log.getLogger("UniURLLoader").info("Received " + rawData.length + "B");

			var b0: int = rawData.length > 0 ? rawData.readUnsignedByte() : -1;
			var b1: int = rawData.length > 1 ? rawData.readUnsignedByte() : -1;
			var b2: int = rawData.length > 2 ? rawData.readUnsignedByte() : -1;
			var b3: int = rawData.length > 3 ? rawData.readUnsignedByte() : -1;
			
			rawData.position = 0;
			// 0x89 P N G
			if(b0 == 0x89 && b1 == 0x50 && b2 == 0x4E && b3 == 0x47) {
				var imageLoader: Loader = new Loader();
				md_imageLoaderToRequestMap[imageLoader] = urlRequest;
				imageLoader.contentLoaderInfo.addEventListener(Event.COMPLETE, onImageLoaded);
	            imageLoader.contentLoaderInfo.addEventListener(IOErrorEvent.IO_ERROR, onImageLoadingIOError);
				imageLoader.loadBytes(rawData);
				return;
			}
			// < - this is quite a weak heuristics
			else if(b0 == 0x3C) {
				var s_data: String = rawData.readUTFBytes(rawData.length);
				try {
					var x: XML = new XML(s_data);
					dispatchResult(urlRequest, x);
				}
				catch(e: Error) {
					dispatchResult(urlRequest, s_data);
				}
			}
			else
				dispatchResult(urlRequest, rawData);
		}

		protected function onDataIOError(event: IOErrorEvent): void
		{
			var urlLoader: URLLoader = URLLoader(event.target);
			var urlRequest: URLRequest = disconnectURLLoader(urlLoader);

			Log.getLogger("UniURLLoader").info("I/O error: " + event.text);
			dispatchFault(urlRequest, ERROR_IO, event.text);
		}

		protected function onSecurityError(event: SecurityErrorEvent): void
		{
			var urlLoader: URLLoader = URLLoader(event.target);
			var urlRequest: URLRequest = disconnectURLLoader(urlLoader);

			Log.getLogger("UniURLLoader").info("Security error: " + event.text);
			dispatchFault(urlRequest, ERROR_SECURITY, event.text);
		}

		protected function onImageLoaded(event: Event): void
		{
			var imageLoader: Loader = Loader(event.target.loader);
			var urlRequest: URLRequest = disconnectImageLoader(imageLoader);
			dispatchResult(urlRequest, imageLoader.content);
		}

		protected function onImageLoadingIOError(event: IOErrorEvent): void
		{
			var imageLoader: Loader = Loader(event.target.loader);
			var urlRequest: URLRequest = disconnectImageLoader(imageLoader);
			dispatchFault(urlRequest, ERROR_BAD_IMAGE, event.text);
		}
		
		protected function dispatchResult(urlRequest: URLRequest, o: Object): void
		{
			var e: UniURLLoaderEvent = new UniURLLoaderEvent(DATA_LOADED, o, urlRequest, false, true);
			dispatchEvent(e);  
		}

		protected function dispatchFault(
				urlRequest: URLRequest, 
				faultCode: String,
				faultString: String,
				faultDetail: String = null): void
		{
			dispatchEvent(new UniURLLoaderEvent(
					DATA_LOAD_FAILED,
					new Fault(faultCode, faultString, faultDetail),
					urlRequest,
					false, true));  
		}

		protected function disconnectURLLoader(urlLoader: URLLoader): URLRequest
		{
			urlLoader.removeEventListener(Event.COMPLETE, onDataComplete);
			urlLoader.removeEventListener(IOErrorEvent.IO_ERROR, onDataIOError);
			urlLoader.removeEventListener(SecurityErrorEvent.SECURITY_ERROR, onSecurityError);
			var urlRequest: URLRequest = md_urlLoaderToRequestMap[urlLoader]; 
			delete md_urlLoaderToRequestMap[urlLoader];
			return urlRequest;
		}

		protected function disconnectImageLoader(imageLoader: Loader): URLRequest
		{
			imageLoader.contentLoaderInfo.removeEventListener(Event.COMPLETE, onImageLoaded);
            imageLoader.contentLoaderInfo.removeEventListener(IOErrorEvent.IO_ERROR, onImageLoadingIOError);
			var urlRequest: URLRequest = md_imageLoaderToRequestMap[imageLoader]; 
			delete md_imageLoaderToRequestMap[imageLoader];
			return urlRequest;
		}
		
	}
}