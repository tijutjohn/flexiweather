package com.iblsoft.flexiweather.utils
{
	import com.iblsoft.flexiweather.widgets.BackgroundJob;
	import com.iblsoft.flexiweather.widgets.BackgroundJobManager;
	
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.IOErrorEvent;
	import flash.events.SecurityErrorEvent;
	import flash.net.URLLoaderDataFormat;
	import flash.net.URLRequest;
	import flash.utils.ByteArray;
	import flash.utils.Dictionary;
	
	import mx.controls.Alert;
	import mx.logging.Log;
	import mx.rpc.Fault;
	
	/**
	 * Replacement of flash.net.URLLoader and flash.display.Loader classes
	 * which unites abilities of both and provides automatic detection of received data format.
	 * Recognised formats are:
	 * - PNG images
	 * - XML data
	 * - other binary/text data
	 * This class is designed to handle parallel HTTP requests fired by the load() method.
	 * Each request may have associated data, which are then dispatched to UniURLLoader user
	 * together with UniURLLoaderEvent.
	 * Each call to load() method instanties internal a new URLLoader instance.
	 * 
	 * There are only 2 types of event (DATA_LOADED, DATA_LOAD_FAILED) dispatched out of this class,
	 * so that the class can be used simplier.
	*/
	public class UniURLLoader extends EventDispatcher
	{
		// FIXME: We should have multiple Loader's for images!
		protected var md_imageLoaderToRequestMap: Dictionary = new Dictionary();
		protected var md_urlLoaderToRequestMap: Dictionary = new Dictionary();
		
		public static var baseURL: String = '';

		/**
		 * URL of the cross-domain script bridging script. The ${URL} pattern
		 * in this string is replaced with the actual URL required to be proxied.
		 * This string may use the ${BASE_URL} expansion.
		 * 
		 * Example: "http://server.com/proxy?url=${URL}"
		 */
		public static var crossDomainProxyURLPattern: String = null;
		
		public static const DATA_LOADED: String = "dataLoaded";
		public static const DATA_LOAD_FAILED: String = "dataLoadFailed";

		[Event(name = DATA_LOADED, type = "com.iblsoft.flexiweather.utils.UniURLLoaderEvent")]
		[Event(name = DATA_LOAD_FAILED, type = "com.iblsoft.flexiweather.utils.UniURLLoaderEvent")]
		
		public static const ERROR_BAD_IMAGE: String = "errorBadImage";
		public static const ERROR_IO: String = "errorIO";
		public static const ERROR_SECURITY: String = "errorSecurity";
		public static const ERROR_CANCELLED: String = "errorCancelled";
		
		/** Deprecated - associated data. Use load(request, associatedData) instead. */
		public var data: Object;
		
		public function UniURLLoader()
		{}
		
		public static function navigateToURL(request: URLRequest): void
		{
			flash.net.navigateToURL(new URLRequest(UniURLLoader.fromBaseURL(request.url)));
		}

		public static function fromBaseURL(s_url: String): String
		{
			if(s_url.indexOf("${BASE_URL}") >= 0)
			{
				var regExp: RegExp = /\$\{BASE_URL\}/ig;
				while(regExp.exec(s_url) != null)
				{
					s_url = s_url.replace(regExp, baseURL);
//					trace("replace url: " + urlRequest.url + " baseURL: " + baseURL);
				}
			}	
			return s_url;
		}
		
		private function checkRequestBaseURL(urlRequest: URLRequest): void
		{
			urlRequest.url = convertBaseURL(urlRequest.url);
		}
		
		public function convertBaseURL(url: String): String
		{
			return UniURLLoader.fromBaseURL(url);
		}
		
		public function load(
				urlRequest: URLRequest,
				associatedData: Object = null,
				s_backgroundJobName: String = null): void
		{
			checkRequestBaseURL(urlRequest);
			
//			trace("Requesting " + urlRequest.url + " " + urlRequest.data);
			var urlLoader: URLLoaderWithAssociatedData = new URLLoaderWithAssociatedData();
			urlLoader.associatedData = associatedData;
			urlLoader.dataFormat = URLLoaderDataFormat.BINARY;
			urlLoader.addEventListener(Event.COMPLETE, onDataComplete);
			urlLoader.addEventListener(IOErrorEvent.IO_ERROR, onDataIOError);
			urlLoader.addEventListener(SecurityErrorEvent.SECURITY_ERROR, onSecurityError);
			urlLoader.load(urlRequest);
			
			var backgroundJob: BackgroundJob = null;
			if(s_backgroundJobName != null)
				backgroundJob = BackgroundJobManager.getInstance().startJob(s_backgroundJobName);
			md_urlLoaderToRequestMap[urlLoader] = {
				request: urlRequest,
				loader: urlLoader,
				backgroundJob: backgroundJob
			};
		}
		
		public function cancel(urlRequest: URLRequest): Boolean
		{
			var key: Object;
			for(key in md_urlLoaderToRequestMap) {
				if(md_urlLoaderToRequestMap[key].request === urlRequest) {
					md_urlLoaderToRequestMap[key].loader.close();
					disconnectURLLoader(URLLoaderWithAssociatedData(md_urlLoaderToRequestMap[key].loader)); 
					delete md_urlLoaderToRequestMap[key];
					return true;
				}
			}
			for(key in md_imageLoaderToRequestMap) {
				var test: * = md_imageLoaderToRequestMap[key];
				if(test && test.hasOwnProperty('request') && test.request)
				{
					
					if(test.request == urlRequest) 
					{
						test.loader.close();
						disconnectImageLoader(LoaderWithAssociatedData(md_imageLoaderToRequestMap[key].loader)); // as LoaderWithAssociatedData);
						delete md_imageLoaderToRequestMap[key];
						return true;
					}
				} else {
					trace("UniURLLoader cancel Loade exists, but it has no request property");
				}
			}
			return false;
		}
		
		protected function onDataComplete(event: Event): void
		{
			var urlLoader: URLLoaderWithAssociatedData = URLLoaderWithAssociatedData(event.target);
			var urlRequest: URLRequest = disconnectURLLoader(urlLoader);
			if(urlRequest == null)
				return;

			var rawData: ByteArray = event.target.data as ByteArray;
			//Log.getLogger("UniURLLoader").info("Received " + rawData.length + "B");

			var b0: int = rawData.length > 0 ? rawData.readUnsignedByte() : -1;
			var b1: int = rawData.length > 1 ? rawData.readUnsignedByte() : -1;
			var b2: int = rawData.length > 2 ? rawData.readUnsignedByte() : -1;
			var b3: int = rawData.length > 3 ? rawData.readUnsignedByte() : -1;
			
			rawData.position = 0;
			// 0x89 P N G
			if(b0 == 0x89 && b1 == 0x50 && b2 == 0x4E && b3 == 0x47) {
				var imageLoader: LoaderWithAssociatedData = new LoaderWithAssociatedData();
				imageLoader.associatedData = urlLoader.associatedData;
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
					dispatchResult(x, urlRequest, urlLoader.associatedData);
				}
				catch(e: Error) {
					dispatchResult(s_data, urlRequest, urlLoader.associatedData);
				}
			}
			else
				dispatchResult(rawData, urlRequest, urlLoader.associatedData);
		}

		protected function onDataIOError(event: IOErrorEvent): void
		{
			var urlLoader: URLLoaderWithAssociatedData = URLLoaderWithAssociatedData(event.target);
			var urlRequest: URLRequest = disconnectURLLoader(urlLoader);
			if(urlRequest == null)
				return;

			Log.getLogger("UniURLLoader").info("I/O error: " + event.text);
			dispatchFault(urlRequest, urlLoader.associatedData, ERROR_IO, event.text);
		}

		protected function onSecurityError(event: SecurityErrorEvent): void
		{
			var urlLoader: URLLoaderWithAssociatedData = URLLoaderWithAssociatedData(event.target);
			var urlRequest: URLRequest;
			
			// Try to use cross-domain proxy if received "Error #2048: Security sandbox violation:" 
			if(crossDomainProxyURLPattern != null
					&& event.text.match(/#2048/)
					&& !urlLoader.b_crossDomainProxyRequest) {
				var s_proxyURL: String = fromBaseURL(crossDomainProxyURLPattern);
				urlRequest = md_urlLoaderToRequestMap[urlLoader].request;
				var s_url: String = urlRequest.url;
				if(urlRequest.data) {
					if(s_url.indexOf("?") >= 0)
						s_url += "&";
					else
						s_url += "?";
					s_url += urlRequest.data;
				}
				s_proxyURL = s_proxyURL.replace("${URL}", encodeURI(s_url));
				//Alert.show("Got error:\n" + event.text + "\n"
				//		+ "Retrying:\n" + s_proxyURL + "\n",
				//		"SecurityErrorEvent received");
				urlRequest.url = s_proxyURL;
				urlLoader.b_crossDomainProxyRequest = true;
				urlLoader.load(urlRequest);
				return;
			}

			urlRequest = disconnectURLLoader(urlLoader);
			if(urlRequest == null)
				return;

			Log.getLogger("UniURLLoader").info("Security error: " + event.text);
			dispatchFault(urlRequest, urlLoader.associatedData, ERROR_SECURITY, event.text);
		}

		protected function onImageLoaded(event: Event): void
		{
			var imageLoader: LoaderWithAssociatedData = LoaderWithAssociatedData(event.target.loader);
			var urlRequest: URLRequest = disconnectImageLoader(imageLoader);
			if(urlRequest == null)
				return;

			dispatchResult(imageLoader.content, urlRequest, imageLoader.associatedData);
		}

		protected function onImageLoadingIOError(event: IOErrorEvent): void
		{
			var imageLoader: LoaderWithAssociatedData = LoaderWithAssociatedData(event.target.loader);
			var urlRequest: URLRequest = disconnectImageLoader(imageLoader);
			if(urlRequest == null)
				return;

			dispatchFault(urlRequest, imageLoader.associatedData, ERROR_BAD_IMAGE, event.text);
		}
		
		protected function dispatchResult(
				result: Object, urlRequest: URLRequest, associatedData: Object): void
		{
			var e: UniURLLoaderEvent = new UniURLLoaderEvent(
					DATA_LOADED, result, urlRequest, associatedData, false, true);
			dispatchEvent(e);  
		}

		protected function dispatchFault(
				urlRequest: URLRequest, associatedData: Object,
				faultCode: String,
				faultString: String,
				faultDetail: String = null): void
		{
			dispatchEvent(new UniURLLoaderEvent(
					DATA_LOAD_FAILED,
					new Fault(faultCode, faultString, faultDetail),
					urlRequest, associatedData,
					false, true));  
		}

		protected function disconnectURLLoader(urlLoader: URLLoaderWithAssociatedData): URLRequest
		{
			urlLoader.removeEventListener(Event.COMPLETE, onDataComplete);
			urlLoader.removeEventListener(IOErrorEvent.IO_ERROR, onDataIOError);
			urlLoader.removeEventListener(SecurityErrorEvent.SECURITY_ERROR, onSecurityError);
			if(!urlLoader in md_urlLoaderToRequestMap)
				return null;

			// finish background job if it was started
			var backgroundJob: BackgroundJob = md_urlLoaderToRequestMap[urlLoader].backgroundJob;
			if(backgroundJob != null)
				BackgroundJobManager.getInstance().finishJob(backgroundJob);
			
			var urlRequest: URLRequest = md_urlLoaderToRequestMap[urlLoader].request; 
			delete md_urlLoaderToRequestMap[urlLoader];
			return urlRequest;
		}

		protected function disconnectImageLoader(imageLoader: LoaderWithAssociatedData): URLRequest
		{
			imageLoader.contentLoaderInfo.removeEventListener(Event.COMPLETE, onImageLoaded);
            imageLoader.contentLoaderInfo.removeEventListener(IOErrorEvent.IO_ERROR, onImageLoadingIOError);
			var urlRequest: URLRequest = md_imageLoaderToRequestMap[imageLoader]; 
			if(!imageLoader in md_imageLoaderToRequestMap)
				return null;
			delete md_imageLoaderToRequestMap[imageLoader];
			return urlRequest;
		}
	}
}

import flash.display.Loader;
import flash.net.URLLoader;

class URLLoaderWithAssociatedData extends URLLoader
{
	public var associatedData: Object;
	public var b_crossDomainProxyRequest: Boolean = false;
}

class LoaderWithAssociatedData extends Loader
{
	public var associatedData: Object;
}
