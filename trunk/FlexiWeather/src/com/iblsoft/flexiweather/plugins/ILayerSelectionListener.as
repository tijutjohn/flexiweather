package com.iblsoft.flexiweather.plugins
{
	import com.iblsoft.flexiweather.widgets.InteractiveLayer;

	public interface ILayerSelectionListener extends IAbility
	{
		function onLayerDeselected(layer: InteractiveLayer): void;
		function onLayerSelected(layer: InteractiveLayer): void;
	}
}
