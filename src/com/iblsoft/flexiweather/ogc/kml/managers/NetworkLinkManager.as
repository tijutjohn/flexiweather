package com.iblsoft.flexiweather.ogc.kml.managers
{
	import com.iblsoft.flexiweather.ogc.kml.features.NetworkLink;

	public class NetworkLinkManager
	{
		private var _links: Array;
		
		public function NetworkLinkManager()
		{
			_links = new Array();
		}
		
		public function addNetworkLink(link: NetworkLink, bLoad: Boolean = false): void
		{
			_links.push(link);
			
			if (bLoad)
			{
				loadNetworkLink(link);
			}
		}
		
		private function loadNetworkLink(link: NetworkLink): void
		{
			
		}
	}
}