package com.iblsoft.flexiweather.net.data
{
	import flash.net.URLRequest;
	import com.iblsoft.flexiweather.utils.UniURLLoader;

	public class UniURLLoaderData
	{
		public var request: URLRequest;
		public var loader: UniURLLoader;
		public var associatedData: Object;
		public var backgroundJobName: String;
		
		public function UniURLLoaderData(request: URLRequest, loader: UniURLLoader, associatedData: Object, backgroundJobName: String)
		{
			this.request = request;
			this.loader = loader;
			this.associatedData = associatedData;
			this.backgroundJobName = backgroundJobName;
		}
	}
}