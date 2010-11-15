package com.iblsoft.flexiweather.plugins
{
	import com.iblsoft.flexiweather.widgets.InteractiveLayerComposer;
	import com.iblsoft.flexiweather.widgets.InteractiveWidget;
	
	// Interface for "InteractiveWidgetClient" Plugin Ability -
	// for manipulations with the current interactive widget
	public interface IInteractiveWidgetClient extends IAbility
	{
		function bind(iw: InteractiveWidget, layerComposer: InteractiveLayerComposer): void;

		function unbind(iw: InteractiveWidget, layerComposer: InteractiveLayerComposer): void;
	}
}