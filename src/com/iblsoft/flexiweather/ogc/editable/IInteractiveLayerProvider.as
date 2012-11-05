package com.iblsoft.flexiweather.ogc.editable
{
	import com.iblsoft.flexiweather.widgets.InteractiveLayer;
	import com.iblsoft.flexiweather.widgets.InteractiveWidget;

	public interface IInteractiveLayerProvider
	{
		function createInteractiveLayer(iw: InteractiveWidget): InteractiveLayer;
	}
}
