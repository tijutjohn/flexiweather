package com.iblsoft.flexiweather.plugins
{
	public interface IPlugin
	{
		function get id(): String;
		function getAbilityImplementation(ability: PluginAbility): IAbility;
	}
}