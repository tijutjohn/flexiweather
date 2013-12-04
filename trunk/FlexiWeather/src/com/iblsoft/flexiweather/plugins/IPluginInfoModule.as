package com.iblsoft.flexiweather.plugins
{

	public interface IPluginInfoModule
	{
		function getPluginTypes(): Array;
		function createPluginInfo(type: String): IPluginInfo;
	}
}
