package com.iblsoft.flexiweather.utils
{
	import flash.display.Loader;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.IOErrorEvent;
	import flash.net.URLLoader;
	import flash.net.URLLoaderDataFormat;
	import flash.net.URLRequest;
	import flash.utils.ByteArray;
	
	import mx.rpc.Fault;
	
	public class UniURLLoader extends EventDispatcher
	{
		internal var m_loader: Loader = new Loader();
		internal var m_urlLoader: URLLoader = new URLLoader();
		
		public static const DATA_LOADED: String = "dataLoaded";
		public static const DATA_LOAD_FAILED: String = "dataLoadFailed";

		[Event(name = DATA_LOADED, type = "com.iblsoft.flexiweather.utils.UniURLLoaderEvent")]
		[Event(name = DATA_LOAD_FAILED, type = "com.iblsoft.flexiweather.utils.UniURLLoaderEvent")]
		
		public static const ERROR_BAD_IMAGE: String = "errorBadImage";
		public static const ERROR_IO: String = "errorIO";
		
		public var data: Object; // user data
		
		public function UniURLLoader()
		{
			m_urlLoader.dataFormat = URLLoaderDataFormat.BINARY;
			m_urlLoader.addEventListener(Event.COMPLETE, onDataComplete);
			m_urlLoader.addEventListener(IOErrorEvent.IO_ERROR, onDataIOError);

			m_loader.contentLoaderInfo.addEventListener(Event.COMPLETE, onImageLoaded);
            m_loader.contentLoaderInfo.addEventListener(IOErrorEvent.IO_ERROR, onImageLoadingIOError);
		}
		
		public function load(url: URLRequest): void
		{
			trace("Requesting " + url.url + " " + url.data); 
			m_urlLoader.load(url);
		}
		
		protected function dispatchResult(o: Object): void
		{
			var e: UniURLLoaderEvent = new UniURLLoaderEvent(DATA_LOADED, o, null, false, true);
			dispatchEvent(e);  
		}

		protected function dispatchFault(
				faultCode: String, faultString: String, faultDetail: String = null): void
		{
			dispatchEvent(new UniURLLoaderEvent(
					DATA_LOAD_FAILED,
					new Fault(faultCode, faultString, faultDetail),
					null,
					false, true));  
		}

		protected function onDataComplete(event: Event): void
		{
			var rawData: ByteArray = event.target.data as ByteArray;

			var b0: int = rawData.length > 0 ? rawData.readUnsignedByte() : -1;
			var b1: int = rawData.length > 1 ? rawData.readUnsignedByte() : -1;
			var b2: int = rawData.length > 2 ? rawData.readUnsignedByte() : -1;
			var b3: int = rawData.length > 3 ? rawData.readUnsignedByte() : -1;
			
			rawData.position = 0;
			// 0x89 P N G
			if(b0 == 0x89 && b1 == 0x50 && b2 == 0x4E && b3 == 0x47) {
				m_loader.loadBytes(rawData);
				return;
			}
			// < - this is quite a weak heuristics
			else if(b0 == 0x3C) {
				var s_data: String = rawData.readUTFBytes(rawData.length);
				try {
					var x: XML = new XML(s_data);
					dispatchResult(x);
				}
				catch(e: Error) {
					dispatchResult(s_data);
				}
			}
			else
				dispatchResult(rawData);
		}

		protected function onDataIOError(event: IOErrorEvent): void
		{
			dispatchFault(ERROR_IO, event.text);
		}

		protected function onImageLoaded(event: Event): void
		{
			var loader: Loader = Loader(event.target.loader);
			dispatchResult(loader.content);
		}

		protected function onImageLoadingIOError(event: IOErrorEvent): void
		{
			dispatchFault(ERROR_BAD_IMAGE, event.text);
		}
		
	}
}