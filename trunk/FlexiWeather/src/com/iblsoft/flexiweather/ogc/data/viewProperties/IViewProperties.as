package com.iblsoft.flexiweather.ogc.data.viewProperties
{
	import com.iblsoft.flexiweather.ogc.configuration.layers.interfaces.ILayerConfiguration;

	public interface IViewProperties
	{
		function setConfiguration(cfg: ILayerConfiguration): void;
		function destroy(): void;
		function clone(): IViewProperties;
	}
}
