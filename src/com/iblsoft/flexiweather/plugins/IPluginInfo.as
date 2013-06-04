package com.iblsoft.flexiweather.plugins
{

	public interface IPluginInfo
	{
		function get id(): String;
		function set manager(value: PluginManager): void;
		function pluginRegistered(pluginID: String): Boolean;
		function getAbilities(): Array;
	}
}
