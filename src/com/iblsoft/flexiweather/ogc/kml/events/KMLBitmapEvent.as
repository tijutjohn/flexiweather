package com.iblsoft.flexiweather.ogc.kml.events
{
	import com.iblsoft.flexiweather.ogc.kml.data.KMLResourceKey;
	import com.iblsoft.flexiweather.ogc.kml.features.styles.StyleSelector;
	import flash.display.BitmapData;
	import flash.events.Event;

	public class KMLBitmapEvent extends Event
	{
		public static const BITMAP_LOADED: String = 'bitmapLoaded';
		public static const BITMAP_LOAD_ERROR: String = 'bitmapLoadError';
		public var key: KMLResourceKey;
		public var bitmapData: BitmapData;

		public function KMLBitmapEvent(type: String, bubbles: Boolean = false, cancelable: Boolean = false)
		{
			super(type, bubbles, cancelable);
		}

		override public function clone(): Event
		{
			var kse: KMLBitmapEvent = new KMLBitmapEvent(type);
			kse.key = key;
			kse.bitmapData = bitmapData;
			return kse;
		}
	}
}
