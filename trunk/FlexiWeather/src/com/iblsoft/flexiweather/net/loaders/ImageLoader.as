package com.iblsoft.flexiweather.net.loaders
{
	import com.iblsoft.flexiweather.net.loaders.errors.URLLoaderError;
	
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.net.URLRequest;
	import flash.utils.ByteArray;
	import flash.utils.Dictionary;
	
	import mx.utils.ObjectUtil;

	public class ImageLoader extends AbstractURLLoader
	{
		protected var md_imageLoaders: Dictionary = new Dictionary();
		protected var md_imageLoaderToRequestMap: Dictionary = new Dictionary();

		public function ImageLoader()
		{
			super();
//			allowedFormats = [UniURLLoader.IMAGE_FORMAT];
		}

		override public function destroy(): void
		{
			super.destroy();
			var id: String;
			var obj: Object;
			if (md_imageLoaders)
			{
				for (id in md_imageLoaders)
				{
					obj = md_imageLoaders[id];
				}
			}
			if (md_imageLoaderToRequestMap)
			{
				for (id in md_imageLoaderToRequestMap)
				{
					obj = md_imageLoaderToRequestMap[id];
				}
			}
		}

		override protected function decodeResult(rawData: ByteArray, urlLoader: URLLoaderWithAssociatedData, urlRequest: URLRequest, resultCallback: Function, errorCallback: Function): void
		{
			var isValid: Boolean = ImageLoader.isValidImage(rawData);
			if (isValid)
			{
				loadImage(rawData, urlLoader, urlRequest, resultCallback, errorCallback);
				return;
			}
			errorCallback("Image Loader error: Expected Image", URLLoaderError.UNSPECIFIED_ERROR, rawData, urlRequest, urlLoader.associatedData);
		}

		protected function loadImage(rawData: ByteArray, urlLoader: URLLoaderWithAssociatedData, urlRequest: URLRequest, resultCallback: Function, errorCallback: Function): void
		{
			var imageLoader: LoaderWithAssociatedData = createImageLoader(rawData, urlLoader.associatedData, urlRequest);
			md_imageLoaders[imageLoader] = {result: resultCallback, error: errorCallback};
		}

		protected function createImageLoader(rawData: ByteArray, associatedData: Object, urlRequest: URLRequest): LoaderWithAssociatedData
		{
			var imageLoader: LoaderWithAssociatedData = new LoaderWithAssociatedData();
			imageLoader.associatedData = associatedData;
			md_imageLoaderToRequestMap[imageLoader] = urlRequest;
			imageLoader.contentLoaderInfo.addEventListener(Event.COMPLETE, onImageLoaded);
			imageLoader.contentLoaderInfo.addEventListener(IOErrorEvent.IO_ERROR, onImageLoadingIOError);
			imageLoader.loadBytes(ObjectUtil.copy(rawData) as ByteArray);
			return imageLoader;
		}

		protected function onImageLoaded(event: Event): void
		{
			var imageLoader: LoaderWithAssociatedData = LoaderWithAssociatedData(event.target.loader);
			var urlRequest: URLRequest = disconnectImageLoader(imageLoader);
			var callbackObject: Object = md_imageLoaders[imageLoader];
			delete md_imageLoaders[imageLoader];
			if (urlRequest == null)
				return;
			callbackObject.result(imageLoader.content, urlRequest, imageLoader.associatedData);
		}

		protected function onImageLoadingIOError(event: IOErrorEvent): void
		{
			var imageLoader: LoaderWithAssociatedData = LoaderWithAssociatedData(event.target.loader);
			var urlRequest: URLRequest = disconnectImageLoader(imageLoader);
			var callbackObject: Object = md_imageLoaders[imageLoader];
			delete md_imageLoaders[imageLoader];
			if (urlRequest == null)
				return;
			callbackObject.error('Image Loader Error: IO Error loading image: ' + event.text, null, imageLoader.content, urlRequest, imageLoader.associatedData);
//			dispatchFault(urlRequest, imageLoader.associatedData, ERROR_BAD_IMAGE, event.text);
		}

		override public function cancel(urlRequest: URLRequest): Boolean
		{
			var cancelBool: Boolean = super.cancel(urlRequest);
			if (!cancelBool)
			{
				var key: Object;
				for (key in md_imageLoaderToRequestMap)
				{
					var test: * = md_imageLoaderToRequestMap[key];
					if (test && test.hasOwnProperty('request') && test.request)
					{
						if (test.request == urlRequest)
						{
							test.loader.close();
							disconnectImageLoader(LoaderWithAssociatedData(md_imageLoaderToRequestMap[key].loader)); // as LoaderWithAssociatedData);
							delete md_imageLoaderToRequestMap[key];
							return true;
						}
					}
					else
						trace("ImageLoader cancel Loader exists, but it has no request property");
				}
			}
			return false;
		}

		protected function disconnectImageLoader(imageLoader: LoaderWithAssociatedData): URLRequest
		{
			imageLoader.contentLoaderInfo.removeEventListener(Event.COMPLETE, onImageLoaded);
			imageLoader.contentLoaderInfo.removeEventListener(IOErrorEvent.IO_ERROR, onImageLoadingIOError);
			var urlRequest: URLRequest = md_imageLoaderToRequestMap[imageLoader];
			delete md_imageLoaderToRequestMap[imageLoader];
			if (!imageLoader in md_imageLoaderToRequestMap)
				return null;
			return urlRequest;
		}

		public static function isValidImage(data: Object): Boolean
		{
			if (data is ByteArray)
			{
				//we need to clone BYteArray, otherwise readded bytes will be removed from ByteArray
				var ba: ByteArray = data as ByteArray;
				
				var b0: int = ba.length > 0 ? ba.readUnsignedByte() : -1;
				var b1: int = ba.length > 1 ? ba.readUnsignedByte() : -1;
				var b2: int = ba.length > 2 ? ba.readUnsignedByte() : -1;
				var b3: int = ba.length > 3 ? ba.readUnsignedByte() : -1;
				
				ba.position = 0;
				
				var isPNG: Boolean = b0 == 0x89 && b1 == 0x50 && b2 == 0x4E && b3 == 0x47;
				var isGIF: Boolean = b0 == 0x47 && b1 == 0x49 && b2 == 0x46;
				var isJPG: Boolean = b0 == 0xff && b1 == 0xd8 && b2 == 0xff && b3 == 0xe0;
				var isJPG2: Boolean = b0 == 0xff && b1 == 0xd8 && b2 == 0xff && b3 == 0xe1;
				//SWT format
				var isSWF: Boolean = b0 == 0x46 && b1 == 0x57 && b2 == 0x53;
				//compressed SWF format
				var isCWF: Boolean = b0 == 0x43 && b1 == 0x57 && b2 == 0x53;
				if (isPNG || isJPG || isJPG2 || isGIF || isSWF || isCWF)
					return true;
			}
			return false;
		}
	}
}
