package com.iblsoft.flexiweather.ogc.data
{
	import flash.events.IEventDispatcher;

	public interface IWMSViewPropertiesLoader extends IEventDispatcher
	{
		function updateWMSData(b_forceUpdate: Boolean, wmsViewProperties: WMSViewProperties, forcedLayerWidth: Number, forcedLayerHeight: Number): void
	}
}