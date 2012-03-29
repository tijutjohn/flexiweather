package com.iblsoft.flexiweather.ogc.kml
{
	import com.iblsoft.flexiweather.ogc.BBox;
	import com.iblsoft.flexiweather.ogc.FeatureUpdateChange;
	import com.iblsoft.flexiweather.ogc.InteractiveLayerFeatureBase;
	import com.iblsoft.flexiweather.ogc.Version;
	import com.iblsoft.flexiweather.ogc.kml.controls.KMLInfoWindow;
	import com.iblsoft.flexiweather.ogc.kml.events.KMLBitmapEvent;
	import com.iblsoft.flexiweather.ogc.kml.events.KMLFeatureEvent;
	import com.iblsoft.flexiweather.ogc.kml.features.Container;
	import com.iblsoft.flexiweather.ogc.kml.features.Document;
	import com.iblsoft.flexiweather.ogc.kml.features.Folder;
	import com.iblsoft.flexiweather.ogc.kml.features.GroundOverlay;
	import com.iblsoft.flexiweather.ogc.kml.features.KML;
	import com.iblsoft.flexiweather.ogc.kml.features.KMLFeature;
	import com.iblsoft.flexiweather.ogc.kml.features.KMLLabel;
	import com.iblsoft.flexiweather.ogc.kml.features.LineString;
	import com.iblsoft.flexiweather.ogc.kml.features.LinearRing;
	import com.iblsoft.flexiweather.ogc.kml.features.Placemark;
	import com.iblsoft.flexiweather.ogc.kml.features.Polygon;
	import com.iblsoft.flexiweather.ogc.kml.interfaces.IKMLIconFeature;
	import com.iblsoft.flexiweather.ogc.kml.interfaces.IKMLLabeledFeature;
	import com.iblsoft.flexiweather.ogc.kml.managers.KMLPopupManager;
	import com.iblsoft.flexiweather.ogc.kml.managers.KMLResourceManager;
	import com.iblsoft.flexiweather.ogc.kml.renderer.DefaultKMLRenderer;
	import com.iblsoft.flexiweather.ogc.kml.renderer.IKMLRenderer;
	import com.iblsoft.flexiweather.utils.AsyncManager;
	import com.iblsoft.flexiweather.utils.DebugUtils;
	import com.iblsoft.flexiweather.utils.ScreenUtils;
	import com.iblsoft.flexiweather.widgets.InteractiveWidget;
	
	import flash.display.BitmapData;
	import flash.display.DisplayObject;
	import flash.display.Graphics;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.MouseEvent;
	import flash.geom.Matrix;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	
	import mx.core.ClassFactory;
	import mx.core.EventPriority;
	import mx.core.FlexGlobals;
	import mx.core.IFlexDisplayObject;
	import mx.events.CloseEvent;
	import mx.managers.PopUpManager;
	
	/**
	 * Interactive Layer for display KML features
	 *  
	 * @author fkormanak
	 * 
	 */	
	public class InteractiveLayerKML extends InteractiveLayerFeatureBase
	{
		public var itemRenderer: Class;
		private var _itemRendererInstance: IKMLRenderer;
		public function get itemRendererInstance(): IKMLRenderer
		{
			if (!itemRenderer)
				itemRenderer = DefaultKMLRenderer;
			
			if (!_itemRendererInstance)
			{
				var newClass: ClassFactory = new ClassFactory(itemRenderer);
				_itemRendererInstance = newClass.newInstance();
				
				if (_itemRendererInstance is EventDispatcher)
				{
					(_itemRendererInstance as EventDispatcher).addEventListener(KMLBitmapEvent.BITMAP_LOADED, onRendererBitmapLoaded);
					(_itemRendererInstance as EventDispatcher).addEventListener(KMLBitmapEvent.BITMAP_LOAD_ERROR, onRendererBitmapLoadError);
					(_itemRendererInstance as EventDispatcher).addEventListener(KMLResourceManager.ALL_RESOURCES_LOADED, onAllRendererResourcesLoaded);
				}
			}
			
			return _itemRendererInstance;
		}
		
		private var _kml: KML;
		
		[Bindable (event="kmlChanged")]
		public function get kml(): KML
		{
			return _kml;
		}
		private var m_boundaryRect: Rectangle;
		
		private var _syncManager: AsyncManager;
		
		public function InteractiveLayerKML(container:InteractiveWidget, kml: KML, version:Version)
		{
			super(container, version);
			
			_kml = kml;
			
			parseKML();
			
			addEventListener(KMLFeatureEvent.KML_FEATURE_CLICK, onKMLFeatureClick, false, EventPriority.DEFAULT_HANDLER, true);
		}
		
		override protected function createChildren():void
		{
			super.createChildren();
			
			_syncManager = new AsyncManager();
			
		}
		
		override protected function childrenCreated():void
		{
			super.childrenCreated();
			
			addChild(_syncManager);
		}
		/**
		 * this function must be called, when layer is destroying to remove all dependencies and unload or destroy features. 
		 * 
		 */		
		override public function destroy(): void
		{
			for each (var feature: KMLFeature in features)
			{
				if (feature is IKMLLabeledFeature)
				{
					//check if info window is not opened
					var window: IFlexDisplayObject = KMLPopupManager.getInstance().getPopUpForFeature(feature);
					if (window)
					{
						KMLPopupManager.getInstance().removePopUp(window);
					}
				}
				removeFeature(feature);
			}
			super.destroy();
			//FIXME implement InteractiveLayerKML destroy function	
		}
		
		private function parseKML(): void
		{
			var rootFeature: KMLFeature = _kml.feature;
			
			if (!rootFeature)
			{
				trace("there is no root feature found");
				return;
			}
			
			var kmlObj: Object = new Object();
			kmlObj.name = rootFeature.name;
			
			if (!canContainFeatures(rootFeature)) 
			{
				//add root feature to layer
				var feature: KMLFeature = rootFeature as KMLFeature;
				if (feature.kmlVisibility)
					addFeature(feature);
				
				//make full update
//				feature.update(true);
				
				kmlParsingFinished();
				return;
			}
			
			// its a container, lets look for children features
			kmlObj.children = getChildrenFeatures(Container(rootFeature));
			
			callLater(kmlParsingFinished);
			callLater(update, [FeatureUpdateChange.fullUpdate()]);
		}
		
		private function kmlParsingFinished(): void
		{
			container.labelLayout.update();
			container.objectLayout.update();
		}
		public function canContainFeatures(feature: KMLFeature):Boolean 
		{
			return (feature is Container);
		}
		
		private function getChildrenFeatures(kmlContainer:Container):Array 
		{
			var childrenFeatures:Array = new Array();
			for (var i:Number = 0; i < kmlContainer.features.length; i++) 
			{
				var feature: KMLFeature = kmlContainer.features[i] as KMLFeature;
				
				if (feature.kmlVisibility)
					addFeature(feature);
				else
					trace("Feature is not KML visible, do not add it to features");
				
				var childObj:Object = new Object();
				childObj.name = feature.name;
				if (canContainFeatures(feature)) 
				{
					childObj.children = getChildrenFeatures(Container(feature));
				}
				childrenFeatures.push(childObj);
				
				feature.update(FeatureUpdateChange.fullUpdate());
			}
			return childrenFeatures;
		}
		
		override public function onMouseRollOver(event:MouseEvent):Boolean
		{
			return (checkKMLFeatureMouseEvent(event, KMLFeatureEvent.KML_FEATURE_ROLL_OVER) != null);
		}
		override public function onMouseRollOut(event:MouseEvent):Boolean
		{
			return (checkKMLFeatureMouseEvent(event, KMLFeatureEvent.KML_FEATURE_ROLL_OUT) != null);
		}
		override public function onMouseMove(event: MouseEvent): Boolean
		{
			for each (var feature: KMLFeature in features)
			{
				if (feature is IKMLIconFeature)
				{
					if(feature.kmlIcon.hitTestPoint(event.stageX, event.stageY, true))
					{
						highlightFeature(feature);
						return true;
					}
				}
			}
			highlightFeature(null);
			return false;
		}
		
		private var m_highlightedFeature: KMLFeature;
		public function highlightFeature(feature: KMLFeature): void
		{
			if (feature != null)
			{
				if (m_highlightedFeature != feature)
				{
					if (m_highlightedFeature)
					{
						//unhighlight previously highlighted feature
						m_highlightedFeature.kmlIcon.showNormal();
					}
					feature.kmlIcon.showHighlight();
					m_highlightedFeature = feature;
					//update graphics
					invalidateDynamicPart();
				}
			} else {
				if (m_highlightedFeature)
				{
					m_highlightedFeature.kmlIcon.showNormal();
					m_highlightedFeature = null;
					//update graphics
					invalidateDynamicPart();
				}
			}
		}
		
		override public function onMouseClick(event: MouseEvent): Boolean
		{
			var featureClicked: KMLFeature = checkKMLFeatureMouseEvent(event, KMLFeatureEvent.KML_FEATURE_CLICK, false);
			
			if (featureClicked)
			{
				var ke: KMLFeatureEvent = new KMLFeatureEvent(KMLFeatureEvent.KML_FEATURE_CLICK, true, true);
				ke.kmlFeature = featureClicked;
				dispatchEvent(ke);

			}
			return featureClicked != null;
		}
		
		private function onKMLFeatureClick(event: KMLFeatureEvent): void
		{
			if (!event.isDefaultPrevented())
			{
				openInfoWindow(event.kmlFeature);
			}
		}
		
		private function checkKMLFeatureMouseEvent(event:MouseEvent, dispatchType: String, bDispatchEvent: Boolean = true): KMLFeature
		{
			for each (var feature: KMLFeature in features)
			{
				
				if(feature is IKMLIconFeature && feature.kmlIcon.hitTestPoint(event.stageX, event.stageY, false))
				{
					if (bDispatchEvent)
					{
						var ke: KMLFeatureEvent = new KMLFeatureEvent(dispatchType, true);
						ke.kmlFeature = feature;
						dispatchEvent(ke);
					}
					return feature;
				}
			}
			return null;
			
		}
		
		private function openInfoWindow(feature: KMLFeature): void
		{
			var kmlPM: KMLPopupManager = KMLPopupManager.getInstance();
			
			var infoWindow: KMLInfoWindow = kmlPM.getPopUpForFeature(feature) as KMLInfoWindow;
			if (!infoWindow)
			{
				infoWindow = new KMLInfoWindow();
				
				infoWindow.feature = feature;
				infoWindow = kmlPM.addPopUp(infoWindow, FlexGlobals.topLevelApplication as DisplayObject, feature) as KMLInfoWindow;
				kmlPM.centerPopUpOnFeature(infoWindow);
			}
		}
		
		public function update(changeFlag: FeatureUpdateChange): void
		{
			trace("KML layer draw: " + features.length);
			
			m_boundaryRect = new Rectangle(0,0,width, height);
//			m_boundaryRect = container.getBounds(this.stage);
			
			if (_syncManager)
			{
				for each (var feature: KMLFeature in features)
				{
					_syncManager.addCall(feature, updateFeature, [feature, changeFlag]);
//					updateFeature(feature, itemRendererInstance, fullUpdate);	
				}
				_syncManager.start();
			}
		}
		
		private function updateFeature(feature:  KMLFeature, changeFlag: FeatureUpdateChange): void
		{
//			if (fullUpdate)
//				feature.invalidatePoints();
			
			feature.update(changeFlag);
			feature.visible = true; //getAbsoluteVisibility(feature);
			
//			if (fullUpdate)
//				itemRendererInstance.render(feature, container);
		}
		
		
		protected function onAllRendererResourcesLoaded(event: Event): void
		{
			kmlParsingFinished();
			update(FeatureUpdateChange.fullUpdate());
		}
		protected function onRendererBitmapLoaded(event: KMLBitmapEvent): void
		{
			kmlParsingFinished();
		}
		protected function onRendererBitmapLoadError(event: KMLBitmapEvent): void
		{
			
		}
		
		// helpers
		protected function getAbsoluteVisibility(object: KMLFeature): Boolean
		{
			
			if(object == null)
				return false;
			// check if at least part of object is within m_boundaryRect
			var bounds: Rectangle = object.getBounds(this);
			if (object is IKMLIconFeature)
				var bounds1: Rectangle = object.kmlIcon.getBounds(this);
			
			var bounds2: Rectangle = object.getBounds(this.stage);
			var bounds3: Rectangle = object.getBounds(this.container);
			
			if(bounds.right < m_boundaryRect.left)
				return false;
			if(bounds.left > m_boundaryRect.right)
				return false;
			if(bounds.bottom < m_boundaryRect.top)
				return false;
			if(bounds.top > m_boundaryRect.bottom)
				return false;
			// analyse chain of visibility flags
			
			var dispObject: DisplayObject = (object as DisplayObject).parent;
			while(dispObject != null) {
				if(!dispObject.visible)
					return false;
				dispObject = dispObject.parent;
			}
			return true;
		}
		
		override public function onAreaChanged(b_finalChange: Boolean): void
		{
			super.onAreaChanged(b_finalChange);
			
			//FIXME this should not be called if panning or zooming is still in progress
			
			//invalidateDynamicPart();
			callLater(isUpdateNeeded);	
		}
		
		private function isUpdateNeeded(): void
		{
			var crs: String = container.getCRS();
			var viewBBox: BBox = container.getViewBBox();
			
			var flag: uint = 0;
			if (crs != m_oldCRS)
			{
				flag |= FeatureUpdateChange.CRS_CHANGED;
			}
			if (!m_oldViewBBox)
			{
				flag |= FeatureUpdateChange.VIEW_BBOX_MOVED;
				flag |= FeatureUpdateChange.VIEW_BBOX_SIZE_CHANGED;
			} else {
				if (!viewBBox.equals(m_oldViewBBox))
				{
					if (m_oldViewBBox.width == viewBBox.width && m_oldViewBBox.height == viewBBox.height)
						flag |= FeatureUpdateChange.VIEW_BBOX_MOVED;
					else
						flag |= FeatureUpdateChange.VIEW_BBOX_SIZE_CHANGED;
				}
			}
			var updateFlag: FeatureUpdateChange = new FeatureUpdateChange(flag);
			
			//TODO: check visible parts change as well
		
			update(updateFlag);
			
			m_oldCRS = crs;	
			m_oldViewBBox = viewBBox;
		}
		
		private var m_oldCRS: String;
		private var m_oldViewBBox: BBox;
		
		override public function onContainerSizeChanged(): void
		{
			super.onContainerSizeChanged();
		}
		override public function hasPreview(): Boolean
		{ return true; }
		
		override public function renderPreview(graphics: Graphics, f_width: Number, f_height: Number): void
		{
			if(!featuresContainer.width || !featuresContainer.height)
			{
				return;
			}
			
			/*
			graphics.lineStyle(2, 0xaa0000, 0.7, true);
			
			graphics.beginFill(0xaa0000);
			graphics.drawRect(0,0, f_width, f_height);
			graphics.endFill();
			
			graphics.moveTo(0, 0);
			graphics.lineTo(f_width - 1, f_height - 1);
			graphics.moveTo(0, f_height - 1);
			graphics.lineTo(f_width - 1, 0);
			*/
			
			var matrix: Matrix  = new Matrix();
			matrix.translate(-f_width / 3, -f_width / 3);
			matrix.scale(3, 3);
			matrix.translate(featuresContainer.width / 3, featuresContainer.height / 3);
			matrix.invert();
			//FIXME - check featuresContainer size (i have size more than 8000px)
			var bd: BitmapData = new BitmapData(featuresContainer.width, featuresContainer.height, true, 0x00000000);
			bd.draw(this);
			
			graphics.clear();
			graphics.beginBitmapFill(bd, matrix, false, true);
			graphics.drawRect(0, 0, f_width, f_height);
			graphics.endFill();
		}
	}
}