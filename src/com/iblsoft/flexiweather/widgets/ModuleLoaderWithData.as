package com.iblsoft.flexiweather.widgets
{
	import mx.modules.ModuleLoader;

	public class ModuleLoaderWithData extends ModuleLoader
	{
		public var associatedData: Object;

		public function ModuleLoaderWithData(data: Object = null)
		{
			super();
			associatedData = data;
		}
	}
}
