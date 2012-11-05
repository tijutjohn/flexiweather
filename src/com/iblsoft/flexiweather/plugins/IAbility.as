package com.iblsoft.flexiweather.plugins
{

	// Common base interface for all Plugin Ability interfaces
	public interface IAbility
	{
		function bindToPlugin(plugin: IPlugin): void;
	}
}
