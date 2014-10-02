package com.iblsoft.flexiweather.ogc.net.loaders
{
	import com.iblsoft.flexiweather.net.UniURLLoaderFormat;
	import com.iblsoft.flexiweather.net.data.UniURLLoaderData;
	import com.iblsoft.flexiweather.net.loaders.ImageLoader;
	import com.iblsoft.flexiweather.net.loaders.URLLoaderWithAssociatedData;
	import com.iblsoft.flexiweather.net.loaders.UniURLLoader;
	import com.iblsoft.flexiweather.net.loaders.XMLLoader;
	import com.iblsoft.flexiweather.net.loaders.errors.URLLoaderError;
	import com.iblsoft.flexiweather.widgets.basicauth.data.BasicAuthAccount;
	
	import flash.net.URLRequest;
//	import flash.system.ImageDecodingPolicy;
	import flash.system.LoaderContext;
	import flash.utils.ByteArray;
	
	import mx.events.DynamicEvent;

	public class WMSImageLoader extends ImageLoader
	{
		public function WMSImageLoader()
		{
			super();
		}

		override public function load(urlRequest:URLRequest, associatedData:Object=null, s_backgroundJobName:String=null, useBasicAuthInRequest:Boolean=false, basicAuthAccount:BasicAuthAccount=null, basicAuthRequestData:UniURLLoaderData=null, loaderContext: LoaderContext = null):void
		{
			var loaderContext: LoaderContext = new LoaderContext();
//			loaderContext.imageDecodingPolicy = ImageDecodingPolicy.ON_LOAD;
			super.load(urlRequest, associatedData, s_backgroundJobName, useBasicAuthInRequest, basicAuthAccount, basicAuthRequestData, loaderContext);
		}
		override protected function decodeResult(rawData: ByteArray, urlLoader: URLLoaderWithAssociatedData, urlRequest: URLRequest, resultCallback: Function, errorCallback: Function): void
		{
			var validXML: Boolean = XMLLoader.isValidXML(rawData);
			var validImage: Boolean = ImageLoader.isValidImage(rawData);
			if (validImage)
			{
				super.decodeResult(rawData, urlLoader, urlRequest, resultCallback, errorCallback);
				return;
			}
			if (validXML)
			{
//				resultCallback(new XML(cloneByteArrayToString(rawData)), urlRequest, urlLoader.associatedData);
				//xml in WMS means error
				errorCallback("WMS Image Loader error: XML is received", URLLoaderError.UNSPECIFIED_ERROR, new XML(cloneByteArrayToString(rawData)), urlRequest, urlLoader.associatedData);
				return;
			}
			errorCallback("WMS Image Loader error: Expected Image or XML", URLLoaderError.UNSPECIFIED_ERROR, rawData, urlRequest, urlLoader.associatedData);
		}

		public static function isWMSServiceException(data: Object): Boolean
		{
			var xmlSource: String;
			var xml: XML
			if (data is String)
			{
				xmlSource = data as String;
				xml = new XML(xmlSource);
			}
			if (data is XML)
				xml = data as XML;
			var topName: String = xml.name().localName;
			var children: XMLList = xml.children();
			if (children)
			{
				var child: XML = children[0] as XML;
				var childName: String = (child.name() as QName).localName;
				if (child.hasOwnProperty('@code'))
				{
					var codeName: String = child.@code;
					if (topName == 'ServiceExceptionReport' && childName == 'ServiceException' && codeName == 'OperationNotSupported')
						return true;
				}
			}
			return false;
		}
	}
}
