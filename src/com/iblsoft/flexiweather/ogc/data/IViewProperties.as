package com.iblsoft.flexiweather.ogc.data
{
	import com.iblsoft.flexiweather.ogc.ILayerConfiguration;

	public interface IViewProperties
	{
		function setConfiguration(cfg: ILayerConfiguration): void;
		function clone(): IViewProperties;
	}
}