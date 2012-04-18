package com.iblsoft.flexiweather.ogc.kml.features
{
	import com.iblsoft.flexiweather.net.events.UniURLLoaderErrorEvent;
	import com.iblsoft.flexiweather.net.events.UniURLLoaderEvent;
	import com.iblsoft.flexiweather.net.loaders.UniURLLoader;
	import com.iblsoft.flexiweather.ogc.kml.InteractiveLayerKML;
	import com.iblsoft.flexiweather.ogc.kml.configuration.KMLLayerConfiguration;
	import com.iblsoft.flexiweather.ogc.kml.data.KMLResourceKey;
	import com.iblsoft.flexiweather.ogc.kml.data.KMZFile;
	import com.iblsoft.flexiweather.ogc.kml.events.KMLFeatureEvent;
	import com.iblsoft.flexiweather.ogc.kml.features.styles.StyleSelector;
	import com.iblsoft.flexiweather.ogc.kml.managers.KMLResourceManager;
	import com.iblsoft.flexiweather.utils.URLUtils;
	
	import flash.display.Bitmap;
	import flash.display.DisplayObject;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.net.URLRequest;
	
	public class KMLIcon extends Sprite
	{
		public static const ICON_TYPE_NORMAL: String = 'normal';
		public static const ICON_TYPE_HIGHLIGHTED: String = 'highlighted';
		
		private var _feature: KMLFeature;
		
		private var _normalStyle: StyleSelector;
		private var _highlightStyle: StyleSelector;
		
		private var _state: String;


		public function get normalStyle():StyleSelector
		{
			return _normalStyle;
		}

		public function set normalStyle(value:StyleSelector):void
		{
			_normalStyle = value;
		}

		public function get highlightStyle():StyleSelector
		{
			return _highlightStyle;
		}

		public function set highlightStyle(value:StyleSelector):void
		{
			_highlightStyle = value;
		}

		public function get state(): String
		{
			return _state;
		}
		public function get isHighlighted(): Boolean
		{
			return _state == ICON_TYPE_HIGHLIGHTED;
		}
		
		private var _normalResourceKey: KMLResourceKey;
		private var _highlightResourceKey: KMLResourceKey;
		
		public function KMLIcon(feature: KMLFeature)
		{
			super();
			
			_state = ICON_TYPE_NORMAL;
			
			_feature = feature;
			
			addEventListener(MouseEvent.CLICK, onKMLFeatureClick);
		}
		
		public function setNormalBitmapResourceKey(key: KMLResourceKey): void
		{
			_normalResourceKey = key;
		}
		public function setHighlightBitmapResourceKey(key: KMLResourceKey): void
		{
			_highlightResourceKey = key;
		}
		
		public function cleanup(): void
		{
			graphics.clear();
			
			removeEventListener(MouseEvent.CLICK, onKMLFeatureClick);
			
			var resourceManager: KMLResourceManager = _feature.kml.resourceManager;
			resourceManager.disposeResource(_normalResourceKey);
			resourceManager.disposeResource(_highlightResourceKey);
			
			_normalResourceKey = null;
			_highlightResourceKey = null;
			
			_feature = null;
		}
		
		public function showNormal(): void
		{
			_state = ICON_TYPE_NORMAL;
		}
		public function showHighlight(): void
		{
			_state = ICON_TYPE_HIGHLIGHTED;
		}
		private function onKMLFeatureClick(event: MouseEvent): void
		{
			var kfe: KMLFeatureEvent = new KMLFeatureEvent(KMLFeatureEvent.KML_FEATURE_CLICK, true);
			kfe.kmlFeature = _feature;
			dispatchEvent(kfe);
		}
	}
}