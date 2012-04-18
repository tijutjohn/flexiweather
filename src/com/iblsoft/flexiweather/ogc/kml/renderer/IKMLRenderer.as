package com.iblsoft.flexiweather.ogc.kml.renderer
{
	import com.iblsoft.flexiweather.ogc.kml.features.KMLFeature;
	import com.iblsoft.flexiweather.widgets.InteractiveWidget;

	public interface IKMLRenderer
	{
		function dispose(feature: KMLFeature): void;
		function render(feature: KMLFeature, container: InteractiveWidget): void;
	}
}