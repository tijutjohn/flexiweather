package com.iblsoft.flexiweather.ogc.kml.managers
{
	import com.iblsoft.flexiweather.ogc.kml.controls.KMLLabel;
	import com.iblsoft.flexiweather.ogc.kml.data.KMLResourceKey;
	import com.iblsoft.flexiweather.ogc.kml.data.KMZFile;
	import com.iblsoft.flexiweather.ogc.kml.events.KMLBitmapEvent;
	import com.iblsoft.flexiweather.ogc.kml.features.KMLFeature;
	import com.iblsoft.flexiweather.ogc.kml.features.constants.KMLIconPins;
	import com.iblsoft.flexiweather.ogc.kml.features.styles.HotSpot;
	import com.iblsoft.flexiweather.plugins.IConsole;
	import com.iblsoft.flexiweather.plugins.IConsoleManager;
	import com.iblsoft.flexiweather.utils.URLUtils;
	
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.geom.Matrix;
	import flash.utils.Dictionary;

	public class KMLResourceManager extends EventDispatcher
	{
		public static const ALL_RESOURCES_LOADED: String = 'allResourcesLoaded';
		public static const RESOURCE_TYPE_ICON: String = 'icon';
		public static const RESOURCE_TYPE_IMAGE: String = 'image';
		public static var debugConsole: IConsole;
		public static var reuseKMLLabels: Boolean = false;
		private var _cache: ResourceCache;
		private var _kmzFiles: Dictionary;
		private var _basePath: String;
		private var _icons: KMLIconPins;

		public function get basePath(): String
		{
			return _basePath;
		}

		public function KMLResourceManager(basePath: String)
		{
			if (!basePath)
				basePath = '';
			_basePath = basePath;
			_cache = new ResourceCache();
			_kmzFiles = new Dictionary();
			_icons = new KMLIconPins();
		}

		public function disposeResource(key: KMLResourceKey): void
		{
			if (!key)
				return;
			var resource: Resource;
			if (_cache.resourceExists(key))
			{
				resource = _cache.getResource(key);
				resource.dispose();
				_cache.deleteResource(key);
				key = null;
				resource = null;
			}
		}

		public function debugCache(txt: String): void
		{
			//debug("cache items: [" + txt + "] " + _cache.getAllResources().length);
		}

		private function debug(txt: String): void
		{
			return;
			if (debugConsole)
			{
				debugConsole.print("KMLResourceManager: " + txt, 'Info', 'KMLResourceManager');
			}
		}

		public function isResourceLoading(key: KMLResourceKey): Boolean
		{
			var resource: Resource = _cache.getResource(key);
			if (resource)
			{
//				debug("isResourceLoading [" + key.toString() + "]: " + resource.isLoading);
				return resource.isLoading;
			}
			return false;
		}

		public function isResourceLoaded(key: KMLResourceKey): Boolean
		{
			var bd: BitmapData = getBitmapData(key);
//			debug("isResourceLoaded [" + key.toString() + "]: " + (bd != null));
			return (bd != null);
		}

		public function getAllBitmapDatas(): Array
		{
			var bitmapDatas: Array = [];
			var resources: Array = _cache.getAllResources();
			for each (var resource: Resource in resources)
			{
				if (resource.isResourceLoaded)
					bitmapDatas.push(resource.bitmapData);
			}
			return bitmapDatas;
		}

		public function getPinHotSpot(color: String): HotSpot
		{
			return _icons.getPinHotSpot(color);
		}

		public function getPinBitmapData(color: String): BitmapData
		{
			return _icons.getPinBitmapData(color);
		}

		public function getBitmapData(key: KMLResourceKey): BitmapData
		{
			var resource: Resource;
			if (_cache.resourceExists(key))
			{
				resource = _cache.getResource(key);
				if (resource.isResourceLoaded)
				{
					//debug("getBitmapData [" + key.toString() + "]: " + (resource.bitmapData != null));
					return resource.bitmapData;
				}
			}
			return null;
		}

		public function addKMZFile(kmzFile: KMZFile): void
		{
			_kmzFiles[kmzFile.kmzURL] = kmzFile;
		}

		public function removeKMZFile(kmzURL: String): void
		{
			delete _kmzFiles[kmzURL];
		}

		public function addResource(key: KMLResourceKey, bitmapData: BitmapData): void
		{
			var resource: Resource;
			if (_cache.resourceExists(key))
				resource = _cache.getResource(key);
			else
				resource = new Resource(key);
			resource.setBitmapData(bitmapData);
		}

		private function notifyBitmapLoaded(resource: Resource): void
		{
			var kbe: KMLBitmapEvent;
			var bd: BitmapData = resource.bitmapData;
			kbe = new KMLBitmapEvent(KMLBitmapEvent.BITMAP_LOADED);
			kbe.key = resource.key;
			kbe.bitmapData = bd;
			dispatchEvent(kbe);
		}

		public function loadResource(key: KMLResourceKey): void
		{
			//debug("loadResource [" + key.toString() + "]");
			var kbe: KMLBitmapEvent;
			var bd: BitmapData
			if (!URLUtils.isAbsolutePath(key.href))
			{
				key.baseURL = _basePath;
				if (_cache.resourceExists(key))
				{
					resource = _cache.getResource(key);
					bd = resource.bitmapData;
					if (bd)
					{
						//debug("\t loadResource absolutepath BITMAP_LOADED [" + key.toString() + "]");
						notifyBitmapLoaded(resource);
						return;
					}
				}
				//debug("\t loadResource relativepath [" + key.toString() + "]");
				//this is relative path, try to check it from .kmz files
				for each (var kmzFile: KMZFile in _kmzFiles)
				{
					bd = kmzFile.getAssetBitmapDataByName(key.href);
					if (bd)
					{
						resource = new Resource(key);
						resource.setBitmapData(bd);
						_cache.addResource(key, resource);
						//debug("\t loadResource relativepath bitmap loaded [" + key.toString() + "]");
						notifyBitmapLoaded(resource);
						return;
					}
				}
			}
			var resource: Resource;
			if (_cache.resourceExists(key))
			{
				//debug("\t loadResource absolutepath resourceExists [" + key.toString() + "]");
				resource = _cache.getResource(key);
				bd = resource.bitmapData;
				if (bd)
				{
					//debug("\t loadResource absolutepath BITMAP_LOADED [" + key.toString() + "]");
					notifyBitmapLoaded(resource);
					return;
				}
			}
			else
			{
				//debug("\t loadResource addResource [" + key.toString() + "]");
				resource = new Resource(key);
				_cache.addResource(key, resource);
			}
			if (resource)
			{
				resource.addEventListener(KMLBitmapEvent.BITMAP_LOADED, onResourceLoaded);
				resource.addEventListener(KMLBitmapEvent.BITMAP_LOAD_ERROR, onResourceLoadError);
				resource.load();
				//debug("\t loadResource load [" + key.toString() + "]");
			}
		}

		public function createBitmap(bitmapData: BitmapData): Bitmap
		{
			return new Bitmap(bitmapData);
		}

		private function allResourcesLoaded(): Boolean
		{
			return _cache.allResourcesLoaded();
		}

		private function notifyAllResourcesLoaded(): void
		{
			if (allResourcesLoaded())
			{
				//debug("\t loadResource allResourcesLoaded");
				dispatchEvent(new Event(ALL_RESOURCES_LOADED));
			}
		}

		private function onResourceLoaded(event: KMLBitmapEvent): void
		{
			var resource: Resource = event.target as Resource;
			if (resource)
			{
				//debug("\t loadResource onResourceLoaded");
				dispatchEvent(event);
			}
			notifyAllResourcesLoaded();
		}

		private function onResourceLoadError(event: KMLBitmapEvent): void
		{
			var resource: Resource = event.target as Resource;
			if (resource)
			{
				//debug("\t loadResource onResourceLoadError");
				dispatchEvent(event);
			}
			notifyAllResourcesLoaded();
		}
		private var _kmlLabels: Array = [];

		public function pushKMLLabel(label: KMLLabel): void
		{
			if (!reuseKMLLabels)
			{
				label.cleanup();
				label = null;
			}
			else
			{
				label.invalidate();
				_kmlLabels.push(label);
			}
		}

		public function getKMLLabel(feature: KMLFeature): KMLLabel
		{
			var label: KMLLabel;
			if (reuseKMLLabels)
			{
				label = popKMLLabel();
				label.kmlFeature = feature;
			}
			if (!label)
				label = new KMLLabel(feature);
			return label;
		}

		public function popKMLLabel(): KMLLabel
		{
			if (_kmlLabels && _kmlLabels.length > 0)
				return _kmlLabels.pop();
			return null;
		}
	}
}
import com.iblsoft.flexiweather.ogc.kml.controls.KMLBitmapLoader;
import com.iblsoft.flexiweather.ogc.kml.data.KMLResourceKey;
import com.iblsoft.flexiweather.ogc.kml.events.KMLBitmapEvent;
import com.iblsoft.flexiweather.ogc.kml.managers.KMLResourceManager;
import flash.display.Bitmap;
import flash.display.BitmapData;
import flash.events.EventDispatcher;
import flash.geom.Matrix;
import flash.utils.Dictionary;

