package com.iblsoft.flexiweather.ogc.configuration.layers.interfaces
{
	import flash.net.URLRequest;
	import com.iblsoft.flexiweather.ogc.configuration.services.WMSServiceConfiguration;

	public interface IWMSLayerConfiguration extends ILayerConfiguration
	{
		function toGetMapRequest(s_crs: String, s_bbox: String, i_width: int, i_height: int, s_stylesList: String, s_printQuality: String, s_layersOverride: String = null): URLRequest;
		function get layerNames(): Array;
		function set layerNames(value: Array): void;
		function get wmsService(): WMSServiceConfiguration;
		function get layerConfigurations(): Array;
		function set layerConfigurations(value: Array): void;
		function set dimensionTimeName(s: String): void;
		function get dimensionTimeName(): String;
		function set dimensionRunName(s: String): void;
		function get dimensionRunName(): String;
		function set dimensionForecastName(s: String): void;
		function get dimensionForecastName(): String;
		function set dimensionVerticalLevelName(s: String): void;
		function get dimensionVerticalLevelName(): String;
		function get styleNames(): Array
		function set styleNames(value: Array): void
		function get autoRefreshPeriod(): uint
		function set autoRefreshPeriod(value: uint): void
		function get imageFormat(): String
		function set imageFormat(value: String): void
		function dimensionToParameterName(s_dim: String): String;
	}
}
