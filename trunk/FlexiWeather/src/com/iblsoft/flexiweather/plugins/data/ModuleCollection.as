package com.iblsoft.flexiweather.plugins.data
{
	import flash.events.EventDispatcher;
	import mx.modules.Module;

	public class ModuleCollection extends EventDispatcher
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
				}
				else
				{
					//module item is there, but module is not loaded yet (still do not do anything)
				}
			}
			else
				_modules.push(item);
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
}
