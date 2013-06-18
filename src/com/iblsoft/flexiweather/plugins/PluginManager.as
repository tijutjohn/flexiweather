package com.iblsoft.flexiweather.plugins
{
	import com.iblsoft.flexiweather.plugins.data.ModuleCollection;
	import com.iblsoft.flexiweather.plugins.data.ModuleInfo;
	import com.iblsoft.flexiweather.plugins.data.ModuleItem;
	import com.iblsoft.flexiweather.plugins.data.PluginCollection;
	import com.iblsoft.flexiweather.utils.ArrayUtils;
	
	import flash.events.Event;
	import flash.events.EventDispatcher;
	
	import mx.core.ClassFactory;
	import mx.events.ModuleEvent;
	import mx.modules.Module;
	import mx.modules.ModuleLoader;

	/**
	 * Singleton class handle all Plugin. There are 2 types of plugins: internal and external
	 * and 2 types of plugin type: PluginInfo and Plugin
	 * @author fkormanak
	 *
	 */
	public class PluginManager extends EventDispatcher
	{
		public static const ACTION_CALL_PLUGIN: String = 'call plugin action';
		public static const GET_PLUGIN: String = 'get plugin';
		public static const PLUGIN_DOES_NOT_EXISTS: String = 'plugin does not exists';
		public static const START_LOADING: String = 'start loading';
		public static const STOP_LOADING: String = 'stop loading';
		public static const ALL_PLUGINS_LOADED: String = 'all plugins are loaded';
		public static const ALL_PLUGINS_INFO_LOADED: String = 'all plugins info are loaded';
		internal static var sm_instance: PluginManager;
		private var _typesSorted: Array = [];
		private var _modules: ModuleCollection;
		private var _internalPlugins: Array = [];
		private var _plugins: PluginCollection;
		private var _pluginsInfo: PluginCollection;

		[Bindable(event = "countChanged")]
		public function get loadingPluginsCount(): int
		{
			return _plugins.loadingPluginsCount + _pluginsInfo.loadingPluginsCount;
		}

		[Bindable(event = "countChanged")]
		public function get loadingPluginsNames(): Array
		{
			var pluginsURLs: Array = _plugins.loadingPluginsNames;
			var pluginInfosURLs: Array = _pluginsInfo.loadingPluginsNames;
			if (pluginsURLs && pluginInfosURLs)
			{
				ArrayUtils.unionArrays(pluginsURLs, pluginInfosURLs);
				return pluginsURLs;
			}
			else
			{
				if (pluginInfosURLs)
					return pluginInfosURLs;
				else
				{
					if (pluginsURLs)
						return pluginsURLs;
				}
			}
			return null;
		}

		public static function getInstance(): PluginManager
		{
			if (sm_instance == null)
				sm_instance = new PluginManager();
			return sm_instance;
		}

		public function PluginManager()
		{
			if (sm_instance != null)
			{
				throw new Error(
						"PluginManager can only be accessed through "
						+ "PluginManager.getInstance()");
			}
			_modules = new ModuleCollection();
			_plugins = new PluginCollection("plugins", "createPlugin");
			_pluginsInfo = new PluginCollection("pluginsInfo", "createPluginInfo");
			_plugins.addEventListener(START_LOADING, onStartLoading);
			_plugins.addEventListener(STOP_LOADING, onStopLoading);
			_plugins.addEventListener(ALL_PLUGINS_LOADED, onAllPluginsLoaded);
			_plugins.addEventListener(PluginEvent.PLUGIN_MODULES_PROGRESS, onPluginModulesProgress);
			_plugins.addEventListener(PluginEvent.PLUGIN_MODULE_LOAD, onPluginLoad);
			_plugins.addEventListener(PluginEvent.PLUGIN_MODULE_LOADED, onPluginLoaded);
			_plugins.addEventListener(PluginEvent.PLUGIN_CREATED, onPluginLoaded);
			_pluginsInfo.addEventListener(START_LOADING, onStartLoading);
			_pluginsInfo.addEventListener(STOP_LOADING, onStopLoading);
			_pluginsInfo.addEventListener(ALL_PLUGINS_LOADED, onAllInfoPluginsLoaded);
			_pluginsInfo.addEventListener(PluginEvent.PLUGIN_MODULES_PROGRESS, onPluginModulesProgress);
			_pluginsInfo.addEventListener(PluginEvent.PLUGIN_MODULE_LOAD, onPluginLoad);
			_pluginsInfo.addEventListener(PluginEvent.PLUGIN_MODULE_LOADED, onPluginInfoLoaded);
		}

		/**
		 * Add internal plugin to internal plugin collection
		 * @param type Type of plugin
		 * @param plugin Instance of plugin
		 *
		 */
		public function addInteralPlugin(type: String, plugin: IPlugin): void
		{
			_internalPlugins.push({type: type, plugin: plugin});
		}

		/**
		 * Returns true if plugin was registered (via addPluginInfo method)
		 *  
		 * @param type
		 * @return 
		 * 
		 */		
		public function pluginRegistered(type: String): Boolean
		{
			return _pluginsInfo.pluginRegistered(type);
		}
		/**
		 * Add information about plugin.
		 *
		 * @param type Type of plugin
		 * @param infoUrl URL of PluginInfo module
		 * @param url URL of Plugin module
		 *
		 */
		public function addPluginInfo(type: String, infoUrl: String, url: String): void
		{
			_modules.addModule(new ModuleItem(null, infoUrl));
			_modules.addModule(new ModuleItem(null, url));
			_pluginsInfo.addPluginInfo(type, infoUrl);
			_plugins.addPluginInfo(type, url);
		}

		/*******************************************************************
		 *
		 *  PLUGINS INFO AND PLUGINS common functions
		 *
		 *******************************************************************/
		/**
		 * Dispatch START_LOADING event when Plugin or PluginInfo is about to start loading
		 *
		 * @param event
		 *
		 */
		private function onStartLoading(event: Event): void
		{
			var event: Event = new Event(PluginManager.START_LOADING);
			dispatchEvent(event);
		}

		/**
		 * Dispatch STOP_LOADING event when Plugin or PluginInfo is loaded
		 *
		 * @param event
		 *
		 */
		private function onStopLoading(event: Event): void
		{
			var event: Event = new Event(PluginManager.STOP_LOADING);
			dispatchEvent(event);
		}

		/**
		 * Dispatch PLUGIN_MODULES_PROGRESS event on Plugin or PluginInfo load progress
		 *
		 * @param event
		 *
		 */
		private function onPluginModulesProgress(event: PluginEvent): void
		{
			var loaders: int = _plugins.loaders.modulesLoadingCount + _pluginsInfo.loaders.modulesLoadingCount;
			var bytesLoaded: int = _plugins.loaders.bytesLoaded + _pluginsInfo.loaders.bytesLoaded;
			var bytesTotal: int = _plugins.loaders.bytesTotal + _pluginsInfo.loaders.bytesTotal;
			//update bytes information with already loaded modules;
			bytesLoaded += _plugins.loadedLoaders.bytesLoaded + _pluginsInfo.loadedLoaders.bytesLoaded;
			bytesTotal += _plugins.loadedLoaders.bytesTotal + _pluginsInfo.loadedLoaders.bytesTotal;
			var pe: PluginEvent = new PluginEvent(PluginEvent.PLUGIN_MODULES_PROGRESS);
			pe.bytesLoaded = bytesLoaded;
			pe.bytesTotal = bytesTotal;
			pe.modulesLoading = loaders;
			dispatchEvent(pe);
		}

		private function onPluginLoad(event: PluginEvent): void
		{
			var item: ModuleItem = _modules.getModuleItemByURL(event.url);
			if (item)
				item.startModuleLoading();
		}

		/*******************************************************************
		 *
		 *  PLUGINS INFO
		 *
		 *******************************************************************/
		public function loadAllInfoPluginModules(): void
		{
			_pluginsInfo.loadAllInfoPluginModules();
		}

		/**
		 * Helper function dump all plugins loaded by type
		 * @param type 2 different types: 'plugin', 'pluginInfo'
		 *
		 */
		public function dumpPlugins(type: String): void
		{
			var collection: PluginCollection;
			switch (type)
			{
				case 'plugin':
				{
					collection = _plugins;
					break;
				}
				case 'pluginInfo':
				{
					collection = _pluginsInfo;
					break;
				}
			}
		}

		public function getAllInfoPlugins(): Array
		{
			return _pluginsInfo.getAllPlugins();
		}

		private function updatePluginManager(event: PluginEvent): void
		{
			if (event.pluginInfo && event.pluginInfo is IPluginInfo)
			{
				event.pluginInfo.manager = this;
			}
			if (event.plugin && event.plugin is IPluginInfo)
			{
				(event.plugin as IPluginInfo).manager = this;
			}
		}
		private function onPluginInfoLoaded(event: PluginEvent): void
		{
			updatePluginManager(event);			
			dispatchEvent(event);
			var item: ModuleItem = _modules.getModuleItemByURL(event.url);
			if (item)
				item.moduleIsLoadedAndReady(event.module);
		}

		public function getInfoPlugin(plugin: IPlugin): IPluginInfo
		{
			//find plugin type;
			var type: String = _pluginsInfo.getPluginType(plugin);
			return getInfoPluginByType(type);
		}

		public function getInfoPluginByType(type: String): IPluginInfo
		{
			return _pluginsInfo.getPluginInfo(type) as IPluginInfo;
		}

		private function onAllInfoPluginsLoaded(event: Event): void
		{
			dispatchEvent(new Event(ALL_PLUGINS_INFO_LOADED));
		}

		/*******************************************************************
		 *
		 *  PLUGINS
		 *
		 *******************************************************************/
		public function loadPlugin(type: String, bLoadPluginInfoFirst: Boolean = false): void
		{
			trace("PluginManager loadPlugin: " + type);
			_plugins.loadPlugin(type);
		}

		public function loadPluginModules(modules: Array): void
		{
			for each (var pluginType: String in modules)
			{
				loadPlugin(pluginType);
			}
		}

		public function loadAllPluginModules(): void
		{
			_plugins.loadAllInfoPluginModules();
		}

		public function getAllPlugins(): Array
		{
			return _plugins.getAllPlugins();
		}

		public function getPlugin(type: String, bLoadPlugin: Boolean = false): IPlugin
		{
			var plugin: IPlugin;
			//check if plugin is internal
			plugin = getInternalPlugin(type);
			if (plugin)
				return plugin;
			//check if both modules are same (pluginInfo module and plugin module)
			var infoURLObject: Object = _pluginsInfo.getModuleInfo(type);
			var urlObject: Object = _plugins.getModuleInfo(type);
			var infoURL: String = infoURLObject.url;
			var url: String = urlObject.url;
			//check plugin in plugins collection
			plugin = _plugins.getPlugin(type) as IPlugin;
			if (plugin)
				return plugin;
			//create plugin from info module
			var pluginModuleItem: ModuleItem = _modules.getModuleItemByURL(url);
			if (pluginModuleItem.isReady)
			{
				_plugins.createPluginFromParams(pluginModuleItem.module, [type], url);
				plugin = _plugins.getPlugin(type) as IPlugin;
			}
			else
			{
				//same module for infoPlugin and plugin
				if (infoURL == url && infoURL != null)
				{
					var pluginInfoModuleItem: ModuleItem = _modules.getModuleItemByURL(infoURL);
					if (pluginInfoModuleItem.isReady)
					{
						_plugins.createPluginFromParams(pluginInfoModuleItem.module, [type], url);
						plugin = _plugins.getPlugin(type) as IPlugin;
					}
				}
			}
			return plugin;
		}

		private function onPluginLoaded(event: PluginEvent): void
		{
			updatePluginManager(event);
			dispatchEvent(event);
			var item: ModuleItem = _modules.getModuleItemByURL(event.url)
			if (item)
				item.moduleIsLoadedAndReady(event.module);
		}

		private function onAllPluginsLoaded(event: Event): void
		{
			dispatchEvent(new Event(ALL_PLUGINS_LOADED));
		}

		public function callPluginOnAbility(type: String, ability: PluginAbility, callback: Function, callbackParams: Array = null, unsuccessfulCallback: Function = null): void
		{
			callPlugin(type, callback, callbackParams, unsuccessfulCallback, ability);
		}

		public function callPlugin(type: String, callback: Function, callbackParams: Array = null, unsuccessfulCallback: Function = null, ability: PluginAbility = null): void
		{
			var plugin: IPlugin = getPlugin(type);
			if (!plugin)
			{
				//check if pluginInfo exists
				var pluginInfo: IPluginInfo = getInfoPluginByType(type);
				if (!pluginInfo)
				{
					if (unsuccessfulCallback != null)
						unsuccessfulCallback.apply(null);
				}
				else
					_plugins.callPlugin(type, callback, callbackParams, unsuccessfulCallback, ability);
			}
			else
			{
				if (callbackParams)
					callbackParams.unshift(plugin);
				else
					callbackParams = [plugin];
				callback.apply(null, callbackParams);
			}
		}

		private function getInternalPlugin(type: String): IPlugin
		{
			if (_internalPlugins && _internalPlugins.length > 0)
			{
				for each (var pluginObject: Object in _internalPlugins)
				{
					if (pluginObject && pluginObject.type == type)
						return pluginObject.plugin;
				}
			}
			return null;
		}
	}
}
