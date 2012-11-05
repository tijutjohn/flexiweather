package com.iblsoft.flexiweather.ogc.kml.managers
{
	import com.iblsoft.flexiweather.ogc.kml.configuration.KMLLayerConfiguration;
	import com.iblsoft.flexiweather.ogc.kml.events.KMLEvent;
	import com.iblsoft.flexiweather.ogc.kml.events.NetworkLinkEvent;
	import com.iblsoft.flexiweather.ogc.kml.features.KML;
	import com.iblsoft.flexiweather.ogc.kml.features.NetworkLink;
	import flash.events.Event;
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

		/**
		 *
		 * @param link
		 * @param refreshInterval Value 0 means no refresh interval. Other value greater than 0 means refresh interval defined in miliseconds
		 * @param bLoad
		 *
		 */
		public function addNetworkLink(link: NetworkLink, refreshInterval: uint = 0, bLoad: Boolean = false): void
		{
			_links.push(link);
			_linksDictionary[link.link.href] = new NetworkLinkObject(link, refreshInterval);
			if (bLoad)
				loadNetworkLink(link);
		}

		private function loadNetworkLink(link: NetworkLink): void
		{
			if (link && link.link)
				addKMLLink(link.link.href, null, true);
		}

		private function unloadNetworkLink(link: NetworkLink): void
		{
			var kml: KML = link.contentKML;
			kml.resourceManager.debugCache("Before unload");
			kml.cleanup();
			kml.resourceManager.debugCache("After unload");
		}

		override protected function onKMLFileLoaded(event: KMLEvent): void
		{
			var kmlConfig: KMLLayerConfiguration = event.currentTarget as KMLLayerConfiguration;
			var kmlURL: String = kmlConfig.kmlPath;
			var linkObj: NetworkLinkObject = _linksDictionary[kmlURL];
			var link: NetworkLink = linkObj.link;
			if (!linkObj.needRefresh)
				delete _linksDictionary[kmlURL];
			else
				waitForRefresh(linkObj);
			link.addLoadedKML(kmlConfig.kml);
			super.onKMLFileLoaded(event);
		}

		public function stopWaitForRefresh(link: NetworkLink): void
		{
			var linkObj: NetworkLinkObject = _linksDictionary[link.link.href];
			if (linkObj)
				linkObj.stop();
		}

		private function waitForRefresh(linkObj: NetworkLinkObject): void
		{
			linkObj.addEventListener("refresh", onNetworkLinkRefresh);
			linkObj.wait();
		}

		private function onNetworkLinkRefresh(event: Event): void
		{
			var linkObj: NetworkLinkObject = event.target as NetworkLinkObject;
			//dispatch refresh event to notify everyone about refresh (e.g to remove old content of networkLink)
			var nle: NetworkLinkEvent = new NetworkLinkEvent(NetworkLinkEvent.NETWORK_LINK_REFRESH);
			nle.networkLink = linkObj.link;
			dispatchEvent(nle);
			linkObj.removeEventListener("refresh", onNetworkLinkRefresh);
			unloadNetworkLink(linkObj.link);
			loadNetworkLink(linkObj.link);
		}
	}
}
import com.iblsoft.flexiweather.ogc.kml.configuration.KMLLayerConfiguration;
import com.iblsoft.flexiweather.ogc.kml.features.NetworkLink;
import flash.events.Event;
import flash.events.EventDispatcher;
import flash.utils.clearTimeout;
import flash.utils.setTimeout;

class NetworkLinkObject extends EventDispatcher
{
	private var _link: NetworkLink;
	private var _refreshInterval: uint;
	private var _timeout: int;

	public function NetworkLinkObject(link: NetworkLink, refreshInterval: uint = 0)
	{
		_link = link;
		_refreshInterval = refreshInterval;
		_timeout = 0;
	}

	public function stop(): void
	{
		if (_timeout > 0)
			clearTimeout(_timeout);
	}

	public function wait(): void
	{
		if (_timeout > 0)
			clearTimeout(_timeout);
		if (_refreshInterval > 0)
			_timeout = setTimeout(refresh, _refreshInterval * 1000);
	}

	private function refresh(): void
	{
		_timeout = 0;
		dispatchEvent(new Event("refresh"));
	}

	public function get link(): NetworkLink
	{
		return _link;
	}

	public function get refreshInterval(): uint
	{
		return _refreshInterval;
	}

	public function get needRefresh(): Boolean
	{
		return _refreshInterval > 0;
	}
}
