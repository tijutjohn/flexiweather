package com.iblsoft.flexiweather.ogc.kml
{
	import com.iblsoft.flexiweather.ogc.BBox;
	import com.iblsoft.flexiweather.ogc.FeatureUpdateContext;
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
	import com.iblsoft.flexiweather.utils.ProfilerUtils;
	import com.iblsoft.flexiweather.utils.ScreenUtils;
	import com.iblsoft.flexiweather.widgets.InteractiveWidget;
	
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.DisplayObject;
	import flash.display.Graphics;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.MouseEvent;
	import flash.geom.Matrix;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	
	import mx.controls.Alert;
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
		private var _syncManagerFullUpdate: AsyncManager;
		
		
		public function InteractiveLayerKML(container:InteractiveWidget, kml: KML, version:Version)
		{
			super(container, version);
			
			_kml = kml;
			
			
//			addEventListener(Event.ENTER_FRAME, onEnterFrame);
			addEventListener(KMLFeatureEvent.KML_FEATURE_CLICK, onKMLFeatureClick, false, EventPriority.DEFAULT_HANDLER, true);
		}
		
		private function onEnterFrame(event: Event): void
		{
			trace("ILKML tick");
		}
		override protected function createChildren():void
		{
			super.createChildren();
			
			if (!_syncManager)
				_syncManager = new AsyncManager();
			if (!_syncManagerFullUpdate)
				_syncManagerFullUpdate = new AsyncManager();
			
		}
		
		override protected function childrenCreated():void
		{
			super.childrenCreated();
			
			if (!_syncManager.parent)
			{
				addChild(_syncManager);
				addChild(_screenshot);
				
				parseKML();
			}
			if (!_syncManagerFullUpdate.parent)
			{
				addChild(_syncManagerFullUpdate);
			}
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
				callLater(update, [FeatureUpdateContext.fullUpdate()]);
				return;
			}
			_syncManager.data = kmlObj;
			
			// its a container, lets look for children features
			getChildrenFeatures(Container(rootFeature));
			
			_syncManager.addEventListener(AsyncManager.EMPTY, onKMLChildrenFeaturesAdded);
			_syncManager.maxCallsPerTick = 45;
			_syncManager.start();
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
		
		private function onKMLChildrenFeaturesAdded(event: Event): void
		{
			_syncManager.removeEventListener(AsyncManager.EMPTY, onKMLChildrenFeaturesAdded);
		
			_syncManager.maxCallsPerTick = 50;
			
			var kmlObj: Object = _syncManager.data;
			
			kmlObj.children = _childrenFeatures;
			
			callLater(kmlParsingFinished);
			callLater(update, [FeatureUpdateContext.fullUpdate()]);
		}
		
		private var _childrenFeatures:Array;
		private function getChildrenFeatures(kmlContainer:Container): void 
		{
			_childrenFeatures = new Array();
//			var total: int = kmlContainer.features.length;
			var feature: KMLFeature = kmlContainer.firstFeature as KMLFeature;
//			for (var i:Number = 0; i < total; i++)
			while ( feature )
			{
//				var feature: KMLFeature = kmlContainer.features[i] as KMLFeature;
				var childObj:Object = new Object();
				childObj.name = feature.name;
				
				if (canContainFeatures(feature)) 
				{
					childObj.children = getChildrenFeatures(Container(feature));
				}
				_childrenFeatures.push(childObj);
				
				_syncManager.addCall(feature, getChildrenFeatureUpdate, [kmlContainer, feature]);
				
				feature = feature.next as KMLFeature;
			}
		}
		
		private function getChildrenFeature(kmlContainer:Container, feature: KMLFeature): void
		{
			var childObj:Object = new Object();
			childObj.name = feature.name;
			if (canContainFeatures(feature)) 
			{
				childObj.children = getChildrenFeatures(Container(feature));
			}
			_childrenFeatures.push(childObj);
			
		}
		private function getChildrenFeatureUpdate(kmlContainer:Container, feature: KMLFeature): void
		{
			if (feature.kmlVisibility)
				addFeature(feature, false);
			else
				trace("Feature is not KML visible, do not add it to features");
//			feature.update(FeatureUpdateChange.fullUpdate());
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
			var feature: KMLFeature = firstFeature as KMLFeature;
			//			for (var i:Number = 0; i < total; i++)
//			for each (var feature: KMLFeature in features)
			while ( feature )
			{
				if (feature is IKMLIconFeature)
				{
					if(feature.kmlIcon.hitTestPoint(event.stageX, event.stageY, true))
					{
						highlightFeature(feature);
						return true;
					}
				}
				feature = feature.next as KMLFeature;
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
			//do not open dialog if shift or ctrl key is pressed
			if (event.shiftKey || event.ctrlKey)
				return false;
			
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
			var feature: KMLFeature = firstFeature as KMLFeature;
			//			for (var i:Number = 0; i < total; i++)
			//			for each (var feature: KMLFeature in features)
//			for each (var feature: KMLFeature in features)
			while ( feature )
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
				feature = feature.next as KMLFeature;
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
		
		public function update(changeFlag: FeatureUpdateContext): void
		{
//			trace("KML layer draw: " + features.length);
			
			m_boundaryRect = new Rectangle(0,0,width, height);
//			m_boundaryRect = container.getBounds(this.stage);
			
			var time: int;
			
			if (_screenshotMode)
			{
				
			}
			if (changeFlag.fullUpdateNeeded && _syncManagerFullUpdate)
			{
				_syncManagerFullUpdate.removeEventListener(AsyncManager.EMPTY, onFullUpdateFinished);
				_syncManagerFullUpdate.maxCallsPerTick = 30;
				trace("FULL UPDATE");
				time = ProfilerUtils.startProfileTimer();
				var feature: KMLFeature;
//				for each (feature in features)
//				{
//					_syncManagerFullUpdate.addCall(feature, updateFeature, [feature, changeFlag]);
//				}
				
				feature = firstFeature as KMLFeature;
				while (feature)
				{
					_syncManagerFullUpdate.addCall(feature, updateFeature, [feature, changeFlag]);
					feature = feature.next as KMLFeature;
				}
				

				if (firstFeature)
					(firstFeature as KMLFeature).debug("ILKML full update add calls: " + ProfilerUtils.stopProfileTimer(time) + " ms");
				_syncManagerFullUpdate.start();
				
			} else {
				if (_syncManager)
				{
					time = ProfilerUtils.startProfileTimer();
//					for each (feature in features)
//					{
//						_syncManager.addCall(feature, updateFeature, [feature, changeFlag]);
//					}
					
					feature = firstFeature as KMLFeature;
					var cnt: int = 0;
					_syncManager.maxCallsPerTick = 1000;
					while (feature)
					{
						_syncManager.addCall(feature, updateFeature, [feature, changeFlag]);
						feature = feature.next as KMLFeature;
						cnt++;
					}
					
					if (firstFeature)
						(firstFeature as KMLFeature).debug("ILKML update add calls: " + ProfilerUtils.stopProfileTimer(time) + " ms. Length: " + cnt);
					_syncManager.start();
				}
				
			}
		}
		
		private function onFullUpdateFinished(event: Event): void
		{
			trace("onFullUpdateFinished");
//			hideLoadingPopup();
		}
		
		private function updateFeature(feature:  KMLFeature, changeFlag: FeatureUpdateContext): void
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
			update(FeatureUpdateContext.fullUpdate());
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
				flag |= FeatureUpdateContext.CRS_CHANGED;
			}
			if (!m_oldViewBBox)
			{
				flag |= FeatureUpdateContext.VIEW_BBOX_MOVED;
				flag |= FeatureUpdateContext.VIEW_BBOX_SIZE_CHANGED;
			} else {
				if (!viewBBox.equals(m_oldViewBBox))
				{
					if (m_oldViewBBox.width == viewBBox.width && m_oldViewBBox.height == viewBBox.height)
						flag |= FeatureUpdateContext.VIEW_BBOX_MOVED;
					else
						flag |= FeatureUpdateContext.VIEW_BBOX_SIZE_CHANGED;
				}
			}
			var updateFlag: FeatureUpdateContext = new FeatureUpdateContext(flag);
			
			//TODO: check visible parts change as well
		
			if (updateFlag.anyChange)
			{
				update(updateFlag);
				trace("ILKML isUpdateNeeded: " + updateFlag.toString());
			}
			
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
