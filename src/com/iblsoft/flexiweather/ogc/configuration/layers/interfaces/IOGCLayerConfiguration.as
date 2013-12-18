package com.iblsoft.flexiweather.ogc.configuration.layers.interfaces
{
	import com.iblsoft.flexiweather.ogc.configuration.services.OGCServiceConfiguration;

	public interface IOGCLayerConfiguration extends ILayerConfiguration
	{
		function get service(): OGCServiceConfiguration;
		function set service(value:OGCServiceConfiguration): void;	
	}
}