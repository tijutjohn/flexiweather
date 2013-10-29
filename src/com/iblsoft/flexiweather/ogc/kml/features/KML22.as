package com.iblsoft.flexiweather.ogc.kml.features
{
	import com.iblsoft.flexiweather.ogc.kml.data.KMZFile;
	import com.iblsoft.flexiweather.ogc.kml.events.KMLEvent;
	import com.iblsoft.flexiweather.ogc.kml.events.KMLParsingStatusEvent;
	import com.iblsoft.flexiweather.syndication.ParsingTools;
	import com.iblsoft.flexiweather.syndication.XmlParser;
	import com.iblsoft.flexiweather.utils.AsyncManager;
	
	import flash.events.Event;
	
	import mx.core.UIComponent;

	/**
	*	Class that represents an KML version 2.2 document.
	*
	* 	@langversion ActionScript 3.0
	*	@playerversion Flash 8.5
	*	@tiptext
	*
	*/
	public class KML22 extends KML
	{
		/**
		*	Constructor for class.
		*
		* 	@langversion ActionScript 3.0
		*	@playerversion Flash 8.5
		*	@tiptext
		*/
		public function KML22(xmlStr: String, urlPath: String, baseUrlPath: String)
		{
			super(xmlStr, urlPath, baseUrlPath);
		}

		override public function cleanup(): void
		{
			super.cleanup();
			if (_kmlParserManager)
			{
				_kmlParserManager.removeEventListener(AsyncManager.EMPTY, onKMLParserFinished);
				_kmlParserManager.removeEventListener(KMLParsingStatusEvent.FEATURE_PARSING_FAILED, onKMLFeatureParsingStatus);
				_kmlParserManager.removeEventListener(KMLParsingStatusEvent.FEATURE_PARSING_PARTIALLY_SUCCESFULL, onKMLFeatureParsingStatus);
				_kmlParserManager.removeEventListener(KMLParsingStatusEvent.FEATURE_PARSING_SUCCESFULL, onKMLFeatureParsingStatus);
			}
		}

		override public function parse(kmzFile: KMZFile = null): void
		{
			beforeKMLParsing();
			
			mb_kmlParsingSupportedFeature = false;
			
			super.parse(kmzFile);
			var kmlns: Namespace = new Namespace(_kmlNamespace);
			// todo support other features
			if (ParsingTools.nullCheck(this.xml.kmlns::Placemark)) {
				this._feature = new Placemark(this, _kmlNamespace, this.xml.kmlns::Placemark);
				mb_kmlParsingSupportedFeature = true;
			}
			if (ParsingTools.nullCheck(this.xml.kmlns::GroundOverlay)) {
				this._feature = new GroundOverlay(this, _kmlNamespace, this.xml.kmlns::GroundOverlay);
				mb_kmlParsingSupportedFeature = true;
			}
			if (ParsingTools.nullCheck(this.xml.kmlns::GroundOverlay)) {
				this._feature = new GroundOverlay(this, _kmlNamespace, this.xml.kmlns::GroundOverlay);
				mb_kmlParsingSupportedFeature = true;
			}
			if (ParsingTools.nullCheck(this.xml.kmlns::ScreenOverlay)) {
				this._feature = new ScreenOverlay(this, _kmlNamespace, this.xml.kmlns::ScreenOverlay)
				mb_kmlParsingSupportedFeature = true;
			}
			if (ParsingTools.nullCheck(this.xml.kmlns::Folder)) {
				this._feature = new Folder(this, _kmlNamespace, this.xml.kmlns::Folder);
				mb_kmlParsingSupportedFeature = true;
			}
			if (ParsingTools.nullCheck(this.xml.kmlns::Document)) {
				this._document = new Document(this, _kmlNamespace, this.xml.kmlns::Document);
				this._document.baseUrlPath = _kmlBaseURLPath;
				this._feature = document;
				mb_kmlParsingSupportedFeature = true;
			}
			if (ParsingTools.nullCheck(this.xml.kmlns::NetworkLink)) {
				this._feature = new NetworkLink(this, _kmlNamespace, this.xml.kmlns::NetworkLink);
				var nLink: NetworkLink = _feature as NetworkLink;
				_networkLinkManager.addNetworkLink(nLink, nLink.refreshInterval, true);
				mb_kmlParsingSupportedFeature = true;
			}
			
			_feature.addEventListener(KMLParsingStatusEvent.FEATURE_PARSING_FAILED, onKMLFeatureParsingStatus);
			_feature.addEventListener(KMLParsingStatusEvent.FEATURE_PARSING_PARTIALLY_SUCCESFULL, onKMLFeatureParsingStatus);
			_feature.addEventListener(KMLParsingStatusEvent.FEATURE_PARSING_SUCCESFULL, onKMLFeatureParsingStatus);
			_feature.parse(_kmlNamespace, _kmlParserManager);
			
			
			_kmlParserManager.addEventListener(AsyncManager.EMPTY, onKMLParserFinished);
			
			_kmlParserManager.addEventListener(KMLParsingStatusEvent.FEATURE_PARSING_FAILED, onKMLFeatureParsingStatus);
			_kmlParserManager.addEventListener(KMLParsingStatusEvent.FEATURE_PARSING_PARTIALLY_SUCCESFULL, onKMLFeatureParsingStatus);
			_kmlParserManager.addEventListener(KMLParsingStatusEvent.FEATURE_PARSING_SUCCESFULL, onKMLFeatureParsingStatus);
			
			_kmlParserManager.maxCallsPerTick = 150;
			_kmlParserManager.start();
		}

		private function onKMLFeatureParsingStatus(event: KMLParsingStatusEvent): void
		{
			switch (event.type)
			{
				case KMLParsingStatusEvent.FEATURE_PARSING_SUCCESFULL:
					changeKMLParsingStatus(KMLParsingStatusEvent.PARSING_SUCCESFULL);
					
					break;
				case KMLParsingStatusEvent.FEATURE_PARSING_PARTIALLY_SUCCESFULL:
					changeKMLParsingStatus(KMLParsingStatusEvent.PARSING_PARTIALLY_SUCCESFULL);
					
					break;
				case KMLParsingStatusEvent.FEATURE_PARSING_FAILED:
					changeKMLParsingStatus(KMLParsingStatusEvent.PARSING_FAILED);
					break;
			}
		}
		
		private function onKMLParserFinished(event: Event): void
		{
			_kmlParserManager.removeEventListener(AsyncManager.EMPTY, onKMLParserFinished);
			_kmlParserManager.stop();
			notifyParsingFinished();
		}

		private function debug(): void
		{
			return;
			if (_feature)
			{
				var txt: String = debugFeature(_feature, 1);
			}
			else
				trace("there is no main feature in this KML: " + _kmlSource);
		}

		private function debugFeature(featureForDebugging: KMLFeature, tabs: int): String
		{
			var tmp: String = getTabsString(tabs);
			tmp += featureForDebugging.toString() + "\n";
			if (featureForDebugging is Container)
			{
				var container: Container = featureForDebugging as Container;
				for each (var childFeature: KMLFeature in container.features)
				{
					tmp += debugFeature(childFeature, tabs + 1);
				}
			}
			return tmp;
		}

		private function getTabsString(count: int): String
		{
			var tmp: String = '';
			for (var i: int = 0; i < count; i++)
			{
				tmp += "\t";
			}
			return tmp
		}

		override public function toString(): String
		{
//			return "KML 2.2: " + this._feature.toString();
			return "KML 2.2";// + this._feature.toString();
		}
	}
}
