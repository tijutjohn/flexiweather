package com.iblsoft.flexiweather.ogc.kml
{
	import com.iblsoft.flexiweather.ogc.BBox;
	import com.iblsoft.flexiweather.ogc.FeatureUpdateContext;
	import com.iblsoft.flexiweather.ogc.InteractiveLayerFeatureBase;
	import com.iblsoft.flexiweather.ogc.Version;
	import com.iblsoft.flexiweather.ogc.kml.controls.KMLInfoWindow;
	import com.iblsoft.flexiweather.ogc.kml.controls.KMLLabel;
	import com.iblsoft.flexiweather.ogc.kml.data.KMZFile;
	import com.iblsoft.flexiweather.ogc.kml.events.KMLBitmapEvent;
	import com.iblsoft.flexiweather.ogc.kml.events.KMLEvent;
	import com.iblsoft.flexiweather.ogc.kml.events.KMLFeatureEvent;
	import com.iblsoft.flexiweather.ogc.kml.events.NetworkLinkEvent;
	import com.iblsoft.flexiweather.ogc.kml.features.Container;
	import com.iblsoft.flexiweather.ogc.kml.features.Document;
	import com.iblsoft.flexiweather.ogc.kml.features.Folder;
	import com.iblsoft.flexiweather.ogc.kml.features.GroundOverlay;
	import com.iblsoft.flexiweather.ogc.kml.features.KML;
	import com.iblsoft.flexiweather.ogc.kml.features.KML22;
	import com.iblsoft.flexiweather.ogc.kml.features.KMLFeature;
	import com.iblsoft.flexiweather.ogc.kml.features.LineString;
	import com.iblsoft.flexiweather.ogc.kml.features.LinearRing;
	import com.iblsoft.flexiweather.ogc.kml.features.NetworkLink;
	import com.iblsoft.flexiweather.ogc.kml.features.Placemark;
	import com.iblsoft.flexiweather.ogc.kml.features.Polygon;
	import com.iblsoft.flexiweather.ogc.kml.interfaces.IKMLLabeledFeature;
	import com.iblsoft.flexiweather.ogc.kml.managers.KMLPopupManager;
	import com.iblsoft.flexiweather.ogc.kml.managers.KMLResourceManager;
	import com.iblsoft.flexiweather.ogc.kml.renderer.DefaultKMLRenderer;
	import com.iblsoft.flexiweather.ogc.kml.renderer.IKMLRenderer;
	import com.iblsoft.flexiweather.proj.Coord;
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
	import mx.events.DynamicEvent;
	import mx.events.FlexEvent;
	import mx.managers.PopUpManager;

	/**
	 * Interactive Layer for display KML features
	 *
	 * @author fkormanak
	 *
	 */
	public class InteractiveLayerKML extends InteractiveLayerFeatureBase
	{
		private var _visibilityChanged: Boolean;
		override public function set visible(b_visible:Boolean):void
		{
			super.visible = b_visible;
			
//			if (b_visible)
//			{
				_visibilityChanged = true;
				//if layer is displayed again, do full update to recalculate position
				update(FeatureUpdateContext.fullUpdate());
//			}
		}
			
		public var kmzFile: KMZFile;
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
				_itemRendererInstance.featureScale = kmlFeatureScaleX;
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

		[Bindable(event = "kmlChanged")]
		public function get kml(): KML
		{
			return _kml;
		}
		private var m_boundaryRect: Rectangle;
		private var _syncManager: AsyncManager;
		private var _syncManagerFullUpdate: AsyncManager;

		public function InteractiveLayerKML(container: InteractiveWidget, kml: KML, version: Version)
		{
			super(container, version);
			_kml = kml;
			_kml.networkLinkManager.addEventListener(KMLEvent.KML_FILE_LOADED, onNetworkLinkLoadedAndParsed)
			_kml.networkLinkManager.addEventListener(NetworkLinkEvent.NETWORK_LINK_REFRESH, onNetworkLinkRefresh)
//			addEventListener(Event.ENTER_FRAME, onEnterFrame);
			addEventListener(KMLFeatureEvent.KML_FEATURE_CLICK, onKMLFeatureClick, false, EventPriority.DEFAULT_HANDLER, true);
		}

		private function onEnterFrame(event: Event): void
		{
			trace("ILKML tick");
		}

		override protected function createChildren(): void
		{
			super.createChildren();
			if (!_syncManager)
				_syncManager = new AsyncManager('syncManager');
			if (!_syncManagerFullUpdate)
				_syncManagerFullUpdate = new AsyncManager('fullSyncManager');
			
			bmp = new Bitmap();
		}

		override protected function childrenCreated(): void
		{
			super.childrenCreated();
			if (!_syncManager.parent)
			{
				addChild(_syncManager);
				addChild(_screenshot);
				parseKML(_kml);
			}
			if (!_syncManagerFullUpdate.parent)
				addChild(_syncManagerFullUpdate);
			
			addChild(bmp);
			bmp.visible = false;
		}

		/**
		 * this function must be called, when layer is destroying to remove all dependencies and unload or destroy features.
		 *
		 */
		override public function destroy(): void
		{
			if (features)
			{
				unloadFeatures(features.source)
				features = null;
			}
//			super.destroy();
		}

		private function unloadFeatures(featuresForUnloading: Array): void
		{
			while (featuresForUnloading.length > 0)
			{
				var currFeature: KMLFeature = featuresForUnloading.shift() as KMLFeature;
				
				//FIXME we need to have reflectionIDs
				var reflectionID: uint = 0;
				var window: IFlexDisplayObject = KMLPopupManager.getInstance().getPopUpForFeature(currFeature, reflectionID);
				if (window)
					KMLPopupManager.getInstance().removePopUp(window);
				if (canContainFeatures(currFeature))
					unloadContainerFeature(currFeature as Container);
				else
					unloadFeature(currFeature);
			}
		}

		private function onNetworkLinkRefresh(event: NetworkLinkEvent): void
		{
			unloadNetworkLinkFeatures(event.networkLink);
		}

		private function onNetworkLinkLoadedAndParsed(event: KMLEvent): void
		{
			var kml: KML = event.kmlLayerConfiguration.kml as KML
			parseKML(kml);
		}

		private function unloadNetworkLinkFeatures(networkLink: NetworkLink): void
		{
			if (networkLink && networkLink.container && networkLink.container.features && networkLink.container.features.length > 0)
			{
				var featuresArray: Array = networkLink.container.features;
				unloadFeatures(featuresArray);
//				kmlParsingFinished();
				callLater(update, [FeatureUpdateContext.fullUpdate()]);
			}
		}

		private function unloadFeature(currFeature: KMLFeature): void
		{
			if (currFeature is NetworkLink)
				currFeature.kml.networkLinkManager.stopWaitForRefresh(currFeature as NetworkLink);
			itemRendererInstance.dispose(currFeature);
			removeFeature(currFeature);
			_syncManager.removeCall(currFeature);
			_syncManagerFullUpdate.removeCall(currFeature);
			currFeature.next = null;
			currFeature.previous = null;
			currFeature.parentFeature = null;
			currFeature.parentDocument = null;
			currFeature = null;
		}

		private function unloadContainerFeature(kmlContainer: Container): void
		{
			var feature: KMLFeature = kmlContainer.firstFeature as KMLFeature;
			var oldFeature: KMLFeature;
			while (kmlContainer.features.length > 0)
			{
				var currFeature: KMLFeature = kmlContainer.features.shift() as KMLFeature;
				var isContainer: Boolean = canContainFeatures(currFeature);
				if (isContainer)
					unloadContainerFeature(currFeature as Container)
				unloadFeature(currFeature);
			}
		}

		private function parseKML(kml: KML): void
		{
			var rootFeature: KMLFeature = kml.feature;
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

		public function canContainFeatures(feature: KMLFeature): Boolean
		{
			return (feature is Container);
		}

		private function onKMLChildrenFeaturesAdded(event: Event): void
		{
			_syncManager.removeEventListener(AsyncManager.EMPTY, onKMLChildrenFeaturesAdded);
			_syncManager.stop();
			_syncManager.maxCallsPerTick = 50;
			var kmlObj: Object = _syncManager.data;
			kmlObj.children = _childrenFeatures;
			kml.resourceManager.debugCache("after children features are added");
			if (kml.feature is NetworkLink)
			{
				var nl: NetworkLink = kml.feature as NetworkLink;
				for each (var f: KMLFeature in nl.container.features)
				{
					debugFeature(f);
				}
			}
			else
				debugFeature(kml.feature);
			callLater(kmlParsingFinished);
			callLater(update, [FeatureUpdateContext.fullUpdate()]);
		}

		private function debugFeature(feature: KMLFeature): void
		{
			return;
			while (feature)
			{
				if (feature is Container)
					debugFeature((feature as Container).firstFeature);
				feature = feature.next as KMLFeature;
			}
		}
		private var _childrenFeatures: Array;

		private function getChildrenFeatures(kmlContainer: Container): void
		{
			_childrenFeatures = new Array();
			var feature: KMLFeature = kmlContainer.firstFeature as KMLFeature;
			while (feature)
			{
				var childObj: Object = new Object();
				childObj.name = feature.name;
				if (canContainFeatures(feature))
					childObj.children = getChildrenFeatures(Container(feature));
				_childrenFeatures.push(childObj);
				_syncManager.addCall(feature, getChildrenFeatureUpdate, [kmlContainer, feature]);
				feature = feature.next as KMLFeature;
			}
		}

		private function getChildrenFeature(kmlContainer: Container, feature: KMLFeature): void
		{
			var childObj: Object = new Object();
			childObj.name = feature.name;
			if (canContainFeatures(feature))
				childObj.children = getChildrenFeatures(Container(feature));
			_childrenFeatures.push(childObj);
		}

		private function getChildrenFeatureUpdate(kmlContainer: Container, feature: KMLFeature): void
		{
			if (feature.kmlVisibility)
				addFeature(feature, false);
			else
				trace("Feature is not KML visible, do not add it to features");
//			feature.update(FeatureUpdateChange.fullUpdate());
		}

		override public function onMouseRollOver(event: MouseEvent): Boolean
		{
			return (checkKMLFeatureMouseEvent(event, KMLFeatureEvent.KML_FEATURE_ROLL_OVER) != null);
		}

		override public function onMouseRollOut(event: MouseEvent): Boolean
		{
			return (checkKMLFeatureMouseEvent(event, KMLFeatureEvent.KML_FEATURE_ROLL_OUT) != null);
		}

		override public function onMouseMove(event: MouseEvent): Boolean
		{
			var feature: KMLFeature = firstFeature as KMLFeature;
			while (feature)
			{
				if (feature.hitTestPoint(event.stageX, event.stageY, true))
				{
					highlightFeature(feature);
					return true;
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
						m_highlightedFeature.showNormal();
					}
					feature.showHighlight();
					m_highlightedFeature = feature;
					//update graphics
					invalidateDynamicPart();
				}
			}
			else
			{
				if (m_highlightedFeature)
				{
					m_highlightedFeature.showNormal();
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
				ke.reflectionID = -1;
				dispatchEvent(ke);
			}
			return featureClicked != null;
		}

		private function onKMLFeatureClick(event: KMLFeatureEvent): void
		{
			if (!event.isDefaultPrevented())
				openInfoWindow(event.kmlFeature, event.reflectionID);
		}

		private function checkKMLFeatureMouseEvent(event: MouseEvent, dispatchType: String, bDispatchEvent: Boolean = true): KMLFeature
		{
			var feature: KMLFeature = firstFeature as KMLFeature;
			//			for (var i:Number = 0; i < total; i++)
			//			for each (var feature: KMLFeature in features)
//			for each (var feature: KMLFeature in features)
			while (feature)
			{
				if (feature.hitTestPoint(event.stageX, event.stageY, false))
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

		private function openInfoWindow(feature: KMLFeature, reflectionID: int): void
		{
			var kmlPM: KMLPopupManager = KMLPopupManager.getInstance();
			var infoWindow: KMLInfoWindow = kmlPM.getPopUpForFeature(feature, reflectionID) as KMLInfoWindow;
			if (!infoWindow)
			{
				if (reflectionID == -1)
					reflectionID = 0;
				
				infoWindow = new KMLInfoWindow();
				infoWindow.feature = feature;
				infoWindow = kmlPM.addPopUp(infoWindow, FlexGlobals.topLevelApplication as DisplayObject, feature, this.container, reflectionID) as KMLInfoWindow;
				infoWindow.addEventListener(FlexEvent.CREATION_COMPLETE, onInfoWindowCreated);
			} else {
				kmlPM.centerPopUpOnFeature(infoWindow);
			}
		}
			
		private function onInfoWindowCreated(event: FlexEvent): void
		{
			var kmlPM: KMLPopupManager = KMLPopupManager.getInstance();
			
			var infoWindow: KMLInfoWindow = event.target as KMLInfoWindow;
			kmlPM.centerPopUpOnFeature(infoWindow);
		}

		private function updateForFeature(feature: KMLFeature, changeFlag: FeatureUpdateContext, asyncManager: AsyncManager): void
		{
			var startFeature: KMLFeature = feature
			var nl: NetworkLink;
			while (feature)
			{
				asyncManager.addCall(feature, updateFeature, [feature, changeFlag, asyncManager]);
				if (feature is NetworkLink)
					updateForFeature((feature as NetworkLink).container.firstFeature, changeFlag, asyncManager);
				if (feature is Container)
					updateForFeature((feature as Container).firstFeature, changeFlag, asyncManager);
				feature = feature.next as KMLFeature;
			}
		}

		public function update(changeFlag: FeatureUpdateContext): void
		{
			//do not anything if layer is not visiblit
			if (!visible)
			{
				if (_visibilityChanged)
				{
					trace("visibility was recently changed, need to make one update");
				} else {
//					trace("layer is not visible and update() call was at least one time perfomed from visibility change");
					return;
				}
			}
			
			m_boundaryRect = new Rectangle(0, 0, width, height);
			var time: int;
			if (changeFlag.fullUpdateNeeded && _syncManagerFullUpdate)
			{
				_syncManagerFullUpdate.removeEventListener(AsyncManager.EMPTY, onFullUpdateFinished);
				_syncManagerFullUpdate.stop();
				_syncManagerFullUpdate.maxCallsPerTick = 30;
				time = ProfilerUtils.startProfileTimer();
				
				updateForFeature(firstFeature as KMLFeature, changeFlag, _syncManagerFullUpdate);
				
				if (firstFeature)
					(firstFeature as KMLFeature).debug("ILKML full update add calls: " + ProfilerUtils.stopProfileTimer(time) + " ms");
				
				if (_syncManagerFullUpdate.notEmpty)
					_syncManagerFullUpdate.start();
			}
			else
			{
				if (_syncManager)
				{
					time = ProfilerUtils.startProfileTimer();
					_syncManager.maxCallsPerTick = 1000;
					updateForFeature(firstFeature as KMLFeature, changeFlag, _syncManager);
					if (firstFeature)
						(firstFeature as KMLFeature).debug("ILKML update add calls: " + ProfilerUtils.stopProfileTimer(time) + " ms ");
					_syncManager.start();
				}
			}
		}

		private function onFullUpdateFinished(event: Event): void
		{
//			hideLoadingPopup();
		}

		private function updateFeature(feature: KMLFeature, changeFlag: FeatureUpdateContext, asyncManager: AsyncManager): void
		{
//			trace("**********************************************************************************");
//			trace("updateFeature: " + feature.name + " isFullUpdate: " + changeFlag.fullUpdateNeeded);
//			var viewBBox: BBox = container.getViewBBox();
//			if (viewBBox.pointInside(feature.x, feature.y))
//			{
//				
//			} else {
//				
//			}
			feature.featureScale = kmlFeatureScaleX;
			feature.update(changeFlag);
			feature.visible = visible; //  true; //getAbsoluteVisibility(feature);
			
			if (_visibilityChanged)
				_visibilityChanged = false;
//			if (feature is Container)
//			{
//				trace("\t updateFeature call updateForFeature: " + (feature as Container).firstFeature);
//			}
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
			if (object == null)
				return false;
			// check if at least part of object is within m_boundaryRect
			var bounds: Rectangle = object.getBounds(this);
			if (bounds.right < m_boundaryRect.left)
				return false;
			if (bounds.left > m_boundaryRect.right)
				return false;
			if (bounds.bottom < m_boundaryRect.top)
				return false;
			if (bounds.top > m_boundaryRect.bottom)
				return false;
			// analyse chain of visibility flags
			var dispObject: DisplayObject = (object as DisplayObject).parent;
			while (dispObject != null)
			{
				if (!dispObject.visible)
					return false;
				dispObject = dispObject.parent;
			}
			return true;
		}

		override protected function commitProperties():void
		{
			if (_suspendUpdatingChanged)
			{
				if (_suspendUpdating)
				{
					createBitmapPreview();
				} else {
					disposeBitmapPreview();
				}
			}
			super.commitProperties();
			
			if (_suspendUpdating)
			{
				drawImagePartAsBitmap(graphics);
			}
		}
		
		private var bmp: Bitmap;
		
		public function testPan(event: DynamicEvent): void
		{
			var diff: Point = event['pixelsDiff'] as Point;
			bmp.x += diff.x;
			bmp.y += diff.y;
		}
		
		private function drawImagePartAsBitmap(graphics: Graphics): void
		{
			
//			removeVectorData();
			
			
			var ptImageStartPoint: Point = container.coordToPoint(imageStartCoord);
			var ptImageEndPoint: Point = container.coordToPoint(imageEndCoord);
			
			ptImageEndPoint.x += 1;
			ptImageEndPoint.y += 1;
			
			var ptImageSize: Point = ptImageEndPoint.subtract(ptImageStartPoint);
			ptImageSize.x = int(Math.round(ptImageSize.x));
			ptImageSize.y = int(Math.round(ptImageSize.y));
			
			var matrix: Matrix = new Matrix();
			matrix.scale(ptImageSize.x / bmp.width, ptImageSize.y / bmp.height);
			matrix.translate(ptImageStartPoint.x, ptImageStartPoint.y);
			
			graphics.clear();
			graphics.beginBitmapFill(bmp.bitmapData, matrix, true, true);
			graphics.drawRect(ptImageStartPoint.x, ptImageStartPoint.y, ptImageSize.x, ptImageSize.y);
			graphics.endFill();
		} 
		
		private var imageStartCoord: Coord; 
		private var imageEndCoord: Coord; 
		
		private function createBitmapPreview(): void
		{
			var s_imageCRS: String = container.crs;
			var imageBBox: BBox = container.getViewBBox();
			
			imageStartCoord = new Coord(s_imageCRS, imageBBox.xMin, imageBBox.yMax);
			imageEndCoord = new Coord(s_imageCRS, imageBBox.xMax, imageBBox.yMin);
			
			hideAllFeatures();
			bmp.x = 0;
			bmp.y = 0;
			bmp.bitmapData = new BitmapData(width, height, true, 0x00000000);
			bmp.bitmapData.draw(m_featuresContainer); 
//			bmp.visible = true;
		}
		private function disposeBitmapPreview(): void
		{
			bmp.x = 0; 
			bmp.y = 0;
			bmp.bitmapData.dispose();
			bmp.visible = false;
			
			showAllFeatures();
			
		}
		
		override public function onAreaChanged(b_finalChange: Boolean): void
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
			//FIXME this should not be called if panning or zooming is still in progress
			//invalidateDynamicPart();
			if (features && features.length > 0)
			{
				callLater(isUpdateNeeded);
//				callLater(update, [new FeatureUpdateContext(FeatureUpdateContext.FULL_UPDATE)]);
			}
			else
				callLater(isUpdateNeeded);
		}
		public var kmlFeatureScaleX: Number = 1;

		private function countKMLFeaturesZoomBasedOnViewBBox(viewBBox: BBox): Boolean
		{
//			var viewBBox: BBox = container.getViewBBox();
			var extentBBox: BBox = container.getExtentBBox();
			var widthPercentage: Number = viewBBox.width / extentBBox.width;
			var heightPercentage: Number = viewBBox.height / extentBBox.height;
			var newScale: Number
			if (widthPercentage < 0.2)
				newScale = 1;
			else if (widthPercentage > 0.8)
				newScale = 0;
			else
				newScale = (0.8 - widthPercentage) * 1.667;
			var changed: Boolean = (newScale != kmlFeatureScaleX);
			kmlFeatureScaleX = newScale;
			return changed;
		}

		private function isUpdateNeeded(): void
		{
			var crs: String = container.getCRS();
			var viewBBox: BBox = container.getViewBBox();
			var scaleChanged: Boolean = countKMLFeaturesZoomBasedOnViewBBox(viewBBox);
			if (_itemRendererInstance)
				_itemRendererInstance.featureScale = kmlFeatureScaleX;
			var flag: uint = 0;
			if (scaleChanged)
				flag |= FeatureUpdateContext.FEATURE_SCALE_CHANGED;
			if (crs != m_oldCRS)
				flag |= FeatureUpdateContext.CRS_CHANGED;
			if (!m_oldViewBBox)
			{
				flag |= FeatureUpdateContext.VIEW_BBOX_MOVED;
				flag |= FeatureUpdateContext.VIEW_BBOX_SIZE_CHANGED;
			}
			else
			{
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
		{
			return true;
		}

		override public function renderPreview(graphics: Graphics, f_width: Number, f_height: Number): void
		{
			if (!featuresContainer.width || !featuresContainer.height)
				return;
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
			var matrix: Matrix = new Matrix();
			matrix.translate(-f_width / 3, -f_width / 3);
			matrix.scale(3, 3);
			matrix.translate(featuresContainer.width / 3, featuresContainer.height / 3);
			matrix.invert();
			//FIXME - check featuresContainer size (i have size more than 8000px)
			var bd: BitmapData = new BitmapData(featuresContainer.width, featuresContainer.height, true, 0x00000000);
			bd.draw(this);
			clear(graphics);
			graphics.beginBitmapFill(bd, matrix, false, true);
			graphics.drawRect(0, 0, f_width, f_height);
			graphics.endFill();
		}
	}
}
