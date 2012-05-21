package com.iblsoft.flexiweather.ogc.preload
{
	import com.iblsoft.flexiweather.ogc.data.IViewProperties;

	public interface IPreloadableLayer
	{
		function get currentViewProperties(): IViewProperties;
		
		function changeViewProperties(viewProperties: IViewProperties): void
			
		function preload(viewProperties: IViewProperties): void;
		function preloadMultiple(viewPropertiesArray: Array): void;
		
		function isPreloaded(viewProperties: IViewProperties): Boolean;
		function isPreloadedMultiple(viewPropertiesArray: Array): Boolean;
	}
}