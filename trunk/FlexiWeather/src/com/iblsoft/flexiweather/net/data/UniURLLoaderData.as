package com.iblsoft.flexiweather.net.data
{
	import com.iblsoft.flexiweather.net.loaders.AbstractURLLoader;
	import flash.net.URLRequest;

	public class UniURLLoaderData
	{
		public var request: URLRequest;
		public var loader: AbstractURLLoader;
		public var associatedData: Object;
		public var backgroundJobName: String;

		public function UniURLLoaderData(request: URLRequest, loader: AbstractURLLoader, associatedData: Object, backgroundJobName: String)
		{
			this.request = request;
			this.loader = loader;
			this.associatedData = associatedData;
			this.backgroundJobName = backgroundJobName;
		}

		public function destroy(): void
		{
			request = null;
			if (loader)
			{
				loader.destroy();
				loader = null;
			}
			associatedData = null;
		}

		public function toString(): String
		{
			var str: String = "UniURLLoaderData: ";
			if (request)
				str += " Request: " + request.url;
			if (loader)
				str += " Loader: " + loader;
			if (associatedData)
			{
				for each (var name: String in associatedData)
				{
					str += "\t" + name + " = " + associatedData[name];
				}
			}
			if (backgroundJobName)
				str += " backgroundJobName: " + backgroundJobName;
			return str;
		}
	}
}
