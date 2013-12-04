package com.iblsoft.flexiweather.plugins
{

	// Interface for "Action" Plugin Ability - a button in the Action Toolbar  
	public interface IAction extends IAbility
	{
		function setActionManager(am: IActionManager): void;
		function activateAction(s_id: String): void;
		function deactivateAction(s_id: String): void;
	}
}
