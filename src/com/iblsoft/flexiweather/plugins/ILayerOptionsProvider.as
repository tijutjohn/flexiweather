package com.iblsoft.flexiweather.plugins
{
	import com.iblsoft.flexiweather.widgets.InteractiveLayer;
	import mx.containers.GridRow;

	public interface ILayerOptionsProvider extends IAbility
	{
		function canProvideLayerOptions(l: InteractiveLayer): Boolean;
		/**
		 * NOTE:	The changeCallback will be a function accepting one Event
		 * 			parameter.
		 **/
		function provideLayerOptionsUI(
		l: InteractiveLayer,
				parent: GridRow,
				changeCallback: Function): void;
		function updateLayerOptions(
		l: InteractiveLayer): Boolean;
	}
}
