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
		
		public function addLoadedKML(kml: KML): void
		{
			if (kml is KML22)
			{
				var kml22: KML22 = kml as KML22;
				
			}
		}
		
		public function get refreshVisibility(): int
		{
			return _refreshVisibility;
		}
		public function get flyToView(): int
		{
			return _flyToView;
		}
		public function get link(): Link
		{
			return _link;
		}
		
		
	}
}