package com.iblsoft.flexiweather.ogc.kml.features
{
	import com.iblsoft.flexiweather.ogc.kml.data.KMZFile;
	import com.iblsoft.flexiweather.ogc.kml.events.KMLEvent;
	import com.iblsoft.flexiweather.ogc.kml.managers.KMLParserManager;
	import com.iblsoft.flexiweather.ogc.kml.managers.KMLResourceManager;
	import com.iblsoft.flexiweather.ogc.kml.managers.NetworkLinkManager;
	import com.iblsoft.flexiweather.syndication.XmlParser;
	import flash.events.Event;
	import flash.utils.getTimer;
	import mx.collections.ArrayCollection;
	import mx.utils.StringUtil;

	public class KML extends XmlParser
	{
		protected var _kmlURLPath: String;

		protected var _kmlBaseURLPath: String;

		protected var _kmlNamespace: String;

		protected var _kmlSource: String;

		protected var _feature: KMLFeature;

		protected var _document: Document;

		protected var _localResourceManager: Boolean;

		protected var _resourceManager: KMLResourceManager;

		protected var _kmlParserManager: KMLParserManager;

		protected var _networkLinkManager: NetworkLinkManager;

		public function get networkLinkManager(): NetworkLinkManager
		{
			return _networkLinkManager;
		}

		public function KML(xmlStr: String, urlPath: String, baseUrlPath: String, resourceManager: KMLResourceManager = null)
		{
			super();
			//SPECIAL FIX for trimming ZERO WIDTH SPACE html character which can be at the end of KML String copied from web browser
			var endIndex: int = xmlStr.length - 1;
			while (isZeroWidthSpaceChar(xmlStr.charCodeAt(endIndex)))
			{
				--endIndex;
			}
			if (endIndex >= 0)
				xmlStr = xmlStr.slice(0, endIndex + 1);
			else
				xmlStr = "";
			_kmlSource = StringUtil.trim(xmlStr);
			_kmlNamespace = getKMLNamespace(_kmlSource);
			_kmlURLPath = urlPath;
			_kmlBaseURLPath = baseUrlPath;
			_resourceManager = resourceManager;
			_kmlParserManager = new KMLParserManager();
			_networkLinkManager = new NetworkLinkManager();
			_networkLinkManager.addEventListener(KMLEvent.KML_FILE_LOADED, onNetworkLinkLoaded);
			if (!_resourceManager)
			{
				_resourceManager = new KMLResourceManager(_kmlBaseURLPath);
				_localResourceManager = true;
			}
		}

		private function isZeroWidthSpaceChar(charCode: int): Boolean
		{
			return (charCode == 8203);
		}

		override public function cleanup(): void
		{
			super.cleanup();
			if (_feature)
			{
				_feature.cleanup();
				_feature = null;
//				cleanupFeature(_feature);
			}
			if (_kmlParserManager)
				_kmlParserManager.cleanup();
			if (_networkLinkManager)
			{
				_networkLinkManager.removeEventListener(KMLEvent.KML_FILE_LOADED, onNetworkLinkLoaded);
//				_networkLinkManager.cleanup();
			}
			if (_localResourceManager && _resourceManager)
			{
//				_resourceManager.cleanup();
			}
		}

		/*
		private function cleanupFeature(feature: KMLFeature): void
		{
			var features: Array;

			if (feature is Container || feature is NetworkLink)
			{
				if (feature is NetworkLink)
				{
					features = (feature as NetworkLink).container.features
				} else {
					var container: Container = feature as Container;
					features = container.features;
				}
				for each (var currFeature: KMLFeature in features)
				{
					cleanupFeature(currFeature);
				}
			}
			feature.cleanup();
//			feature = null;
		}
		*/
		public function parse(kmzFile: KMZFile = null): void
		{
			parseSource(_kmlSource);
			if (kmzFile)
				_resourceManager.addKMZFile(kmzFile);
		}

		protected function notifyParsingFinished(): void
		{
			dispatchEvent(new KMLEvent(KMLEvent.PARSING_FINISHED));
		}

		protected function getKMLNamespace(source: String): String
		{
			var xml: XML = new XML(source);
			var root: QName = xml.name();
			return root.uri;
		}

		private function createDataProvider(): ArrayCollection
		{
			var ac: ArrayCollection = new ArrayCollection();
			var currFeature: KMLFeature = _feature;
			if (currFeature)
			{
				var name: String = getKMLFeatureName(currFeature);
				if (_feature is NetworkLink)
					currFeature = (_feature as NetworkLink).container;
				if (currFeature is Container)
				{
					var objContainer: Object = {label: name, data: currFeature, children: []};
					addFeaturesToDataProvider(currFeature as Container, objContainer);
					ac.addItem(objContainer);
				}
				else
				{
					var obj: Object = {label: name, data: currFeature};
					ac.addItem(obj);
				}
			}
			return ac;
		}

		private function getKMLFeatureName(feature: KMLFeature): String
		{
			var name: String;
			if (feature.name)
				name = feature.name;
			else if (feature.description)
			{
				if (feature.description.length <= 20)
					name = feature.description;
				else
					name = feature.description.substr(0, 20);
			}
			else
				name = 'no name (' + getTimer() + ')';
			return name;
		}

		private function addFeaturesToDataProvider(container: Container, parentObject: Object): Object
		{
			if (container && container.features)
			{
				for each (var feature: KMLFeature in container.features)
				{
					if (feature is NetworkLink)
						feature = (feature as NetworkLink).container;
					var name: String = getKMLFeatureName(feature);
					var obj: Object = {label: name, data: feature};
//					trace("\n\t CREATE "  + obj.label);
					if (feature is Container)
					{
						if (!obj.hasOwnProperty("children"))
							obj['children'] = new Array();
						var newObj: Object = addFeaturesToDataProvider(feature as Container, obj);
						if (!isParentObjectInside((obj['children'] as Array), newObj))
						{
//							trace("\t\t ADD["+obj.label+"] " + newObj.label);
							(obj['children'] as Array).push(newObj);
//							trace("\t\t ADD["+obj.label+"] len: " + (obj['children'] as Array).length);
//						} else {
//							trace("\t\t ADD " + newObj.label + " IS ALREADY THERE ");
						}
					}
					if (!isParentObjectInside((parentObject['children'] as Array), obj))
					{
//						trace("\t\t\t add to PARENT["+parentObject.label+"]: " + obj.label);
						(parentObject['children'] as Array).push(obj);
//						trace("\t\t\t add to PARENT["+parentObject.label+"] len: " + (parentObject['children'] as Array).length);
//					} else {
//						trace("\t\t\t add to PARENT: " + obj.label + " IS ALREADY THERE ");
					}
				}
			}
			return obj;
		}

		private function isParentObjectInside(parentArray: Array, child: Object): Boolean
		{
			for each (var currChild: Object in parentArray)
			{
				if (currChild == child)
					return true;
			}
			return false;
		}

		private function onNetworkLinkLoaded(event: KMLEvent): void
		{
			//kml data provider must be updated, because NetworkLink's KML was loaded and parsed
			notifyKmlDataProviderChange();
		}

		protected function notifyKmlDataProviderChange(): void
		{
			dispatchEvent(new Event("kmlDataProviderChanged"));
		}

		[Bindable(event = "kmlDataProviderChanged")]
		public function get kmlDataProvider(): ArrayCollection
		{
			return createDataProvider();
		}

		/**
		 * 	@langversion ActionScript 3.0
		 *	@playerversion Flash 8.5
		 *	@tiptext
		 */
		public function get feature(): KMLFeature
		{
			return this._feature;
		}

		public function get resourceManager(): KMLResourceManager
		{
			return _resourceManager;
		}

		public function get document(): Document
		{
			return this._document;
		}

		override public function toString(): String
		{
			return "KML: " + this._feature.toString();
		}
	}
}
