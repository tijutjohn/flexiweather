package com.iblsoft.flexiweather.ogc.kml.features
{
	import com.iblsoft.flexiweather.net.events.UniURLLoaderErrorEvent;
	import com.iblsoft.flexiweather.net.events.UniURLLoaderEvent;
	import com.iblsoft.flexiweather.net.loaders.UniURLLoader;
	import com.iblsoft.flexiweather.ogc.kml.InteractiveLayerKML;
	import com.iblsoft.flexiweather.ogc.kml.configuration.KMLLayerConfiguration;
	import com.iblsoft.flexiweather.ogc.kml.data.KMZFile;
	import com.iblsoft.flexiweather.ogc.kml.events.KMLFeatureEvent;
	import com.iblsoft.flexiweather.ogc.kml.features.styles.StyleSelector;
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
		
//		private var _iconBitmap: Bitmap;
//		private var _iconHighlightBitmap: Bitmap;
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
		
		public function KMLIcon(feature: KMLFeature)
		{
			super();
			
			_state = ICON_TYPE_NORMAL;
			
			_feature = feature;
			
			addEventListener(MouseEvent.CLICK, onKMLFeatureClick);
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
		
		/*
		public function get iconBitmap(): Bitmap
		{
			return _iconBitmap;
		}
		public function get iconHighlightBitmap(): Bitmap
		{
			return _iconHighlightBitmap;
		}
		
		public function get isIconLoaded(): Boolean
		{
			return (_iconBitmap != null);
		}
		*/
		//		public function loadIcon(style: Style, succesfulCallback: Function = null, unsuccesfulCallback: Function = null): void
		/*
		public function loadIcon(href: String, hrefHighligted: String, succesfulCallback: Function = null, unsuccesfulCallback: Function = null): void
		{
			//			if (style && style.iconStyle && style.iconStyle.icon)
			//			{
			//				var href: String = style.iconStyle.icon.href;
			
			_iconSucessfulCallback = succesfulCallback;
			_iconUnsucessfulCallback = unsuccesfulCallback;
			
			href = fixIconHref(href);
			hrefHighligted = fixIconHref(hrefHighligted);
			
			_loadCount = 0;
			_loadCount += (href != null);
			_loadCount += (hrefHighligted != null && hrefHighligted != href);
			
			var highlightIconIsSame: Boolean = false;
			
			if (hrefHighligted && hrefHighligted != href)
			{
				loadIconAsset(hrefHighligted, ICON_TYPE_HIGHLIGHTED);
			} else {
				highlightIconIsSame = true;
			}
			
			if (href)
				loadIconAsset(href, ICON_TYPE_NORMAL, highlightIconIsSame);
			
		}
		
		
		private function get kmlLayer(): InteractiveLayerKML
		{
			var dispObject: DisplayObject = this.parent as DisplayObject;
			while (dispObject)
			{
				if (dispObject is InteractiveLayerKML)
				{
					return dispObject as InteractiveLayerKML;
				}
				dispObject = dispObject.parent as DisplayObject;
			}
			return null;
		}
		
		*/
		/**
		 * KMZ file is ready and we can load all icons in stack from kmz file 
		 * @param event
		 * 
		 */
		/*
		private var _iconStack: Array = [];
		private function onKMZIconReady(event: Event = null): void
		{
			for each (var obj: Object in _iconStack)
			{
				loadKMZIcon(obj.kmz as KMZFile, obj.href as String, obj.assocData);
			}
			_iconStack.splice(0, _iconStack.length);
		}
		
		private function loadKMZIcon(kmz: KMZFile, href: String, assocData: Object): void
		{
			var bmp: Bitmap = kmz.getAssetByName(href);
			if (bmp)
			{
				if (assocData.type == ICON_TYPE_NORMAL)
				{
					_iconBitmap = bmp;
					if (assocData.highlightIconIsSame)
					{
						_iconHighlightBitmap = bmp;
					}
				} else {
					if (assocData.type == ICON_TYPE_HIGHLIGHTED) 
					{
						_iconHighlightBitmap = bmp;
					}
				}
				
				if (_iconSucessfulCallback != null)
					_iconSucessfulCallback(_feature);
				
				return;
			}
		}
		*/
	}
}