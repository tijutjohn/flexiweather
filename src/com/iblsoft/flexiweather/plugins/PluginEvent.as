package com.iblsoft.flexiweather.plugins
{
	import flash.events.Event;
	import mx.modules.Module;

	public class PluginEvent extends Event
	{
		public static const PLUGIN_CREATED: String = 'pluginCreated';
		public static const PLUGIN_MODULE_LOADED: String = 'plugin module loaded';
		public static const PLUGIN_MODULE_LOAD: String = 'plugin module load';
		public static const PLUGIN_MODULES_PROGRESS: String = 'plugin modules progress';
		public var module: Module;
		public var url: String;
		public var pluginInfo: IPluginInfo;
		public var plugin: IPlugin;
		public var isSameModule: Boolean;
		public var bytesLoaded: int;
		public var bytesTotal: int;
		public var modulesLoading: int;

		public function PluginEvent(type: String, bubbles: Boolean = false, cancelable: Boolean = false)
		{
			super(type, bubbles, cancelable);
		}

		override public function clone(): Event
		{
			var event: PluginEvent = new PluginEvent(type);
			event.pluginInfo = pluginInfo;
			event.plugin = plugin;
			event.isSameModule = isSameModule;
			event.url = url;
			event.bytesLoaded = bytesLoaded;
			event.bytesTotal = bytesTotal;
			event.modulesLoading = modulesLoading;
			return event;
		}
	}
}
