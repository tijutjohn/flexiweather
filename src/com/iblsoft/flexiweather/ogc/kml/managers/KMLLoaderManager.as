package com.iblsoft.flexiweather.ogc.kml.managers
{
	import com.iblsoft.flexiweather.ogc.kml.InteractiveLayerKML;
	import com.iblsoft.flexiweather.ogc.kml.configuration.KMLLayerConfiguration;
	import com.iblsoft.flexiweather.ogc.kml.events.KMLEvent;
	
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.utils.ByteArray;
	import flash.utils.Dictionary;

	public class KMLLoaderManager extends EventDispatcher
	{
		private var _kmlLayerDictionary: Dictionary;
		
		private var _urls: Array;
		
		public function KMLLoaderManager()
		{
			_urls = [];
			_kmlLayerDictionary = new Dictionary();
		}
		
		public function addKMLLink(url: String, kmlContent: ByteArray = null, bLoad: Boolean = true): void
		{
			_urls.push(url);
			
			if (bLoad || kmlContent)
			{
				loadKML(url, kmlContent);
			}
		}
		
		private function loadKML(kmlURL: String, kmlContent: ByteArray = null): void
		{
			//start kml loadind and parsing => suspend anticollision layout updating for now
			kmlLoadingAndParsingStarted();
			
			var extension: String;
			var urlArr: Array = kmlURL.split('.');
			if (urlArr)
				extension = urlArr[urlArr.length - 1];
			//				toggleButton.enabled = false;
			var kmlConfig: KMLLayerConfiguration = new KMLLayerConfiguration();
			
			if (extension == 'kml')
			{
				_kmlLayerDictionary[kmlURL] = {url: kmlURL, type: "kmz", configuration: kmlConfig};
				
				//kml layer does not exist yet create it
				kmlConfig.addEventListener(KMLEvent.PARSING_STARTED, onKMLParsingStarted);
				kmlConfig.addEventListener(KMLEvent.PARSING_FINISHED, onKMLParsingFinished);
				kmlConfig.addEventListener(KMLEvent.KML_FILE_LOADED, onKMLFileLoaded);
				
				if (kmlContent)
				{
					var kmlString: String = kmlContent.readUTFBytes(kmlContent.length);
					kmlConfig.addKMLSource(kmlString, kmlURL, 'assets/');
				} else {
					kmlConfig.loadKML(kmlURL, 'assets/');
				}
				
			} else if (extension == 'kmz') {
				_kmlLayerDictionary[kmlURL] = {url: kmlURL, type: "kmz", configuration: kmlConfig};
				
				kmlConfig.addEventListener(KMLEvent.UNPACKING_STARTED, onKMZUnpackingStarted);
				kmlConfig.addEventListener(KMLEvent.UNPACKING_FINISHED, onKMZUnpackingFinished);
				kmlConfig.addEventListener(KMLEvent.PARSING_STARTED, onKMLParsingStarted);
				kmlConfig.addEventListener(KMLEvent.PARSING_FINISHED, onKMLParsingFinished);
				kmlConfig.addEventListener(KMLEvent.KMZ_FILE_LOADED, onKMZFileLoaded);
				if (kmlContent)
				{
					kmlConfig.addKMZByteArray(kmlURL, kmlContent);
				} else {
					kmlConfig.loadKMZ(kmlURL);
				}
			}
		}
		
		protected function onKMZUnpackingStarted(event: KMLEvent): void
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
			
			event.data = _kmlLayerDictionary[kmlURL];
			//notify
			dispatchEvent(event);
			
			kmlLoadingAndParsingFinished();
		}
		
		protected function onKMZFileLoaded(event: KMLEvent): void
		{
			var kmlConfig: KMLLayerConfiguration = event.currentTarget as KMLLayerConfiguration;
			var kmlURL: String = kmlConfig.kmlPath;
			
			event.data = _kmlLayerDictionary[kmlURL];
			
			//notify
			dispatchEvent(event);
			
			kmlLoadingAndParsingFinished();
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