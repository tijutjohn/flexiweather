package com.iblsoft.flexiweather.plugins
{

	public interface IMenuManager
	{
		function addMainMenu(s_main_id: String): void;
		function addSubmenu(s_main_id: String, s_submenu_id: String): void;
	}
}
