package com.iblsoft.flexiweather.ogc.configuration
{
	import com.iblsoft.flexiweather.utils.Serializable;
	import com.iblsoft.flexiweather.utils.Storage;
	import flash.events.Event;
	import flash.events.EventDispatcher;

	public class AnimationSetConfiguration extends EventDispatcher implements Serializable
	{
		protected var ms_label: String;
		protected var ms_animationsSetConfiguration: XML;

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
		public function get animationsSetConfiguration(): XML
		{
			return ms_animationsSetConfiguration;
		}

		public function set animationsSetConfiguration(value: XML): void
		{
			ms_animationsSetConfiguration = value;
			dispatchEvent(new Event('animationChanged'));
		}

		public function AnimationSetConfiguration()
		{
		}

		public function serialize(storage: Storage): void
		{
			ms_label = storage.serializeString("label", ms_label);
			if (storage.isLoading())
				ms_animationsSetConfiguration = new XML(storage.serializeString("animations-set", ms_animationsSetConfiguration));
			else
				storage.serializeString("animations-set", ms_animationsSetConfiguration.toXMLString());
		}
	}
}
