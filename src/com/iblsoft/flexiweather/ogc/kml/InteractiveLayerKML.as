package com.iblsoft.flexiweather.ogc.kml
{
	import com.iblsoft.flexiweather.ogc.InteractiveLayerFeatureBase;
	import com.iblsoft.flexiweather.ogc.Version;
	import com.iblsoft.flexiweather.widgets.InteractiveWidget;
	
	/**
	 * Interactive Layer for display KML features
	 *  
	 * @author fkormanak
	 * 
	 */	
	public class InteractiveLayerKML extends InteractiveLayerFeatureBase
	{
		public function InteractiveLayerKML(container:InteractiveWidget, version:Version)
		{
			super(container, version);
		}
	}
}