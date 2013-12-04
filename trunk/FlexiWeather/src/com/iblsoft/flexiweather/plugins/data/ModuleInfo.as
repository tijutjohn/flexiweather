package com.iblsoft.flexiweather.plugins.data
{
	import com.iblsoft.flexiweather.plugins.IPlugin;
	import com.iblsoft.flexiweather.plugins.IPluginInfo;
	import mx.modules.Module;

	public class ModuleInfo
	{
		public var plugins: String;
		public var type: String;
		public var url: String;
		public var paramName: String;
		public var module: Module;
		private var _plugin: IPlugin;
		private var _pluginInfo: IPluginInfo;

		public function ModuleInfo()
		{
		}

		public function clone(): ModuleInfo
		{
			var mi: ModuleInfo = new ModuleInfo();
			mi.plugins = plugins;
			mi.type = type;
			mi.url = url;
			mi.paramName = paramName;
			mi.module = module;
			mi.plugin = plugin;
			mi.pluginInfo = pluginInfo;
			return mi;
		}

		public function get plugin(): IPlugin
		{
			return _plugin;
		}

		public function set plugin(value: IPlugin): void
		{
			_plugin = value;
		}

		public function get pluginInfo(): IPluginInfo
		{
			return _pluginInfo;
		}

		public function set pluginInfo(value: IPluginInfo): void
		{
			_pluginInfo = value;
		}

		public function get pluginsArray(): Array
		{
			var arr: Array = [plugins];
			if (plugins.indexOf(',') >= 0)
				arr = plugins.split(',');
			return arr;
		}
	}
}
