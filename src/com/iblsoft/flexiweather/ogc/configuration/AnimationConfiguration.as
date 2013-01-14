package com.iblsoft.flexiweather.ogc.configuration
{
	import com.iblsoft.flexiweather.utils.Serializable;
	import com.iblsoft.flexiweather.utils.Storage;
	import flash.events.Event;
	import flash.events.EventDispatcher;

	public class AnimationConfiguration extends EventDispatcher implements Serializable
	{
		protected var ms_label: String;
		protected var ms_animationConfiguration: XML;

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

		[Bindable(event = "animationChanged")]
		public function get animationConfiguration(): XML
		{
			return ms_animationConfiguration;
		}

		public function set animationConfiguration(value: XML): void
		{
			ms_animationConfiguration = value;
			dispatchEvent(new Event('animationChanged'));
		}

		public function AnimationConfiguration()
		{
		}

		public function serialize(storage: Storage): void
		{
			ms_label = storage.serializeString("label", ms_label);
			if (storage.isLoading())
				ms_animationConfiguration = new XML(storage.serializeString("map", ms_animationConfiguration));
			else
				storage.serializeString("animation", ms_animationConfiguration.toXMLString());
		}
	}
}
