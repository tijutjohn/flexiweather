package com.iblsoft.flexiweather.ogc.kml.data
{
	import com.iblsoft.flexiweather.ogc.kml.events.KMLEvent;
	import com.iblsoft.flexiweather.ogc.kml.managers.KMLParserManager;
	import com.iblsoft.flexiweather.utils.AsyncManager;
	
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.Loader;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.utils.ByteArray;
	import flash.utils.Dictionary;
	import flash.utils.getTimer;
	import flash.utils.setTimeout;
	
	import nochump.util.zip.ZipEntry;
	import nochump.util.zip.ZipFile;

	public class KMZFile extends EventDispatcher
	{
		public static const KMZ_FILE_READY: String = 'kmzFileReady';
		private var _kmzURL: String;
		private var _kmlSource: String;
		private var _name: String;
		private var _assets: Dictionary;
		private var _isReady: Boolean

		public function get ready(): Boolean
		{
			return _isReady;
		}

		public function get kmzURL(): String
		{
			return _kmzURL;
		}

		public function get kmlSource(): String
		{
			return _kmlSource;
		}

		public function get name(): String
		{
			return _name;
		}

		public function set name(value: String): void
		{
			_name = value;
		}

		public function KMZFile(url: String)
		{
			_assets = new Dictionary();
			_kmzURL = url;
		}

		public function addKML(src: String): void
		{
			_kmlSource = src;
		}

		public function addAssets(name: String, ba: ByteArray): void
		{
			var loader: Loader = new Loader();
			loader.loadBytes(ba);
			_assets[name] = {name: name, loader: loader};
		}

		private function getAssetNameByLoader(loader: Loader): String
		{
			for each (var obj: Object in _assets)
			{
				if (obj.loader == loader)
					return obj.name;
			}
			return null;
		}

		private function onAssetsComplete(): void
		{
			var _allOK: Boolean = true;
			for each (var obj: Object in _assets)
			{
				var loader: Loader = obj.loader as Loader
				var assetName: String = obj.name;
				if (loader)
				{
					if (loader.width == 0 && loader.height == 0)
					{
						_allOK = false;
						continue;
					}
					else
					{
						if (assetName)
						{
							var bd: BitmapData = new BitmapData(loader.width, loader.height, true, 0x00000000);
//							var bd: BitmapData = new BitmapData(loader.width, loader.height);
							bd.draw(loader);
							_assets[assetName].bitmapData = bd;
							delete _assets[assetName].loader;
						}
						else
							trace("KMZFile: cannot find asset for loader");
					}
				}
			}
			if (!_allOK)
			{
				//not every bitmap is created from loader, try again in 100ms
				setTimeout(onAssetsComplete, 100);
			}
			else
			{
				_isReady = true;
				notifyReady();
			}
		}

		private function notifyReady(): void
		{
			dispatchEvent(new Event(KMZ_FILE_READY));
		}

		public function createBitmaps(): void
		{
			setTimeout(onAssetsComplete, 100);
		}

		public function getAssetBitmapDataByName(name: String): BitmapData
		{
			if (_assets[name])
				return _assets[name].bitmapData as BitmapData;
			return null;
		}

		public function createFromByteArray(ba: ByteArray): void
		{
			var time: Number = getTimer();
			var zipFile: ZipFile = new ZipFile(ba);
			var kmzParser: KMLParserManager = new KMLParserManager('KMZFile parser');
			kmzParser.addEventListener(KMLEvent.PARSING_PROGRESS, onKMZParserProgress);
			kmzParser.addEventListener(AsyncManager.EMPTY, onKMZParserFinish);
			kmzParser.maxCallsPerTick = 1;
			
			for (var i: int = 0; i < zipFile.entries.length; i++)
			{
				var entry: ZipEntry = zipFile.entries[i];
				kmzParser.addCall({obj: entry}, onZipEntryParsing, [zipFile, entry]);
				
			}
			trace("KMZFile createFromByteArray unzipped: " + (getTimer() - time) + "ms");
			time = getTimer();
			kmzParser.start();			
			
		}
		
		private function onKMZParserProgress(event: KMLEvent): void
		{
			var ke: KMLEvent = new KMLEvent(KMLEvent.UNPACKING_PROGRESS, true);
			ke.progress = event.progress;
			dispatchEvent(ke);
		}
		private function onKMZParserFinish(event: Event): void
		{
			var kmzParser: KMLParserManager = event.target as KMLParserManager;
			kmzParser.removeEventListener(KMLEvent.UNPACKING_PROGRESS, onKMZParserProgress);
			kmzParser.removeEventListener(AsyncManager.EMPTY, onKMZParserFinish);
			
			
			createBitmaps();
		}
		public function onZipEntryParsing(zipFile: ZipFile, entry: ZipEntry): void
		{
			// extract the entry's data from the zip
			var data: ByteArray = zipFile.getInput(entry);
			var name: String = entry.name;
			if (name.indexOf(".kml") > 0)
			{
				name = name;
				addKML(data.toString());
			}
			else
			{
				if (name.indexOf(".png") > 0 || name.indexOf(".jpg") > 0 || name.indexOf(".gif") > 0)
					addAssets(name, data);
			}
			
		}
	}
}
