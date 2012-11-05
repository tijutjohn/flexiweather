package com.iblsoft.flexiweather.plugins
{
	import com.iblsoft.flexiweather.ogc.editable.IInteractiveLayerProvider;
	import com.iblsoft.flexiweather.widgets.InteractiveLayer;
	import com.iblsoft.flexiweather.widgets.InteractiveWidget;

	// Supporting interface for ILayerChangeListener's management
	public interface ILayerManager
	{
		function addLayer(ilp: IInteractiveLayerProvider): InteractiveLayer;
		function removeLayer(l: InteractiveLayer): void;
		function getLayerCount(): uint;
		function getLayerAt(i_index: uint): InteractiveLayer;
		function moveLayerToIndex(l: InteractiveLayer, i_index: uint): void;
		function getLayersOrderString(): String;
		function getInteractiveWidget(): InteractiveWidget;
	}
}
