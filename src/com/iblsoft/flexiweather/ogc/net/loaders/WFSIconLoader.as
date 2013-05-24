package com.iblsoft.flexiweather.ogc.net.loaders
{
	import com.iblsoft.flexiweather.net.events.UniURLLoaderErrorEvent;
	import com.iblsoft.flexiweather.net.events.UniURLLoaderEvent;
	import com.iblsoft.flexiweather.net.loaders.UniURLLoader;
	import flash.events.EventDispatcher;
	import flash.net.URLRequest;
	import flash.utils.Dictionary;

	public class WFSIconLoader extends EventDispatcher
	{
		internal static var sm_instance: WFSIconLoader;
		protected var md_iconStorage: Dictionary = new Dictionary();
		protected var md_loadingIcons: Dictionary = new Dictionary();
		protected var ml_loader: UniURLLoader = new UniURLLoader();

		/**
		 *
		 */
		public function WFSIconLoader()
		{
			if (sm_instance != null)
				throw new Error("WFSIconLoader can only be accessed through WFSIconLoader.getInstance");
			ml_loader = new UniURLLoader();
			ml_loader.addEventListener(UniURLLoaderEvent.DATA_LOADED, onIconLoaded);
			ml_loader.addEventListener(UniURLLoaderErrorEvent.DATA_LOAD_FAILED, onIconLoadFailed);
		}

		/**
		 *
		 */
		public static function getInstance(): WFSIconLoader
		{
			if (sm_instance == null)
				sm_instance = new WFSIconLoader();
			return sm_instance;
		}

		/**
		 * Function check if some icon was loaded before or not and call f_callbackFunction with preloaded icon.
		 * If WFSIconLoader doesn't alredy have loaded requested icon, it starts loading icon and after load it calls f_callbackFunction with loaded icon
		 */
		public function getIcon(s_iconName: String, f_callbackObject: Object, f_callbackFunction: Function, s_folder: String = 'SIGWX', i_width: int = 24, i_height: int = 24): Boolean
		{
			var s_url: String = iconUrl(s_iconName, s_folder, i_width, i_height);
			return getIconByURL(s_url, f_callbackObject, f_callbackFunction);
		}
		
		public function getIconFromDocstorage(s_docstoragePath: String, f_callbackObject: Object, f_callbackFunction: Function, i_width: int = 24, i_height: int = 24): Boolean
		{
			var s_url: String = iconDocstorageUrl(s_docstoragePath, i_width, i_height);
			return getIconByURL(s_url, f_callbackObject, f_callbackFunction);
		}
		
		private function getIconByURL(s_url: String, f_callbackObject: Object, f_callbackFunction: Function ): Boolean
		{			
			var b_alreadyLoaded: Boolean = iconExists(s_url);
			var b_currentlyLoading: Boolean = iconIsLoading(s_url);
			var d_assocData: IconAssociatedData;
			
			if (b_alreadyLoaded)
			{
				// HERE WE NEED INPLEMENT CHECK IF SOME SAME ICON IS NOT ALREADY LOADING
				f_callbackFunction.call(null, md_iconStorage[s_url]);
				return (true);
			}
			else if (b_currentlyLoading)
			{
				//wait till it will be loaded
				d_assocData = new IconAssociatedData(f_callbackFunction, s_url);
				var l_assocArray: Array = md_loadingIcons[s_url] as Array;
				l_assocArray.push(d_assocData);
				return (false);
			}
			else
			{
				d_assocData = new IconAssociatedData(f_callbackFunction, s_url);
				var nRequest: URLRequest = new URLRequest(s_url);
				md_loadingIcons[s_url] = [d_assocData];
				ml_loader.load(nRequest, d_assocData);
				return (false);
			}
		}

		private function iconUrl(s_iconName: String, s_folder: String = 'SIGWX', i_width: int = 24, i_height: int = 24): String
		{
			var url: String = '${BASE_URL}/ria/helpers/gpaint-macro/render/' + s_folder + '/' + s_iconName + '?width=' + i_width + '&height=' + i_height;
			return url;
		}
		
		private function iconDocstorageUrl(s_docstoragePath: String, i_width: int = 24, i_height: int = 24): String
		{
			//wms.iblsoft.com/ria/helpers/gpaint-macro/render?doc=doc%3aglobal/macros/SIGWX/hail&WIDTH=128&FORMAT=PNG
			var s_url: String = '${BASE_URL}/ria/helpers/gpaint-macro/render?doc=' + encodeURIComponent(s_docstoragePath) + 
				"&width=" + i_width + '&height=' + i_height;
			return s_url;			
		}

		private function iconIsLoading(s_url: String): Boolean
		{
			return md_loadingIcons.hasOwnProperty(s_url);
		}

		private function iconExists(s_url: String): Boolean
		{
			return md_iconStorage.hasOwnProperty(s_url);
		}

		/**
		 *
		 */
		protected function onIconLoaded(evt: UniURLLoaderEvent): void
		{
			var d_assocData: IconAssociatedData = IconAssociatedData(evt.associatedData);
			var s_url: String = d_assocData.url;
			md_iconStorage[s_url] = evt.result;
			var l_assocArray: Array = md_loadingIcons[s_url];
			for each (d_assocData in l_assocArray)
			{
				d_assocData.callbackFunction.apply(null, [evt.result]);
			}
			delete md_loadingIcons[s_url];
		}

		/**
		 *
		 */
		protected function onIconLoadFailed(evt: UniURLLoaderErrorEvent): void
		{
			trace("WFSIconLoader onIconLoadFailed: " + evt.associatedData);
		}
	}
}

class IconAssociatedData
{
	public var callbackFunction: Function;
	public var url: String;

	public function IconAssociatedData(_callbackFunction: Function, s_url: String)
	{
		callbackFunction = _callbackFunction;
		url = s_url;
	}
}
