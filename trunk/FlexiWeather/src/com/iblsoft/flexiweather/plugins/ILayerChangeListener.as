package com.iblsoft.flexiweather.plugins
{
	import com.iblsoft.flexiweather.widgets.InteractiveLayer;

	public interface ILayerChangeListener extends IAbility
	{
		function setLayerManager(layerManager: ILayerManager): void;
		function onLayersStartup(): void;
		function onLayerAdded(l: InteractiveLayer, i_index: uint): void;
		function onLayerRemoved(l: InteractiveLayer): void;
		function onLayerOrderChanged(): void;
	}
}
