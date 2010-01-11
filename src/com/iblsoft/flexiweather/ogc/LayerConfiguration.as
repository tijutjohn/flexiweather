package com.iblsoft.flexiweather.ogc
{
	import com.iblsoft.flexiweather.utils.Serializable;
	import com.iblsoft.flexiweather.utils.Storage;
	
	import flash.events.EventDispatcher;
	
	public class LayerConfiguration extends EventDispatcher implements Serializable
	{
		protected var ms_label: String;

		public function LayerConfiguration()
		{
		}

		public function serialize(storage: Storage): void
		{
			ms_label = storage.serializeString("label", ms_label);
		}
		
		public function get label(): String
		{ return ms_label; }

		public function set label(s: String): void
		{ ms_label = s; }
	}
}