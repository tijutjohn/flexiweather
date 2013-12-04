package com.iblsoft.flexiweather.plugins
{
	import mx.core.UIComponent;

	// Interface for "Docklet" Plugin Ability - a UI component in the right pane toolbox 
	public interface IDocklet extends IAbility
	{
		function setDockletManager(docketManager: IDockletManager): void;
		function getDocklet(s_id: String): UIComponent;
		function canBeClosed(): Boolean;
		function dockletIsOpening(): void;
		function dockletIsClosing(): void;
	}
}
