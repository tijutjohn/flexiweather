package com.iblsoft.flexiweather.ogc.kml.configuration
{
	import com.iblsoft.flexiweather.net.events.UniURLLoaderErrorEvent;
	import com.iblsoft.flexiweather.net.events.UniURLLoaderEvent;
	import com.iblsoft.flexiweather.net.loaders.BinaryLoader;
	import com.iblsoft.flexiweather.net.loaders.UniURLLoader;
	import com.iblsoft.flexiweather.net.loaders.XMLLoader;
	import com.iblsoft.flexiweather.ogc.LayerConfiguration;
	import com.iblsoft.flexiweather.ogc.Version;
	import com.iblsoft.flexiweather.ogc.kml.InteractiveLayerKML;
	import com.iblsoft.flexiweather.ogc.kml.data.KMZFile;
	import com.iblsoft.flexiweather.ogc.kml.features.Document;
	import com.iblsoft.flexiweather.ogc.kml.features.KML22;
	import com.iblsoft.flexiweather.widgets.InteractiveLayer;
	import com.iblsoft.flexiweather.widgets.InteractiveWidget;
	
	import flash.events.Event;
	import flash.net.URLRequest;
	import flash.utils.ByteArray;
	
	public class KMLLayerConfiguration extends LayerConfiguration
	{
		public static const KML_FILE_LOADED: String = 'kmlFileLoaded';
		public static const KMZ_FILE_LOADED: String = 'kmzFileLoaded';
		
		/**
		 * Storage for kmzFile with all assets stored inside; 
		 */		
		private var _kmzFile: KMZFile;
		
		private var _kml: KML22;
		
		/**
		 * Path which will be added to icon URL (if they are relative) 
		 */		
		private var _kmlBaseURLPath: String;
		private var _kmlPath: String;
		
		public function get kmlPath(): String
		{
			return _kmlPath;
		}
		public function KMLLayerConfiguration()
		{
			super();
		}
		
		public function loadKMZ(kmzURLPath: String): void
		{
			_kmlPath =  kmzURLPath;
			
			var loader: BinaryLoader = new BinaryLoader();
			loader.addEventListener(UniURLLoaderEvent.DATA_LOADED, onKMZLoaded);
			loader.load(new URLRequest(_kmlPath));
		}
		private function onKMZLoaded(event: UniURLLoaderEvent): void
		{
			var ba: ByteArray = event.result as ByteArray;
			var kmz: KMZFile = new KMZFile(_kmlPath);
			kmz.addEventListener(KMZFile.KMZ_FILE_READY, onKMZFileReady);
			kmz.createFromByteArray(ba);
//			addKMLSource(xml.toXMLString(), _kmlPath);
			
		}
		private function onKMZFileReady(event: Event): void
		{
			var kmzFile: KMZFile = event.target as KMZFile;
			var kmzURL: String = kmzFile.kmzURL; 
			
			addKMZSource(kmzFile, kmzURL);
			
			dispatchEvent(new Event(KMZ_FILE_LOADED));
			//and create KML layer now
		}
		
		public function loadKML(kmlURLPath: String, baseURLPath: String): void
		{
			_kmlBaseURLPath = baseURLPath;
			_kmlPath =  kmlURLPath;
			
			var loader: XMLLoader = new XMLLoader();
			loader.addEventListener(UniURLLoaderEvent.DATA_LOADED, onKMLLoaded);
			loader.load(new URLRequest(_kmlPath));
		}
		
		private function onKMLLoaded(event: UniURLLoaderEvent): void
		{
			var xml: XML = event.result as XML;
			addKMLSource(xml.toXMLString(), _kmlPath);
			
			dispatchEvent(new Event(KML_FILE_LOADED));
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
			_kml = new KML22(kmz.kmlSource, urlPath);
			_kml.parse(kmz);
			
			_kmzFile = kmz;
			_kmlPath = urlPath;
			
			if (_kml.document)
			{
				//if there is Document with shared styles
				var doc: Document = _kml.document;
//				doc.setBitmapsInSharedStylesFromKMZ(KMZFile);
				
			}
		}
		
		/**
		 * Add KML Source. Use if for single .kml files 
		 * @param kmlString
		 * @param urlPath
		 * 
		 */		
		public function addKMLSource(kmlString: String, urlPath: String): void
		{
			_kml = new KML22(kmlString, urlPath);
			_kml.parse();
			
			_kmlPath = urlPath;
		}
		
		override public function createInteractiveLayer(iw: InteractiveWidget): InteractiveLayer
		{
//			trace("KMLLayerConfiguration create new KML layer: " + this);
			
			//TODO need to check KML version from loaded KML
			var l: InteractiveLayerKML = new InteractiveLayerKML(iw, _kml, new Version(2,2,0));
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
	}
}