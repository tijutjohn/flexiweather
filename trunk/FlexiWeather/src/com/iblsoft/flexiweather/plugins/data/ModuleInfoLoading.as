package com.iblsoft.flexiweather.plugins.data
{
	import com.iblsoft.flexiweather.widgets.ModuleLoaderWithData;

	/**
	 * Data for storing information about currently loading plugin module
	 * @author fkormanak
	 *
	 */
	public class ModuleInfoLoading
	{
		public var info: ModuleInfo;
		public var loader: ModuleLoaderWithData;

		function ModuleInfoLoading(moduleInfo: ModuleInfo = null, _loader: ModuleLoaderWithData = null)
		{
			info = moduleInfo;
			loader = _loader;
		}
	}
}
