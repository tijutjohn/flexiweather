package com.iblsoft.flexiweather.ogc.kml.interfaces
{
	import com.iblsoft.flexiweather.ogc.kml.features.KMLIcon;
	
	import flash.display.Bitmap;

	public interface IKMLIconFeature
	{
		function get kmlIcon(): KMLIcon;
//		function get iconBitmap(): Bitmap;
//		function get isIconLoaded(): Boolean;
//		function loadIcon(href: String, succesfulCallback: Function = null, unsuccesfulCallback: Function = null): void;
	}
}