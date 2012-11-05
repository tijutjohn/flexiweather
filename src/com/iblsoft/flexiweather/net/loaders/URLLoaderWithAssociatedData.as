package com.iblsoft.flexiweather.net.loaders
{
	import flash.net.URLLoader;
	import flash.net.URLRequest;

	public class URLLoaderWithAssociatedData extends URLLoader
	{
		public var associatedData: Object;
		public var b_crossDomainProxyRequest: Boolean = false;

		public function URLLoaderWithAssociatedData(request: URLRequest = null)
		{
			super(request);
		}
	}
}
