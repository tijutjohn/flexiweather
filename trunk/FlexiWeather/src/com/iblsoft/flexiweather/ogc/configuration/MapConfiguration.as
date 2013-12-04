package com.iblsoft.flexiweather.ogc.configuration
{
	import com.iblsoft.flexiweather.utils.Serializable;
	import com.iblsoft.flexiweather.utils.Storage;
	import flash.events.Event;
	import flash.events.EventDispatcher;

	public class MapConfiguration extends EventDispatcher implements Serializable
	{
		protected var ms_label: String;
		protected var ms_mapConfiguration: XML;

		[Bindable(event = "labelChanged")]
		public function get label(): String
		{
			return ms_label;
		}

		public function set label(s: String): void
		{
			ms_label = s;
			dispatchEvent(new Event('labelChanged'));
		}

		[Bindable(event = "mapChanged")]
		public function get mapConfiguration(): XML
		{
			return ms_mapConfiguration;
		}

		public function set mapConfiguration(value: XML): void
		{
			ms_mapConfiguration = value;
			dispatchEvent(new Event('mapChanged'));
		}

		public function MapConfiguration()
		{
		}

		public function serialize(storage: Storage): void
		{
			ms_label = storage.serializeString("label", ms_label);
			if (storage.isLoading())
				ms_mapConfiguration = new XML(storage.serializeString("map", ms_mapConfiguration));
			else
				storage.serializeString("map", ms_mapConfiguration.toXMLString());
		}
	}
}
