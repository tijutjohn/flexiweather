package com.iblsoft.flexiweather.plugins
{

	public interface IPluginModule
	{
		function createPlugin(type: String): IPlugin;
	}
}
