package com.iblsoft.flexiweather.ogc.kml.configuration
{
	import com.iblsoft.flexiweather.net.events.UniURLLoaderErrorEvent;
	import com.iblsoft.flexiweather.net.events.UniURLLoaderEvent;
	import com.iblsoft.flexiweather.net.loaders.BinaryLoader;
	import com.iblsoft.flexiweather.net.loaders.KMLLoader;
	import com.iblsoft.flexiweather.net.loaders.KMZLoader;
	import com.iblsoft.flexiweather.net.loaders.UniURLLoader;
	import com.iblsoft.flexiweather.net.loaders.XMLLoader;
	import com.iblsoft.flexiweather.ogc.Version;
	import com.iblsoft.flexiweather.ogc.configuration.layers.LayerConfiguration;
	import com.iblsoft.flexiweather.ogc.editable.IInteractiveLayerProvider;
	import com.iblsoft.flexiweather.ogc.kml.InteractiveLayerKML;
	import com.iblsoft.flexiweather.ogc.kml.data.KMZFile;
	import com.iblsoft.flexiweather.ogc.kml.events.KMLEvent;
	import com.iblsoft.flexiweather.ogc.kml.events.KMLParsingStatusEvent;
	import com.iblsoft.flexiweather.ogc.kml.features.Document;
	import com.iblsoft.flexiweather.ogc.kml.features.KML;
	import com.iblsoft.flexiweather.ogc.kml.features.KML22;
	import com.iblsoft.flexiweather.widgets.InteractiveLayer;
	import com.iblsoft.flexiweather.widgets.InteractiveWidget;
	
	import flash.events.Event;
	import flash.net.URLRequest;
	import flash.utils.ByteArray;
	
	import mx.controls.Alert;

	public class KMLLayerConfiguration extends LayerConfiguration implements IInteractiveLayerProvider
	{
		/**
		 * Storage for kmzFile with all assets stored inside;
		 */
		private var _kmzFile: KMZFile;
		private var _kml: KML22;

		private var _kmlType: String;
		
		public function get kml(): KML22
		{
			return _kml;
		}
		/**
		 * Path which will be added to icon URL (if they are relative)
		 */
		private var _kmlBaseURLPath: String;
		private var _kmlPath: String;

		public function set kmlPath(value: String): void
		{
			_kmlPath = value;
		}

		public function get kmlPath(): String
		{
			return _kmlPath;
		}

		public function KMLLayerConfiguration()
		{
			super();
		}

		public function get kmlType(): String
		{
			if (_kmlType)
				return _kmlType;
			else {
				if (kmlPath.indexOf('kmz') >= 0)
					return 'kmz';
			}
			return 'kml';
		}
		public function loadKMZ(kmzURLPath: String): void
		{
			kmlPath = kmzURLPath;
			_kmlType = 'kmz';
			var loader: KMZLoader = new KMZLoader();
			loader.addEventListener(UniURLLoaderEvent.DATA_LOADED, onKMZLoaded);
			loader.load(new URLRequest(kmlPath));
		}

		/**
		 * KMZ file is loaded and can be un packed
		 * @param event
		 *
		 */
		private function onKMZLoaded(event: UniURLLoaderEvent): void
		{
			var ba: ByteArray = event.result as ByteArray;
			addKMZByteArray(kmlPath, ba);
		}

		public function addKMZByteArray(kmlPath: String, ba: ByteArray): void
		{
			notifyKMZUnpackingStarted();
			var kmz: KMZFile = new KMZFile(kmlPath);
			
			_kmlType = 'kmz';
			
			kmz.addEventListener(KMLEvent.UNPACKING_PROGRESS, onKMZUnpackingProgress);
			kmz.addEventListener(KMZFile.KMZ_FILE_READY, onKMZFileReady);
			kmz.createFromByteArray(ba);
		}

		/**
		 * KMZ file is unpacked and parsing process can be started
		 * @param event
		 *
		 */
		private function onKMZFileReady(event: Event): void
		{
			notifyKMZUnpackingFinished();
			notifyKMLParsingStarted();
			var kmzFile: KMZFile = event.target as KMZFile;
			var kmzURL: String = kmzFile.kmzURL;
			addKMZSource(kmzFile, kmzURL);
		}

		public function loadKML(kmlURLPath: String, baseURLPath: String): void
		{
			_kmlBaseURLPath = baseURLPath;
			kmlPath = kmlURLPath;
			var loader: KMLLoader = new KMLLoader();
			
			_kmlType = 'kml';
			
			loader.addEventListener(UniURLLoaderEvent.DATA_LOADED, onKMLLoaded);
			loader.addEventListener(UniURLLoaderErrorEvent.DATA_LOAD_FAILED, onKMLLoadFailed);
			loader.load(new URLRequest(kmlPath));
		}

		private function onKMLLoadFailed(event: UniURLLoaderErrorEvent): void
		{
			Alert.show("KMLLayerConfiguration: Loading of KML failed", "Loading failed", Alert.OK);
		}

		private function onKMLLoaded(event: UniURLLoaderEvent): void
		{
			notifyKMLParsingStarted();
			var xml: XML = event.result as XML;
			addKMLSource(xml.toXMLString(), kmlPath, _kmlBaseURLPath);
		}

		private function notifyKMZUnpackingStarted(): void
		{
			dispatchEvent(new KMLEvent(KMLEvent.UNPACKING_STARTED));
		}

		private function notifyKMZUnpackingFinished(): void
		{
			dispatchEvent(new KMLEvent(KMLEvent.UNPACKING_FINISHED));
		}

		private function notifyKMLParsingStarted(): void
		{
			dispatchEvent(new KMLEvent(KMLEvent.PARSING_STARTED));
		}

		private function notifyKMLParsingFinished(): void
		{
			dispatchEvent(new KMLEvent(KMLEvent.PARSING_FINISHED));
		}

		/**
		 * Add KMZ file. It will unzip .kmz file parse main .kml file and set bitmaps to styles to be able to display images from .kmz file
		 *
		 * @param kmz
		 * @param urlPath
		 *
		 */
		public function addKMZSource(kmz: KMZFile, urlPath: String): void
		{
			_kml = new KML22(kmz.kmlSource, urlPath, '');
			
			_kmlType = 'kmz';
			
			addKMLEventListeners(_kml);
			_kml.parse(kmz);
			_kmzFile = kmz;
			kmlPath = urlPath;
			if (_kml.document)
			{
				//if there is Document with shared styles
				var doc: Document = _kml.document;
//				doc.setBitmapsInSharedStylesFromKMZ(KMZFile);
			}
		}
		
		private function addKMLEventListeners(kml: KML): void
		{
			kml.addEventListener(KMLParsingStatusEvent.PARSING_FAILED, onKMLParsingStatus);
			kml.addEventListener(KMLParsingStatusEvent.PARSING_PARTIALLY_SUCCESFULL, onKMLParsingStatus);
			kml.addEventListener(KMLParsingStatusEvent.PARSING_SUCCESFULL, onKMLParsingStatus);
			kml.addEventListener(KMLEvent.PARSING_FINISHED, onKMLParsingFinished);
			kml.addEventListener(KMLEvent.PARSING_PROGRESS, onKMLParsingProgress);
			kml.addEventListener(KMLEvent.UNPACKING_PROGRESS, onKMZUnpackingProgress);
		}
		private function removeKMLEventListeners(kml: KML): void
		{
			kml.removeEventListener(KMLParsingStatusEvent.PARSING_FAILED, onKMLParsingStatus);
			kml.removeEventListener(KMLParsingStatusEvent.PARSING_PARTIALLY_SUCCESFULL, onKMLParsingStatus);
			kml.removeEventListener(KMLParsingStatusEvent.PARSING_SUCCESFULL, onKMLParsingStatus);
			kml.removeEventListener(KMLEvent.PARSING_FINISHED, onKMLParsingFinished);
			kml.removeEventListener(KMLEvent.PARSING_PROGRESS, onKMLParsingProgress);
			kml.removeEventListener(KMLEvent.UNPACKING_PROGRESS, onKMZUnpackingProgress);
		}
		private function onKMLParsingStatus(event: KMLParsingStatusEvent): void
		{
			dispatchEvent(event);
		}

		/**
		 * Add KML Source. Use if for single .kml files
		 * @param kmlString
		 * @param urlPath
		 *
		 */
		public function addKMLSource(kmlString: String, urlPath: String, baseUrlPath: String): void
		{
			_kml = new KML22(kmlString, urlPath, baseUrlPath);
			
			addKMLEventListeners(_kml);
			
			_kml.parse();
			kmlPath = urlPath;
		}



		/**
		 * KMZ unpacking finished
		 * @param event
		 *
		 */
		private function onKMZUnpackingProgress(event: KMLEvent): void
		{
			trace(this + " onKMZUnpackingProgress");
			dispatchEvent(event);
		}
		
		private function onKMLParsingProgress(event: KMLEvent): void
		{
			dispatchEvent(event);
		}
		
		/**
		 * KML parsing finished
		 *
		 * @param event
		 *
		 */
		private function onKMLParsingFinished(event: KMLEvent): void
		{
			var kml: KML22 = event.target as KML22;
			
			removeKMLEventListeners(kml);
			
			notifyKMLParsingFinished();
			var ke: KMLEvent;
			if (kmlType == 'kml')
				ke = new KMLEvent(KMLEvent.KML_FILE_LOADED);
			else
				ke = new KMLEvent(KMLEvent.KMZ_FILE_LOADED);
			
			ke.kmlLayerConfiguration = this;
			dispatchEvent(ke);
			
			dispatchEvent(event);
		}
		
		/*
		private function onKMZParsingFinished(event: KMLEvent): void
		{
			var kml: KML22 = event.target as KML22;
			
			removeKMLEventListeners(kml);
			
			notifyKMLParsingFinished();
			var ke: KMLEvent = new KMLEvent(KMLEvent.KMZ_FILE_LOADED);
			ke.kmlLayerConfiguration = this;
			dispatchEvent(ke);
		}
		*/

		override public function createInteractiveLayer(iw: InteractiveWidget): InteractiveLayer
		{
			//TODO need to check KML version from loaded KML
			var l: InteractiveLayerKML = new InteractiveLayerKML(iw, _kml, new Version(2, 2, 0));
			if (label)
			{
				l.name = label;
				l.layerName = label;
			}
			return l;
		}

		override public function hasCustomLayerOptions(): Boolean
		{
			return false;
		}
		
		override public function toString(): String
		{
			return 'KMLLayerConfiguration ['+id+']';
		}
	}
}
