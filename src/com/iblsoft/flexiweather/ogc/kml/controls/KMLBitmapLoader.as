package com.iblsoft.flexiweather.ogc.kml.controls
{
	import com.iblsoft.flexiweather.net.events.UniURLLoaderErrorEvent;
	import com.iblsoft.flexiweather.net.events.UniURLLoaderEvent;
	import com.iblsoft.flexiweather.net.loaders.UniURLLoader;
	import com.iblsoft.flexiweather.ogc.kml.events.KMLBitmapEvent;
	import com.iblsoft.flexiweather.ogc.kml.features.Document;
	import com.iblsoft.flexiweather.plugins.IConsole;
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.events.EventDispatcher;
	import flash.net.URLRequest;

	public class KMLBitmapLoader extends EventDispatcher
	{
		public static var console: IConsole;
		private var _isLoading: Boolean;

		public function get isLoading(): Boolean
		{
			return _isLoading;
		}
		private var _baseURLPath: String;
		private var _iconBitmapData: BitmapData;

		public function KMLBitmapLoader(baseURLPath: String)
		{
			_baseURLPath = baseURLPath;
		}

		public function unload(): void
		{
			if (_iconBitmapData)
				_iconBitmapData.dispose();
			console = null;
		}

		/**
		 * You can set bitmapData directly, e.g. for KMZ assets
		 * @param bd
		 *
		 */
		public function setBitmapData(bd: BitmapData): void
		{
			_iconBitmapData = bd;
		}

		public function loadBitmap(href: String): void
		{
			if (_iconBitmapData)
			{
				//icon is already loaded
				notifyAllListeners();
				return;
			}
			href = fixBitmapHref(href);
			if (href)
				loadBitmapAsset(href);
		}

		private function loadBitmapAsset(href: String): void
		{
			_isLoading = true;
			var assocData: Object = {};
			var loader: UniURLLoader = new UniURLLoader();
			loader.addEventListener(UniURLLoaderEvent.DATA_LOADED, onBitmapLoaded);
			loader.addEventListener(UniURLLoaderErrorEvent.DATA_LOAD_FAILED, onBitmapIOError);
			if (href.indexOf('http') == 0)
			{
				if (console)
					console.print("KMLBitmapLoader load: " + href);
				loader.load(new URLRequest(href), assocData);
			}
			else
			{
				if (console)
					console.print("KMLBitmapLoader load: " + (_baseURLPath + href));
				loader.load(new URLRequest(_baseURLPath + href), assocData);
			}
		}

		/**
		 * In some case we need to fix icon href url. E.g. when href starts with "root:", which is deprecated in 2.2, of if url is relative
		 *
		 * @param href
		 * @return
		 *
		 */
		private function fixBitmapHref(href: String): String
		{
			if (!href)
				return null;
			if (href.indexOf('root:') == 0)
			{
				//this is old unsupport icon format, change href
				/*
				http://maps.google.com/mapfiles/kml/pushpin/ylw-pushpin.png
				http://maps.google.com/mapfiles/kml/pushpin/blue-pushpin.png
				http://maps.google.com/mapfiles/kml/pushpin/grn-pushpin.png
				http://maps.google.com/mapfiles/kml/pushpin/ltblu-pushpin.png
				http://maps.google.com/mapfiles/kml/pushpin/pink-pushpin.png
				http://maps.google.com/mapfiles/kml/pushpin/purple-pushpin.png
				http://maps.google.com/mapfiles/kml/pushpin/red-pushpin.png
				http://maps.google.com/mapfiles/kml/pushpin/wht-pushpin.png
				*/
				//need to fix hotsport
				href = 'http://maps.google.com/mapfiles/kml/pushpin/ylw-pushpin.png';
			}
			return href;
		}

		private function onBitmapLoaded(event: UniURLLoaderEvent): void
		{
			_iconBitmapData = (event.result as Bitmap).bitmapData;
			notifyAllListeners();
			if (console)
				console.print("KMLBitmapLoader onBitmapLoaded :" + _iconBitmapData.width + " , " + _iconBitmapData.height);
		}

		private function notifyAllListeners(): void
		{
			_isLoading = false;
			var kse: KMLBitmapEvent = new KMLBitmapEvent(KMLBitmapEvent.BITMAP_LOADED, true);
			dispatchEvent(kse);
		}

		private function onBitmapIOError(event: UniURLLoaderErrorEvent): void
		{
			if (console)
				console.print("KMLBitmapLoader onBitmaopIOError: " + event.errorString);
			var kse: KMLBitmapEvent = new KMLBitmapEvent(KMLBitmapEvent.BITMAP_LOAD_ERROR, true);
			dispatchEvent(kse);
		}

		public function get bitmapData(): BitmapData
		{
			return _iconBitmapData;
		}
	}
}
