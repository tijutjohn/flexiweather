package com.iblsoft.flexiweather.ogc.kml.managers
{
	import com.iblsoft.flexiweather.net.loaders.KMLGenericLoader;
	import com.iblsoft.flexiweather.ogc.kml.InteractiveLayerKML;
	import com.iblsoft.flexiweather.ogc.kml.configuration.KMLLayerConfiguration;
	import com.iblsoft.flexiweather.ogc.kml.data.KMLLoaderObject;
	import com.iblsoft.flexiweather.ogc.kml.data.KMLType;
	import com.iblsoft.flexiweather.ogc.kml.events.KMLEvent;
	import com.iblsoft.flexiweather.ogc.kml.events.KMLParsingStatusEvent;
	import com.iblsoft.flexiweather.ogc.kml.features.KML;
	
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.utils.ByteArray;
	import flash.utils.Dictionary;

	[Event(name = "kmlFileLoaded", type = "com.iblsoft.flexiweather.ogc.kml.events.KMLEvent")]
	[Event(name = "parsingFinished", type = "com.iblsoft.flexiweather.ogc.kml.events.KMLEvent")]
	public class KMLLoaderManager extends EventDispatcher
	{
		private var _kmlLayerDictionary: Dictionary;

//		private var _urls: Array;
		public function KMLLoaderManager()
		{
//			_urls = [];
			_kmlLayerDictionary = new Dictionary();
		}

		public function addKMLLink(url: String, kmlContent: ByteArray = null, bLoad: Boolean = true): void
		{
//			_urls.push(url);
			if (bLoad || kmlContent)
				loadKML(url, kmlContent);
		}

		public function getKMLLayerConfigurationForURL(kmlURL: String): KMLLayerConfiguration
		{
			if (_kmlLayerDictionary && _kmlLayerDictionary[kmlURL])
			{
				var kmlDictObject: KMLLoaderObject = _kmlLayerDictionary[kmlURL] as KMLLoaderObject;
				return kmlDictObject.configuration;
			}
			return null;
		}
		
		private function loadKML(kmlURL: String, kmlContent: ByteArray = null): void
		{
			//start kml loadind and parsing => suspend anticollision layout updating for now
			kmlLoadingAndParsingStarted();
			
			if (kmlContent)
			{
				trace("loadKML with content");
			}
			
			var kmlConfig: KMLLayerConfiguration;
			var kmlDictObject: KMLLoaderObject;
			
			var kmlType: String = KMLType.UNKNOWN;
			if (kmlContent)
				kmlType = KMLGenericLoader.getKMLType(kmlContent);
			
			
			if (_kmlLayerDictionary[kmlURL])
			{
				kmlDictObject = _kmlLayerDictionary[kmlURL] as KMLLoaderObject;
				kmlConfig = kmlDictObject.configuration;
			} else {
				
				kmlConfig = new KMLLayerConfiguration();
				
				_kmlLayerDictionary[kmlURL] = new KMLLoaderObject(kmlURL, kmlType, kmlConfig);
				
				kmlConfig.addEventListener(KMLEvent.KML_TYPE_IDENTIFIED, onKMLTypeIdentified);
			}
			
			if (kmlContent)
			{
				addLoadingEventListeners(kmlConfig, kmlType);
				//if there is kmlContent, which should be able to get KML type
				switch (kmlType)
				{
					case KMLType.KML:
						var kmlString: String = kmlContent.readUTFBytes(kmlContent.length);
						kmlConfig.addKMLSource(kmlString, kmlURL, 'assets/');
						break;
					case KMLType.KMZ:
						kmlConfig.addKMZByteArray(kmlURL, kmlContent);
						break;
				}
			}
			else
				kmlConfig.loadKMLWithUnknowType(kmlURL, _kmlLayerDictionary[kmlURL]);
//				kmlConfig.loadKML(kmlURL, 'assets/');
			
			/*
			var extension: String;
			var urlArr: Array = kmlURL.split('.');
			if (urlArr)
				extension = urlArr[urlArr.length - 1];
			
			var kmlConfig: KMLLayerConfiguration;
			if (extension == KMLType.KML)
			{
				if (_kmlLayerDictionary[kmlURL])
				{
					kmlDictObject = _kmlLayerDictionary[kmlURL] as KMLLoaderObject;
					kmlConfig = kmlDictObject.configuration;
				}
				else
				{
					kmlConfig = new KMLLayerConfiguration();
					addKMLLoadingEventListener(kmlConfig);
				}
				_kmlLayerDictionary[kmlURL] = new KMLLoaderObject(kmlURL, KMLType.KMZ, kmlConfig);
				//kml layer does not exist yet create it
				if (kmlContent)
				{
					var kmlString: String = kmlContent.readUTFBytes(kmlContent.length);
					kmlConfig.addKMLSource(kmlString, kmlURL, 'assets/');
				}
				else
					kmlConfig.loadKML(kmlURL, 'assets/');
			}
			else if (extension == KMLType.KMZ)
			{
				if (_kmlLayerDictionary[kmlURL])
				{
					kmlDictObject = _kmlLayerDictionary[kmlURL] as KMLLoaderObject;
					kmlConfig = kmlDictObject.configuration;
				}
				else
				{
					kmlConfig = new KMLLayerConfiguration();
					
					addKMZLoadingEventListener(kmlConfig);
					
				}
				_kmlLayerDictionary[kmlURL] = new KMLLoaderObject(kmlURL, KMLType.KMZ, kmlConfig);
				if (kmlContent)
					kmlConfig.addKMZByteArray(kmlURL, kmlContent);
				else
					kmlConfig.loadKMZ(kmlURL);
			} else {
				
				kmlConfig = new KMLLayerConfiguration();
				_kmlLayerDictionary[kmlURL] = new KMLLoaderObject(kmlURL, KMLType.KMZ, kmlConfig);
				kmlConfig.addEventListener(KMLEvent.KML_TYPE_IDENTIFIED, onKMLTypeIdentified);
				kmlConfig.loadKMLWithUnknowType(kmlURL);
			}
			*/
		}
		
		private function onKMLTypeIdentified(event: KMLEvent): void
		{
			var kmlConfig: KMLLayerConfiguration = event.target as KMLLayerConfiguration;
			var kmlType: String = event.kmlType;
			
			addLoadingEventListeners(kmlConfig, kmlType);
		}
		
		private function addLoadingEventListeners(kmlConfig: KMLLayerConfiguration, kmlType: String): void
		{
			switch (kmlType)
			{
				case KMLType.KML:
					addKMLLoadingEventListener(kmlConfig);
					break;
				case KMLType.KMZ:
					addKMZLoadingEventListener(kmlConfig);
					break;
				default:
					trace("onKMLTypeIdentified Unknown KML type");
					break;
			}
		}
		
		private function addKMZLoadingEventListener(kmlConfig: KMLLayerConfiguration): void
		{
			kmlConfig.addEventListener(KMLParsingStatusEvent.PARSING_FAILED, onKMLParsingStatus);
			kmlConfig.addEventListener(KMLParsingStatusEvent.PARSING_PARTIALLY_SUCCESFULL, onKMLParsingStatus);
			kmlConfig.addEventListener(KMLParsingStatusEvent.PARSING_SUCCESFULL, onKMLParsingStatus);
			
			kmlConfig.addEventListener(KMLEvent.UNPACKING_STARTED, onKMZUnpackingStarted);
			kmlConfig.addEventListener(KMLEvent.UNPACKING_PROGRESS, onKMZUnpackingProgress);
			kmlConfig.addEventListener(KMLEvent.UNPACKING_FINISHED, onKMZUnpackingFinished);
			kmlConfig.addEventListener(KMLEvent.PARSING_STARTED, onKMLParsingStarted);
			kmlConfig.addEventListener(KMLEvent.PARSING_FINISHED, onKMLParsingFinished);
			kmlConfig.addEventListener(KMLEvent.KMZ_FILE_LOADED, onKMZFileLoaded);
		}
		
		private function addKMLLoadingEventListener(kmlConfig: KMLLayerConfiguration): void
		{
			kmlConfig.addEventListener(KMLParsingStatusEvent.PARSING_FAILED, onKMLParsingStatus);
			kmlConfig.addEventListener(KMLParsingStatusEvent.PARSING_PARTIALLY_SUCCESFULL, onKMLParsingStatus);
			kmlConfig.addEventListener(KMLParsingStatusEvent.PARSING_SUCCESFULL, onKMLParsingStatus);
			
			kmlConfig.addEventListener(KMLEvent.PARSING_STARTED, onKMLParsingStarted);
			kmlConfig.addEventListener(KMLEvent.PARSING_FINISHED, onKMLParsingFinished);
			kmlConfig.addEventListener(KMLEvent.KML_FILE_LOADED, onKMLFileLoaded);
		}

		protected function onKMZUnpackingStarted(event: KMLEvent): void
		{
			//notify
			dispatchEvent(event);
		}
		
		protected function onKMZUnpackingProgress(event: KMLEvent): void
		{
			//notify
			dispatchEvent(event);
		}

		protected function onKMZUnpackingFinished(event: KMLEvent): void
		{
			//notify
			dispatchEvent(event);
		}

		protected function onKMLParsingStarted(event: KMLEvent): void
		{
			//notify
			dispatchEvent(event);
		}

		protected function onKMLParsingFinished(event: KMLEvent): void
		{
			//notify
			dispatchEvent(event);
		}

		protected function onKMLFileLoaded(event: KMLEvent): void
		{
			var kmlConfig: KMLLayerConfiguration = event.currentTarget as KMLLayerConfiguration;
			
			var kmlURL: String = kmlConfig.kmlPath;
			event.data = _kmlLayerDictionary[kmlURL] as KMLLoaderObject;
			//notify
			dispatchEvent(event);
			kmlLoadingAndParsingFinished();
		}

		protected function onKMZFileLoaded(event: KMLEvent): void
		{
			var kmlConfig: KMLLayerConfiguration = event.currentTarget as KMLLayerConfiguration;
			
			var kmlURL: String = kmlConfig.kmlPath;
			event.data = _kmlLayerDictionary[kmlURL] as KMLLoaderObject;
			//notify
			dispatchEvent(event);
			kmlLoadingAndParsingFinished();
		}
		
		private function onKMLParsingStatus(event: KMLParsingStatusEvent): void
		{
			dispatchEvent(event);
		}

		protected function kmlLoadingAndParsingStarted(): void
		{
			//notify
		}

		protected function kmlLoadingAndParsingFinished(): void
		{
			//notify
		}
	}
}
