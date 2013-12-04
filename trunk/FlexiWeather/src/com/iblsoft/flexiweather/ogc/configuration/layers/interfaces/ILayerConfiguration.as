package com.iblsoft.flexiweather.ogc.configuration.layers.interfaces
{
	import com.iblsoft.flexiweather.widgets.IConfigurableLayer;
	import com.iblsoft.flexiweather.widgets.InteractiveLayer;
	import com.iblsoft.flexiweather.widgets.InteractiveWidget;
	import flash.net.URLRequest;
	import spark.components.Group;

	public interface ILayerConfiguration
	{
		function get label(): String;
		function set label(s: String): void;
		function destroy(): void;
		function createInteractiveLayer(iw: InteractiveWidget): InteractiveLayer;
		function isCompatibleWithCRS(crs: String): Boolean;
		function hasPreview(): Boolean;
		function getPreviewURL(): String;
		function renderPreview(f_width: Number, f_height: Number, iw: InteractiveWidget = null): void;
		function set previewURL(s: String): void;
		function get previewURL(): String;
		function hasCustomLayerOptions(): Boolean;
		function createCustomLayerOption(layer: IConfigurableLayer): Group;
	}
}
