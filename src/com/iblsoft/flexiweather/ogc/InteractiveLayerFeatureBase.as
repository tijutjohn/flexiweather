package com.iblsoft.flexiweather.ogc
{
	import com.iblsoft.flexiweather.ogc.editable.WFSFeatureEditable;
	import com.iblsoft.flexiweather.ogc.events.FeatureEvent;
	import com.iblsoft.flexiweather.ogc.kml.features.KMLFeature;
	import com.iblsoft.flexiweather.widgets.InteractiveDataLayer;
	import com.iblsoft.flexiweather.widgets.InteractiveLayer;
	import com.iblsoft.flexiweather.widgets.InteractiveLayerPan;
	import com.iblsoft.flexiweather.widgets.InteractiveWidget;
	
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.display.Sprite;
	import flash.display.Stage;
	import flash.events.Event;
	
	import mx.collections.ArrayCollection;

	public class InteractiveLayerFeatureBase extends InteractiveDataLayer
	{
		protected var _areaChanged: Boolean;
		protected var _areaChangedFinalChange: Boolean;
		protected var _suspendUpdating: Boolean;
		protected var _suspendUpdatingChanged: Boolean;
		
		protected var m_firstFeature: FeatureBase;


		public function get suspendUpdating():Boolean
		{
			return _suspendUpdating;
		}

		public function set suspendUpdating(value:Boolean):void
		{
			if (_suspendUpdating != value)
			{
				_suspendUpdating = value;
				_suspendUpdatingChanged = true;
				invalidateProperties();
			}
		}

		public function get version(): Version
		{
			return m_version;
		}

		public function set version(value: Version): void
		{
			m_version = value;
		}

		public function get firstFeature(): FeatureBase
		{
			return m_firstFeature;
		}

		public function set firstFeature(value: FeatureBase): void
		{
			m_firstFeature = value;
		}
		private var ma_features: ArrayCollection = new ArrayCollection();
		protected var m_featuresContainer: Sprite = new Sprite();
		protected var ms_serviceURL: String = null;
		private var m_version: Version;
		protected var mb_useMonochrome: Boolean = false;
		protected var mi_monochromeColor: uint = 0x333333;
		protected var _screenshot: Screenshot;

		public function InteractiveLayerFeatureBase(container: InteractiveWidget = null,
				version: Version = null)
		{
			super(container);
			m_version = version;
			m_featuresContainer.mouseEnabled = false;
			m_featuresContainer.mouseChildren = false;
			addChild(m_featuresContainer);
			addScreenshotModeListeners();
		}

		override protected function createChildren(): void
		{
			super.createChildren();
			if (!_screenshot)
				_screenshot = new Screenshot();
		}

		override protected function childrenCreated(): void
		{
			super.childrenCreated();
			if (!_screenshot.parent)
				addChild(_screenshot);
		}

		/**
		 * Creates new features from XML and remove old features if bRemoveOld = true
		 * @param xml
		 * @param bRemoveOld Boolean flag if old features must be removed (Load = true, Import = false)
		 *
		 */
		public function createFeaturesFromXML(xml: XML, bIsImport: Boolean = false): ArrayCollection
		{
			return null;
		}
		private var _oldFeature: FeatureBase;

		public function addFeature(feature: FeatureBase, bDoUpdate: Boolean = true): void
		{
			feature.setMaster(this);
			if (bDoUpdate)
				feature.update(new FeatureUpdateContext(FeatureUpdateContext.FULL_UPDATE));
			m_featuresContainer.addChild(feature);
			if (!m_firstFeature)
				firstFeature = feature;
			if (_oldFeature)
			{
				if (_oldFeature.parentFeature == feature.parentFeature)
				{
					_oldFeature.next = feature;
					feature.previous = _oldFeature;
				}
			}
			else
				firstFeature = feature;
			_oldFeature = feature;
			ma_features.addItem(feature);
			onFeatureAdded(feature);
		}

		protected function onFeatureAdded(feature: FeatureBase): void
		{
			feature.addEventListener(FeatureEvent.PRESENCE_IN_VIEW_BBOX_CHANGED, onFeaturePresenceInViewBBoxIsChanged);
			invalidateDynamicPart();
		}

		protected function onFeatureRemoved(feature: FeatureBase): void
		{
			feature.removeEventListener(FeatureEvent.PRESENCE_IN_VIEW_BBOX_CHANGED, onFeaturePresenceInViewBBoxIsChanged);
			invalidateDynamicPart();
		}
		
		protected function showAllFeatures(): void
		{
			m_featuresContainer.visible = true;
		}
		protected function hideAllFeatures(): void
		{
			m_featuresContainer.visible = false;
		}

		private function onFeaturePresenceInViewBBoxIsChanged(event: FeatureEvent): void
		{
			var feature: FeatureBase = event.target as FeatureBase;
			feature.presentInViewBBox = event.insideViewBBox;
			feature.visible = event.insideViewBBox;
		}
		
		override protected function commitProperties():void
		{
			if (_areaChanged)
			{
				if (!_suspendUpdating)
					onAreaChanged(_areaChangedFinalChange);
				else
					callLater(onAreaChanged, [_areaChangedFinalChange]);
				_suspendUpdatingChanged = false;
			}
		}
		
		override public function onAreaChanged(b_finalChange:Boolean):void
		{
			if (_suspendUpdating)
			{
				if (!_areaChanged)
				{
					_areaChanged = true;
					_areaChangedFinalChange = b_finalChange;
				} else {
					_areaChangedFinalChange = _areaChangedFinalChange || b_finalChange;
				}
				invalidateProperties();
				return;
			}
			
			super.onAreaChanged(b_finalChange);
			updateAllFeatures();
		}
		
		public function updateAllFeatures(): void
		{
			var i_count: int = featuresContainer.numChildren;
			for (var i: int = i_count - 1; i >= 0; --i)
			{
				var feature: FeatureBase = featuresContainer.getChildAt(i) as FeatureBase;
				feature.update(FeatureUpdateContext.fullUpdate());
			}
		}
		
		public function removeAllFeatures(): void
		{
			var i_count: int = featuresContainer.numChildren;
			for (var i: int = i_count - 1; i >= 0; --i)
			{
				var feature: FeatureBase = featuresContainer.getChildAt(i) as FeatureBase;
				var id: int = features.getItemIndex(feature);
				if (id >= 0)
					features.removeItemAt(id);
				onFeatureRemoved(feature);
				feature.cleanup();
				featuresContainer.removeChildAt(i);
			}
			if (features && features.length > 0)
			{
				features.removeAll();
			}
		}

		public function removeFeature(feature: FeatureBase): void
		{
			if (feature.parent == featuresContainer)
			{
				featuresContainer.removeChild(feature);
				var i: int = features.getItemIndex(feature);
				if (i >= 0)
					features.removeItemAt(i);
				onFeatureRemoved(feature);
				feature.cleanup();
			}
		}

		public override function destroy(): void
		{
			removeAllFeatures();
			super.destroy();
		}
		/**
		 * Screenshot functionality
		 */
		protected var _screenshotMode: Boolean;

		private function addScreenshotModeListeners(): void
		{
			//for now we are not using screenshot functionality
			return;
			//need to find out pan layer first
			var panLayer: InteractiveLayerPan;
			var total: int = container.numLayers;
			for (var i: int = 0; i < total; i++)
			{
				var layer: InteractiveLayer = container.getLayerAt(i);
				if (layer is InteractiveLayerPan)
				{
					panLayer = layer as InteractiveLayerPan;
					break;
				}
			}
			if (panLayer)
			{
				panLayer.addEventListener(InteractiveLayerPan.START_PANNING, onPanningStarted);
				panLayer.addEventListener(InteractiveLayerPan.STOP_PANNING, onPanningFinished);
				panLayer.addEventListener(InteractiveLayerPan.PAN, onPanning);
			}
		}

		private function onPanning(event: Event): void
		{
			changeToScreenshotMode();
		}

		private function onPanningStarted(event: Event): void
		{
			changeToScreenshotMode();
		}

		private function onPanningFinished(event: Event): void
		{
			changeBackFromScreenshotMode();
		}

		public function changeToScreenshotMode(): void
		{
			_screenshot.create(this, width, height);
			_screenshot.visible = true;
			_screenshotMode = true;
			m_featuresContainer.visible = false;
		}

		public function changeBackFromScreenshotMode(): void
		{
			_screenshot.visible = false;
			_screenshotMode = false;
			m_featuresContainer.visible = true;
		}

		public function set useMonochrome(val: Boolean): void
		{
			var b_needUpdate: Boolean = false;
			if (mb_useMonochrome != val)
				b_needUpdate = true;
			mb_useMonochrome = val;
			if (b_needUpdate)
			{
				for (var i: int = 0; i < m_featuresContainer.numChildren; i++)
				{
					if (m_featuresContainer.getChildAt(i) is WFSFeatureEditable)
						WFSFeatureEditable(m_featuresContainer.getChildAt(i)).update(FeatureUpdateContext.fullUpdate());
				}
			}
		}

		public function get useMonochrome(): Boolean
		{
			return mb_useMonochrome;
		}

		public function set monochromeColor(i_color: uint): void
		{
			var b_needUpdate: Boolean = false;
			if (mi_monochromeColor != i_color)
				b_needUpdate = true;
			mi_monochromeColor = i_color;
			if (b_needUpdate)
			{
				for (var i: int = 0; i < m_featuresContainer.numChildren; i++)
				{
					if (m_featuresContainer.getChildAt(i) is WFSFeatureEditable)
						WFSFeatureEditable(m_featuresContainer.getChildAt(i)).update(FeatureUpdateContext.fullUpdate());
				}
			}
		}

		public function get monochromeColor(): uint
		{
			return mi_monochromeColor;
		}

		public function get featuresContainer(): Sprite
		{
			return m_featuresContainer;
		}

		public function set features(value: ArrayCollection): void
		{
			ma_features = value;
		}

		// getters & setters		
		public function get features(): ArrayCollection
		{
			return ma_features;
		}

		public function get serviceURL(): String
		{
			return ms_serviceURL;
		}

		public function set serviceURL(s_serviceURL: String): void
		{
			ms_serviceURL = s_serviceURL;
		}
	}
}
import com.iblsoft.flexiweather.ogc.InteractiveLayerFeatureBase;
import flash.display.Bitmap;
import flash.display.BitmapData;
import flash.display.Graphics;
import flash.geom.ColorTransform;
import mx.core.UIComponent;

class Screenshot extends UIComponent
{
	/**
	 * Bitmap stores screenshot of current layer features. It's used for moving 1 bitmap instead of many features when panning
	 */
	private var _featuresBitmap: Bitmap;
	private var _bd: BitmapData;
	private var _changed: Boolean;

	public function Screenshot()
	{
	}

	public function invalidate(): void
	{
		_changed = true;
	}

	public function create(layer: InteractiveLayerFeatureBase, w: int, h: int): void
	{
		_bd = new BitmapData(w, h, true, 0x00000000);
		var clrTransform: ColorTransform = new ColorTransform(1, 0, 0);
		_bd.draw(layer, null, clrTransform);
		if (!_featuresBitmap)
			_featuresBitmap = new Bitmap(_bd);
		else
		{
			_featuresBitmap.bitmapData.dispose();
			_featuresBitmap.bitmapData = _bd;
		}
		if (!_featuresBitmap.parent)
			addChild(_featuresBitmap);
	}
}
