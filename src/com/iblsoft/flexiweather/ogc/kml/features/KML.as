package com.iblsoft.flexiweather.ogc.kml.features
{
	import com.iblsoft.flexiweather.ogc.kml.data.KMZFile;
	import com.iblsoft.flexiweather.ogc.kml.events.KMLEvent;
	import com.iblsoft.flexiweather.ogc.kml.managers.KMLParserManager;
	import com.iblsoft.flexiweather.ogc.kml.managers.KMLResourceManager;
	import com.iblsoft.flexiweather.syndication.XmlParser;
	
	import flash.events.Event;
	import flash.utils.getTimer;
	
	import mx.collections.ArrayCollection;
	
	public class KML extends XmlParser
	{
		protected var _kmlURLPath: String;
		protected var _kmlBaseURLPath: String;
		
		protected var _kmlNamespace: String;
		protected var _kmlSource: String;
		protected var _feature: KMLFeature;
		
		protected var _document: Document;
		
		protected var _resourceManager: KMLResourceManager;
		protected var _kmlParserManager: KMLParserManager;
		
		public function KML(xmlStr:String, urlPath: String, baseUrlPath: String, resourceManager: KMLResourceManager = null)
		{
			super();
			
			_kmlSource = xmlStr;
			_kmlNamespace = getKMLNamespace(xmlStr);
			
			_kmlURLPath = urlPath;
			_kmlBaseURLPath = baseUrlPath;
			
			_resourceManager = resourceManager;
			_kmlParserManager = new KMLParserManager();
			
			if (!_resourceManager)
			{
				_resourceManager = new KMLResourceManager(_kmlBaseURLPath);
			}
			
		}
		
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
			if (_feature)
			{
				var name: String = getKMLFeatureName(_feature);
				if (feature is Container)
				{
					var objContainer: Object = {label: name, data: _feature, children: []};
					addFeaturesToDataProvider(feature as Container, objContainer);
					ac.addItem(objContainer);	
				} else {
					var obj: Object = {label: name, data: _feature};
					ac.addItem(obj);	
				}
			}
			
			return ac;
		}
		
		private function getKMLFeatureName(feature: KMLFeature): String
		{
			var name: String;
			if (feature.name)
			{
				name = feature.name;
			} else if (feature.description) {
				if (feature.description.length <= 20)
					name = feature.description;
				else
					name = feature.description.substr(0,20);
			} else {
				name = 'no name ('+getTimer()+')';
			}
			return name;
		}
		private function addFeaturesToDataProvider(container: Container, parentObject: Object): Object
		{
			if (container && container.features)
			{
				for each (var feature: KMLFeature in container.features)
				{
					var name: String = getKMLFeatureName(feature);
					var obj: Object = {label: name, data: feature};
					if (feature is Folder)
					{
						trace("stop");
					}
					if (feature is Container)
					{
						if (!obj.hasOwnProperty("children"))
						{
							obj['children'] = new Array();
						}
						(obj['children'] as Array).push(addFeaturesToDataProvider(feature as Container, obj));
					}
					(parentObject['children'] as Array).push(obj);
				}

			}
			
			return obj;
		}
		
		protected function notifyKmlDataProviderChange(): void
		{
			dispatchEvent(new Event("kmlDataProviderChanged"));
		}
		
		[Bindable (event="kmlDataProviderChanged")]
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
		
		override public function toString():String {
			return "KML: " + this._feature.toString();
		}
	}
}