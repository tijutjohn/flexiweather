package com.iblsoft.flexiweather.utils
{
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.IOErrorEvent;
	import flash.events.SecurityErrorEvent;
	import flash.net.URLLoaderDataFormat;
	import flash.net.URLRequest;
	import flash.utils.ByteArray;
	import flash.utils.Dictionary;
	
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
		
		public function load(urlRequest: URLRequest, associatedData: Object = null): void
		{
			trace("Requesting " + urlRequest.url + " " + urlRequest.data);
			var urlLoader: URLLoaderWithAssociatedData = new URLLoaderWithAssociatedData();
			urlLoader.associatedData = associatedData;
			urlLoader.dataFormat = URLLoaderDataFormat.BINARY;
			urlLoader.addEventListener(Event.COMPLETE, onDataComplete);
			urlLoader.addEventListener(IOErrorEvent.IO_ERROR, onDataIOError);
			urlLoader.addEventListener(SecurityErrorEvent.SECURITY_ERROR, onSecurityError);
			urlLoader.load(urlRequest);
			md_urlLoaderToRequestMap[urlLoader] = {
				request: urlRequest,
				loader: urlLoader
			};
		}
		
		public function cancel(urlRequest: URLRequest): Boolean
		{
			for each(var s_key: String in md_urlLoaderToRequestMap) {
				if(md_urlLoaderToRequestMap[s_key].request == urlRequest) {
					md_urlLoaderToRequestMap[s_key].request.loader.close();
					delete md_urlLoaderToRequestMap[s_key];
					return true;
				}
			}
			return false;
		}
		
		protected function onDataComplete(event: Event): void
		{
			var urlLoader: URLLoaderWithAssociatedData = URLLoaderWithAssociatedData(event.target);
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

			Log.getLogger("UniURLLoader").info("I/O error: " + event.text);
			dispatchFault(urlRequest, urlLoader.associatedData, ERROR_IO, event.text);
		}

		protected function onSecurityError(event: SecurityErrorEvent): void
		{
			var urlLoader: URLLoaderWithAssociatedData = URLLoaderWithAssociatedData(event.target);
			var urlRequest: URLRequest = disconnectURLLoader(urlLoader);

			Log.getLogger("UniURLLoader").info("Security error: " + event.text);
			dispatchFault(urlRequest, urlLoader.associatedData, ERROR_SECURITY, event.text);
		}

		protected function onImageLoaded(event: Event): void
		{
			var imageLoader: LoaderWithAssociatedData = LoaderWithAssociatedData(event.target.loader);
			var urlRequest: URLRequest = disconnectImageLoader(imageLoader);
			dispatchResult(imageLoader.content, urlRequest, imageLoader.associatedData);
		}

		protected function onImageLoadingIOError(event: IOErrorEvent): void
		{
			var imageLoader: LoaderWithAssociatedData = LoaderWithAssociatedData(event.target.loader);
			var urlRequest: URLRequest = disconnectImageLoader(imageLoader);
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
			var urlRequest: URLRequest = md_urlLoaderToRequestMap[urlLoader].request; 
			delete md_urlLoaderToRequestMap[urlLoader];
			return urlRequest;
		}

		protected function disconnectImageLoader(imageLoader: LoaderWithAssociatedData): URLRequest
		{
			imageLoader.contentLoaderInfo.removeEventListener(Event.COMPLETE, onImageLoaded);
            imageLoader.contentLoaderInfo.removeEventListener(IOErrorEvent.IO_ERROR, onImageLoadingIOError);
			var urlRequest: URLRequest = md_imageLoaderToRequestMap[imageLoader]; 
			delete md_imageLoaderToRequestMap[imageLoader];
			return urlRequest;
		}
		
	}
}

import flash.net.URLLoader;
import flash.display.Loader;

class URLLoaderWithAssociatedData extends URLLoader
{
	public var associatedData: Object;
}

class LoaderWithAssociatedData extends Loader
{
	public var associatedData: Object;
}
