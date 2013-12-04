package com.iblsoft.flexiweather.ogc.data.viewProperties
{
	import flash.events.IEventDispatcher;

	public interface IWMSViewPropertiesLoader extends IEventDispatcher
	{
		function cancel(): void;
		function destroy(): void;
		function updateWMSData(b_forceUpdate: Boolean, viewProperties: IViewProperties, forcedLayerWidth: Number, forcedLayerHeight: Number, printQuality: String): void
	}
}
