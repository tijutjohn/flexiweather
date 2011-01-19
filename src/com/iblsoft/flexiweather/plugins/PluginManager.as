package com.iblsoft.flexiweather.plugins
{
	import flash.events.Event;
	import flash.events.EventDispatcher;
	
	import mx.core.ClassFactory;
	import mx.events.ModuleEvent;
	import mx.modules.Module;
	import mx.modules.ModuleLoader;
	
	public class PluginManager extends EventDispatcher
	{
		public static const ACTION_CALL_PLUGIN: String = 'call plugin action';
		
		public static const GET_PLUGIN: String = 'get plugin';
		public static const PLUGIN_DOES_NOT_EXISTS: String = 'plugin does not exists';
		
		public static const ALL_PLUGINS_LOADED: String = 'all plugins are loaded';
		public static const ALL_PLUGINS_INFO_LOADED: String = 'all plugins info are loaded';
		
		internal static var sm_instance: PluginManager;
		
		private var _typesSorted: Array = [];
		
		private var _modules: ModuleCollection;
		private var _internalPlugins: Array = [];
		private var _plugins: PluginCollection;
		private var _pluginsInfo: PluginCollection;
		
		
		public static function getInstance(): PluginManager
		{
			if(sm_instance == null) {
				sm_instance = new PluginManager();
			}			
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
    		
    		_plugins = new PluginCollection("createPlugin");
    		_pluginsInfo = new PluginCollection("createPluginInfo");
    		
    		_plugins.addEventListener(ALL_PLUGINS_LOADED, onAllPluginsLoaded);
    		_plugins.addEventListener(PluginEvent.PLUGIN_MODULE_LOAD, onPluginLoad);
    		_plugins.addEventListener(PluginEvent.PLUGIN_MODULE_LOADED, onPluginLoaded);
    		
    		_pluginsInfo.addEventListener(ALL_PLUGINS_LOADED, onAllInfoPluginsLoaded);
    		_pluginsInfo.addEventListener(PluginEvent.PLUGIN_MODULE_LOAD, onPluginLoad);
    		_pluginsInfo.addEventListener(PluginEvent.PLUGIN_MODULE_LOADED, onPluginInfoLoaded);
		}
		
		public function addInteralPlugin(type: String, plugin: IPlugin): void
		{
			_internalPlugins.push({type: type, plugin: plugin});
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
		private function onPluginLoad(event: PluginEvent): void
		{
			var item: ModuleItem = _modules.getModuleItemByURL(event.url);
			if (item)
			{
				item.startModuleLoading();
			} 	
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
		
		public function getAllInfoPlugins(): Array
		{
			return _pluginsInfo.getAllPlugins();
		}
		
		private function onPluginInfoLoaded(event: PluginEvent): void
		{
			dispatchEvent(event);
			
			var item: ModuleItem = _modules.getModuleItemByURL(event.url);
			if (item)
			{
				item.moduleIsLoadedAndReady(event.module);
			}
		}
		
		public function getInfoPlugin(plugin: IPlugin): IPluginInfo
		{
			//find plugin type;
			var type: String = _pluginsInfo.getPluginType(plugin);
			return getInfoPluginByType(type);
		}
		public function getInfoPluginByType(type: String): IPluginInfo
		{
			return _pluginsInfo.getPlugin(type) as IPluginInfo;
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
		
		public function loadAllPluginModules(): void
		{
			_plugins.loadAllInfoPluginModules();
		}
		public function getAllPlugins(): Array
		{
			return _plugins.getAllPlugins();
		}
		public function getPlugin(type: String): IPlugin
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
			
			plugin = _plugins.getPlugin(type) as IPlugin;
			if (plugin)
				return plugin;
				
			var pluginModuleItem: ModuleItem = _modules.getModuleItemByURL(url);
			if (pluginModuleItem.isReady)
			{
				_plugins.createPluginFromParams(pluginModuleItem.module, [type], url);
				plugin  = _plugins.getPlugin(type) as IPlugin;
			} else {
				if (infoURL == url && infoURL != null)
				{
					var pluginInfoModuleItem: ModuleItem = _modules.getModuleItemByURL(infoURL);
					if (pluginInfoModuleItem.isReady)
					{
						_plugins.createPluginFromParams(pluginInfoModuleItem.module, [type], url);
						plugin  = _plugins.getPlugin(type) as IPlugin;
					}
				}
			}
			
			return plugin;
		}
		
		private function onPluginLoaded(event: PluginEvent): void
		{
			dispatchEvent(event);
			var item: ModuleItem = _modules.getModuleItemByURL(event.url)
			if (item)
			{
				item.moduleIsLoadedAndReady(event.module);
			}
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
				var pluginInfo: Object = getInfoPluginByType(type);
				if (!pluginInfo)
				{
					if (unsuccessfulCallback != null)
						unsuccessfulCallback.apply(null);
				} else {
					_plugins.callPlugin(type, callback, callbackParams, unsuccessfulCallback, ability);
				}
			} else {
				if (callbackParams)
					callbackParams.unshift(plugin);
				else
					callbackParams = [plugin];
					
				callback.apply(null, callbackParams);
			}
		}
		
	}
}

class ModuleItem
{
	public var module: Module;
	public var url: String;
	private var _isLoading: Boolean;
	private var _isReady: Boolean;
	
	public function get isLoading(): Boolean
	{
		return _isLoading;
	}
	public function get isReady(): Boolean
	{
		return _isReady;
	}
	
	public function ModuleItem(module: Module, url: String)
	{
		this.module = module;
		this.url = url;
	} 
	
	public function startModuleLoading(): void
	{
		trace("Module ["+url+"] starts loading");
		_isLoading = true;
	}
	public function moduleIsLoadedAndReady(module: Module): void
	{
		trace("Module ["+url+"] is ready");
		this.module = module;
		_isLoading = false;
		_isReady = true;
	}
}	

class ModuleCollection extends EventDispatcher
{
	private var _modules: Array = [];
	public function ModuleCollection(): void
	{
		
	}	
	
	public function addModule(item: ModuleItem): void
	{
		if (getModuleItemByURL(item.url))
		{
			if (isModuleReady(item.url))
			{
				//module is ready do not do anything
			} else {
				//module item is there, but module is not loaded yet (still do not do anything)
			}
		} else {
			_modules.push(item);
		}
	}
	
	public function isModuleItemInside(url: String): Boolean
	{
		var item: ModuleItem = getModuleItemByURL(url);
		return item != null;
	}
	public function isModuleReady(url: String): Boolean
	{
		var module: ModuleItem = getModuleItemByURL(url);
		return module.isReady;
	}
	
	public function getModuleItemByURL(url: String): ModuleItem
	{
		for each (var module: ModuleItem in _modules)
		{
			if (module.url == url)
				return module;
		}
		return null;
	}
	public function getModuleByURL(url: String): Module
	{
		var item: ModuleItem = getModuleItemByURL(url);
		if (item)
			return item.module;
			
		return null;
	}
}	

	import mx.events.ModuleEvent;
	import mx.modules.ModuleLoader;
	import mx.modules.Module;
	import mx.core.ClassFactory;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import com.iblsoft.flexiweather.plugins.PluginManager;
	import com.iblsoft.flexiweather.widgets.ModuleLoaderWithData;
	import com.iblsoft.flexiweather.plugins.PluginEvent;
	import com.iblsoft.flexiweather.plugins.IPluginInfo;
	import com.iblsoft.flexiweather.plugins.IPlugin;
	import com.iblsoft.flexiweather.plugins.IPluginInfoModule;
	import com.iblsoft.flexiweather.plugins.IAbility;
	import com.iblsoft.flexiweather.plugins.PluginAbility;
	import mx.controls.Alert;
	


class PluginCollection extends EventDispatcher
{
	private var _typesSorted: Array = [];
	private var _pluginsInfo: Array = [];
	private var _pluginsInfoLoading: Array = [];
	private var _pluginInfoModules: Array = [];
	private var _pluginFunction: String;
	
	public function PluginCollection(fnc: String = '')
	{
		_pluginFunction = fnc;
	}
	
	public function addPluginInfo(type: String, url: String): void
	{
		_typesSorted.push(type);
		
		//find if module already exists
		var infoObject: Object;
		for each (var object: Object in _pluginInfoModules)
		{
			if (object.url == url)
			{
				infoObject = object;
				break;
			}
		}
		if (infoObject)
			infoObject.plugins += ','+type;
		else 
			_pluginInfoModules.push({plugins: type, url: url});
	}
		
	public function loadAllInfoPluginModules(): void
	{
		if (_pluginInfoModules && _pluginInfoModules.length > 0)
		{
			for each (var moduleInfo: Object in _pluginInfoModules)
			{
				loadPluginModule(moduleInfo);
			}
		}
	}
	
	public function getModuleInfo(type: String): Object
	{
		if (_pluginInfoModules && _pluginInfoModules.length > 0)
		{
			for each (var moduleInfo: Object in _pluginInfoModules)
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
	
	private function loadPluginModule(moduleInfo: Object, data: Object = null): void
	{
		var url: String = moduleInfo.url;
		
		var pe: PluginEvent = new PluginEvent(PluginEvent.PLUGIN_MODULE_LOAD);
		pe.url = url;
		dispatchEvent(pe);
		
		var loader: ModuleLoaderWithData = new ModuleLoaderWithData(data);
		loader.url = url;
		loader.addEventListener(ModuleEvent.ERROR, onModuleError);
		loader.addEventListener(ModuleEvent.PROGRESS, onModuleProgress);
		loader.addEventListener(ModuleEvent.SETUP, onModuleSetup);
		loader.addEventListener(ModuleEvent.READY, onModuleReady);
		_pluginsInfoLoading.push({info: moduleInfo, loader: loader});
		loader.loadModule();
	}
	
	public function callPlugin(type: String, callback: Function, callbackParams: Array, unsuccessfulCallback: Function = null, ability: PluginAbility = null): void
	{
		var moduleInfo: Object = getModuleInfo(type);
		if (moduleInfo)
		{
			var data: Object = {action: PluginManager.ACTION_CALL_PLUGIN, type: type, callback: callback, params: callbackParams, unsuccessfulCallback: unsuccessfulCallback, ability: ability};
			loadPluginModule(moduleInfo, data);
		} else {
			if (unsuccessfulCallback != null)
				unsuccessfulCallback.apply();
		}
	}
	
	public function getAllPlugins(): Array
	{
		return _pluginsInfo;
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
			for each (var moduleInfo: Object in _pluginsInfo)
			{
				var currPluginInfo: Object = moduleInfo.pluginInfo;
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
			for each (var moduleInfo: Object in _pluginsInfo)
			{
				var currPluginInfo: Object = moduleInfo.pluginInfo;
				if (currPluginInfo && currPluginInfo.id == type)
				{
					if (moduleInfo.hasOwnProperty(paramName))
						return moduleInfo.paramName;
				}
			}
		}
		return null;
	}
	
	public function getPlugin(type: String): Object
	{
		if (_pluginsInfo && _pluginsInfo.length > 0)
		{
			for each (var moduleInfo: Object in _pluginsInfo)
			{
				var currPluginInfo: Object = moduleInfo.pluginInfo;
				if (moduleInfo.type == type)
				{
					return currPluginInfo;
				}
			}
		}
		
		return null;
	}
		
	private function createInfoPlugin(loader: ModuleLoader): void
	{
		var pluginInfo: Object;

		var info: Object;
		
		//find module info	
		if (_pluginsInfoLoading && _pluginsInfoLoading.length > 0)
		{
			var total: int = _pluginsInfoLoading.length;
			
			for (var i: int = 0; i < total; i++)
			{
				var moduleInfo: Object = _pluginsInfoLoading[i];
				
				info = moduleInfo.info;
				var currLoader: Object = moduleInfo.loader;
				
				if (loader == currLoader)
				{
					var module: Module = loader.child as Module;
					if (!module)
					{
						trace("module does not exists");
					} else {
						var pluginTypes: String = info.plugins;
						var typesArr: Array = pluginTypes.split(',');
//						for each (var type: String in typesArr)
//						{ 
							if (createPluginFromParams(module, typesArr, moduleInfo.info.url))
							{
								//remove plugins from loading array
								_pluginsInfoLoading.splice(i, 1);
								if (_pluginsInfoLoading.length == 0)
								{
									notifyAllInfoPluginsAreLoaded();
								}
							}
							
//							break;
//						}
					}
					
					return;
				}
			}	
		}	
	}
	
	public function createPluginFromParams(module: Module, types: Array, url: String): Boolean
	{
		trace("createPluginFromParams type: " + type + " url: " + url);
		var pluginInfo: Object;
		if (_pluginFunction && _pluginFunction.length > 3)
		{
			if (types.length > 1)
			{
				trace("More types");
			}
			for each (var type: String in types)
			{
				pluginInfo = module[_pluginFunction](type);
				if (pluginInfo)
				{
					
					var moduleInfo: Object;
					if (_pluginsInfo.length > 0)
					{
						for each (var info: Object in _pluginsInfo)
						{
							if (info.type == type)
							{
								moduleInfo = info;
								break;
							}
						}
					}
					if (moduleInfo)
						moduleInfo.pluginInfo = pluginInfo;
					else			
						_pluginsInfo.push({type: type, pluginInfo: pluginInfo, url: url, module: module});
					
					var isPluginInfo: Boolean = pluginInfo is IPluginInfo;
					var isPlugin: Boolean = pluginInfo is IPlugin;
					
					notifyPluginIsLoaded(pluginInfo as IPlugin, pluginInfo as IPluginInfo, module, url);
					
				} else {
					trace("PLUGIN WAS NOT CREATED");
				}
			}
			return true;
		} else {
			trace("no plugin function defined");
		}
		
		return false;
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
		var plugin: Object;
		
		for each (var type: String in _typesSorted)
		{
			plugin = getPlugin(type);
			if (!plugin)
			{
				trace("notifyAllInfoPluginsAreLoaded: NO PLUGIN !!!");
			} else {
				temp.push({type: type, pluginInfo: plugin, url: getPluginTypeParam(type, 'url'), module: getPluginTypeParam(type, 'module')});
			}	
		}
		_pluginsInfo = temp;
		
		dispatchEvent(new Event(PluginManager.ALL_PLUGINS_LOADED));
	}
	
	private function onModuleReady(event: ModuleEvent): void
	{
		var loader: ModuleLoaderWithData = event.target as ModuleLoaderWithData;
		removeModuleListeners(loader);
		
		
		// TODO: correctly create plugin or pluginInfo inside
		createInfoPlugin(loader);
		if (loader.associatedData)
		{
			trace("Module loader has data: " + loader.associatedData);
			switch (loader.associatedData.action)
			{
				case PluginManager.ACTION_CALL_PLUGIN:
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
							{
								callback.apply(abilityImplementationInstance, callbackParams);
							} else {
								callback.apply(null, callbackParams);
							}
						}
					} else {
						var unsuccessfulCallback: Function = loader.associatedData.unsuccessfulCallback as Function;
						if (unsuccessfulCallback != null)
						{
							if (ability)
							{
								unsuccessfulCallback.apply(abilityImplementationInstance);
							} else {
								unsuccessfulCallback.apply(null);
							}
						}
					}
					break;
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
	}
	
	private function onModuleError(event: ModuleEvent): void
	{
		var loader: ModuleLoader = event.target as ModuleLoader;
		
		Alert.show(event.errorText, "Module loading error ", Alert.OK);
		
		removeModuleListeners(loader);
	}
	
	private function removeModuleListeners(loader: ModuleLoader): void
	{
		loader.removeEventListener(ModuleEvent.ERROR, onModuleError);
		loader.removeEventListener(ModuleEvent.PROGRESS, onModuleProgress);
		loader.removeEventListener(ModuleEvent.SETUP, onModuleSetup);
		loader.removeEventListener(ModuleEvent.READY, onModuleReady);
	}
}