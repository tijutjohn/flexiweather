package com.iblsoft.flexiweather.plugins
{
	import com.iblsoft.flexiweather.plugins.data.ModuleLoaderItem;
	import mx.collections.ArrayCollection;
	import mx.modules.ModuleLoader;

	public class ModuleLoaderCollection
	{
		private var _collection: ArrayCollection = new ArrayCollection();

		public function get modulesLoadingCount(): int
		{
			return _collection.length;
		}

		public function get bytesLoaded(): int
		{
			var bytes: int = 0;
			if (_collection && _collection.length > 0)
			{
				for each (var item: ModuleLoaderItem in _collection)
				{
					bytes += item.bytesLoaded;
				}
			}
			return bytes;
		}

		public function get bytesTotal(): int
		{
			var bytes: int = 0;
			if (_collection && _collection.length > 0)
			{
				for each (var item: ModuleLoaderItem in _collection)
				{
					bytes += item.bytesTotal;
				}
			}
			return bytes;
		}

		public function ModuleLoaderCollection()
		{
		}

		private function getModuleLoader(module: ModuleLoader): ModuleLoaderItem
		{
			if (_collection && _collection.length > 0)
			{
				for each (var item: ModuleLoaderItem in _collection)
				{
					if (item.module == module)
						return item;
				}
			}
			return null;
		}

		private function isModuleInside(module: ModuleLoader): Boolean
		{
			return getModuleLoader(module) != null;
		}

		public function addModuleLoaderItem(module: ModuleLoader, bytesLoaded: int, bytesTotal: int): void
		{
			if (!isModuleInside(module))
			{
				var loaderItem: ModuleLoaderItem = new ModuleLoaderItem();
				loaderItem.module = module;
				loaderItem.bytesLoaded = bytesLoaded;
				loaderItem.bytesTotal = bytesTotal;
				_collection.addItem(loaderItem);
			}
			else
			{
				var item: ModuleLoaderItem = getModuleLoader(module);
				item.bytesLoaded = bytesLoaded;
				item.bytesTotal = bytesTotal;
			}
		}

		public function removeModuleLoader(module: ModuleLoader): void
		{
			if (isModuleInside(module))
			{
				var item: ModuleLoaderItem = getModuleLoader(module);
				var pos: int = _collection.getItemIndex(item);
				if (pos >= 0)
					_collection.removeItemAt(pos);
			}
		}
	}
}