class ResourceCache
{
	private var _dictionary: Dictionary;

	public function ResourceCache(): void
	{
		_dictionary = new Dictionary();
	}

	public function addResource(key: KMLResourceKey, resource: Resource): void
	{
		var id: String = key.toString();
		_dictionary[id] = resource;
	}

	public function getAllResources(): Array
	{
		var resources: Array = [];
		for each (var resource: Resource in _dictionary)
		{
			resources.push(resource);
		}
		return resources;
	}

	public function deleteResource(key: KMLResourceKey): void
	{
		if (_dictionary)
		{
			var id: String = key.toString();
			delete _dictionary[id];
		}
	}

	public function getResource(key: KMLResourceKey): Resource
	{
		if (_dictionary)
		{
			var id: String = key.toString();
			return _dictionary[id] as Resource;
		}
		return null;
	}

	public function resourceExists(key: KMLResourceKey): Boolean
	{
		return getResource(key) != null;
	}

	public function allResourcesLoaded(): Boolean
	{
		for each (var resource: Resource in _dictionary)
		{
			if (!resource.loadingFinished)
				return false;
		}
		return true;
	}
}

class Resource extends EventDispatcher
{
	public var key: KMLResourceKey
	private var _loader: KMLBitmapLoader;
	private var _loadingFinished: Boolean;

