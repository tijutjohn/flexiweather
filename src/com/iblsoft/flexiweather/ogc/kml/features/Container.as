package com.iblsoft.flexiweather.ogc.kml.features
{
	import com.iblsoft.flexiweather.ogc.FeatureUpdateContext;
	import com.iblsoft.flexiweather.ogc.kml.events.KMLParsingStatusEvent;
	import com.iblsoft.flexiweather.ogc.kml.managers.KMLParserManager;
	import com.iblsoft.flexiweather.syndication.Namespaces;
	import com.iblsoft.flexiweather.utils.DebugUtils;

	/**
	*	Class that represents an Entry element within an Atom feed
	*
	* 	@langversion ActionScript 3.0
	*	@playerversion Flash 8.5
	*	@tiptext
	*
	* 	@see http://www.atomenabled.org/developers/syndication/atom-format-spec.php#rfc.section.4.1.2
	*/
	public class Container extends KMLFeature
	{
//		private var atom:Namespace = Namespaces.ATOM_NS;
//		private var georss:Namespace = Namespaces.GEORSS_NS;
		private var _features: Array;

		/**
		*	Constructor for class.
		*
		*	@param x An XML document that contains an individual Entry element from
		*	an Aton XML feed.
		*
		* 	@langversion ActionScript 3.0
		*	@playerversion Flash 8.5
		*	@tiptext
		*/
		public function Container(kml: KML, s_namespace: String, x: XMLList)
		{
			super(kml, s_namespace, x);
			this._features = new Array();
		}

		override public function update(changeFlag: FeatureUpdateContext): void
		{
			for each (var feature: KMLFeature in features)
			{
				feature.update(changeFlag);
			}
			super.update(changeFlag);
		}

		override public function cleanup(): void
		{
			for each (var feature: KMLFeature in features)
			{
				feature.cleanup();
			}
			firstFeature = null;
			super.cleanup();
		}

		override protected function parseKML(s_namespace: String, kmlParserManager: KMLParserManager): void
		{
			mb_kmlFeatureParsingSupportedFeature = false;
			// Features are: Placemark, GroundOverlay, ScreenOverlay, PhotoOverlay, NetworkLink, Folder, Document
			// We'll only support Placemark, GroundOverlay, Folder, and Document
			var time: int = startProfileTimer();
			super.parseKML(s_namespace, kmlParserManager);
			var i: XML;
			var folder: Folder;
			var document: Document;
			var kmlns: Namespace = new Namespace(s_namespace);
			for each (i in this.xml.kmlns::NetworkLink)
			{
				var networkLink: NetworkLink = new NetworkLink(kml, s_namespace, XMLList(i));
				kmlParserManager.addCall(networkLink, networkLink.parse, [s_namespace, kmlParserManager]);
				kmlParserManager.addCall(networkLink, addFeature, [networkLink]);
				
				mb_kmlFeatureParsingSupportedFeature = true;
			}
			for each (i in this.xml.kmlns::Placemark)
			{
				var placemark: Placemark = new Placemark(kml, s_namespace, XMLList(i));
//				addFeature(placemark);
				kmlParserManager.addCall(placemark, placemark.parse, [s_namespace, kmlParserManager]);
				kmlParserManager.addCall(placemark, addFeature, [placemark]);
				
				mb_kmlFeatureParsingSupportedFeature = true;
			}
			for each (i in this.xml.kmlns::GroundOverlay)
			{
				var groundOverlay: GroundOverlay = new GroundOverlay(kml, s_namespace, XMLList(i))
//				addFeature(groundOverlay);
				kmlParserManager.addCall(groundOverlay, groundOverlay.parse, [s_namespace, kmlParserManager]);
				kmlParserManager.addCall(groundOverlay, addFeature, [groundOverlay]);
				
				mb_kmlFeatureParsingSupportedFeature = true;
			}
			for each (i in this.xml.kmlns::ScreenOverlay)
			{
				var screenOverlay: ScreenOverlay = new ScreenOverlay(kml, s_namespace, XMLList(i))
//				addFeature(screenOverlay);
				kmlParserManager.addCall(screenOverlay, screenOverlay.parse, [s_namespace, kmlParserManager]);
				kmlParserManager.addCall(screenOverlay, addFeature, [screenOverlay]);
				
				mb_kmlFeatureParsingSupportedFeature = true;
			}
			for each (i in this.xml.kmlns::Folder)
			{
				folder = new Folder(kml, s_namespace, XMLList(i));
//				addFeature(folder);
				kmlParserManager.addCall(folder, folder.parse, [s_namespace, kmlParserManager]);
				kmlParserManager.addCall(folder, addFeature, [folder]);
				
				mb_kmlFeatureParsingSupportedFeature = true;
			}
			for each (i in this.xml.kmlns::Document)
			{
				document = new Document(kml, s_namespace, XMLList(i));
				kmlParserManager.addCall(document, document.parse, [s_namespace, kmlParserManager]);
				kmlParserManager.addCall(document, addFeature, [document]);
				
				mb_kmlFeatureParsingSupportedFeature = true;
			}
			debug("Container parseKML: " + (stopProfileTimer(time)) + "ms");
			
			if (!mb_kmlFeatureParsingSupportedFeature)
			{
				changeKMLFeatureParsingStatus(KMLParsingStatusEvent.FEATURE_PARSING_FAILED);
			} else {
				changeKMLFeatureParsingStatus(KMLParsingStatusEvent.FEATURE_PARSING_SUCCESFULL);
			}
		}

		override public function set parentDocument(value: Document): void
		{
			super.parentDocument = value;
			for each (var childFeature: KMLFeature in features)
			{
				childFeature.parentDocument = value;
			}
		}
		private var _oldFeature: KMLFeature;
		private var _firstFeature: KMLFeature;

		public function get firstFeature(): KMLFeature
		{
			return _firstFeature;
		}

		public function set firstFeature(value: KMLFeature): void
		{
			_firstFeature = value;
		}

		public function removeFeature(feature: KMLFeature): void
		{
			if (feature)
				feature.parentFeature = null;
			if (this is Document)
				feature.parentDocument = null;
			else if (parentDocument)
				feature.parentDocument = null;
			var len: int = _features.length;
			for (var i: int = 0; i < len; i++)
			{
				var currFeature: KMLFeature = _features[i] as KMLFeature;
				if (currFeature == feature)
				{
					_features.splice(i, 1);
					if (currFeature.previous)
						currFeature.previous.next = currFeature.previous;
					if (currFeature.next)
						currFeature.next.previous = currFeature.previous;
					if (_firstFeature == currFeature)
						firstFeature = currFeature.next as KMLFeature;
					break;
				}
			}
		}

		/**
		 * Add feature to feature container
		 *
		 * @param feature
		 *
		 */
		public function addFeature(feature: KMLFeature): void
		{
			if (feature)
				feature.parentFeature = this;
			if (this is Document)
			{
				feature.parentDocument = this as Document;
					//FIXME check all children features if parent are set
//				var document: Document = feature as Document;
//				for each (var childFeature: KMLFeature in document)
//				{
//					childFeature.parentDocument = document;
//				}
			}
			else
			{
				if (parentDocument)
				{
					//if this container has already set parentDocument, set it to new child feature as well
					feature.parentDocument = parentDocument;
				}
			}
			_features.push(feature);
			if (_oldFeature)
			{
				_oldFeature.next = feature;
				feature.previous = _oldFeature;
			}
			else
				firstFeature = feature;
			_oldFeature = feature;
			if (feature is NetworkLink)
			{
				var nLink: NetworkLink = feature as NetworkLink;
				kml.networkLinkManager.addNetworkLink(nLink, nLink.refreshInterval, true)
			}
		}

		/**
		*	A String that contains the title for the entry.
		*
		* 	@langversion ActionScript 3.0
		*	@playerversion Flash 8.5
		*	@tiptext
		*/
		public function get features(): Array
		{
			return this._features;
		}

		public override function toString(): String
		{
			var str: String = "";
			var i: KMLFeature;
			for each (i in this._features)
			{
				str += this._features + "\n";
			}
			return "Container: " + str;
		}
	}
}
