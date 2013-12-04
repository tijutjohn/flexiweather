package com.iblsoft.flexiweather.plugins
{

	public interface IMenu
	{
		function setMenuManager(am: IMenuManager): void;
		function menuClick(id: String): void;
	}
}
