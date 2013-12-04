package com.iblsoft.flexiweather.plugins
{

	public interface IPlugin
	{
		function get id(): String;
		function getAbilityImplementation(ability: PluginAbility): IAbility;
		/**
		 * Call action. Each plugin can implement different actions and they can be called through this function
		 *
		 * @param actionString Should have format "action=params", but you can use your own format as well
		 *
		 */
		function callAction(actionString: String): void;
	}
}
