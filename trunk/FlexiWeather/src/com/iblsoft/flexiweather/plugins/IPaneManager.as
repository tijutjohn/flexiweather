package com.iblsoft.flexiweather.plugins
{
	import mx.core.UIComponent;

	public interface IPaneManager
	{
		function addPaneContent(component: UIComponent): void;
		function removePaneContent(component: UIComponent): void;
	}
}
