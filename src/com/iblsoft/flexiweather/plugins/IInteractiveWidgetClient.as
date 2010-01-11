package com.iblsoft.flexiweather.plugins
{
	import com.iblsoft.flexiweather.widgets.InteractiveWidget;
	
	// Interface for "InteractiveWidgetClient" Plugin Ability -
	// for manipulations with the current interactive widget
	public interface IInteractiveWidgetClient extends IAbility
	{
		function bind(iw: InteractiveWidget): void;

		function unbind(iw: InteractiveWidget): void;
	}
}