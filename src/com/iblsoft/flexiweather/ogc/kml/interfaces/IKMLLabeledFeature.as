package com.iblsoft.flexiweather.ogc.kml.interfaces
{
	import com.iblsoft.flexiweather.ogc.kml.features.KMLLabel;

	public interface IKMLLabeledFeature
	{
		function get kmlLabel(): KMLLabel;
	}
}