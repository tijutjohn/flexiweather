package com.iblsoft.flexiweather.widgets
{
	import com.iblsoft.flexiweather.ogc.ILayerConfiguration;

	public interface IConfigurableLayer
	{
		function get configuration(): ILayerConfiguration;		
	}
}