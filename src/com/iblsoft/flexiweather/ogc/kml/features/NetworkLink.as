package com.iblsoft.flexiweather.ogc.kml.features
{
	import com.iblsoft.flexiweather.syndication.ParsingTools;

	public class NetworkLink extends KMLFeature
	{
		private var _refreshVisibility: int;
		private var _flyToView: int;
		private var _link: Link;
		
		public function NetworkLink(kml:KML, s_namespace:String, s_xml:XMLList)
		{
			super(kml, s_namespace, s_xml);
			
			var kmlns:Namespace = new Namespace(s_namespace);
			
			this._refreshVisibility = ParsingTools.nanCheck(this.xml.kmlns::refreshVisibility);
			this._flyToView = ParsingTools.nanCheck(this.xml.kmlns::flyToView);
			if (ParsingTools.nullCheck(this.xml.kmlns::Link)) {
				this._link = new Link(s_namespace, this.xml.kmlns::Link);
			}
		}
		
		
	}
}