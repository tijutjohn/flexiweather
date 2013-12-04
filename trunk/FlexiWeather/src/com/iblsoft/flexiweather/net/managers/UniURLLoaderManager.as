package com.iblsoft.flexiweather.net.managers
{
	import flash.events.EventDispatcher;
	import flash.net.URLRequest;
	import com.iblsoft.flexiweather.net.events.UniURLLoaderEvent;

	public class UniURLLoaderManager extends EventDispatcher
	{
		public static const ADD_LOADER: String = 'addLoader';
		public static const REMOVE_LOADER: String = 'removeLoader';
		private static var _instance: UniURLLoaderManager;

		public static function get instance(): UniURLLoaderManager
		{
			if (!_instance)
				_instance = new UniURLLoaderManager();
			return _instance;
		}

		public function UniURLLoaderManager()
		{
		}

		public function addLoaderRequest(request: URLRequest): void
		{
			var e: UniURLLoaderEvent = new UniURLLoaderEvent(ADD_LOADER, null, request, null);
			dispatchEvent(e);
		}

		public function removeLoaderRequest(request: URLRequest): void
		{
			var e: UniURLLoaderEvent = new UniURLLoaderEvent(REMOVE_LOADER, null, request, null);
			dispatchEvent(e);
		}
	}
}
