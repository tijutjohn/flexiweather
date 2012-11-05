package com.iblsoft.flexiweather.ogc.kml.events
{
	import com.iblsoft.flexiweather.ogc.kml.features.NetworkLink;
	import flash.events.Event;

	public class NetworkLinkEvent extends Event
	{
		public static const NETWORK_LINK_REFRESH: String = 'networkLinkRefresh';
		public var networkLink: NetworkLink;

		public function NetworkLinkEvent(type: String, bubbles: Boolean = false, cancelable: Boolean = false)
		{
			super(type, bubbles, cancelable);
		}
	}
}
