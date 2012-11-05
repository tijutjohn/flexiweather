package com.iblsoft.flexiweather.ogc.kml.events
{
	import com.iblsoft.flexiweather.ogc.kml.configuration.KMLLayerConfiguration;
	import com.iblsoft.flexiweather.ogc.kml.data.KMLLoaderObject;
	import flash.events.Event;

	public class KMLEvent extends Event
	{
		public static const KML_FILE_LOADED: String = 'kmlFileLoaded';

		public static const KMZ_FILE_LOADED: String = 'kmzFileLoaded';

		public static const UNPACKING_STARTED: String = 'unpackingStarted';

		public static const UNPACKING_FINISHED: String = 'unpackingFinished';

		public static const PARSING_STARTED: String = 'parsingStarted';

		public static const PARSING_FINISHED: String = 'parsingFinished';

		public var data: KMLLoaderObject;

		public var kmlLayerConfiguration: KMLLayerConfiguration;

		public function KMLEvent(type: String, bubbles: Boolean = false, cancelable: Boolean = false)
		{
			super(type, bubbles, cancelable);
		}

		override public function clone(): Event
		{
			var event: KMLEvent = new KMLEvent(type, bubbles, cancelable);
			event.data = data;
			event.kmlLayerConfiguration = kmlLayerConfiguration;
			return event;
		}
	}
}
