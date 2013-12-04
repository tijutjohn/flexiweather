package com.iblsoft.flexiweather.ogc.kml.features
{
	import com.iblsoft.flexiweather.ogc.kml.data.KMLFeaturesReflectionDictionary;
	import com.iblsoft.flexiweather.ogc.kml.events.KMLParsingStatusEvent;
	import com.iblsoft.flexiweather.ogc.kml.features.constants.LinkRefreshMode;
	import com.iblsoft.flexiweather.ogc.kml.managers.KMLParserManager;
	import com.iblsoft.flexiweather.syndication.ParsingTools;
	
	import flashx.textLayout.operations.RedoOperation;

	public class NetworkLink extends KMLFeature
	{
		private static var _nlID: int = 0;
		public var nlID: int;
		
		private var _refreshVisibility: int;
		private var _flyToView: int;
		private var _link: Link;
		private var _container: Container;
		private var _contentKML: KML;

		public function NetworkLink(kml: KML, s_namespace: String, s_xml: XMLList)
		{
			nlID = _nlID++;
			
			super(kml, s_namespace, s_xml);
			var kmlns: Namespace = new Namespace(s_namespace);
			
			_container = new Container(null, s_namespace, null);
			_container.addEventListener(KMLParsingStatusEvent.FEATURE_PARSING_FAILED, onKMLFeatureParsingStatus);
			_container.addEventListener(KMLParsingStatusEvent.FEATURE_PARSING_PARTIALLY_SUCCESFULL, onKMLFeatureParsingStatus);
			_container.addEventListener(KMLParsingStatusEvent.FEATURE_PARSING_SUCCESFULL, onKMLFeatureParsingStatus);
			
			this._refreshVisibility = ParsingTools.nanCheck(this.xml.kmlns::refreshVisibility);
			this._flyToView = ParsingTools.nanCheck(this.xml.kmlns::flyToView);
			if (ParsingTools.nullCheck(this.xml.kmlns::Link))
				this._link = new Link(s_namespace, this.xml.kmlns::Link);
		}
		
		override public function parse(s_namespace: String, kmlParserManager: KMLParserManager): void
		{
			beforeKMLFeatureParsing();
			
			parseKML(s_namespace, kmlParserManager);
			
			changeKMLFeatureParsingStatus(KMLParsingStatusEvent.FEATURE_PARSING_SUCCESFULL);
			
			afterKMLFeatureParsing();
		}
		
		private function onKMLFeatureParsingStatus(event: KMLParsingStatusEvent): void
		{
			dispatchEvent(event);
		}

		public override function cleanup(): void
		{
			super.cleanup();
			if (_link)
			{
				_link.cleanupKML();
				_link = null;
			}
			if (_container)
			{
				_container.cleanup();
				_container = null;
			}
		}

		public function addLoadedKML(kml: KML): void
		{
			_contentKML = kml;
			if (kml is KML22)
			{
				//unload old feature;
				if (_container.features && _container.features.length > 0)
				{
					for each (var currFeature: KMLFeature in _container.features)
					{
						_container.removeFeature(currFeature);
					}
				}
				var kml22: KML22 = kml as KML22;
				_container.addFeature(kml22.feature);
			}
			kml.resourceManager.debugCache("AFter NetworkLink add loaded KML");
		}

		public function get contentKML(): KML
		{
			return _contentKML;
		}

		public function get container(): Container
		{
			return _container;
		}

		public function get refreshInterval(): int
		{
			if (_link && _link.refreshMode == LinkRefreshMode.ON_INTERVAL)
			{
				//TODO this is debug for testing refreshing each 10 seconds;
//				return 10;
				return _link.refreshInterval;
			}
			return 0;
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
		
		override public function toString(): String
		{
			return "NetworkLink: " + nlID;
		}
	}
}
