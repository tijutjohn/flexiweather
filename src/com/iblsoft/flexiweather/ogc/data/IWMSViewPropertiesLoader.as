package com.iblsoft.flexiweather.ogc.data
{
	import flash.events.IEventDispatcher;

	public interface IWMSViewPropertiesLoader extends IEventDispatcher
	{
		function destroy(): void;
		function updateWMSData(b_forceUpdate: Boolean, viewProperties: IViewProperties, forcedLayerWidth: Number, forcedLayerHeight: Number): void
	}
}