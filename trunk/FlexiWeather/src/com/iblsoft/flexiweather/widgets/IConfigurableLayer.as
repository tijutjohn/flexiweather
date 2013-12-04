package com.iblsoft.flexiweather.widgets
{
	import com.iblsoft.flexiweather.ogc.configuration.layers.interfaces.ILayerConfiguration;

	public interface IConfigurableLayer
	{
		function get configuration(): ILayerConfiguration;
	}
}
