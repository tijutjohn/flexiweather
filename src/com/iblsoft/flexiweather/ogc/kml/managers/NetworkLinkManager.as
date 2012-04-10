package com.iblsoft.flexiweather.ogc.kml.managers
{
	import com.iblsoft.flexiweather.ogc.kml.configuration.KMLLayerConfiguration;
	import com.iblsoft.flexiweather.ogc.kml.events.KMLEvent;
	import com.iblsoft.flexiweather.ogc.kml.features.NetworkLink;
	
	import flash.utils.Dictionary;

	public class NetworkLinkManager extends KMLLoaderManager
	{
		private var _links: Array;
		private var _linksDictionary: Dictionary;
		
		public function NetworkLinkManager()
		{
			super();
			
			_links = new Array();
			_linksDictionary = new Dictionary();
		}
		
		public function addNetworkLink(link: NetworkLink, bLoad: Boolean = false): void
		{
			_links.push(link);
			_linksDictionary[link.link.href] = {link: link};
			
			if (bLoad)
			{
				loadNetworkLink(link);
			}
		}
		
		private function loadNetworkLink(link: NetworkLink): void
		{
			addKMLLink(link.link.href, null,  true);
		}
		
		override protected function onKMLFileLoaded(event: KMLEvent): void
		{
			super.onKMLFileLoaded(event);
			
			var kmlConfig: KMLLayerConfiguration = event.currentTarget as KMLLayerConfiguration;
			var kmlURL: String = kmlConfig.kmlPath;
			
			var linkObj: Object = _linksDictionary[kmlURL];
			var link: NetworkLink = linkObj.link;
			
			delete _linksDictionary[kmlURL];
			
			link.addLoadedKML(kmlConfig.kml);
//			
//			event.data = _kmlLayerDictionary[kmlURL];
//			//notify
//			dispatchEvent(event);
//			
//			kmlLoadingAndParsingFinished();
		}
	}
}