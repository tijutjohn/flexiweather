package com.iblsoft.flexiweather.plugins
{
	import com.iblsoft.flexiweather.widgets.InteractiveLayerMap;
	import com.iblsoft.flexiweather.widgets.InteractiveWidget;

	// Interface for "InteractiveWidgetClient" Plugin Ability -
	// for manipulations with the current interactive widget
	public interface IInteractiveWidgetClient extends IAbility
	{
		function bind(iw: InteractiveWidget, layerComposer: InteractiveLayerMap): void;
		function unbind(iw: InteractiveWidget, layerComposer: InteractiveLayerMap, bDeleteLayer: Boolean = true): void;
	}
}
