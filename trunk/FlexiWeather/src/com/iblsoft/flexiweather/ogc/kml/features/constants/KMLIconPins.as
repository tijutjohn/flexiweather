package com.iblsoft.flexiweather.ogc.kml.features.constants
{
	import com.iblsoft.flexiweather.net.events.UniURLLoaderErrorEvent;
	import com.iblsoft.flexiweather.net.events.UniURLLoaderEvent;
	import com.iblsoft.flexiweather.net.loaders.ImageLoader;
	import com.iblsoft.flexiweather.net.loaders.URLLoaderWithAssociatedData;
	import com.iblsoft.flexiweather.ogc.kml.features.styles.HotSpot;
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.Graphics;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.net.URLLoader;
	import flash.net.URLRequest;
	import flash.utils.ByteArray;
	import flash.utils.Dictionary;

	public class KMLIconPins
	{
		private var yellow_pin: String = 'http://maps.google.com/mapfiles/kml/pushpin/ylw-pushpin.png';
		private var blue_pin: String = 'http://maps.google.com/mapfiles/kml/pushpin/blue-pushpin.png';
		private var green_pin: String = 'http://maps.google.com/mapfiles/kml/pushpin/grn-pushpin.png';
		private var light_blue_pin: String = 'http://maps.google.com/mapfiles/kml/pushpin/ltblu-pushpin.png';
		private var pink_pin: String = 'http://maps.google.com/mapfiles/kml/pushpin/pink-pushpin.png';
		private var purple_pin: String = 'http://maps.google.com/mapfiles/kml/pushpin/purple-pushpin.png';
		private var red_pin: String = 'http://maps.google.com/mapfiles/kml/pushpin/red-pushpin.png';
		private var white_pin: String = 'http://maps.google.com/mapfiles/kml/pushpin/wht-pushpin.png';
		static private var _icons: Dictionary = new Dictionary();

		public function KMLIconPins()
		{
			initIcons();
		}

		public function getPinHotSpot(color: String): HotSpot
		{
			//<hotSpot x="20" y="2" xunits="pixels" yunits="pixels"/>
			var hotspot: HotSpot = new HotSpot(new XML('<hotSpot x="20" y="2" xunits="pixels" yunits="pixels"/>'));
			return hotspot;
		}

		public function getPinBitmapData(color: String): BitmapData
		{
			if (_icons && _icons[color])
			{
				var obj: Object = _icons[color];
				return (obj.icon as Bitmap).bitmapData;
			}
			var sprite: Sprite = new Sprite();
			var gr: Graphics = sprite.graphics;
			gr.beginFill(0xaa0000, 0.3);
			gr.lineStyle(1, 0);
			gr.drawCircle(0, 0, 16);
			gr.endFill();
			var bd: BitmapData = new BitmapData(32, 32, true, 0x00000000);
			bd.draw(sprite);
			return bd;
		}

		private function initIcons(): void
		{
			var colors: Array = ['yellow', 'blue', 'green', 'light_blue', 'pink', 'purple', 'red', 'white'];
			var cnt: int = 1;
			for each (var color: String in colors)
			{
				var url: String = this[color + "_pin"];
				var request: URLRequest = new URLRequest(url);
				var imageLoader: ImageLoader = new ImageLoader();
				imageLoader.addEventListener(Event.COMPLETE, onKMLPinIconLoaded);
				imageLoader.addEventListener(UniURLLoaderEvent.DATA_LOADED, onKMLPinIconLoaded);
				imageLoader.addEventListener(UniURLLoaderErrorEvent.DATA_LOAD_FAILED, onKMLPinIconLoadFailed);
				imageLoader.load(request, {color: color, id: cnt});
				cnt++;
			}
		}

		private function onKMLPinIconLoadFailed(event: UniURLLoaderErrorEvent): void
		{
			trace("onIconLoadFailed");
		}

		private function onKMLPinIconLoaded(event: UniURLLoaderEvent): void
		{
			var loader: URLLoaderWithAssociatedData = event.target as URLLoaderWithAssociatedData;
			var data: Object = event.associatedData;
			var result: Bitmap = event.result as Bitmap;
			_icons[data.color] = {color: data.color, id: data.id, icon: result};
		}
	}
}
