package com.iblsoft.flexiweather.plugins.data
{
	import com.iblsoft.flexiweather.plugins.IAbility;
	import com.iblsoft.flexiweather.plugins.IPlugin;
	import com.iblsoft.flexiweather.plugins.IPluginInfo;
	import com.iblsoft.flexiweather.plugins.IPluginInfoModule;
	import com.iblsoft.flexiweather.plugins.IPluginModule;
	import com.iblsoft.flexiweather.plugins.ModuleLoaderCollection;
	import com.iblsoft.flexiweather.plugins.PluginAbility;
	import com.iblsoft.flexiweather.plugins.PluginEvent;
	import com.iblsoft.flexiweather.plugins.PluginManager;
	import com.iblsoft.flexiweather.widgets.ModuleLoaderWithData;
	
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.system.ApplicationDomain;
	
	import mx.collections.ArrayCollection;
	import mx.controls.Alert;
	import mx.core.ClassFactory;
	import mx.events.ModuleEvent;
	import mx.modules.Module;
	import mx.modules.ModuleLoader;

	public class PluginCollection extends EventDispatcher
	{
		private var _name: String;

		public function get name(): String
		{
			return _name;
		}
		private var _typesSorted: Array = [];
		/**
		 * list of all plugins
		 */
		private var _pluginsInfo: Array = [];
		/**
		 * info of all modules currently loading
		 */
		private var _pluginsInfoLoading: Array = [];
		/**
		 * list of all modules
		 */
		private var _pluginInfoModules: Array = [];
		private var _pluginFunction: String;
		public var loaders: ModuleLoaderCollection = new ModuleLoaderCollection();
		//just store already loaded loaders to have them for total loaded bytes information
		public var loadedLoaders: ModuleLoaderCollection = new ModuleLoaderCollection();

		public function get loadingPluginsCount(): int
		{
			return _pluginsInfoLoading.length;
		}

		public function PluginCollection(name: String, fnc: String = '')
		{
			_name = name;
			_pluginFunction = fnc;
		}

		private function addItemToPluginsInfo(item: Object): void
		{
			_pluginsInfo.push(item);
		}

		public function pluginRegistered(type: String): Boolean
		{
//			trace(_pluginInfoModules);
//			trace(_pluginsInfo);
//			trace(_pluginsInfoLoading);
			
			return true;
		}
		
		/**
		 * Add new plugin info to _pluginInfoModules
		 * @param type
		 * @param url
		 *
		 */
		public function addPluginInfo(type: String, url: String): void
		{
			_typesSorted.push(type);
			//find if module already exists
			var infoObject: ModuleInfo;
			for each (var object: ModuleInfo in _pluginInfoModules)
			{
				if (object.url == url)
				{
					infoObject = object;
					break;
				}
			}
			if (infoObject)
				infoObject.plugins += ',' + type;
			else
			{
				var newPluginInfo: ModuleInfo = new ModuleInfo();
				newPluginInfo.plugins = type;
				newPluginInfo.url = url;
				_pluginInfoModules.push(newPluginInfo);
			}
		}

		public function loadPlugin(type: String): void
		{
			if (_pluginInfoModules && _pluginInfoModules.length > 0)
			{
				var pluginInfo: ModuleInfo;
				for each (var moduleInfo: ModuleInfo in _pluginInfoModules)
				{
					var pluginsArr: Array = moduleInfo.pluginsArray;
					for each (var currType: String in pluginsArr)
					{
						if (currType == type)
						{
							pluginInfo = moduleInfo;
							break;
						}
					}
					if (pluginInfo)
						break;
				}
				if (pluginInfo)
					loadPluginModule(pluginInfo);
			}
		}

		public function loadAllInfoPluginModules(): void
		{
			if (_pluginInfoModules && _pluginInfoModules.length > 0)
			{
				for each (var moduleInfo: ModuleInfo in _pluginInfoModules)
				{
					loadPluginModule(moduleInfo);
				}
			}
		}

		public function getModuleInfo(type: String): ModuleInfo
		{
			if (_pluginInfoModules && _pluginInfoModules.length > 0)
			{
				for each (var moduleInfo: ModuleInfo in _pluginInfoModules)
				{
					var pluginTypes: String = moduleInfo.plugins;
					var typesArr: Array = pluginTypes.split(',');
					for each (var currType: String in typesArr)
					{
						if (currType == type)
							return moduleInfo;
					}
				}
			}
			return null;
		}

		/**
		 * Check wether plugin module is currently loading, so if there is other request to load this plugin, manager will not start load it again
		 * @param moduleInfo
		 * @return
		 *
		 */
		private function isPluginModuleLoading(moduleInfo: ModuleInfo): Boolean
		{
			for each (var infoLoading: ModuleInfoLoading in _pluginsInfoLoading)
			{
				if (infoLoading.info.url == moduleInfo.url)
					return true;
			}
			return false
		}

		private function loadPluginModule(moduleInfo: ModuleInfo, data: Object = null): void
		{
			//if plugin is not currently loading, then loaded
			if (!isPluginModuleLoading(moduleInfo))
			{
				var url: String = moduleInfo.url;
				
				var pe: PluginEvent = new PluginEvent(PluginEvent.PLUGIN_MODULE_LOAD);
				pe.url = url;
				dispatchEvent(pe);
				var loader: ModuleLoaderWithData = new ModuleLoaderWithData(data);
				loader.applicationDomain = ApplicationDomain.currentDomain;
				loader.url = url;
				loader.addEventListener(ModuleEvent.ERROR, onModuleError);
				loader.addEventListener(ModuleEvent.PROGRESS, onModuleProgress);
				loader.addEventListener(ModuleEvent.SETUP, onModuleSetup);
				loader.addEventListener(ModuleEvent.READY, onModuleReady);
				var infoLoading: ModuleInfoLoading = new ModuleInfoLoading();
				infoLoading.info = moduleInfo;
				infoLoading.loader = loader;
				_pluginsInfoLoading.push(infoLoading);
				loader.loadModule();
				if (_pluginsInfoLoading.length == 1)
					notifyStartLoading();
			}
		}

		public function get loadingPluginsNames(): Array
		{
			if (_pluginsInfoLoading && _pluginsInfoLoading.length > 0)
			{
				var arr: Array = [];
				for each (var infoLoading: ModuleInfoLoading in _pluginsInfoLoading)
				{
					arr.push(infoLoading.info.url);
				}
				return arr;
			}
			return null;
		}

		public function callPlugin(type: String, callback: Function, callbackParams: Array, unsuccessfulCallback: Function = null, ability: PluginAbility = null): void
		{
			var moduleInfo: ModuleInfo = getModuleInfo(type);
			if (moduleInfo)
			{
				var data: Object = {action: PluginManager.ACTION_CALL_PLUGIN, type: type, callback: callback, params: callbackParams, unsuccessfulCallback: unsuccessfulCallback, ability: ability};
				loadPluginModule(moduleInfo, data);
			}
			else
			{
				if (unsuccessfulCallback != null)
					unsuccessfulCallback.apply();
			}
		}

		public function getAllPlugins(): Array
		{
			var clonedArray: Array = [];
			for each (var module: ModuleInfo in _pluginsInfo)
			{
				clonedArray.push(module.clone());
			}
			return clonedArray;
		}

		public function getPluginModule(plugin: Object): Module
		{
			return getPluginParam(plugin, "module") as Module;
		}

		public function getPluginURL(plugin: Object): String
		{
			return getPluginParam(plugin, "url") as String;
		}

		public function getPluginType(plugin: Object): String
		{
			return getPluginParam(plugin, "type") as String;
		}

		private function getPluginParam(plugin: Object, paramName: String): Object
		{
			if (_pluginsInfo && _pluginsInfo.length > 0)
			{
				for each (var moduleInfo: ModuleInfo in _pluginsInfo)
				{
					var currPluginInfo: IPluginInfo = moduleInfo.pluginInfo;
					if (currPluginInfo && currPluginInfo.id == plugin.id)
					{
						if (moduleInfo.hasOwnProperty(paramName))
							return moduleInfo[paramName];
					}
				}
			}
			return null;
		}

		public function getPluginTypeParam(type: String, paramName: String): Object
		{
			if (_pluginsInfo && _pluginsInfo.length > 0)
			{
				for each (var moduleInfo: ModuleInfo in _pluginsInfo)
				{
					var currPluginInfo: IPluginInfo = moduleInfo.pluginInfo;
					if (currPluginInfo && currPluginInfo.id == type)
					{
						if (moduleInfo.hasOwnProperty(paramName))
							return moduleInfo.paramName;
					}
				}
			}
			return null;
		}

		public function getPlugin(type: String): IPlugin
		{
			if (_pluginsInfo && _pluginsInfo.length > 0)
			{
				for each (var moduleInfo: ModuleInfo in _pluginsInfo)
				{
					var currPluginInfo: IPlugin = moduleInfo.plugin;
					if (moduleInfo.type == type)
						return currPluginInfo;
				}
			}
			return null;
		}

		public function getPluginInfo(type: String): IPluginInfo
		{
			if (_pluginsInfo && _pluginsInfo.length > 0)
			{
				for each (var moduleInfo: ModuleInfo in _pluginsInfo)
				{
					var currPluginInfo: IPluginInfo = moduleInfo.pluginInfo;
					if (moduleInfo.type == type)
						return currPluginInfo;
				}
			}
			return null;
		}

		private function createInfoPlugin(loader: ModuleLoader): void
		{
			var pluginInfo: IPluginInfo;
			var info: ModuleInfo;
			//find module info	
			if (_pluginsInfoLoading && _pluginsInfoLoading.length > 0)
			{
				var total: int = _pluginsInfoLoading.length;
				for (var i: int = 0; i < total; i++)
				{
					var moduleInfoLoading: ModuleInfoLoading = _pluginsInfoLoading[i] as ModuleInfoLoading;
					info = moduleInfoLoading.info;
					var currLoader: Object = moduleInfoLoading.loader;
					if (loader == currLoader)
					{
						var module: Module = loader.child as Module;
						if (!module)
							trace("module does not exists");
						else
						{
							var pluginTypes: String = info.plugins;
							var typesArr: Array = pluginTypes.split(',');
							if (createPluginFromParams(module, typesArr, moduleInfoLoading.info.url))
							{
								//remove plugins from loading array
								_pluginsInfoLoading.splice(i, 1);
								if (_pluginsInfoLoading.length == 0)
								{
									notifyStopLoading();
									notifyAllInfoPluginsAreLoaded();
								}
							}
						}
						return;
					}
				}
			}
		}

		private function updatePluginInModuleInfo(pluginObject: Object, type: String, url: String, module: Module): void
		{
			var pluginInfo: IPluginInfo;
			var plugin: IPlugin;
			if (pluginObject is IPluginInfo)
				pluginInfo = pluginObject as IPluginInfo;
			if (pluginObject is IPlugin)
				plugin = pluginObject as IPlugin;
			var moduleInfo: ModuleInfo;
			if (_pluginsInfo.length > 0)
			{
				for each (var info: ModuleInfo in _pluginsInfo)
				{
					if (info.type == type)
					{
						moduleInfo = info;
						break;
					}
				}
			}
			if (moduleInfo)
			{
				moduleInfo.url = url;
				moduleInfo.module = module;
				if (pluginInfo)
					moduleInfo.pluginInfo = pluginInfo;
				if (plugin)
					moduleInfo.plugin = plugin;
			}
			else
			{
				//TODO create nwe ModuleInfo
				var newModuleInfo: ModuleInfo = new ModuleInfo();
				newModuleInfo.type = type;
				if (pluginInfo is IPluginInfo)
					newModuleInfo.pluginInfo = pluginInfo as IPluginInfo;
				if (plugin is IPlugin)
					newModuleInfo.plugin = plugin as IPlugin;
				newModuleInfo.url = url;
				newModuleInfo.module = module;
				addItemToPluginsInfo(newModuleInfo);
			}
			var isPluginInfo: Boolean = pluginInfo is IPluginInfo;
			var isPlugin: Boolean = plugin is IPlugin;
			notifyPluginIsLoaded(plugin as IPlugin, pluginInfo as IPluginInfo, module, url);
		}

		public function createPluginFromParams(module: Module, types: Array, url: String): Boolean
		{
			if (_pluginFunction && _pluginFunction.length > 3)
			{
				for each (var type: String in types)
				{
					try
					{
						var createdPluginObj: Object = module[_pluginFunction](type);
					}
					catch (error: Error)
					{
						trace("ERROR createPluginFromParams: " + error.message);
					}
					if (createdPluginObj)
					{
						updatePluginInModuleInfo(createdPluginObj, type, url, module);
						notifyPluginIsCreated(createdPluginObj as IPlugin);
					}
					else
						trace("PLUGIN WAS NOT CREATED");
				}
				return true;
			}
			else
				trace("no plugin function defined");
			return false;
		}

		private function notifyPluginIsCreated(plugin: IPlugin): void
		{
			var event: PluginEvent = new PluginEvent(PluginEvent.PLUGIN_CREATED);
			event.plugin = plugin;
			dispatchEvent(event);
		}
		
		private function notifyLoadingProgress(): void
		{
			var event: PluginEvent = new PluginEvent(PluginEvent.PLUGIN_MODULES_PROGRESS);
			dispatchEvent(event);
		}

		private function notifyStartLoading(): void
		{
			var event: Event = new Event(PluginManager.START_LOADING);
			dispatchEvent(event);
		}

		private function notifyStopLoading(): void
		{
			var event: Event = new Event(PluginManager.STOP_LOADING);
			dispatchEvent(event);
		}

		private function notifyPluginIsLoaded(plugin: IPlugin, pluginInfo: IPluginInfo, module: Module, url: String): void
		{
			var pe: PluginEvent = new PluginEvent(PluginEvent.PLUGIN_MODULE_LOADED);
			pe.plugin = plugin;
			pe.pluginInfo = pluginInfo;
			pe.module = module;
			pe.url = url;
			dispatchEvent(pe);
		}

		private function notifyAllInfoPluginsAreLoaded(): void
		{
			var temp: Array = [];
			var pluginInfo: IPluginInfo;
			var plugin: IPlugin;
			var module: Module;
			var moduleInfo: ModuleInfo
			for each (var type: String in _typesSorted)
			{
				pluginInfo = getPluginInfo(type);
				plugin = getPlugin(type);
				moduleInfo = getModuleInfo(type);
				module = moduleInfo.module;
				if (!plugin && !pluginInfo && !module) {
//					trace("notifyAllInfoPluginsAreLoaded: NO PLUGIN !!!");
				} 
				else
				{
					moduleInfo = new ModuleInfo();
					moduleInfo.type = type;
					moduleInfo.pluginInfo = pluginInfo;
					moduleInfo.plugin = plugin;
					moduleInfo.url = getPluginTypeParam(type, 'url') as String;
					moduleInfo.module = getPluginTypeParam(type, 'module') as Module;
					temp.push(moduleInfo);
				}
			}
			if (_pluginsInfo.length != temp.length)
				trace("_pluginsInfo items are not equal");
//			_pluginsInfo = temp;
			dispatchEvent(new Event(PluginManager.ALL_PLUGINS_LOADED));
		}

		private function onModuleReady(event: ModuleEvent): void
		{
			var loader: ModuleLoaderWithData = event.target as ModuleLoaderWithData;
			removeModuleListeners(loader);
			var moduleLoader: ModuleLoader = loader as ModuleLoader;
			loaders.removeModuleLoader(moduleLoader);
			loadedLoaders.addModuleLoaderItem(moduleLoader, event.bytesLoaded, event.bytesTotal);
			// TODO: correctly create plugin or pluginInfo inside
			createInfoPlugin(loader);
			if (loader.associatedData)
			{
				switch (loader.associatedData.action)
				{
					case PluginManager.ACTION_CALL_PLUGIN:
					{
						//TODO here was IPlugin, check what should be there (IPlguin or IPluginInfo)
						var pluginInfo: IPluginInfo = getPluginInfo(loader.associatedData.type) as IPluginInfo;
						var plugin: IPlugin = getPlugin(loader.associatedData.type) as IPlugin;
						var ability: PluginAbility = loader.associatedData.ability as PluginAbility;
						var abilityImplementationInstance: IAbility;
						if (ability)
							abilityImplementationInstance = plugin.getAbilityImplementation(ability);
						if (plugin)
						{
							var callback: Function = loader.associatedData.callback as Function;
							if (callback != null)
							{
								var callbackParams: Array = loader.associatedData.params as Array;
								if (callbackParams)
									callbackParams.unshift(plugin);
								else
									callbackParams = [plugin];
								if (ability)
									callback.apply(abilityImplementationInstance, callbackParams);
								else
									callback.apply(null, callbackParams);
							}
						}
						else
						{
							var unsuccessfulCallback: Function = loader.associatedData.unsuccessfulCallback as Function;
							if (unsuccessfulCallback != null)
							{
								if (ability)
									unsuccessfulCallback.apply(abilityImplementationInstance);
								else
									unsuccessfulCallback.apply(null);
							}
						}
						break;
					}
				}
			}
		}

		private function onModuleSetup(event: ModuleEvent): void
		{
			var loader: ModuleLoader = event.target as ModuleLoader;
		}

		private function onModuleProgress(event: ModuleEvent): void
		{
			var loader: ModuleLoader = event.target as ModuleLoader;
			var bytesLoaded: int = event.bytesLoaded;
			var bytesTotal: int = event.bytesTotal;
			loaders.addModuleLoaderItem(loader, bytesLoaded, bytesTotal);
			notifyLoadingProgress();
		}

		private function onModuleError(event: ModuleEvent): void
		{
			//FIXME this is quick test for solving .swf problems
//			event.preventDefault();
//			return;
			
			var loader: ModuleLoader = event.target as ModuleLoader;
			Alert.show("Loading module: " + loader.url + "  error: " + event.errorText, "Module loading error ", Alert.OK);
			removeModuleListeners(loader);
			loaders.removeModuleLoader(loader);
		}

		private function removeModuleListeners(loader: ModuleLoader): void
		{
			loader.removeEventListener(ModuleEvent.ERROR, onModuleError);
			loader.removeEventListener(ModuleEvent.PROGRESS, onModuleProgress);
			loader.removeEventListener(ModuleEvent.SETUP, onModuleSetup);
			loader.removeEventListener(ModuleEvent.READY, onModuleReady);
		}

		override public function toString(): String
		{
			return "PublicCollection [" + name + "]";
		}
	}
}