	public function get loadingFinished(): Boolean
	{
		return _loadingFinished;
	}

	public function Resource(key: KMLResourceKey)
	{
		this.key = key;
		_loadingFinished = true;
	}

	public function dispose(): void
	{
		if (_loader && _loader.bitmapData)
		{
			removeLoaderListeners();
			_loader.unload();
			_loader = null;
		}
	}

	public function setBitmapData(bitmapData: BitmapData): void
	{
		if (!_loader)
		{
			_loader = new KMLBitmapLoader(key.baseURL);
			_loader.setBitmapData(bitmapData);
		}
	}

	public function load(): void
	{
		if (!_loader)
		{
			_loader = new KMLBitmapLoader(key.baseURL);
			_loader.addEventListener(KMLBitmapEvent.BITMAP_LOADED, onBitmapLoaded);
			_loader.addEventListener(KMLBitmapEvent.BITMAP_LOADED, onBitmapLoadError);
		}
		_loadingFinished = false;
		_loader.loadBitmap(key.href);
	}

	private function removeLoaderListeners(): void
	{
		_loader.removeEventListener(KMLBitmapEvent.BITMAP_LOADED, onBitmapLoaded);
		_loader.removeEventListener(KMLBitmapEvent.BITMAP_LOADED, onBitmapLoadError);
	}

	private function onBitmapLoaded(event: KMLBitmapEvent): void
	{
		removeLoaderListeners();
		_loadingFinished = true;
		_loader.setBitmapData(fixBitmapData(bitmapData, key.type));
		event.key = key;
		event.bitmapData = _loader.bitmapData;
		dispatchEvent(event);
	}

	private function onBitmapLoadError(event: KMLBitmapEvent): void
	{
		removeLoaderListeners();
		_loadingFinished = true;
		event.key = key;
		dispatchEvent(event);
	}

	private function fixBitmapData(bd: BitmapData, type: String): BitmapData
	{
		if (type == KMLResourceManager.RESOURCE_TYPE_ICON)
		{
			var resizeWidth: int = 32;
			var resizeHeight: int = 32;
			//check if bitmap data is 32x32 pixels, if not, resize it to 32x32 pixels
			if (bd.width != resizeWidth || bd.height != resizeHeight)
			{
				var sx: Number = resizeWidth / bd.width;
				var sy: Number = resizeHeight / bd.height;
				var m: Matrix = new Matrix();
				m.scale(sx, sy);
				var bdNew: BitmapData = new BitmapData(resizeWidth, resizeHeight, true, 0x00000000);
				bdNew.draw(bd, m);
				return bdNew
			}
		}
		return bd;
	}

	public function getClonedBitmap(): Bitmap
	{
		if (_loader && _loader.bitmapData)
			return new Bitmap(_loader.bitmapData);
		return null;
	}

	public function get bitmapData(): BitmapData
	{
		if (_loader && _loader.bitmapData)
			return _loader.bitmapData;
		return null;
	}

	public function get isLoading(): Boolean
	{
		if (_loader)
			return _loader.isLoading;
		return false;
	}

	public function get isResourceLoaded(): Boolean
	{
		if (_loader && _loader.bitmapData)
			return (_loader.bitmapData != null);
		return false;
	}
}
