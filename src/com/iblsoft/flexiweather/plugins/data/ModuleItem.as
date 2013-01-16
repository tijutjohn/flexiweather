package com.iblsoft.flexiweather.plugins.data
{
	import mx.modules.Module;

	public class ModuleItem
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
			_isLoading = true;
		}

		public function moduleIsLoadedAndReady(module: Module): void
		{
			this.module = module;
			_isLoading = false;
			_isReady = true;
		}
	}
}
