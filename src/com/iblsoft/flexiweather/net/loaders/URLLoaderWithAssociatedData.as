package com.iblsoft.flexiweather.net.loaders
{
	import flash.net.URLLoader;
	import flash.net.URLRequest;

	public class URLLoaderWithAssociatedData extends URLLoader
	{
		public static var uid: int = 0;

		public var loaderID: int;

		public var associatedData: Object;
		public var b_crossDomainProxyRequest: Boolean = false;

		public function URLLoaderWithAssociatedData(request: URLRequest = null)
		{
			loaderID = uid++;
			super(request);
		}

		override public function toString(): String
		{
			return "URLLoaderWithAssociatedData ["+loaderID+"]";
		}
	}
}
