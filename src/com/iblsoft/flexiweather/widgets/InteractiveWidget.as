package com.iblsoft.flexiweather.widgets
{
	import com.iblsoft.flexiweather.FlexiWeatherConfiguration;
	import com.iblsoft.flexiweather.events.InteractiveLayerEvent;
	import com.iblsoft.flexiweather.events.InteractiveLayerWMSEvent;
	import com.iblsoft.flexiweather.events.InteractiveWidgetEvent;
	import com.iblsoft.flexiweather.ogc.BBox;
	import com.iblsoft.flexiweather.ogc.InteractiveLayerMSBase;
	import com.iblsoft.flexiweather.ogc.cache.WMSCacheManager;
	import com.iblsoft.flexiweather.ogc.data.GlobalVariable;
	import com.iblsoft.flexiweather.ogc.editable.data.FeatureData;
	import com.iblsoft.flexiweather.ogc.editable.data.FeatureDataLine;
	import com.iblsoft.flexiweather.ogc.editable.data.FeatureDataLineSegment;
	import com.iblsoft.flexiweather.ogc.editable.data.FeatureDataReflection;
	import com.iblsoft.flexiweather.ogc.kml.InteractiveLayerKML;
	import com.iblsoft.flexiweather.ogc.multiview.data.SynchronizationChangeType;
	import com.iblsoft.flexiweather.ogc.multiview.synchronization.events.SynchronisationEvent;
	import com.iblsoft.flexiweather.proj.Coord;
	import com.iblsoft.flexiweather.proj.Projection;
	import com.iblsoft.flexiweather.utils.ArrayUtils;
	import com.iblsoft.flexiweather.utils.CubicBezier;
	import com.iblsoft.flexiweather.utils.ICurveRenderer;
	import com.iblsoft.flexiweather.utils.ProfilerUtils;
	import com.iblsoft.flexiweather.utils.anticollision.AnticollisionLayout;
	import com.iblsoft.flexiweather.utils.anticollision.AnticollisionLayoutObject;
	import com.iblsoft.flexiweather.utils.draw.DrawMode;
	import com.iblsoft.flexiweather.utils.draw.FillStyle;
	import com.iblsoft.flexiweather.utils.draw.LineStyle;
	import com.iblsoft.flexiweather.utils.geometry.LineSegment;
	import com.iblsoft.flexiweather.utils.wfs.FeatureSplitter;

	import flash.display.DisplayObject;
	import flash.display.GradientType;
	import flash.display.Graphics;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.events.TimerEvent;
	import flash.external.ExternalInterface;
	import flash.geom.Matrix;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.system.Capabilities;
	import flash.utils.Dictionary;
	import flash.utils.Timer;
	import flash.utils.clearTimeout;
	import flash.utils.getTimer;
	import flash.utils.setTimeout;

	import mx.core.IVisualElement;
	import mx.core.UIComponent;
	import mx.events.DynamicEvent;
	import mx.events.FlexEvent;
	import mx.events.ResizeEvent;

	import spark.components.DataGroup;
	import spark.components.Group;
	import spark.components.supportClasses.GroupBase;
	import spark.events.ElementExistenceEvent;

	[Event(name = "viewBBoxChanged", type = "flash.events.Event")]
	/**
	 * Dispatched, when all layers which were loaded at once are loaded.
	 */
	[Event(name = "allDataLayersLoaded", type = "com.iblsoft.flexiweather.events.InteractiveWidgetEvent")]
	[Event(name = "dataLayerLoadingStarted", type = "com.iblsoft.flexiweather.events.InteractiveWidgetEvent")]
	[Event(name = "dataLayerLoadingFinished", type = "com.iblsoft.flexiweather.events.InteractiveWidgetEvent")]
	[Event(name = "areaChanged", type = "com.iblsoft.flexiweather.events.InteractiveWidgetEvent")]
	[Event(name = "anticollisionUpdated", type = "flash.events.Event")]
	[Event(name = "zoomLevelChanged", type = "com.iblsoft.flexiweather.events.InteractiveLayerQTTEvent")]
	/**
	 *  Dispatched by the component when user click on InteractiveWidget
	 *
	 *  @eventType com.iblsoft.flexiweather.events.InteractiveWidgetEvent.WIDGET_SELECTED
	 *
	 *  @langversion 3.0
	 *  @playerversion Flash 9
	 *  @playerversion AIR 1.1
	 *  @productversion Flex 3
	 */
	[Event(name = "widgetSelected", type = "com.iblsoft.flexiweather.events.InteractiveWidgetEvent")]
	public class InteractiveWidget extends Group
	{
		public static const VIEW_BBOX_CHANGED: String = 'viewBBoxChanged';

		protected function get oldWidgetHeight():Number
		{
			return m_oldWidgetHeight;
		}

		protected function set oldWidgetHeight(value:Number):void
		{
			m_oldWidgetHeight = value;
		}

		protected function get oldWidgetWidth():Number
		{
			return m_oldWidgetWidth;
		}

		protected function set oldWidgetWidth(value:Number):void
		{
			m_oldWidgetWidth = value;
		}

		override public function set id(value:String):void
		{
			super.id = value;
		}

		public function get areaX(): Number
		{
			if (!autoLayoutInParent)
				return 0; //x;
			if (m_widgetBounds && !isNaN(m_widgetBounds.x))
				return m_widgetBounds.x;

			return 0;
		}
		public function get areaY(): Number
		{
			if (!autoLayoutInParent)
				return 0;//y;
			if (m_widgetBounds && !isNaN(m_widgetBounds.y))
				return m_widgetBounds.y;

			return 0;
		}
		public function get areaWidth(): Number
		{
			if (!autoLayoutInParent)
				return width;
			if (m_widgetBounds && !isNaN(m_widgetBounds.width))
				return m_widgetBounds.width;

			return 0;
		}
//		override public function get height():Number
		public function get areaHeight(): Number
		{
			if (!autoLayoutInParent)
				return height;
			if (m_widgetBounds && !isNaN(m_widgetBounds.height))
				return m_widgetBounds.height;

			return 0;
		}
		override public function set x(value:Number):void
		{
			super.x = value;
		}
		override public function set y(value:Number):void
		{
			super.y = value;
		}

		override public function set width(value:Number):void
		{
			super.width = value;
//			if (id == "m_iw1")
//			{
//				debug("Widget size[width]: " + this + " ["+width+","+height+"] ["+explicitWidth+","+explicitHeight+"]");
//			}
			if (m_widgetBounds)
				m_widgetBounds.width = value;
		}

		private var m_widgetBounds: WidgetSize;

		override public function set height(value:Number):void
		{
			super.height = value;
//			if (id == "m_iw1")
//			{
//				debug("Widget size[height]: " + this + " ["+width+","+height+"] ["+explicitWidth+","+explicitHeight+"]");
//			}
			if (m_widgetBounds)
				m_widgetBounds.height = value;
		}

		private var ms_crs: String;
		private var m_crsProjection: Projection;
		private var m_viewBBox: BBox;
		private var m_extentBBox: BBox;
		private var mb_orderingLayers: Boolean = false;
		private var mb_autoLayout: Boolean = false;
		private var mb_backgroundChessBoard: Boolean = true;
		private var m_resizeTimer: Timer;
		private var m_layerBackground: UIComponent;
		private var m_layerContainer: Group = new Group();
		private var m_layerLayoutParent: UIComponent;
		private var m_lastResizeTime: Number;
		private var m_wmsCacheManager: WMSCacheManager;

		//variable for drawing viewport
		private var mi_viewportXAxisMarginPixels: int = 30;
		private var mi_viewportYAxisMarginPixels: int = 30;
		private var m_viewBBoxWestLine: LineSegment;
		private var m_viewBBoxEastLine: LineSegment;
		private var m_viewBBoxNorthLine: LineSegment;
		private var m_viewBBoxSouthLine: LineSegment;


		/**
		 * anticollision layout for Labels
		 */
		private var m_labelLayout: AnticollisionLayout;

		/**
		 * anticollision layout for Labels
		 */
		private var m_objectLayout: AnticollisionLayout;

		/**
		 * Set it to true when you want suspend anticaollision processing (e.g. user is dragging map)
		 */
		private var m_suspendAnticollisionProcessing: Boolean;
		private var _enableMouseClick: Boolean;
		private var _enableMouseMove: Boolean;
		private var _enableMouseWheel: Boolean;
		private var _enableGestures: Boolean;

		/**
		 * Helper variable, if usedForIcon == true, it's used for interactive icon (e.g. menu icon)
		 */
		public var usedForIcon: Boolean;

		override public function set enabled(value: Boolean): void
		{
			super.enabled = value;
			invalidateDisplayList();
		}

		public function get enableMouseClick(): Boolean
		{
			return _enableMouseClick;
		}

		public function set enableMouseClick(value: Boolean): void
		{
			_enableMouseClick = value;
		}

		public function get enableMouseMove(): Boolean
		{
			return _enableMouseMove;
		}

		public function set enableMouseMove(value: Boolean): void
		{
			_enableMouseMove = value;
		}

		public function get enableMouseWheel(): Boolean
		{
			return _enableMouseWheel;
		}

		public function set enableMouseWheel(value: Boolean): void
		{
			_enableMouseWheel = value;
		}

		public function get enableGestures(): Boolean
		{
			return _enableGestures;
		}

		public function set enableGestures(value: Boolean): void
		{
			_enableGestures = value;
		}

		public function get frame(): Date
		{
			if (interactiveLayerMap && interactiveLayerMap.primaryLayer)
			{
				return interactiveLayerMap.primaryLayer.getSynchronisedVariableValue(GlobalVariable.FRAME) as Date;
			}
			return null;
		}

		public var kmlSpeedOptimization: KMLSpeedOptimization;

		public function InteractiveWidget(bUsedForIcon: Boolean = false)
		{
			super();

			kmlSpeedOptimization = new KMLSpeedOptimization(this);
			m_widgetBounds = new WidgetSize();

			usedForIcon = bUsedForIcon;

			m_labelLayout = new AnticollisionLayout('Label Layout', this);
			m_objectLayout = new AnticollisionLayout('Object Layout', this);

			m_featureSplitter = new FeatureSplitter(this);

			enableGestures = true;
			enableMouseClick = true;
			enableMouseMove = true;
			enableMouseWheel = true;
			mouseEnabled = true;
			mouseFocusEnabled = true;
			doubleClickEnabled = true;
			clipAndEnableScrolling = true;

			m_layerContainer.mouseEnabled = false;


			addEventListener(MouseEvent.MOUSE_DOWN, onMouseDown);
			addEventListener(MouseEvent.MOUSE_UP, onMouseUp);
			addEventListener(MouseEvent.MOUSE_MOVE, onMouseMove);
			addEventListener(MouseEvent.MOUSE_WHEEL, onMouseWheel);
			addEventListener(MouseEvent.CLICK, onMouseClick);
			addEventListener(MouseEvent.DOUBLE_CLICK, onMouseDoubleClick);
			addEventListener(MouseEvent.ROLL_OVER, onMouseRollOver);
			addEventListener(MouseEvent.ROLL_OUT, onMouseRollOut);
			addEventListener(ResizeEvent.RESIZE, onResized);
			addEventListener(ElementExistenceEvent.ELEMENT_ADD, onElementAdd);
			addEventListener(FlexEvent.CREATION_COMPLETE, onWidgetCreationComplete);
			addEventListener(Event.ENTER_FRAME, onWidgetEnterFrame);
			m_lastResizeTime = getTimer();

			initializeDefaultProjection();
		}

		/**
		 * Debug function to test what is executed between frames. This function just write "NEW FRAME" to console.
		 * @param event
		 *
		 */
		private function onWidgetEnterFrame(event: Event): void
		{
//			debug("NEW TICK");
			//we want to force mouse move event to be executed just once per frame
			if (_mouseMoveExecuted)
			{
				_mouseMoveExecuted = false;
//				debug("Commit properties: _mouseMoveExecuted = " + _mouseMoveExecuted);
			}
		}
		private function initializeDefaultProjection(): void
		{
			ms_crs = Projection.CRS_GEOGRAPHIC;
			m_crsProjection = Projection.getByCRS(ms_crs);
			m_viewBBox = new BBox(-180, -90, 180, 90);
			m_extentBBox = m_crsProjection.extentBBox;

		}

		public function destroy(): void
		{
			removeEventListener(MouseEvent.MOUSE_DOWN, onMouseDown);
			removeEventListener(MouseEvent.MOUSE_UP, onMouseUp);
			removeEventListener(MouseEvent.MOUSE_MOVE, onMouseMove);
			removeEventListener(MouseEvent.MOUSE_WHEEL, onMouseWheel);
			removeEventListener(MouseEvent.CLICK, onMouseClick);
			removeEventListener(MouseEvent.DOUBLE_CLICK, onMouseDoubleClick);
			removeEventListener(MouseEvent.ROLL_OVER, onMouseRollOver);
			removeEventListener(MouseEvent.ROLL_OUT, onMouseRollOut);
			removeEventListener(ResizeEvent.RESIZE, onResized);
			removeEventListener(ElementExistenceEvent.ELEMENT_ADD, onElementAdd);
			removeEventListener(FlexEvent.CREATION_COMPLETE, onWidgetCreationComplete);
			m_labelLayout.destroy();
			m_objectLayout.destroy();
			if (m_resizeTimer)
			{
				m_resizeTimer.stop();
				m_resizeTimer.removeEventListener(TimerEvent.TIMER_COMPLETE, callDelayedResize);
			}
			m_featureSplitter.destroy();
		}

		override protected function createChildren(): void
		{
			super.createChildren();
			m_layerBackground = new UIComponent();
			m_layerLayoutParent = new UIComponent();

			m_layerContainer.id = "LayerContainer: " + id
		}

		override protected function childrenCreated(): void
		{
			super.childrenCreated();
			addElement(m_layerBackground);
			addElement(m_layerContainer);
			addElement(m_layerLayoutParent);
			m_layerLayoutParent.addChild(m_labelLayout);

			for each (var layer: InteractiveLayer in _mxmlContentElements)
			{
				addLayer(layer);
			}

			m_layerContainer.x = m_layerContainer.y = 0;
		}

		override protected function commitProperties(): void
		{
			super.commitProperties();

			if (m_suspendDataUpdatingChanged)
			{
				debug("commitProperties m_suspendDataUpdatingChanged");
				var layersCount: int = m_layerContainer.numElements;
				for (var i : int = 0; i < layersCount; i++)
				{
					var l: InteractiveLayer = m_layerContainer.getElementAt(i) as InteractiveLayer;
					if (l is InteractiveDataLayer)
						(l as InteractiveDataLayer).suspendDataUpdating = m_suspendDataUpdating;
				}
				m_suspendDataUpdatingChanged = false;
			}
			if (_forceAnticollisionUpdate)
			{
				notifyAnticollisionUpdate();
				m_labelLayout.invalidateLayout();
				notifyAnticollisionUpdate();
				m_objectLayout.invalidateLayout();

				_forceAnticollisionUpdate = false;
			}

			if (mb_autoLayoutChanged)
			{
//				var widgetParent: DataGroup = parent as DataGroup;
				var widgetParent: GroupBase = parent as GroupBase;
				if (widgetParent)
				{
//					debug(this + " mb_autoLayoutChanged: addEventListener(ResizeEvent.RESIZE, onParentResize) ");
					if (mb_autoLayout)
					{
						if (!widgetParent.hasEventListener(ResizeEvent.RESIZE))
							widgetParent.addEventListener(ResizeEvent.RESIZE, onParentResize);
					} else {
						widgetParent.removeEventListener(ResizeEvent.RESIZE, onParentResize);
					}

					updateAreaSize();
					updateLayersBounds();
				}
				mb_autoLayoutChanged = false;
			}



			if (_layersOrderChanged)
			{
				orderLayers();
				_layersOrderChanged = false;
			}
		}
		private var _resizeInterval: Number;

		private function onParentResize(event: ResizeEvent): void
		{
			clearTimeout(_resizeInterval);
			//wait 1 second before resing (if there is another resize event)
			var resizeMinimumTime: Number = 1000; //1000ms
			var currTime: Number = getTimer();
			if ((currTime - m_lastResizeTime) >= resizeMinimumTime)
			{
				m_lastResizeTime = currTime;
				autoLayoutViewBBox(m_viewBBox, true, true);
			}
			else
			{
				//uto layout but do not load layers (finalUpdate = false)
				autoLayoutViewBBox(m_viewBBox, false, true);
				_resizeInterval = setTimeout(autoLayoutViewBBox, (currTime - m_lastResizeTime), m_viewBBox, true, true);
			}
		}

		/**
		 * All elements, which are InteractiveLayer, added before CREATION_COMPLETE (check @onElementAdd function) are stored
		 * and in this function are added as new layer.
		 * This fix added InteractiveLayer through MXML. (like InteractiveLayerZoom and InteractiveLayerPan and similar interactice layers)
		 *
		 * @param event
		 *
		 */
		private function onWidgetCreationComplete(event: FlexEvent): void
		{
//			for each (var layer: InteractiveLayer in _mxmlContentElements)
//			{
//				addLayer(layer);
//			}
		}
		private var _mxmlContentElements: Array = [];

		/**
		 * This function is called when new element is added to widget. All elements, which are InteractiveLayer,
		 * added before CREATION_COMPLETE are stored and in function onWidgetCreationComplete are added as new layer.
		 * This fix added InteractiveLayer through MXML. (like InteractiveLayerZoom and InteractiveLayerPan and similar interactice layers)
		 *
		 * @param event
		 *
		 */
		private function onElementAdd(event: ElementExistenceEvent): void
		{
			if (event.element is InteractiveLayer)
			{
				_mxmlContentElements.push(event.element as InteractiveLayer);
				(event.element as InteractiveLayer).container = this;
			}
		}

		public function get numLayers(): int
		{
			if (m_layerContainer)
				return m_layerContainer.numElements;
			return 0;
		}

		/**
		 * Function returns first layer of requested type
		 *
		 * @param classType
		 * @return
		 *
		 */
		public function getLayerByType(classType: Class): InteractiveLayer
		{
			var total: int = m_layerContainer.numElements;
			for (var i: int = 0; i < total; i++)
			{
				var l: InteractiveLayer = m_layerContainer.getElementAt(i) as InteractiveLayer;
				if (l && l is classType)
					return l;
			}
			return null;
		}

		public function getLayerAt(position: int): InteractiveLayer
		{
			if (position < m_layerContainer.numElements)
				return m_layerContainer.getElementAt(position) as InteractiveLayer;
			return null;
		}

		public override function addElement(element: IVisualElement): IVisualElement
		{
			if (element is InteractiveLayer)
			{
				// InteractiveLayer based child are added to m_layerContainer
				InteractiveLayer(element).container = this; // this also ensures that child is InteractiveLayer
				element.width = width;
				element.height = height;
				var o: IVisualElement = m_layerContainer.addElement(element);
				orderLayers();
				return o;
			}
			else
				return super.addElement(element);
		}

		public override function addElementAt(element: IVisualElement, index: int): IVisualElement
		{
			if (element is InteractiveLayer)
			{
				// InteractiveLayer based child are added to m_layerContainer
				InteractiveLayer(element).container = this; // this also ensures that element is InteractiveLayer
				element.x = x;
				element.y = y;
				element.width = width;
				element.height = height;
				var o: IVisualElement = m_layerContainer.addElementAt(element, index);
				invalidateLayersOrder();
				return o;
			}
			else
				return super.addElementAt(element, index);
		}

		private var m_layersLoading: int = 0;

		private function onLayerLoadingStart(event: InteractiveLayerEvent): void
		{
//			m_layersLoading++;
			updateLayersLoadingState();

//			debug(this + "IW onLayerLoadingStart: " + m_layersLoading);

			var ile: InteractiveWidgetEvent = new InteractiveWidgetEvent(InteractiveWidgetEvent.DATA_LAYER_LOADING_STARTED);
			ile.layersLoading = m_layersLoading;
			dispatchEvent(ile);
		}

		private function updateLayersLoadingState(): void
		{
			m_layersLoading = 0;
			if (interactiveLayerMap)
			{
				var total: int = interactiveLayerMap.layers.length;
				for (var i: int = 0; i < total; i++)
				{
					var layer: InteractiveDataLayer = interactiveLayerMap.layers.getItemAt(i) as InteractiveDataLayer;
					if (layer.status == InteractiveDataLayer.STATE_LOADING_DATA)
						m_layersLoading++;
				}
			}
		}
		private function onLayerLoaded(event: InteractiveLayerEvent): void
		{
//			m_layersLoading--;
			updateLayersLoadingState();
//			debug(this + " onLayerLoaded: " + m_layersLoading);
			notifyLayerLoaded();
		}
		private function onLayerLoadedFromCache(event: InteractiveLayerEvent): void
		{
//			m_layersLoading--;
			updateLayersLoadingState();
//			debug(this + " onLayerLoadedFromCache: " + m_layersLoading);
			notifyLayerLoaded();
		}

		private function notifyLayerLoaded(): void
		{
			var ile: InteractiveWidgetEvent;
			ile = new InteractiveWidgetEvent(InteractiveWidgetEvent.DATA_LAYER_LOADING_FINISHED);
			ile.layersLoading = m_layersLoading;
			dispatchEvent(ile);

			var bAllLayersLoaded: Boolean = false;
			if (m_layersLoading <= 0)
				bAllLayersLoaded = true;

			if (bAllLayersLoaded)
			{
//				debug("\t"+this + " IW onLayerLoaded ALL_DATA_LAYERS_LOADED: " + m_layersLoading);
				ile = new InteractiveWidgetEvent(InteractiveWidgetEvent.ALL_DATA_LAYERS_LOADED);
				dispatchEvent(ile);
			}
		}

		private function onLayerInInteractiveLayerMapAdded(event: DynamicEvent): void
		{
			notifyWidgetChanged(SynchronizationChangeType.MAP_LAYER_ADDED, this);
		}

		private function onLayerInInteractiveLayerMapRemoved(event: DynamicEvent): void
		{
			notifyWidgetChanged(SynchronizationChangeType.MAP_LAYER_REMOVED, this);
		}

		private function onInteractiveLayerMapAnimatorSettingsChanged(event: Event): void
		{
			notifyWidgetChanged(SynchronizationChangeType.ANIMATOR_SETTINGS_CHANGED, event.target);
		}

		private function onLayerChangedInInteractiveLayerMap(event: Event): void
		{
			if (event.type == SynchronisationEvent.START_GLOBAL_VARIABLE_SYNCHRONIZATION || event.type == SynchronisationEvent.STOP_GLOBAL_VARIABLE_SYNCHRONIZATION)
			{
				notifyWidgetChanged(SynchronizationChangeType.SYNCHRONIZE_LEVEL_CHANGED, event.target);
				notifyWidgetChanged(SynchronizationChangeType.SYNCHRONIZE_RUN_CHANGED, event.target);
			}

			if (event.type == InteractiveLayerWMSEvent.WMS_STYLE_CHANGED)
				notifyWidgetChanged(SynchronizationChangeType.WMS_STYLE_CHANGED, event.target);

			if (event.type == InteractiveLayerWMSEvent.LEVEL_CHANGED)
				notifyWidgetChanged(SynchronizationChangeType.LEVEL_CHANGED, event.target);
			if (event.type == InteractiveLayerWMSEvent.RUN_CHANGED)
				notifyWidgetChanged(SynchronizationChangeType.RUN_CHANGED, event.target);

			if (event.type == InteractiveLayerEvent.ALPHA_CHANGED)
				notifyWidgetChanged(SynchronizationChangeType.ALPHA_CHANGED, event.target);
			if (event.type == InteractiveLayerEvent.VISIBILITY_CHANGED)
				notifyWidgetChanged(SynchronizationChangeType.VISIBILITY_CHANGED, event.target);
		}

		private function registerInteractiveLayerMap(ilm: InteractiveLayerMap): void
		{
			if (ilm)
			{
				ilm.addEventListener(SynchronisationEvent.START_GLOBAL_VARIABLE_SYNCHRONIZATION, onLayerChangedInInteractiveLayerMap);
				ilm.addEventListener(SynchronisationEvent.STOP_GLOBAL_VARIABLE_SYNCHRONIZATION, onLayerChangedInInteractiveLayerMap);
				ilm.addEventListener(InteractiveLayerEvent.ALPHA_CHANGED, onLayerChangedInInteractiveLayerMap);
				ilm.addEventListener(InteractiveLayerEvent.VISIBILITY_CHANGED, onLayerChangedInInteractiveLayerMap);
				ilm.addEventListener(InteractiveLayerWMSEvent.WMS_STYLE_CHANGED, onLayerChangedInInteractiveLayerMap);
				ilm.addEventListener(InteractiveLayerWMSEvent.LEVEL_CHANGED, onLayerChangedInInteractiveLayerMap);
				ilm.addEventListener(InteractiveLayerWMSEvent.RUN_CHANGED, onLayerChangedInInteractiveLayerMap);

				ilm.addEventListener(InteractiveLayerMap.TIMELINE_CONFIGURATION_CHANGE, onInteractiveLayerMapAnimatorSettingsChanged);
				ilm.addEventListener(InteractiveLayerMap.LAYER_ADDED, onLayerInInteractiveLayerMapAdded);
				ilm.addEventListener(InteractiveLayerMap.LAYER_REMOVED, onLayerInInteractiveLayerMapRemoved);
			}
		}

		private function unregisterInteractiveLayerMap(ilm: InteractiveLayerMap): void
		{
			if (ilm)
			{
				ilm.removeEventListener(SynchronisationEvent.START_GLOBAL_VARIABLE_SYNCHRONIZATION, onLayerChangedInInteractiveLayerMap);
				ilm.removeEventListener(SynchronisationEvent.STOP_GLOBAL_VARIABLE_SYNCHRONIZATION, onLayerChangedInInteractiveLayerMap);
				ilm.removeEventListener(InteractiveLayerEvent.ALPHA_CHANGED, onLayerChangedInInteractiveLayerMap);
				ilm.removeEventListener(InteractiveLayerEvent.VISIBILITY_CHANGED, onLayerChangedInInteractiveLayerMap);
				ilm.removeEventListener(InteractiveLayerWMSEvent.WMS_STYLE_CHANGED, onLayerChangedInInteractiveLayerMap);
				ilm.removeEventListener(InteractiveLayerWMSEvent.LEVEL_CHANGED, onLayerChangedInInteractiveLayerMap);
				ilm.removeEventListener(InteractiveLayerWMSEvent.RUN_CHANGED, onLayerChangedInInteractiveLayerMap);

				ilm.addEventListener(InteractiveLayerMap.TIMELINE_CONFIGURATION_CHANGE, onInteractiveLayerMapAnimatorSettingsChanged);
				ilm.removeEventListener(InteractiveLayerMap.LAYER_ADDED, onLayerInInteractiveLayerMapAdded);
				ilm.removeEventListener(InteractiveLayerMap.LAYER_REMOVED, onLayerInInteractiveLayerMapRemoved);
			}
		}

		private function setInteractiveLayerMap(ilm: InteractiveLayerMap): void
		{
			unregisterInteractiveLayerMap(m_interactiveLayerMap);
			m_interactiveLayerMap = ilm;
			registerInteractiveLayerMap(m_interactiveLayerMap);
			notifyInteractiveLayerMapChanged();
		}

		private function notifyInteractiveLayerMapChanged(): void
		{
			dispatchEvent(new Event('interactiveLayerMapChanged'));
		}
		private var _tempLayersForInteractiveLayerMap: Array;

		public function addLayer(l: InteractiveLayer, index: int = -1): void
		{
//			debug("addLayer: " + l);
			l.addEventListener(InteractiveDataLayer.LOADING_FINISHED, onLayerLoaded);
			l.addEventListener(InteractiveDataLayer.LOADING_FINISHED_FROM_CACHE, onLayerLoadedFromCache);
			l.addEventListener(InteractiveDataLayer.LOADING_STARTED, onLayerLoadingStart);
			l.addEventListener(InteractiveLayerEvent.LAYER_INITIALIZED, onLayerInitialized);
//			var bAddLayer: Boolean = false;

			//all map data layer have to go to interactiveLayerMap, all others just to interactiveWidget
			if (l is InteractiveLayerMap)
				setInteractiveLayerMap(l as InteractiveLayerMap);

			if (l is InteractiveLayerPan)
				kmlSpeedOptimization.setPanLayer(l as InteractiveLayerPan);
			if (l is InteractiveLayerZoom)
				kmlSpeedOptimization.setZoomLayer(l as InteractiveLayerZoom);

			if (l is InteractiveLayerKML)
				kmlSpeedOptimization.addKMLLayer(l as InteractiveLayerKML)


			l.container = this;
			if (index >= 0)
				addElementAt(l, index);
			else
				addElement(l);
			l.onAreaChanged(true);
			//all other functionality will be done after layer will be initialized in onLayerInitialized function
		}

		private function onLayerInitialized(event: InteractiveLayerEvent): void
		{
			var l: InteractiveLayer = event.target as InteractiveLayer;

			//TODO we need to check if layer is synchronizable and call this when it will be ready for synchronization
			//when new layer is added to container, call onAreaChange to notify layer, that layer is already added to container, so it can render itself
			l.onAreaChanged(true);


			invalidateLayersOrder();

			if (l is InteractiveLayerMSBase)
				notifyWidgetChanged(SynchronizationChangeType.MAP_LAYER_ADDED, this);
			else
				debug(this + " onLayerInitialized do not notify widget, because it's not WMS layer");
		}

		public function removeLayer(l: InteractiveLayer, b_destroy: Boolean = false): void
		{
			debug("removeLayer: " + l);
			if (l is InteractiveLayerMap && m_interactiveLayerMap == l)
				setInteractiveLayerMap(null);
			l.removeEventListener(InteractiveDataLayer.LOADING_FINISHED, onLayerLoaded);
			l.removeEventListener(InteractiveDataLayer.LOADING_FINISHED_FROM_CACHE, onLayerLoadedFromCache);
			l.removeEventListener(InteractiveDataLayer.LOADING_STARTED, onLayerLoadingStart);
			if (l.parent == m_layerContainer)
			{
				m_layerContainer.removeElement(l);
				if (b_destroy)
					l.destroy();
				l.container = null;
			}
			notifyWidgetChanged(SynchronizationChangeType.MAP_LAYER_REMOVED, this);
		}

		public function removeAllLayers(): void
		{
			debug("removeAllLayers" );
			while (m_layerContainer.numElements)
			{
				var i: int = m_layerContainer.numElements - 1;
				var l: InteractiveLayer = InteractiveLayer(m_layerContainer.getElementAt(i));
				l.removeEventListener(InteractiveDataLayer.LOADING_FINISHED, onLayerLoaded);
				l.removeEventListener(InteractiveDataLayer.LOADING_FINISHED_FROM_CACHE, onLayerLoadedFromCache);
				l.removeEventListener(InteractiveDataLayer.LOADING_STARTED, onLayerLoadingStart);
				l.destroy();
				m_layerContainer.removeElementAt(i);
			}
		}

		private var _layersOrderChanged: Boolean;
		public function invalidateLayersOrder(): void
		{
			if (!_layersOrderChanged)
			{
				_layersOrderChanged = true;
				invalidateProperties();
			}
		}

		private function debugLayers(): void
		{
			return;
			var total: int = m_layerContainer.numElements;
			if (total > 1)
			{
				debug("******************************************************");
				debug("IW debug layers");
				var displayObject: DisplayObject;
				var layerObject: DisplayObject;
				for (var i: int = 0; i < total; ++i)
				{
					displayObject = m_layerContainer.getElementAt(i) as DisplayObject;
					debug("\tIW["+i+"] " + displayObject);

					if (displayObject is InteractiveLayerMap)
					{
						var im: InteractiveLayerMap = displayObject as InteractiveLayerMap;
						var totalMapLayers: int = im.numChildren;
						for (var j: int = 0; j < totalMapLayers; j++)
						{
							layerObject = im.getLayerAt(j) as DisplayObject;
							debug("\tIW["+i+"] " + layerObject + " parent: " + layerObject.parent);
						}
					}
				}
			}
		}
		private function orderLayers(): void
		{
			if (mb_orderingLayers)
				return;

			mb_orderingLayers = true;
			try
			{
				// stable-sort interactive layers in ma_layers according to their zOrder property
				var displayObject: DisplayObject;
				for (var i: int = 0; i < m_layerContainer.numElements; ++i)
				{
					displayObject = m_layerContainer.getElementAt(i) as DisplayObject;
					var ilI: InteractiveLayer = InteractiveLayer(displayObject);
					for (var j: int = i + 1; j < m_layerContainer.numElements; ++j)
					{
						displayObject = m_layerContainer.getElementAt(j) as DisplayObject;
						var ilJ: InteractiveLayer = InteractiveLayer(displayObject);
						if (ilJ.zOrder < ilI.zOrder)
						{
							// swap Ith and Jth layer, we know that J > I
//							debug("\nswap layers " + ilJ.name + " , " + ilI.name);
							m_layerContainer.swapElements(ilJ, ilI);
						}
					}
				}
			}
			catch (error: Error)
			{
				debug("InteractiveLayer.orderLayer: catch: " + error.message);
			}
			finally
			{
				mb_orderingLayers = false;
			}
			if (interactiveLayerMap)
				interactiveLayerMap.invalidateLayersOrder();

			debugLayers();
		}
		private var _disableUI: UIComponent;

		private function drawDisabledState(): void
		{
			if (!_disableUI)
			{
				_disableUI = new Group();
				addElement(_disableUI);
			}
			_disableUI.includeInLayout = true;
			_disableUI.visible = true;
			var g: Graphics = _disableUI.graphics;
			g.clear();
			g.beginFill(0, 0.5);
			g.drawRect(0, 0, unscaledWidth, unscaledHeight);
			g.endFill()
		}

		override protected function updateDisplayList(unscaledWidth: Number, unscaledHeight: Number): void
		{
			if (isNaN(unscaledWidth) || isNaN(unscaledHeight))
			{
				//when user press Cancel on printing interactiveWidget, both sizes was NaN
				return;
			}

			if (m_widgetBounds)
			{
				if (isNaN(m_widgetBounds.width))
				{
					m_widgetBounds.width = unscaledWidth;
					m_widgetBounds.height = unscaledHeight;
				}
				var w: Number = width; //m_widgetBounds.width;
				var h: Number = height; //m_widgetBounds.height;
				if (m_layerContainer.width != w || m_layerContainer.height != h)
				{
//					m_layerContainer.width = w;
//					m_layerContainer.height = h;
					if (m_labelLayout.m_placementBitmap == null)
						m_labelLayout.setBoundary(new Rectangle(0, 0, w, h));

					var bDrawDisableState: Boolean = !enabled;
					if (_enableSynchronization)
						bDrawDisableState = bDrawDisableState && !mb_listenForChanges;

					if (bDrawDisableState)
					{
						drawDisabledState();
		//				return;
					}
					else
					{
						if (_disableUI)
						{
							_disableUI.graphics.clear();
							_disableUI.includeInLayout = false;
							_disableUI.visible = false;
						}
					}
					anticollisionUpdate();
				}
					var g: Graphics = m_layerBackground.graphics;
					g.clear();
					if (mb_backgroundChessBoard)
					{
						var i_squareSize: uint = 10;
						var i_row: uint = 0;
						if (width > 0 && height > 0 && g)
						{
							for (var y: uint = 0; y < height; y += i_squareSize, ++i_row)
							{
								var b_flag: Boolean = (i_row & 1) != 0;
								for (var x: uint = 0; x < width; x += i_squareSize)
								{
									g.beginFill(b_flag ? 0xc0c0c0 : 0x808080);
									g.drawRect(x, y, i_squareSize, i_squareSize);
									g.endFill();
									b_flag = !b_flag;
								}
							}
						}
					}
					else
					{
						var matrix: Matrix = new Matrix();
						matrix.rotate(90);
						g.beginGradientFill(GradientType.LINEAR, [0xAAAAAA, 0xFFFFFF], [1, 1], [0, 255], matrix);
						g.drawRect(0, 0, width, height);
						g.endFill();
					}
					//TODO: uncomment next if statement if you want display label layout placement bitmap
					if (m_labelLayout.m_placementBitmap)
						m_labelLayout.drawDebugPlacementBitmap(g);
					if (m_objectLayout.m_placementBitmap)
						m_objectLayout.drawDebugPlacementBitmap(g);
					super.updateDisplayList(unscaledWidth, unscaledHeight);
//				}
			}
		}

		protected function signalAreaChanged(b_finalChange: Boolean): void
		{
			onAreaChanged(b_finalChange);
		}
		private var _oldViewBBox: BBox = new BBox(0,0,0,0);

		protected function onAreaChanged(b_finalChange: Boolean): void
		{
			var areaChanged: Boolean = true;
			if (_oldViewBBox.equals(m_viewBBox))
			{
				areaChanged = false;
				if (!b_finalChange)
					return;
			}
			for (var i: int = 0; i < m_layerContainer.numElements; ++i)
			{
				var l: InteractiveLayer = InteractiveLayer(m_layerContainer.getElementAt(i));
				if (l.onAreaChanged(b_finalChange))
					break;
				if (!l.isDynamicPartInvalid())
					l.invalidateDynamicPart();
			}
			setAnticollisionLayoutsDirty();
			_oldViewBBox = m_viewBBox.clone();

//			debug(this + " area: " + m_viewBBox.toBBOXString());

			if (areaChanged || (!areaChanged && b_finalChange))
			{
				//dispatch area change event
				var iwe: InteractiveWidgetEvent = new InteractiveWidgetEvent(InteractiveWidgetEvent.AREA_CHANGED);
				iwe.finalChange = b_finalChange;
				dispatchEvent(iwe);
//			} else {
//				debug(this + " onAreaChanged but are is not changed: " + m_viewBBox.toBBOXString());
			}
		}

		private function setAnticollisionLayoutsDirty(): void
		{
			m_objectLayout.areaChanged(m_viewBBox);
			m_objectLayout.setDirty();
			m_labelLayout.areaChanged(m_viewBBox);
			m_labelLayout.setDirty();
		}

		internal function onLayerVisibilityChanged(layer: InteractiveLayer): void
		{
			setAnticollisionLayoutsDirty();
		}

		/**
		 * Return reflection delta of point on screen
		 *
		 * @param x
		 * @param y
		 * @return
		 *
		 */
		public function pointReflection(x: Number, y: Number): int
		{
			var c: Coord = pointToCoord(x, y);
			var reflectedCoords: Array = mapCoordInCRSToViewReflections(new Point(c.x, c.y));
			if (reflectedCoords.length == 1)
				return reflectedCoords[0].reflection;

			return 0;
		}

		public function viewBBoxReflections(): Array
		{
			//check left and right edges
//			var leftCoord: Coord = new Coord(crs, m_viewBBox.xMin, m_viewBBox.yMin);
//			var rightCoord: Coord = new Coord(crs, m_viewBBox.xMax, m_viewBBox.yMin);

			var reflectedLeftCoords: Array = mapCoordInCRSToViewReflections(new Point(m_viewBBox.xMin, m_viewBBox.yMin));
			var reflectedRightCoords: Array = mapCoordInCRSToViewReflections(new Point(m_viewBBox.xMax, m_viewBBox.yMin));

			ArrayUtils.unionArrays(reflectedLeftCoords, reflectedRightCoords);

			var reflectionDeltas: Array = [];
			for each (var reflObject: Object in reflectedLeftCoords)
			{
				var currReflectionDelta: int = reflObject.reflection;
				var existingID: int = reflectionDeltas.indexOf(currReflectionDelta);
				if (existingID == -1)
					reflectionDeltas.push(currReflectionDelta);
			}

			reflectionDeltas.sort();

			return reflectionDeltas;
		}

		/** Converts screen point (pixels) into Coord with current CRS. */
		public function pointToCoord(x: Number, y: Number): Coord
		{
			var w: Number = areaWidth;
			var h: Number = areaHeight;

			var cx: Number = x * m_viewBBox.width / (w - 1) + m_viewBBox.xMin;
			var cy: Number = (h - 1 - y) * m_viewBBox.height / (h - 1) + m_viewBBox.yMin;
			return new Coord(ms_crs, cx , cy);
		}

		/**
		 *
		 * @param p1
		 * @param p2
		 * @param extent if null it will get actual extent. You can provide extent to optimize performance
		 * @return
		 *
		 */
		public function coordsFarThanExtentWidth(p1: Coord, p2: Coord, extent: BBox = null): Boolean
		{
			var projExtent: BBox = m_crsProjection.extentBBox;
			var bIsFar: Boolean = (Math.abs(p1.x - p2.x) > projExtent.width / 2);
			return bIsFar;
		}
		public function pointsFarThanExtentWidth(p1: Point, p2: Point, extent: BBox = null): Boolean
		{
			var extentWidthInPixels: Number = getProjectionWidthInPixels();
			var bIsFar: Boolean = (Math.abs(p1.x - p2.x) > extentWidthInPixels / 2);
			return bIsFar;
		}

		/**
		 * Helper function, which finds out if there is dateline between two points
		 * @param p1
		 * @param p2
		 * @return
		 *
		 */
		public function crossDateline(p1: Point, p2: Point): Boolean
		{
			var leftX: Number = m_crsProjection.extentBBox.xMin;
			var rightX: Number = m_crsProjection.extentBBox.xMax;
			var projWidthHalf: Number = m_crsProjection.extentBBox.width / 2;

			var p1x: Number = Math.min(p1.x, p2.x);
			var p2x: Number = Math.max(p1.x, p2.x);


			if (p1x <= rightX && p2x >= rightX)
				return true;

			if (p1x <= leftX && p2x >= leftX)
				return true;

			if (Point.distance(p1, p2) > projWidthHalf)
				return true;

			return false;
		}

		public function crossDatelineCoords(c1: Coord, c2: Coord): Boolean
		{

			if (c1.crs != crs)
				c1 = c1.convertToProjection(m_crsProjection);
			if (c2.crs != crs)
				c2 = c2.convertToProjection(m_crsProjection);

			//must be in same projection as widget projection
			return crossDateline(new Point(c1.x, c1.y), new Point(c2.x, c2.y));
		}


		/**
		 * Find out if coordinate is inside view bbox.
		 * @param c
		 * @return
		 *
		 */
		public function coordInside(c: Coord): Boolean
		{
			if (!Projection.equalCRSs(c.crs, ms_crs))
			{
				//same projectsion
				c = c.convertToProjection(m_crsProjection);
			}
			if (c)
				return m_viewBBox.coordInside(c);

			return false;
		}

		/**
		 * Convert coordinate to Point on screen, but returns reflected point closest to the reference point
		 * @param c
		 * @param referencePoint
		 * @return
		 *
		 */
		public function coordToPointClosestTo(c: Coord, referencePoint: Point): Point
		{
			var p: Point = coordToPoint(c);
			if (m_crsProjection.wrapsHorizontally)
			{
				var f_crsExtentBBoxWidth: Number = m_crsProjection.extentBBox.width;

				var c1: Coord = new Coord(crs, c.x + f_crsExtentBBoxWidth, c.y);
				var p1: Point = coordToPoint(c1);
				var pixelsWidth: int = Math.abs(p1.x - p.x);

				var maxDistance: Number = Point.distance(p, referencePoint);
				var selectedPoint: Point = p;
				for(var i: int = 0; i < 10; i++)
				{
					var i_delta: int = (i & 1 ? 1 : -1) * ((i + 1) >> 1);

					var currPoint: Point = new Point(p.x + i_delta * pixelsWidth, p.y);
					var dist: Number = Point.distance(referencePoint, currPoint);
					if (dist < maxDistance)
					{
						maxDistance = dist;
						selectedPoint = currPoint;
					}
				}
				return selectedPoint;
			}
			return p;
		}

		/**
		 * Converts Coord into screen point (pixels) with current CRS.
		 * @param c
		 * @return
		 *
		 */
		public function coordToPoint(c: Coord): Point
		{
			var ptInOurCRS: Point;
			if (Projection.equalCRSs(c.crs, ms_crs))
				ptInOurCRS = c;
			else
			{
				if (m_crsProjection == null)
					return null;
				var sourceProjection: Projection = Projection.getByCRS(c.crs);
				if (sourceProjection == null)
					return null;
				var laLoPtRad: Point = sourceProjection.prjXYToLaLoPt(c.x, c.y);
				if (laLoPtRad)
					ptInOurCRS = m_crsProjection.laLoPtToPrjPt(laLoPtRad);
			}
			if (ptInOurCRS && m_viewBBox)
			{
				var w: Number = areaWidth;
				var h: Number = areaHeight;

				var pX: Number = (ptInOurCRS.x - m_viewBBox.xMin) * (w - 1) / m_viewBBox.width;
				var pY: Number = h - 1 - (ptInOurCRS.y - m_viewBBox.yMin) * (h - 1) / m_viewBBox.height;
				return new Point(pX, pY);
			}
			return null;
		}

		public function shownOnScreen(bbox: BBox): Boolean
		{
			var crs: String = getCRS();

			if (crs == Projection.CRS_GEOGRAPHIC)
			{
				var layerBbox:BBox = getViewBBox();

				var allReflectionParts:Array = mapBBoxToViewReflections(bbox, true);
				for each (var currentReflectionPart:BBox in allReflectionParts) {
					var allReflectionVisibleParts:Array = mapBBoxToProjectionExtentParts(currentReflectionPart);
					for each (var currentReflectionVisiblePart:BBox in allReflectionVisibleParts) {
						if (layerBbox.intersects(currentReflectionVisiblePart)) {
							return true; //Layer bounds within viewing bounds
						}
					}
				}
				return false;
			}
			return true;
		}

		/**
		 * Splits coordinates of BBox (in the currently used CRS) into partial sub-BBoxes of the
		 * IW's View BBox, which are visible.
		 * When panning over the anti-meridian (assuming the IW's View BBox is bigger than
		 * Projection extent BBOx - the source BBox must be split into typically 2 sub-parts
		 * one to the left (east hemisphere) and on the righ (west hemisphere). If the view is zoomed
		 * out enough even multiple reflection of the part can be seen.
		 **/
		public function mapBBoxToProjectionExtentParts(bbox: BBox, vBBox: BBox = null): Array
		{
			if (!vBBox)
				vBBox = m_crsProjection.extentBBox;
			var aNew: Array = [];
			if (m_crsProjection.wrapsHorizontally)
			{
				var f_crsExtentBBoxWidth: Number = m_crsProjection.extentBBox.width;
				/*
				var testExtentBBox: BBox = m_crsProjection.extentBBox;
				for(var i: int = 0; i < 10; i++)
				{
					var i_delta: int = (i & 1 ? 1 : -1) * ((i + 1) >> 1); // generates sequence 0, 1, -1, 2, -2, ..., 5, -5
					var reflectedBBox: BBox = bbox.translated(f_crsExtentBBoxWidth * i_delta, 0)
					var intersectionOfReflectedBBoxWithCRSExtentBBox: BBox =
							reflectedBBox.intersected(m_crsProjection.extentBBox);

					if(intersectionOfReflectedBBoxWithCRSExtentBBox && intersectionOfReflectedBBoxWithCRSExtentBBox.width > 0 && intersectionOfReflectedBBoxWithCRSExtentBBox.height > 0) {
						var b_foundEnvelopingBBox: Boolean = false;
						for each(var otherBBox: BBox in a) {
							if(otherBBox.contains(intersectionOfReflectedBBoxWithCRSExtentBBox)) {
								b_foundEnvelopingBBox = true;
								break;
							}
						}
						if(!b_foundEnvelopingBBox) {
							a.push(intersectionOfReflectedBBoxWithCRSExtentBBox);
						}
					}
				}
				*/
				//NEW SOLUTION
				var extentBBoxWest: Number = vBBox.xMin;
				var extentBBoxEast: Number = vBBox.xMax;
				var bboxWest: Number = bbox.xMin;
				var bboxEast: Number = bbox.xMax;
				var bboxNorth: Number = Math.min(vBBox.yMax, bbox.yMax);
				var bboxSouth: Number = Math.max(vBBox.yMin, bbox.yMin);
				var partWidth: Number;
				var bSearching: Boolean = true;
				while (bSearching)
				{
					if ((bboxEast - bboxWest) > f_crsExtentBBoxWidth)
					{
						// BBox is wider than Extent
						aNew.push(new BBox(extentBBoxWest, bboxSouth, extentBBoxEast, bboxNorth));
						bSearching = false;
					}
					else if (bboxWest >= extentBBoxWest && bboxEast <= extentBBoxEast)
					{
						//BBox is narrower than Extent
						aNew.push(new BBox(bboxWest, bboxSouth, bboxEast, bboxNorth));
						bSearching = false;
					}
					else if (bboxWest < extentBBoxWest && bboxEast <= extentBBoxEast && bboxEast >= extentBBoxWest)
					{
						//BBox is partlt in Extent, west side is outside of Extent
						aNew.push(new BBox(extentBBoxWest, bboxSouth, bboxEast, bboxNorth));
						partWidth = extentBBoxWest - bboxWest;
						aNew.push(new BBox(extentBBoxEast - partWidth, bboxSouth, extentBBoxEast, bboxNorth));
						bSearching = false;
					}
					else if (bboxWest > extentBBoxWest && bboxWest <= extentBBoxEast && bboxEast > extentBBoxEast)
					{
						//BBox is partlt in Extent, east side is outside of Extent
						aNew.push(new BBox(bboxWest, bboxSouth, extentBBoxEast, bboxNorth));
						partWidth = bboxEast - extentBBoxEast;
						aNew.push(new BBox(extentBBoxWest, bboxSouth, extentBBoxWest + partWidth, bboxNorth));
						bSearching = false;
					}
					else
					{
						var delta: int;
						if (bboxWest > extentBBoxEast)
						{
							//BBOx is outsite extent at right side
							delta = Math.ceil((bboxWest - extentBBoxEast) / f_crsExtentBBoxWidth);
							bboxWest -= delta * f_crsExtentBBoxWidth;
							bboxEast -= delta * f_crsExtentBBoxWidth;
						}
						else
						{
							//BBOx is outsite extent at left side
							delta = Math.ceil((extentBBoxWest - bboxEast) / f_crsExtentBBoxWidth);
							bboxWest += delta * f_crsExtentBBoxWidth;
							bboxEast += delta * f_crsExtentBBoxWidth;
						}
					}
				}
			}
			if (aNew.length == 0)
			{
				var primaryPartBBox: BBox = bbox;
				primaryPartBBox = primaryPartBBox.intersected(m_crsProjection.extentBBox);
				if (primaryPartBBox == null) // no intersection!
					primaryPartBBox = bbox; // just keep the current view BBox and let's see what server returns
				aNew.push(primaryPartBBox);
			}
			return aNew;
		}

		/**
		 * Converts coordinates of BBox (in the currently used CRS) into its visual reflections
		 * if the IW's View BBox is bigger than extent BBox of the Projection.
		 * Then at certain zoom-out distance the same BBox may appear multiple times withing the View.
		 * Visualy this looks like multiple reflection of the same BBox in the View.
		 **/
		public function mapBBoxToViewReflections(bbox: BBox, returnIntersectedBBox: Boolean = false, vBBox: BBox = null): Array
		{
			var f_crsExtentBBoxWidth: Number = m_crsProjection.extentBBox.width;
			var intersectedBBox: BBox;
			if (!vBBox)
				vBBox = m_viewBBox;
			if (!m_crsProjection.wrapsHorizontally)
			{
				if (!returnIntersectedBBox)
					return [bbox];
				else
				{
					intersectedBBox = bbox.intersected(vBBox);
					if (intersectedBBox == null)
						return [];
					else
						return [intersectedBBox];
				}
			}
			else
			{
				var a: Array = [];
				//NEW SOLUTION
				var aNew: Array = [];
				var viewBBoxWest: Number = vBBox.xMin;
				var viewBBoxEast: Number = vBBox.xMax;
				var bboxWest: Number = bbox.xMin;
				var bboxEast: Number = bbox.xMax;
				var bboxNorth: Number = bbox.yMax;
				var bboxSouth: Number = bbox.yMin;
				if (returnIntersectedBBox)
				{
					bboxNorth = Math.min(vBBox.yMax, bbox.yMax);
					bboxSouth = Math.max(vBBox.yMin, bbox.yMin);
				}
				var westPoint: Point = new Point(bboxWest, 0);
				var eastPoint: Point = new Point(bboxEast, 0);
				var westReflections: Array = mapCoordInCRSToViewReflections(westPoint, vBBox);
				var eastReflections: Array = mapCoordInCRSToViewReflections(eastPoint, vBBox);
				var p: Number = 0;
				var px: Number;
				var nextX: Number;
				var currWest: Number = viewBBoxWest;
				var lastEast: Number = viewBBoxEast;
				var reflectionObject: Object;
				if (westReflections && westReflections.length > 0)
				{
					p = westReflections[0].point.x;
					if (p != bboxWest)
					{
						bboxWest = p;
						bboxEast = bboxWest + bbox.width;
					}
				}
				if (eastReflections && eastReflections.length > 0)
				{
					p = eastReflections[0].point.x;
					if (p != bboxEast)
					{
						bboxEast = p;
						bboxWest = bboxEast - bbox.width;
					}
				}
				var bSearching: Boolean = true;
				while (bSearching)
				{
					if ((bboxEast - bboxWest) > f_crsExtentBBoxWidth)
					{
						// BBox is wider than Extent
						if (returnIntersectedBBox)
							aNew.push(new BBox(Math.max(viewBBoxWest, bboxWest), bboxSouth, Math.min(viewBBoxEast, bboxEast), bboxNorth));
						else
							aNew.push(new BBox(bboxWest, bboxSouth, bboxEast, bboxNorth));
					}
					else if (bboxWest >= viewBBoxWest && bboxEast <= viewBBoxEast)
					{
						// BBox is narrower than Extent
						aNew.push(new BBox(bboxWest, bboxSouth, bboxEast, bboxNorth));
					}
					else if (bboxWest < viewBBoxWest && bboxEast <= viewBBoxEast && bboxEast >= viewBBoxWest)
					{
						// BBox is partly in Extent, west side is outside of Extent
						if (returnIntersectedBBox)
							aNew.push(new BBox(viewBBoxWest, bboxSouth, bboxEast, bboxNorth));
						else
							aNew.push(new BBox(bboxWest, bboxSouth, bboxEast, bboxNorth));
					}
					else if (bboxWest > viewBBoxWest && bboxWest <= viewBBoxEast && bboxEast > viewBBoxEast)
					{
						//BBox is partlt in Extent, east side is outside of Extent
						if (returnIntersectedBBox)
							aNew.push(new BBox(bboxWest, bboxSouth, viewBBoxEast, bboxNorth));
						else
							aNew.push(new BBox(bboxWest, bboxSouth, bboxEast, bboxNorth));
					}
					bboxWest += f_crsExtentBBoxWidth;
					bboxEast += f_crsExtentBBoxWidth;
					if (bboxWest > viewBBoxEast)
						bSearching = false;
				}
				//OLD SOLUTION
				for (var i: int = 0; i < 11; i++)
				{
					var i_delta: int = (i & 1 ? 1 : -1) * ((i + 1) >> 1); // generates sequence 0, 1, -1, 2, -2, ..., 5, -5
					var reflectedBBox: BBox = bbox.translated(f_crsExtentBBoxWidth * i_delta, 0)
					intersectedBBox = reflectedBBox.intersected(vBBox);
					if (intersectedBBox && intersectedBBox.surface == 0)
						intersectedBBox = null;
					if (intersectedBBox)
					{
						if (!returnIntersectedBBox)
							a.push(reflectedBBox);
						else
							a.push(intersectedBBox);
					}
				}
				return a;
			}
		}

		public function getReflectedViewBBox(reflectionDelta: int): BBox
		{
			var f_crsExtentBBoxWidth: Number = m_crsProjection.extentBBox.width;

			var reflectedBBox: BBox = m_crsProjection.extentBBox.translated(f_crsExtentBBoxWidth * reflectionDelta, 0);
//			debug("getReflectedViewBBox  ["+reflectionDelta+"]: " + reflectedBBox);
			return reflectedBBox;
		}

		public function mapLineCoordToViewReflections(coordFrom: Coord, coordTo: Coord, vBBox: BBox = null): Array
		{
			if (!coordFrom || !coordTo)
				return [];

			var point: Point = new Point(coordFrom.x, coordFrom.y);
			var pointTo: Point = new Point(coordTo.x, coordTo.y);
			if (m_crsProjection.wrapsHorizontally)
			{
				if (coordFrom.x > coordTo.x)
				{
					var px: Number = coordFrom.x;
					var py: Number = coordFrom.y;

					coordFrom = new Coord(coordFrom.crs, px, py);
				}

				point = new Point(coordFrom.x, coordFrom.y);

				var diffX: Number = coordTo.x - coordFrom.x;
				var diffY: Number = coordTo.y - coordFrom.y;

				var f_crsExtentBBoxWidth: Number = m_crsProjection.extentBBox.width;
				var reflections: Array = mapCoordInCRSToViewReflections(point, m_crsProjection.extentBBox);
				if (reflections && reflections.length > 0)
				{
					var pX0: Number = reflections[0].point.x;
					var a: Array = [];
					for(var i: int = 0; i < 10; i++)
					{
						var i_delta: int = (i & 1 ? 1 : -1) * ((i + 1) >> 1); // generates sequence 0, 1, -1, 2, -2, ..., 5, -5
						var pFrom: Point = new Point(pX0 + f_crsExtentBBoxWidth * i_delta, point.y);
						var pTo: Point = new Point(pFrom.x + diffX, pFrom.y + diffY);

						a.push({pointFrom: pFrom, pointTo: pTo, reflection: i_delta});
					}
					return a;
				}
			}
			return [{pointFrom: point,  pointTo: pointTo, reflection: 0}];
		}

		public function mapRectangleCoordToViewReflections(coordTopLeft: Coord, coordBottomLeft: Coord, coordTopRight: Coord, coordBottomRight: Coord, vBBox: BBox = null): Array
		{
			if (!coordTopLeft || !coordBottomLeft || !coordTopRight || !coordBottomRight)
				return [];

			var pointTopLeft: Point = new Point(coordTopLeft.x, coordTopLeft.y);
			var pointBottomLeft: Point = new Point(coordBottomLeft.x, coordBottomLeft.y);
			var pointTopRight: Point = new Point(coordTopRight.x, coordTopRight.y);
			var pointBottomRight: Point = new Point(coordBottomRight.x, coordBottomRight.y);

			if (m_crsProjection.wrapsHorizontally)
			{
//				if (coordLeft.x > coordTop.x)
//				{
//					var px: Number = coordLeft.x;
//					var py: Number = coordLeft.y;
//
//					coordLeft = new Coord(coordLeft.crs, px, py);
//				}
//
//				pointLeft = new Point(coordLeft.x, coordLeft.y);

				var diffX: Number = coordTopRight.x - coordTopLeft.x;
//				var diffY: Number = coordBottomRight.y - coordTopRight.y;

				var f_crsExtentBBoxWidth: Number = m_crsProjection.extentBBox.width;
				var reflections: Array = mapCoordInCRSToViewReflections(pointTopLeft, m_crsProjection.extentBBox);
				var pX0: Number = reflections[0].point.x;
				var a: Array = [];
				for(var i: int = 0; i < 10; i++)
				{
					var i_delta: int = (i & 1 ? 1 : -1) * ((i + 1) >> 1); // generates sequence 0, 1, -1, 2, -2, ..., 5, -5
					var pTopLeft: Point = new Point(pX0 + f_crsExtentBBoxWidth * i_delta, pointTopLeft.y);
					var pBottomLeft: Point = new Point(pTopLeft.x, pointBottomLeft.y);
					var pTopRight: Point = new Point(pTopLeft.x + diffX, pointTopRight.y);
					var pBottomRight: Point = new Point(pBottomLeft.x + diffX, pointBottomRight.y);

					a.push({pointTopLeft: pTopLeft,
							pointTopRight: pTopRight,
							pointBottomLeft: pBottomLeft,
							pointBottomRight: pBottomRight,
							reflection: i_delta}
						);
				}
				return a;
			}
			return [{pointTopLeft: pointTopLeft,
					 pointTopRight: pointTopRight,
					 pointBottomLeft: pointBottomLeft,
					 pointBottomRight: pointBottomRight,
					 reflection: 0}];
		}

		public function mapCoordToViewReflections(coord: Coord, vBBox: BBox = null): Array
		{
			if (coord.crs != crs)
				coord = coord.convertToProjection(m_crsProjection);
			return mapCoordInCRSToViewReflections(new Point(coord.x, coord.y), vBBox);
		}

		/**
		 * Returns array of object pairs {point: reflected point, reflection: reflection delta}
		 * Input point is x,y coordinate and not pixel position.
		 * @param point Point which will be reflected
		 * @param vBBox if you want to return reflections for different view BBox than InteractiveWidget.viewBBox
		 * @return
		 *
		 */
		public function mapCoordInCRSToViewReflections(point: Point, vBBox: BBox = null): Array
		{
			if (!point)
				return [];
			if (m_crsProjection.wrapsHorizontally)
			{
				var extentBox: BBox = m_crsProjection.extentBBox;
				var f_crsExtentBBoxWidth: Number = m_crsProjection.extentBBox.width;
				if (!vBBox)
					vBBox = m_viewBBox;

//				debug(this.id + " mapCoordInCRSToViewReflections m_viewBBox: " + m_viewBBox);

				var viewBBoxWest: Number = vBBox.xMin;
				var viewBBoxEast: Number = vBBox.xMax;
				var extentBBoxWest: Number = extentBox.xMin;
				var extentBBoxEast: Number = extentBox.xMax;
				var px: Number = point.x;
				var py: Number = point.y;
				var refCount: int;
				var reflectionX: Number;

				//move point to ViewBBox
				if (px >= viewBBoxWest)
				{
					refCount = Math.floor((px - viewBBoxWest) / f_crsExtentBBoxWidth);
					reflectionX = px - refCount * f_crsExtentBBoxWidth;
				}
				else
				{
					refCount = Math.ceil(Math.abs((px - viewBBoxWest) / f_crsExtentBBoxWidth));
					reflectionX = px + refCount * f_crsExtentBBoxWidth;
				}
//				var i_delta: int = int((reflectionX - extentBBoxWest) / f_crsExtentBBoxWidth) - refCount;
//				var i_delta: int = Math.floor((px - extentBBoxWest) / f_crsExtentBBoxWidth) - refCount;
				var i_delta: int = Math.floor((reflectionX - extentBBoxWest) / f_crsExtentBBoxWidth);
				var a: Array = [];
				while (reflectionX <= viewBBoxEast && reflectionX >= viewBBoxWest)
				{
					var p: Point = new Point(reflectionX, py);
					a.push({point: p, reflection: i_delta});
					reflectionX += f_crsExtentBBoxWidth;
					i_delta++;
				}
				return a;
			}
			return [{point: point, reflection: 0}];
		}

		/**
		 * Similar function to function mapCoordInCRSToViewReflections, but you can set deltas manually
		 *
		 * @param point
		 * @param deltas
		 * @return
		 *
		 */
		public function mapCoordInCRSToViewReflectionsForDeltas(point: Point, deltas: Array): Array
		{
			if (!point)
				return [];
			if (m_crsProjection.wrapsHorizontally)
			{
				var f_crsExtentBBoxWidth: Number = m_crsProjection.extentBBox.width;
				var reflections: Array = mapCoordInCRSToViewReflections(point, m_crsProjection.extentBBox);

				var pX0: Number;
				var pointInZeroReflectionFound: Boolean;
				//TODO: need to checkout deltas in reflections if they are same as requested deltas

				//get 0 reflection index
				for each (var reflectedObject: Object in reflections)
				{
					if (reflectedObject.reflection == 0)
					{
						pX0 = reflectedObject.point.x;
						pointInZeroReflectionFound = true;
						break;
					}
				}

				if (pointInZeroReflectionFound)
				{
					var a: Array = [];
					for each (var i_delta: int in deltas)
					{
	//					var p: Point = new Point(pX0 + f_crsExtentBBoxWidth * i_delta, point.y)
						var p: Point = new Point(pX0 + f_crsExtentBBoxWidth * i_delta, point.y)
						a.push({point: p, reflection: i_delta});
					}
					return a;
				}
			}
			return [{point: point, reflection: 0}];
		}

		private function getReflectedXPositionForDelta(pX0: Number, delta: Number, f_crsExtentBBoxWidth: Number): Number
		{
			return pX0 + f_crsExtentBBoxWidth * delta;
		}

		private var _enableSynchronization: Boolean;
		public function get enableSynchronization():Boolean
		{
			return _enableSynchronization;
		}

		public function set enableSynchronization(value:Boolean):void
		{
			_enableSynchronization = value;
		}


		private var mb_listenForChanges: Boolean;

		[Bindable(event = "listeningForChangesChanged")]
		public function get listeningForChanges(): Boolean
		{
			return mb_listenForChanges;
		}

		public function startListenForChanges(bInvalidateDisplayList: Boolean = true): void
		{
			if (!mb_listenForChanges)
			{
				mb_listenForChanges = true;
				dispatchEvent(new Event("listeningForChangesChanged"));

				if (bInvalidateDisplayList)
					invalidateDisplayList();
			}
		}

		public function stopListenForChanges(bInvalidateDisplayList: Boolean = true): void
		{
			if (mb_listenForChanges)
			{
				mb_listenForChanges = false;
				dispatchEvent(new Event("listeningForChangesChanged"));

				if (bInvalidateDisplayList)
					invalidateDisplayList();
			}
		}

		/**
		 * InteractiveWidget needs to call this function is anything, what needs to be synchronized was changed
		 *
		 */
		public function notifyWidgetChanged(change: String, objectChanged: Object): void
		{
			if (mb_listenForChanges)
			{
				var iwe: InteractiveWidgetEvent = new InteractiveWidgetEvent(InteractiveWidgetEvent.WIDGET_CHANGED);
				iwe.changeDescription = change;
				iwe.data = objectChanged;
				dispatchEvent(iwe);
			}
		}

		private function notifyWidgetSelected(): void
		{
			dispatchEvent(new InteractiveWidgetEvent(InteractiveWidgetEvent.WIDGET_SELECTED));
		}

		// Mouse events handling
		protected function onMouseDown(event: MouseEvent): void
		{
			if (!_enableMouseClick)
				return;

			event.target.stage.addEventListener( MouseEvent.MOUSE_UP, onStageMouseUpHandler );

			for (var i: int = m_layerContainer.numElements - 1; i >= 0; --i)
			{
				var l: InteractiveLayer = InteractiveLayer(m_layerContainer.getElementAt(i));
				if (!l.enabled)
					continue;
				if (l.onMouseDown(event))
				{
					notifyWidgetSelected();
					break;
				}
			}
			postUserActionUpdate();
		}

		protected function onStageMouseUpHandler(event: MouseEvent): void
		{
			event.target.removeEventListener( MouseEvent.MOUSE_UP, onStageMouseUpHandler );

			onMouseUpOutside(event);
		}

		protected function onMouseUpOutside(event: MouseEvent): void
		{
			if (!_enableMouseClick)
				return;
			for (var i: int = m_layerContainer.numElements - 1; i >= 0; --i)
			{
				var l: InteractiveLayer = InteractiveLayer(m_layerContainer.getElementAt(i));
				if (!l.enabled)
					continue;
				if (l.onMouseUpOutside(event))
					break;
			}
			postUserActionUpdate();
		}
		protected function onMouseUp(event: MouseEvent): void
		{
			if (!_enableMouseClick)
				return;

			event.stopImmediatePropagation( );
			event.target.removeEventListener( MouseEvent.MOUSE_UP, onStageMouseUpHandler );

			for (var i: int = m_layerContainer.numElements - 1; i >= 0; --i)
			{
				var l: InteractiveLayer = InteractiveLayer(m_layerContainer.getElementAt(i));
				if (!l.enabled)
					continue;
				if (l.onMouseUp(event))
					break;
			}
			postUserActionUpdate();
		}

		private var _mouseMoveExecuted: Boolean;

		protected function onMouseMove(event: MouseEvent): void
		{
			if (!_enableMouseMove || _mouseMoveExecuted)
				return;

			_mouseMoveExecuted = true;
			for (var i: int = m_layerContainer.numElements - 1; i >= 0; --i)
			{
				var l: InteractiveLayer = InteractiveLayer(m_layerContainer.getElementAt(i));
				if (!l.enabled)
					continue;
				if (l.onMouseMove(event))
					break;
			}
			postUserActionUpdate();

			invalidateProperties();
		}

		protected function onMouseWheel(event: MouseEvent): void
		{
			for (var i: int = m_layerContainer.numElements - 1; i >= 0; --i)
			{
				var l: InteractiveLayer = InteractiveLayer(m_layerContainer.getElementAt(i));
				if (!l.enabled)
					continue;
				if (l.onMouseWheel(event))
					break;
			}
			postUserActionUpdate();
		}

		protected function onMouseClick(event: MouseEvent): void
		{
			if (!_enableMouseClick)
				return;
			for (var i: int = m_layerContainer.numElements - 1; i >= 0; --i)
			{
				var l: InteractiveLayer = InteractiveLayer(m_layerContainer.getElementAt(i));
				if (!l.enabled)
					continue;
				if (l.onMouseClick(event))
				{
					notifyWidgetSelected();
					break;
				}
			}
			postUserActionUpdate();
		}

		protected function onMouseDoubleClick(event: MouseEvent): void
		{
			if (!_enableMouseClick)
				return;
			for (var i: int = m_layerContainer.numElements - 1; i >= 0; --i)
			{
				var l: InteractiveLayer = InteractiveLayer(m_layerContainer.getElementAt(i));
				if (!l.enabled)
					continue;
				if (l.onMouseDoubleClick(event))
				{
					notifyWidgetSelected();
					break;
				}
			}
			postUserActionUpdate();
		}

		protected function onMouseRollOver(event: MouseEvent): void
		{
			for (var i: int = m_layerContainer.numElements - 1; i >= 0; --i)
			{
				var l: InteractiveLayer = InteractiveLayer(m_layerContainer.getElementAt(i));
				if (!l.enabled)
					continue;
				if (l.onMouseRollOver(event))
					break;
			}
			postUserActionUpdate();
		}

		protected function onMouseRollOut(event: MouseEvent): void
		{
			for (var i: int = m_layerContainer.numElements - 1; i >= 0; --i)
			{
				var l: InteractiveLayer = InteractiveLayer(m_layerContainer.getElementAt(i));
				if (!l.enabled)
					continue;
				if (l.onMouseRollOut(event))
					break;
			}
			postUserActionUpdate();
		}

		protected function onResized(Event: ResizeEvent): void
		{
			if (!m_suspendDataUpdating)
			{
				var w: Number;
				var h: Number;

				if (!isNaN(explicitWidth))
					w = explicitWidth;
				else
					w = width;
				if (!isNaN(explicitHeight))
					h = explicitHeight;
				else
					h = height;

				if (autoLayoutInParent)
				{
					w = areaWidth;
					h = areaHeight;
				}

	//			debug("IW onResized: ["+w+","+h+"] old ["+Event.oldWidth+","+Event.oldHeight+"]");
				m_labelLayout.setBoundary(new Rectangle(0, 0, w, h));
				m_objectLayout.setBoundary(new Rectangle(0, 0, w, h));
				if (!m_resizeTimer)
				{
					m_resizeTimer = new Timer(500, 1);
					m_resizeTimer.addEventListener(TimerEvent.TIMER_COMPLETE, callDelayedResize);
				}
				m_resizeTimer.stop();
				m_resizeTimer.start();
			}
		}

		private function callDelayedResize(event: TimerEvent = null): void
		{
			callLater(afterDelayedResize);
		}
		private function afterDelayedResize(): void
		{
//			debug("afterDelayedResize");
//			if (!suspendResizeNotifying)
//			{
				setViewBBox(m_viewBBox, false); // set the view bbox to update the aspects
				updateLayersBounds();
//			} else {
//				debug("IW resize notifying is suspended");
//			}
		}

		/**
		 * Update correct area size. Need to be called when property autoLayoutInParent is changed.
		 *
		 */
		private function updateAreaSize(): void
		{
			if (!autoLayoutInParent)
			{

				m_widgetBounds.x = 0;
				m_widgetBounds.y = 0;
				m_widgetBounds.width = width;
				m_widgetBounds.height = height;

				setViewBBox(m_viewBBox, false);
			} else {

				autoLayoutViewBBox(m_viewBBox, true, true);
			}
		}

		/**
		 * Updates all layers bounds to current area size. Area size depends whether autoLayoutInParent is set to true (fit map) or false
		 *
		 */
		private function updateLayersBounds(): void
		{
			var w: Number = areaWidth;
			var h: Number = areaHeight;
			var xPos: Number = areaX;
			var yPos: Number = areaY;

			m_layerContainer.x = xPos;
			m_layerContainer.y = yPos;
			m_layerContainer.width = w;
			m_layerContainer.height = h;

			for (var i: int = 0; i < m_layerContainer.numElements; ++i)
			{
				var l: InteractiveLayer = InteractiveLayer(m_layerContainer.getElementAt(i));
				if (l.width != w || l.height != h)
				{
					l.x = 0;
					l.y = 0;
					l.width = w;
					l.height = h;
					l.onContainerSizeChanged();
					if (!l.isDynamicPartInvalid())
						l.invalidateDynamicPart();
				}
			}
			scrollRect = new Rectangle(0, 0, w, h);
			postUserActionUpdate();
		}

		private function postUserActionUpdate(): void
		{
			for (var i: int = 0; i < m_layerContainer.numElements; ++i)
			{
				var l: InteractiveLayer = InteractiveLayer(m_layerContainer.getElementAt(i));
//FIXME check if this is needed, it's not good solution to call validateNow more times in one frame
//				if (l.isDynamicPartInvalid())
//					l.validateNow();
			}
			anticollisionUpdate();
		}

		// Getters & setters
		public function getCRS(): String
		{
			return ms_crs;
		}

		public function setCRS(s_crs: String, b_finalChange: Boolean = true): void
		{
			if (ms_crs != s_crs)
			{
				ms_crs = s_crs;
				m_crsProjection = Projection.getByCRS(s_crs);
				signalAreaChanged(b_finalChange);
				dispatchEvent(new Event("crsChanged"));
			}
		}

		public function setCRSExtentAndViewBBox(s_crs: String, extentBBox: BBox = null, viewBBox: BBox = null, b_finalChange: Boolean = true): void
		{
			setCRS(s_crs, false);
			if (extentBBox == null)
				extentBBox = getCRSProjection().extentBBox;
			if (extentBBox == null)
				throw new Error("CRS " + s_crs + " does not have specified extent");
			setExtentBBox(extentBBox);
			if (viewBBox == null)
				viewBBox = extentBBox;
			setViewBBox(viewBBox, b_finalChange);
		}

		public function getProjectionWidthInPixels(): Number
		{
			var projExtent: BBox = m_crsProjection.extentBBox;

			var p: Array = coordsToPoints([new Coord(crs, projExtent.xMin, projExtent.yMin), new Coord(crs, projExtent.xMax, projExtent.yMax)]);
			return p[1].x - p[0].x;
		}
		public function getCRSProjection(): Projection
		{
			return m_crsProjection;
		}

		public function setViewBBoxRaw(xmin: Number, ymin: Number, xmax: Number, ymax: Number, b_finalChange: Boolean): void
		{
			setViewBBox(new BBox(xmin, ymin, xmax, ymax), b_finalChange);
		}

		public function isCRSWrappingOverXAxis(): Boolean
		{
			m_crsProjection = Projection.getByCRS(ms_crs);
			return m_crsProjection.wrapsHorizontally;
		}

		public function getPixelDistance(): Number
		{
			var w: Number = areaWidth;
			var h: Number = areaHeight;
			var bbox: BBox = m_viewBBox;
			var prj: Projection = m_crsProjection;
			var dpi: int = Capabilities.screenDPI;
//			var maxDistanceOnEarthInKm: Number = bbox.getBBoxMaximumDistance(crs);
			var screenDistanceInPixels: Number = Math.sqrt(w * w + h * h);
			var screenDistanceInInches: Number = screenDistanceInPixels / dpi;
			var screenDistanceInMeters: Number = screenDistanceInInches * 2.54 * 0.01;

			return screenDistanceInMeters / w;
		}
		public function getMapScale(bbox: BBox = null): Number
		{
			var w: Number = areaWidth;
			var h: Number = areaHeight;
			if (!bbox)
				bbox = m_viewBBox;
			var prj: Projection = m_crsProjection;
			var dpi: int = Capabilities.screenDPI;
			var maxDistanceOnEarthInKm: Number = bbox.getBBoxMaximumDistance(crs);
			var screenDistanceInPixels: Number = Math.sqrt(w * w + h * h);
			var screenDistanceInInches: Number = screenDistanceInPixels / dpi;
			var screenDistanceInKm: Number = screenDistanceInInches * 2.54 * 0.00001;
			var scale: Number = screenDistanceInKm / maxDistanceOnEarthInKm;
			return scale;
		}

		/**
		 * Set center of  View BBox without changing zoom.
		 * @param coord	Coording to center map on.
		 */
		public function centerViewBBoxTo(coord: Coord): void
		{
			var newViewBBox: BBox;
			var b_changeZoom: Boolean = false;
			var oldBox: BBox = getViewBBox();
			var ptInOurCRS: Point;
			if (!Projection.equalCRSs(coord.crs, ms_crs))
			{
				//need to convert coord to current interactive widget coordinate
				var sourceProjection: Projection = Projection.getByCRS(coord.crs);
				var laLoPtRad: Point = sourceProjection.prjXYToLaLoPt(coord.x, coord.y);
				if (laLoPtRad)
					ptInOurCRS = m_crsProjection.laLoPtToPrjPt(laLoPtRad);
			}
			else
				ptInOurCRS = new Point(coord.x, coord.y);
			//clone old bbox, because size of new box will be same, just center will be moved
			newViewBBox = oldBox.clone();
			var oldCenter: Point = newViewBBox.center;
			newViewBBox = newViewBBox.translated(ptInOurCRS.x - oldCenter.x, ptInOurCRS.y - oldCenter.y)
			setViewBBox(newViewBBox, true);
		}

		//[Deprecated(replacement=centerViewTo]
		public function setCenter(coord: Coord): void
		{
			centerViewBBoxTo(coord);
		}

		/**
		 * Set View bounding box for all layers
		 *
		 * @param bbox - new bounding box to be changed to
		 * @param b_finalChange - false if it is change in some running action (like user has draging map or zooming in or out). If action is finished, set b_finalChange = true
		 * @param b_negotiateBBox - if bounding box needs to be negotiated (because some layers e.g. google can not set any bounding box (because of zoom)
		 * @param b_changeZoom - This is temporary argument, just for Google Maps fix of scaling maps on Map PAN
		 */
		public function setViewBBox(bbox: BBox, b_finalChange: Boolean, b_negotiateBBox: Boolean = true): void
		{
//			debug("\t\t\t setViewBBox: " + bbox.toBBOXString());
//			debug(this + " setViewBBox: " + bbox.toBBOXString() + " finalChange: " + b_finalChange + " , negotiate: " + b_negotiateBBox);

			var b_changeZoom: Boolean = true;
			var oldBox: BBox = getViewBBox();
			var bboxWidthDiff: int = Math.abs(bbox.width - oldBox.width);
			var bboxHeightDiff: int = Math.abs(bbox.height - oldBox.height);
			if (bboxHeightDiff == 0 && bboxWidthDiff == 0)
				b_changeZoom = false;
			// aspect is the > 1 if bbox is wider than higher
			// this is the aspect ratio we want to maintain
			var f_extentAspect: Number = 1; //m_extentBBox.width / m_extentBBox.height;
			var f_bboxCenterX: Number = bbox.xMin + bbox.width / 2.0;
			var f_bboxCenterY: Number = bbox.yMin + bbox.height / 2.0;
			// this is the aspect ratio of currently requeste bbox
			var f_bboxApect: Number = bbox.width / bbox.height;
			var f_componentAspect: Number = width / height;
			if (isNaN(f_componentAspect))
				f_componentAspect = 1;
			var f_newBBoxWidth: Number;
			var f_newBBoxHeight: Number;
			if (!mb_autoLayout)
			{
				if (f_bboxApect < f_extentAspect)
				{
					// extent looks wider
					f_newBBoxWidth = f_componentAspect * f_extentAspect * bbox.height;
					f_newBBoxHeight = bbox.height;
				}
				else
				{
					// extent looks higher
					f_newBBoxWidth = bbox.width;
					f_newBBoxHeight = bbox.width / f_extentAspect / f_componentAspect;
				}
				// uncomment this if statement, if you want enable unzoom to see more reflections
				//			if (!isCRSWrappingOverXAxis())
				//			{
				if (f_newBBoxHeight > m_extentBBox.height)
				{
					f_newBBoxHeight = m_extentBBox.height;
					f_newBBoxWidth = f_componentAspect * f_extentAspect * f_newBBoxHeight;
				}
				if (f_newBBoxWidth > m_extentBBox.width)
				{
					f_newBBoxWidth = m_extentBBox.width;
					f_newBBoxHeight = f_newBBoxWidth / f_componentAspect / f_extentAspect;
				}
				//			}
				if (isNaN(f_newBBoxHeight))
					debug("InteractiveWidget.isVisible.setViewBBox: f_newBBoxHeight is NaN");
				var viewBBox: Rectangle = new Rectangle(f_bboxCenterX - f_newBBoxWidth / 2.0, f_bboxCenterY - f_newBBoxHeight / 2.0, f_newBBoxWidth, f_newBBoxHeight);
				//check if view BBox is not outside extent BBox
				if (viewBBox.y < m_extentBBox.yMin)
					viewBBox.offset(0, -viewBBox.y + m_extentBBox.yMin);
				if (viewBBox.bottom > m_extentBBox.yMax)
					viewBBox.offset(0, -viewBBox.bottom + m_extentBBox.yMax);
				if (!isCRSWrappingOverXAxis())
				{
					if (viewBBox.x < m_extentBBox.xMin)
						viewBBox.offset(-viewBBox.x + m_extentBBox.xMin, 0);
					if (viewBBox.right > m_extentBBox.xMax)
						viewBBox.offset(-viewBBox.right + m_extentBBox.xMax, 0);
				}
				var newBBox: BBox = BBox.fromRectangle(viewBBox);
//				debug(this + " setViewBBox inp: " + bbox.toBBOXString() + " finalChange: " + b_finalChange + " , negotiate: " + b_negotiateBBox);
//				debug(this + " setViewBBox new: " + newBBox.toBBOXString() + " finalChange: " + b_finalChange + " , negotiate: " + b_negotiateBBox);
				if (b_negotiateBBox)
					negotiateBBox(newBBox, b_finalChange, b_changeZoom);
				else
					setViewBBoxAfterNegotiation(newBBox, b_finalChange);
			}
			else
			{
				//auto layout in widget parent
				autoLayoutViewBBox(bbox, b_finalChange, true, b_changeZoom, b_negotiateBBox);
			}
		}


		private var m_oldWidgetWidth: Number = 0;
		private var m_oldWidgetHeight: Number = 0;

		private function autoLayoutViewBBox(bbox: BBox, b_finalChange: Boolean, b_setViewBBox: Boolean = false, b_changeZoom: Boolean = true, b_negotiateBBox: Boolean = true): void
		{
			//auto layout in widget parent
//			var widgetParent: DataGroup = parent as DataGroup;
			var widgetParent: GroupBase = parent as GroupBase;
			if (widgetParent)
			{
				var f_bboxApect: Number = bbox.width / bbox.height;
				var f_bboxCenterX: Number = bbox.xMin + bbox.width / 2.0;
				var f_bboxCenterY: Number = bbox.yMin + bbox.height / 2.0;
				var parentWidth: Number = widgetParent.width;
				var parentHeight: Number = widgetParent.height;
				var f_parentAspect: Number = parentWidth / parentHeight;
				var widgetXPosition: Number = 0;
				var widgetYPosition: Number = 0;
				var widgetWidth: Number = parentWidth;
				var widgetHeight: Number = parentHeight;
				if (f_bboxApect < f_parentAspect)
				{
					// extent looks wider
					widgetWidth = widgetHeight * f_bboxApect;
					widgetXPosition = (parentWidth - widgetWidth) / 2;
				}
				else
				{
					// extent looks higher
					widgetHeight = widgetWidth / f_bboxApect;
					widgetYPosition = (parentHeight - widgetHeight) / 2;
				}

				//check if change in width and height is higher than 1px
				var widthDiff: Number = Math.abs(oldWidgetWidth - widgetWidth);
				var heightDiff: Number = Math.abs(oldWidgetHeight - widgetHeight);
				if (widthDiff > 1 || heightDiff > 1)
				{

					m_widgetBounds.setBounds(widgetXPosition, widgetYPosition, widgetWidth, widgetHeight);
//					debug("autoLayout pos: ["+widgetXPosition+","+widgetYPosition+"] size ["+widgetWidth+","+widgetHeight+"] diff: ["+widthDiff+","+heightDiff+"] OLD  ["+oldWidgetWidth+","+oldWidgetHeight+"]");
//					debug("autoLayoutViewBBox ["+areaWidth+","+areaHeight+"] ["+widgetWidth+","+widgetHeight+"] previous size ["+width+","+height+"] b_setViewBBox: " + b_setViewBBox);

					//move and change size of layers into area
					updateLayersBounds();

					oldWidgetWidth = widgetWidth;
					oldWidgetHeight = widgetHeight;
//					debug("autoLayoutViewBBox OLD SIZE set ["+oldWidgetWidth+","+oldWidgetHeight+"]");


//					if (b_setViewBBox)
//					{
//						if (b_negotiateBBox)
//							negotiateBBox(bbox, b_finalChange, b_changeZoom);
//						else
//							setViewBBoxAfterNegotiation(bbox, b_finalChange);
//					}

				}
				else {
					debug("autoLayoutViewBBox(): View BBox is too small: ["+widgetXPosition+","+widgetYPosition+"] size ["+widgetWidth+","+widgetHeight+"] diff: ["+widthDiff+","+heightDiff+"]");
				}

				var f_newBBoxWidth: Number = bbox.width;
				var f_newBBoxHeight: Number = bbox.height;

				if (f_newBBoxHeight > m_extentBBox.height)
				{
					f_newBBoxHeight = m_extentBBox.height;
					f_newBBoxWidth = f_bboxApect * 1 * f_newBBoxHeight;
				}
				if (f_newBBoxWidth > m_extentBBox.width)
				{
					f_newBBoxWidth = m_extentBBox.width;
					f_newBBoxHeight = f_newBBoxWidth / f_bboxApect / 1;
				}

				var viewBBox: Rectangle = new Rectangle(f_bboxCenterX - f_newBBoxWidth / 2.0, f_bboxCenterY - f_newBBoxHeight / 2.0, f_newBBoxWidth, f_newBBoxHeight);
				if (viewBBox.y < m_extentBBox.yMin)
					viewBBox.offset(0, -viewBBox.y + m_extentBBox.yMin);
				if (viewBBox.bottom > m_extentBBox.yMax)
					viewBBox.offset(0, -viewBBox.bottom + m_extentBBox.yMax);
				if (!isCRSWrappingOverXAxis())
				{
					if (viewBBox.x < m_extentBBox.xMin)
						viewBBox.offset(-viewBBox.x + m_extentBBox.xMin, 0);
					if (viewBBox.right > m_extentBBox.xMax)
						viewBBox.offset(-viewBBox.right + m_extentBBox.xMax, 0);
				}
				var newBBox: BBox = BBox.fromRectangle(viewBBox);

//				debug("1 BBOX: "+ bbox.width + ", " + bbox.height + " NEW BBOX: "+ f_newBBoxWidth + ", "+ f_newBBoxHeight);
//				debug("2 BBOX: "+ bbox.toBBOXString()  + " NEW BBOX: "+ newBBox.toBBOXString());
				setViewBBoxAfterNegotiation(newBBox, b_finalChange);
			}
		}

		private function negotiateBBox(newBBox: BBox, b_finalChange: Boolean, b_changeZoom: Boolean = true): void
		{
			var latestBBox: BBox;
			for (var i: int = 0; i < m_layerContainer.numElements; ++i)
			{
				var l: InteractiveLayer = InteractiveLayer(m_layerContainer.getElementAt(i));
				latestBBox = l.negotiateBBox(newBBox, b_changeZoom);
				if (!latestBBox.equals(newBBox))
					debug("InteractiveWidget.negotiateBBox(): bbox changed by layer " + l.layerName);
				newBBox = latestBBox;
			}
			setViewBBoxAfterNegotiation(newBBox, b_finalChange);
		}

		private function setViewBBoxAfterNegotiation(newBBox: BBox, b_finalChange: Boolean): void
		{
			//dispath view bbox changed event to notify about change
			m_viewBBox = newBBox;

			//to optimize drawing, count drawing viewport lines when ViewBBox is changed is done just once
			createDrawingViewBBoxLines();

			dispatchEvent(new Event(VIEW_BBOX_CHANGED));
			signalAreaChanged(b_finalChange);
		}


		/**
		 * Function will prepare viewport edge lines for drawing of features.
		 *
		 */
		private function createDrawingViewBBoxLines(): void
		{
			var vbLeft: Number = m_viewBBox.xMin;
			var vbRight: Number = m_viewBBox.xMax;
			var vbTop: Number = m_viewBBox.yMax;
			var vbBottom: Number = m_viewBBox.yMin;

			var ebLeft: Number = m_extentBBox.xMin;
			var ebRight: Number = m_extentBBox.xMax;
			var ebTop: Number = m_extentBBox.yMax;
			var ebBottom: Number = m_extentBBox.yMin;

			mi_viewportXAxisMarginPixels = 30;
			mi_viewportYAxisMarginPixels = 30;

			var coords: Array = pointsToCoords([new Point(0,0), new Point(mi_viewportXAxisMarginPixels, mi_viewportYAxisMarginPixels)]);

			//cound margins in coordinates space
			var xMargin: Number = (coords[1] as Coord).x - (coords[0] as Coord).x;
			var yMargin: Number = (coords[0] as Coord).y - (coords[1] as Coord).y;

			var viewportLeft: Number;
			var viewportRight: Number;
			var viewportTop: Number;
			var viewportBottom: Number;
			var projection: Projection = getCRSProjection();

			if (projection.wrapsHorizontally)
			{
				viewportLeft = vbLeft - xMargin;
				viewportRight = vbRight + xMargin;
				viewportTop = vbTop + yMargin;
				viewportBottom = vbBottom - yMargin;
			} else {
				viewportLeft = Math.max(ebLeft, vbLeft - xMargin);
				viewportRight = Math.min(ebRight, vbRight + xMargin);
				viewportTop = Math.min(ebTop, vbTop + yMargin);
				viewportBottom = Math.max(ebBottom, vbBottom - yMargin);
			}
			_drawingViewport = new BBox(viewportLeft, viewportBottom, viewportRight, viewportTop);

			m_viewBBoxWestLine = new LineSegment(viewportLeft, viewportTop, viewportLeft, viewportBottom);
			m_viewBBoxEastLine = new LineSegment(viewportRight, viewportTop, viewportRight, viewportBottom);
			m_viewBBoxNorthLine = new LineSegment(viewportLeft, viewportTop, viewportRight, viewportTop);
			m_viewBBoxSouthLine = new LineSegment(viewportLeft, viewportBottom, viewportRight, viewportBottom);
		}

		private var _drawingViewport: BBox;



		public function setExtentBBox(bbox: BBox, b_finalChange: Boolean = true): void
		{
			m_extentBBox = bbox;
//			debug("\t\t\t setExtentBBox: " + m_extentBBox.toBBOXString());
			if (b_finalChange)
				setViewBBox(m_extentBBox, b_finalChange); // this calls signalAreaChanged()
		}

		[Deprecated(replacement = setExtentBBox)]
		public function setExtentBBOX(bbox: BBox, b_finalChange: Boolean = true): void
		{
			setExtentBBox(bbox, b_finalChange);
		}

		public function setExtentBBoxRaw(xmin: Number, ymin: Number, xmax: Number, ymax: Number, b_finalChange: Boolean = true): void
		{
			setExtentBBox(new BBox(xmin, ymin, xmax, ymax), b_finalChange);
		}

		[Deprecated(replacement = setExtentBBoxRaw)]
		public function setExtentBBOXRaw(xmin: Number, ymin: Number, xmax: Number, ymax: Number, b_finalChange: Boolean = true): void
		{
			setExtentBBoxRaw(xmin, ymin, xmax, ymax, b_finalChange);
		}

		public function setViewFullExtent(): void
		{
			setViewBBox(m_extentBBox, true);
		}

		public function getExtentBBox(): BBox
		{
			return m_extentBBox;
		}

		public function getViewBBox(): BBox
		{
			return m_viewBBox;
		}

		public function invalidate(): void
		{
			signalAreaChanged(true);
		}
		//*****************************************************************************************
		// Drawing of splitted features
		//*****************************************************************************************
		private var m_featureSplitter: FeatureSplitter;

		public function get featureSplitter(): FeatureSplitter
		{
			return m_featureSplitter;
		}

		public function getSplineReflections(coords: Array, b_closed: Boolean = false): Array
		{
			var features: Array = m_featureSplitter.splitCoordHermitSplineToArrayOfPointPolyLines(coords, b_closed);
			return features;
		}

		/**
		 * Get reflections of polyline. If you want to draw all polyline reflections with sa ICurveRenderers, use  drawPolyline function instead
		 *
		 * @param coords
		 * @param b_closed
		 * @return
		 *
		 */
		public function getPolylineReflections(coords: Array, b_closed: Boolean = false): Array
		{
			var features: Array = m_featureSplitter.splitCoordPolyLineToArrayOfPointPolyLines(coords, b_closed, false);
			return features;
		}

		public function pointIsOutside(p: Point): Boolean
		{
			var w: Number = areaWidth;
			var h: Number = areaHeight;
			if (p.x < 0 || p.x > w)
				return true;
			if (p.y < 0 || p.y > h)
				return true;
			return false;
		}

		public function lineIsOutside(p1: Point, p2: Point): Boolean
		{
			return pointIsOutside(p1) && pointIsOutside(p2);
		}

		public function placeGeoSprite(coord: Coord, spriteCreator: Function): void
		{
			var features: Array = m_featureSplitter.splitCoordPolyLineToArrayOfPointPolyLines([coord], false, false, false);
			var p: Point;
			var oldPoint: Point;
			for each (var mPoints: Array in features)
			{
				var total: int = mPoints.length;
				if (total > 0)
				{
					p = mPoints[0] as Point;
					var sprite: Sprite = spriteCreator(coord);

					sprite.x = p.x;
					sprite.y = p.y;
				}
			}
		}
		public function drawGeoSprite(coord: Coord, spriteCreator: Function): void
		{
			var features: Array = m_featureSplitter.splitCoordPolyLineToArrayOfPointPolyLines([coord], false, false, false);
			var p: Point;
			var oldPoint: Point;
			for each (var mPoints: Array in features)
			{
				var total: int = mPoints.length;
				if (total > 0)
				{
					p = mPoints[0] as Point;
					var sprite: Sprite = spriteCreator(coord, p.x, p.y);
				}
			}
		}

		public function datelineBetweenPixelPositions(p1: Point, p2: Point): Boolean
		{
			var c1: Coord = pointToCoord(p1.x, p1.y);
			var c2: Coord = pointToCoord(p2.x, p2.y);
			return crossDateline(new Point(c1.x, c1.y), new Point(c2.x, c2.y));
		}

		/**
		 * Distance validator used for bisection to find out if 2 pixel positions are too close to go deeper with bisection
		 * @param p1
		 * @param p2
		 * @return Returns "true" if coordinates are too close, returns false if coordinates are not close enough
		 *
		 */
		public function pixelDistanceValidator(p1: Point, p2: Point): Boolean
		{
			var dist: Number = Point.distance(p1, p2);
//			trace("pixelDistanceValidator p1: " + p1 + ", p2: " + p2 + " => dist: " + dist);
			var maxDist: Number = FlexiWeatherConfiguration.BEZIER_POINTS_MAXIMUM_DISTANCE;
			var bDistance: Boolean = (dist < maxDist);
			return bDistance;
		}

		/**
		 * Distance validator used for bisection to find out if 2 coordinates are too close to go deeper with bisection
		 *
		 * @param c1
		 * @param c2
		 * @return Returns "true" if coordinates are too close, returns false if coordinates are not close enough
		 *
		 */
		public function distanceValidator(c1: Coord, c2: Coord): Boolean
		{
			var _mapScale: Number = getMapScale();
			c1 = c1.toLaLoCoord();
			c2 = c2.toLaLoCoord();
			var dist: Number = c1.distanceTo(c2);

			var maxDist: Number;

			maxDist = 100;

			var maxDistConst: int = 120000;
//			var maxDistConst: int = 70000;

			maxDist = (1/ _mapScale) / maxDistConst;
			if (maxDist > 1000)
				maxDist = 1000;
			if (maxDist < 300)
				maxDist = 300;

			trace("distanceValidator: dist: " + dist + "  maxDist: " + maxDist + " IS VALID: " +  (dist < maxDist) + " _mapScale: " + (1/ _mapScale));
			return (dist < maxDist);
		}

		public function splitCoordsOnDateline(coordFrom: Coord, coordTo: Coord): Array
		{
			var projection: Projection = getCRSProjection();

			coordFrom = coordFrom.toLaLoCoord();
			coordTo = coordTo.toLaLoCoord();
			var line1: FeatureDataLineSegment;
			var internationalDateLine: LineSegment = new LineSegment(180,-90,180,90);

			//create line1 in correct order
			if (coordFrom.x > coordTo.x)
				line1 = new FeatureDataLineSegment(coordFrom.x, coordFrom.y, coordTo.x + 360, coordTo.y, true, true, true);
			else {
				line1 = new FeatureDataLineSegment(coordTo.x, coordTo.y, coordFrom.x + 360, coordFrom.y, true, true, true);
			}

			var intersection: Point = line1.intersectionWithLineSegment(internationalDateLine);
			var intersectionCoordLeft: Coord = new Coord(coordFrom.crs, intersection.x - 0.00001, intersection.y);
			var intersectionCoordRight: Coord = new Coord(coordFrom.crs, intersection.x + 0.00001, intersection.y);
			//FIXME proble when converting coord from EPSG 900913
			intersectionCoordRight = Coord.convertCoordOnSphere(intersectionCoordRight, projection);

			var bisectedCoordsLeft: Array;
			var bisectedCoordsRight: Array;

			var tempCoords: Array;
			var cEdgeCoord: EdgeCoord;

			//now there are 2 lines and NULL (dateline) coord, so we split line crossing date line to 2 different lines not crossing dateline
			if (coordFrom.x > coordTo.x)
			{
				tempCoords = [new EdgeCoord(coordFrom, false, true), new EdgeCoord(intersectionCoordLeft, true, false), null, new EdgeCoord(intersectionCoordRight, true, false), new EdgeCoord(coordTo, false, true)];
			} else {
				tempCoords = [new EdgeCoord(coordFrom, false, true), new EdgeCoord(intersectionCoordRight, true, false), null, new EdgeCoord(intersectionCoordLeft, true, false), new EdgeCoord(coordTo, false, true)];
				//				tempCoords = [new EdgeCoord(coordTo, false, true), new EdgeCoord(intersectionCoordLeft, true, false), null, new EdgeCoord(intersectionCoordRight, true, false), new EdgeCoord(coordFrom, false, true)];
			}


			//convert coords back to origin projection
			var tempCoords2: Array = tempCoords;
			tempCoords = [];
			for each (cEdgeCoord in tempCoords2)
			{
				if (cEdgeCoord)
					if (cEdgeCoord.coord.crs != projection.crs)
						cEdgeCoord.coord = projection.laLoCoordToPrjCoord(cEdgeCoord.coord);
					else
						trace("splitCoordsOnDateline: cEdgeCoord was already in correct projection");

				tempCoords.push(cEdgeCoord);
			}

			return tempCoords;
		}

		/**
		 *
		 * @param g
		 * @param coordFrom
		 * @param coordTo
		 * @param drawMode
		 * @param b_closed
		 * @return
		 *
		 */
		private function _drawGeoLine(coordFrom: Coord, coordTo: Coord, drawMode: String, d_reflectionToSegmentPoints: Dictionary, featureData: FeatureData = null, featureDataLineID: int = 0): void
		{
			var fdlID: int = featureDataLineID;
			var bGreatArcHack: Boolean = false;

			var currTime: Number = getTimer();
			var bDebugTimes: Boolean = false;

			if (!coordFrom && !coordTo)
				return;

			var tempCoords: Array;
			var c: Coord;
			var cEdgeCoord: EdgeCoord;

			var projection: Projection = getCRSProjection();
			var extent: BBox = getExtentBBox();

			var originalCRS: String = coordFrom.crs;

			var bothCoordsMode: Boolean = false;

			//both coords are defined
			if (coordFrom && coordTo)
			{
				bothCoordsMode = true;

//				trace("_drawGeoLine(from: " + coordFrom.toString() + " to: " + coordTo.toString() + " featureDataLineID: "+ featureDataLineID);
				//move coords into extent
				coordFrom = Coord.convertCoordOnSphere(coordFrom, projection);
				coordTo = Coord.convertCoordOnSphere(coordTo, projection);
//				debug("_drawGeoLine convertCoordOnSphere(from: " + coordFrom.toString() + " to: " + coordTo.toString());


				if (drawMode == DrawMode.GREAT_ARC)
				{
					var arcCoords: Array;
					tempCoords = [];

					if (true) { // FIXME: missing support for non-wrapped projections
						if (projection.wrapsHorizontally && (crossDateline(coordFrom, coordTo) || coordsFarThanExtentWidth(coordFrom, coordTo)))
						{
							var bUseDatelineSplit: Boolean = false;

							if (bUseDatelineSplit)
							{
								tempCoords = splitCoordsOnDateline(coordFrom, coordTo);

								var arcTempCoords: Array = [];

								var ec1: EdgeCoord;
								var ec2: EdgeCoord;
								while(tempCoords.length > 0)
								{
									if (tempCoords[0] == null)
										arcTempCoords.push(tempCoords.shift());

									if (!ec1 && tempCoords.length > 0)
										ec1 = tempCoords.shift();
									if (!ec2 && tempCoords.length > 0)
										ec2 = tempCoords.shift();

									if (ec1 && ec2)
									{
										arcCoords = Coord.interpolateGreatArc(ec1.coord, ec2.coord, distanceValidator, crossDatelineCoords);
										for each (c in arcCoords)
										{
											if (c)
												arcTempCoords.push(new EdgeCoord(c, false, true));
											else
												arcTempCoords.push(null);
//											arcTempCoords.push(new EdgeCoord(c, false, true));
										}

										ec1 = null;
										ec2 = null;
									}
								}

								tempCoords = arcTempCoords;
							} else {


								tempCoords = [];
								arcCoords = Coord.interpolateGreatArc(coordFrom, coordTo, distanceValidator, crossDatelineCoords);
								for each (c in arcCoords)
								{
									if (c)
										tempCoords.push(new EdgeCoord(c, false, true));
									else
										tempCoords.push(null);
								}


							}

						} else {
							tempCoords = [];
							arcCoords = Coord.interpolateGreatArc(coordFrom, coordTo, distanceValidator, crossDatelineCoords);
							for each (c in arcCoords)
							{
								if (c)
									tempCoords.push(new EdgeCoord(c, false, true));
								else
									tempCoords.push(c);
							}
						}
					}

	//				debug(coords);
				}
				else if (drawMode == DrawMode.PLAIN) {
					if (projection.wrapsHorizontally) {

						//if Projection wraps horizontally, we need to check if coordinates distance is higher then half of extent to check if there is not InternationDateLine
						if (crossDateline(coordFrom, coordTo) || coordsFarThanExtentWidth(coordFrom, coordTo) )
						{
							tempCoords = splitCoordsOnDateline(coordFrom, coordTo);
						} else {
							tempCoords = [new EdgeCoord(coordFrom, false, true), new EdgeCoord(coordTo, false, true)];
						}
					} else {
						tempCoords = [new EdgeCoord(coordFrom, false, true), new EdgeCoord(coordTo, false, true)];
					}
				}
			} else {
				//at least one coord is defined
				if (coordFrom)
					tempCoords = [new EdgeCoord(coordFrom, false, true)];
				if (coordTo)
					tempCoords = [new EdgeCoord(coordTo, false, true)];
			}

//			if (bDebugTimes) debug("\t\t _drawGeoPolyLine - 1 - took " + (getTimer() - currTime) + "ms.");
			// coords can now contain null to mark point of discontinuity if line crosses dateline or projection boundaries

			var i_part: int = 0;
			var continousParts: Array = [[]];
			var isEdge: Boolean = false;


			for each (cEdgeCoord in tempCoords) {
				if(!cEdgeCoord) {

					//set last point as edge
					(continousParts[i_part][(continousParts[i_part] as Array).length - 1] as EdgeCoord).edge = true;

					continousParts.push([]);
					i_part = continousParts.length - 1;

					isEdge = true;
				}
				else {
					cEdgeCoord.edge = isEdge;
					continousParts[i_part].push(cEdgeCoord);
					isEdge = false;
				}
			}

//			if (bDebugTimes) debug("\t\t _drawGeoPolyLine - 2 - took " + (getTimer() - currTime) + "ms.");
			//if line crosses dateline there must be at least 2 continuosParts items
//			debug("_drawGeoLine ContinosParts: "+ continousParts.length);

			var reflections: Array;
			var projectionExtent: BBox = m_crsProjection.extentBBox;
			var part: Array;
			var cObject: EdgeCoord;
			var o: Object;
			var s_reflectionId: String;
			var reflectedSegmentPoints: Array;
			var reflection: FeatureDataReflection;
			var currLine: FeatureDataLine
			var p1: Point;
			var p2: Point;

			if (bothCoordsMode)
			{
				//FIXME add some negative margin to viewBBox to hide clipped feature borders (etc. clouds)
				//create lines which are edges of viewBBox


				var helpTime: Number;

				var line: FeatureDataLineSegment;
				var usedReflections: Dictionary;
				for each(part in continousParts)
				{

					/*
					* if "usedReflections" exists (it was already created in previous "part"), add null for discontinuation
					* - it is at the start of loop, to do not add null segments when there is just one part, or after the last part
					*/
					if (usedReflections)
					{
						for (var usedReflection: String in usedReflections)
						{
							var reflID: int = parseInt(usedReflection);

							reflection = featureData.getReflectionAt(reflID);
							currLine = reflection.getLineAt(fdlID);
							currLine.addLineSegment(null);
						}
					}


					cObject = null;
					var prevCObject: EdgeCoord = null;
					var prevC: Coord = null;

					usedReflections = new Dictionary(true);
					for each(cObject in part)
					{
						if (prevCObject)
						{
							prevC = prevCObject.coord;
							if (cObject && cObject.coord)
							{
								c = cObject.coord;
	//							debug("mapLineCoordToViewReflections : " + prevC.toString() + " , " + c.toString());

								if (bDebugTimes) helpTime = startProfileTimer();
								//find reflections of line defined by coords prevC and c in projection extent
//								reflections = mapLineCoordToViewReflections(prevC, c, projectionExtent);
								reflections = mapLineCoordToViewReflections(prevC, c, m_viewBBox);
//								if (bDebugTimes) stopProfileTimer(helpTime, '\t\t\t mapLineCoordToViewReflections');

								var origLine: FeatureDataLineSegment = new FeatureDataLineSegment(prevC.x, prevC.y,c.x, c.y, true, prevCObject.editable, cObject.editable);
								//temporary check why line is not drawn when it's partially not visible
								var bTemporaryIsInReflection: Boolean = false;

								for each(o in reflections)
								{
									if (bDebugTimes) helpTime = startProfileTimer();
									s_reflectionId = String(o.reflection);

									usedReflections[s_reflectionId] = true;

									reflectedSegmentPoints = d_reflectionToSegmentPoints[s_reflectionId];

									if(reflectedSegmentPoints == null)
									{
										reflectedSegmentPoints = [];
										d_reflectionToSegmentPoints[s_reflectionId] = reflectedSegmentPoints;
									}

									line = new FeatureDataLineSegment(o.pointFrom.x, o.pointFrom.y, o.pointTo.x, o.pointTo.y, true, prevCObject.editable, cObject.editable);
//									if (o.reflection == 0)
//										debug("\t\tdraw lines : "+ line + " reflection: " + o.reflection);

									var bLineIsInsideViewBBox: Boolean = line.isInsideBox(_drawingViewport);
									var bLineIsIntersectedWithViewBBox: Boolean = line.isIntersectedBox(m_viewBBoxWestLine, m_viewBBoxEastLine, m_viewBBoxNorthLine, m_viewBBoxSouthLine);

//									if (bDebugTimes)
//									{
//										stopProfileTimer(helpTime, '\t\t\t bLineIsInsideViewBBox: ' + bLineIsInsideViewBBox + ', bLineIsIntersectedWithViewBBox: ' + bLineIsIntersectedWithViewBBox);
//										helpTime = startProfileTimer();
//									}

//									if (!bLineIsInsideViewBBox && !bLineIsIntersectedWithViewBBox)
//									{
//										if (o.reflection == -1 || o.reflection == 0)
//											debug("Check line [Reflection: " + o.reflection + ", line ID: " + featureDataLineID+"] if it is in reflection ");
//									}
//									var bLineIsInsideReflection: Boolean = line.isInsideBox(getReflectedViewBBox(o.reflection));
//									if (bLineIsInsideViewBBox || bLineIsIntersectedWithViewBBox)
									if (bLineIsInsideViewBBox || bLineIsIntersectedWithViewBBox)
									{
//											if (o.reflection == -1 || o.reflection == 0)
												bTemporaryIsInReflection = true;
		//									debug("\t\t\t DRAW IT");☺
	//										reflection = featureDataLine.parentFeatureData.getReflectionAt(o.reflection);
	//										currLine = reflection.getLineAt(featureDataLine.id);

//											if (bDebugTimes)
//											{
//												stopProfileTimer(helpTime, '\t\t\t\t t1');
//												helpTime = startProfileTimer();
//											}
											reflection = featureData.getReflectionAt(o.reflection);
//											featureDataLine = featureData.getLineAt(reflection.reflectionDelta, featureDataLineID);

//											if (bDebugTimes)
//											{
//												stopProfileTimer(helpTime, '\t\t\t\t t2');
//												helpTime = startProfileTimer();
//											}

											if (bGreatArcHack && drawMode == DrawMode.GREAT_ARC)
												fdlID++;

											currLine = reflection.getLineAt(fdlID);
		//									debug("_drawGeoLine reflection: " + reflection);
		//									debug("_drawGeoLine currLine: " + currLine);

//											if (bDebugTimes)
//											{
//												stopProfileTimer(helpTime, '\t\t\t\t t3');
//												helpTime = startProfileTimer();
//											}
											//check if line is intersect vieBBox
											p1 = coordToPoint(new Coord(ms_crs, o.pointFrom.x, o.pointFrom.y));
											p2 = coordToPoint(new Coord(ms_crs, o.pointTo.x, o.pointTo.y));

//											debug("Add line segment [Reflection: " + reflection.reflectionDelta + ", line ID: " + currLine.id+"] points: " + p1 + " , " + p2);
											var lineSegment: FeatureDataLineSegment = new FeatureDataLineSegment(p1.x, p1.y, p2.x, p2.y, bLineIsInsideViewBBox, prevCObject.editable, cObject.editable);

//											if (bDebugTimes)
//											{
//												stopProfileTimer(helpTime, '\t\t\t\t t4');
//												helpTime = startProfileTimer();
//											}
											currLine.addLineSegment(lineSegment, prevCObject.edge, cObject.edge);

											if (bDebugTimes)
											{
												stopProfileTimer(helpTime, '\t\t\t\t t5');
												helpTime = startProfileTimer();
											}
											reflectedSegmentPoints.push(p1);
											reflectedSegmentPoints.push(p2);

											if (drawMode == DrawMode.PLAIN)
											{
												reflectedSegmentPoints.push(null);
			//									d_reflectionToSegmentPoints[s_reflectionId].push(null);
											}
//									} else {

//										check if line is inside reflection ...so it means it's not visible
//										if (bLineIsIntersectedWithViewBBox)
//										{
//											debug("Line is not visible, but is inside reflection: [Reflection: " + o.reflection + ", line ID: " + featureDataLineID+"]");
//											if (o.reflection == -1 || o.reflection == 0)
//											{
//												bTemporaryIsInReflection = true;
//												reflectedSegmentPoints.push(null);
//											}
//										}
//										if (o.reflection == -1 || o.reflection == 0)
//											debug("There is no intersection with current viewBBox: [Reflection: " + o.reflection + ", line ID: " + featureDataLineID+"]");
									}

//									if (bDebugTimes) stopProfileTimer(helpTime, '\t\t\t add line');
								}
								if (!bTemporaryIsInReflection)
								{
									if (!featureData.closed)
									{
										//add non-visible line to reflection 0 (how to find, which reflection is correct
										reflection = featureData.getReflectionAt(featureData.reflectionsIDs[0]);
										if (bGreatArcHack && drawMode == DrawMode.GREAT_ARC)
											fdlID++;

										currLine = reflection.getLineAt(fdlID);

										if (!lineSegment)
										{
											p1 = coordToPoint(new Coord(ms_crs, line.x1, line.y1));
											p2 = coordToPoint(new Coord(ms_crs, line.x2, line.y2));
											lineSegment = new FeatureDataLineSegment(p1.x, p1.y, p2.x, p2.y, false, false);
										}

										currLine.addLineSegment(lineSegment, prevCObject.edge, cObject.edge);

	//									debug("There is no intersection with current viewBBox: [Reflection: " + o.reflection + ", line ID: " + featureDataLineID+"]");
									}
								}
							}
						}
						if (cObject.coord)
							prevCObject = cObject;
					}
				}
			} else {

				//single coord mode
				for each(part in continousParts)
				{
					cObject = null;
					for each(cObject in part)
					{
						c = cObject.coord;
						reflections = mapCoordInCRSToViewReflections(new Point(c.x, c.y), m_viewBBox);
						for each(o in reflections)
						{
							s_reflectionId = String(o.reflection);
							reflectedSegmentPoints = d_reflectionToSegmentPoints[s_reflectionId];

							if(reflectedSegmentPoints == null)
							{
								reflectedSegmentPoints = [];
								d_reflectionToSegmentPoints[s_reflectionId] = reflectedSegmentPoints;
							}

							line = new FeatureDataLineSegment(o.point.x, o.point.y, Number.NaN, Number.NaN, cObject.editable, false);

							//it's "line with one points
							reflection = featureData.getReflectionAt(o.reflection);

							if (bGreatArcHack && drawMode == DrawMode.GREAT_ARC)
								fdlID++;
							currLine = reflection.getLineAt(fdlID);

//							debug("_drawGeoLine reflection: " + reflection);
//							debug("_drawGeoLine currLine: " + currLine);

							//check if line is intersect vieBBox
							p1 = coordToPoint(new Coord(ms_crs, o.point.x, o.point.y));

							currLine.addLineSegment(new FeatureDataLineSegment(p1.x, p1.y, Number.NaN, Number.NaN, cObject.editable, false), cObject.edge, cObject.edge);

							reflectedSegmentPoints.push(p1);

							if (drawMode == DrawMode.PLAIN)
							{
								reflectedSegmentPoints.push(null);
								//									d_reflectionToSegmentPoints[s_reflectionId].push(null);
							}
						}
					}
				}
			}

//			if (bDebugTimes) debug("\t\t _drawGeoPolyLine - 3 - took " + (getTimer() - currTime) + "ms.");

			for(s_reflectionId in d_reflectionToSegmentPoints) {
				reflectedSegmentPoints = d_reflectionToSegmentPoints[s_reflectionId];
				if(reflectedSegmentPoints.length > 0 && reflectedSegmentPoints[reflectedSegmentPoints.length - 1] != null)
					reflectedSegmentPoints.push(null);
			}

//			if (bDebugTimes) debug("\t_drawGeoPolyLine took " + (getTimer() - currTime) + "ms.");

		}

		protected function startProfileTimer(): Number
		{
			return ProfilerUtils.startProfileTimer();
		}

		/**
		 * Return time interval in seconds
		 * @param startTime
		 * @return
		 *
		 */
		protected function stopProfileTimer(startTime: Number, text: String): void
		{
			debug(ProfilerUtils.formatStringProfileTimer(startTime, text));
		}

		private function _drawReflectedSegmentPoints(rendererCreator: Function, d_reflectionToSegmentPoints: Dictionary): void
		{
			var projectionHalf: Number = getProjectionWidthInPixels() / 2;

			for (var s_reflectionStr: String in d_reflectionToSegmentPoints) {
				var b_first: Boolean = true;
				var ptPrev: Point = null;
				var ptLast: Point = null;

				var l_reflection: int = parseInt(s_reflectionStr);

				var l_reflectedSegmentPoints: Array = d_reflectionToSegmentPoints[s_reflectionStr];

				var g: ICurveRenderer = rendererCreator(l_reflection);

				//debug("_drawReflectedSegmentPoints: l_reflectionStr: " + l_reflectedSegmentPoints.length + " points");
				var str: String = '\nReflection: ' + l_reflection + ': ';
				for each(var pt: Point in l_reflectedSegmentPoints) {
					if(!pt) {
						ptPrev = null;
						str += 'null, ';
					}
					else {
						str += pt.x + ', ';

						if(b_first) {
							g.start(pt.x, pt.y);
							b_first = false;
						}
						if(ptPrev)
							g.lineTo(pt.x, pt.y);
						else
							g.moveTo(pt.x, pt.y);
						ptLast = ptPrev = pt;
					}
				}
				//debug(str);
				if(ptLast)
					g.finish(ptLast.x, ptLast.y);
			}
		}

		public function drawGeoLine(rendererCreator: Function, coordFrom: Coord, coordTo: Coord, drawMode: String, b_justCompute: Boolean = false, featureDataLine: FeatureDataLine = null): void
		{
			var d_reflectionToSegmentPoints: Dictionary = new Dictionary();
			_drawGeoLine(coordFrom, coordTo, drawMode, d_reflectionToSegmentPoints);
			if (!b_justCompute)
				_drawReflectedSegmentPoints(rendererCreator, d_reflectionToSegmentPoints);
		}

		private function debugCoords(coords: Array): void
		{
			return;
			if (coords[0] is Coord)
			{
				debug("DEBUG drawSmoothPolyLine input coords");
				debug("--------------------");

				for each (var cc: Coord in coords)
				{
					if (cc)
						debug("Coord: "+ cc.x + ","+ cc.y);
					else
						debug("--------------------");
				}
				debug("--------------------");
				debug("END DEBUG drawSmoothPolyLine input coords");
			}
			if (coords[0] is Point)
			{
				debug("DEBUG drawSmoothPolyLine input points");
				debug("--------------------");

				for each (var pp: Point in coords)
				{
					if (pp)
						debug("Coord: "+ pp.x + ","+ pp.y);
					else
						debug("--------------------");
				}
				debug("--------------------");
				debug("END DEBUG drawSmoothPolyLine input points");
			}
		}
		private function debugSplittedCoords(coords: Array): void
		{
			return;
			debug("DEBUG splitted coords");
			debug("--------------------");
			for each (var ec: EdgeCoord in coords)
			{
				if (ec)
					debug("Coord: "+ ec.coord.x + ","+ ec.coord.y);
				else
					debug("--------------------");
			}
			debug("--------------------");
			debug("END DEBUG splitted coords");
		}
		/**
		 *
		 * @param rendererCreator
		 * @param coords
		 * @param drawMode
		 * @param b_closed
		 * @param b_justCompute
		 * @param featureData
		 * @param b_fixDateline
		 *
		 */
		public function drawSmoothPolyLine(rendererCreator: Function, coords: Array, drawMode: String, b_closed: Boolean = false, b_justCompute: Boolean = false,  featureData: FeatureData = null, b_fixDateline: Boolean = false): void
		{
			var currTime: Number = getTimer();
//			debug("****************************************************************************");
//			debug("DRAW SMOOTH POLYLINE \n");
			//debug coords
			var renderer: SmoothRendererNew = new SmoothRendererNew(this, distanceValidator, pixelDistanceValidator, datelineBetweenPixelPositions);

			debugCoords(coords);

			var projection: Projection = getCRSProjection();
			if (projection.wrapsHorizontally)
			{
				//Convert pixel points to coordinates (if needed), because of checking dateline crossing
				coords = pointsToCoords(coords);

//				var renderer: SmoothRendererOld = new SmoothRendererOld(this);
				coords = renderer.smoothDatelineOptimization(coords, b_fixDateline);

				//if Polyline crosses dateline, it will drawn as 2 different polylines, so it can not be closed
//				if (renderer.crossDateline(coords))
//				{
//					b_closed = false;
//				}
//			} else {
//				coords = [coords];
			}

			//debug coords
			debugSplittedCoords(coords);

			//coords must be screen pixels position. If needed, convert coordinates to pixel points
//			var points: Array = [];
//			for each (var currCoords: Array in coords)
//			{
//				points.push(coordsToPoints(currCoords));
//			}
//			coords = points;
			coords = coordsToPoints(coords);


			//FIXME need to fix state when all points are counted for 0th reflection, but are not on viewBBox.
			//How to reproduce this... First point in -1 reflection and then continue to 0 reflection


			renderer.drawSmoothDatelineDividedParts(rendererCreator, coords, drawMode, b_closed, b_justCompute, featureData, b_fixDateline);

//			debug("drawSmoothPolyLine took " + (getTimer() - currTime) + "ms.");
//			debug("****************************************************************************");
		}



		/**
		 * Batch conversion of screen pixel positions to coordinates (if needed, otherwise returns same array)
		 * @param points
		 * @return
		 *
		 */
		public function pointsToCoords(points: Array): Array
		{
			var total: int = points.length;
			if (points[0] && !(points[0] is Coord))
			{
				var newCoords: Array = [];
				for (var i: int = 0; i < total; i++)
				{
					var p: Point = points[i] as Point;

					if (p && p.x > 2000)
						trace("debug wrong positions x > 2000");

					if (p)
						newCoords.push(pointToCoord(p.x, p.y));
					else
						newCoords.push(null);
				}
				return newCoords;
			}
			return points;
		}

		/**
		 * Batch conversion of coordinates to screen pixel positions (if needed, otherwise returns same array)
		 * @param coords
		 * @return
		 *
		 */
		public function coordsToPoints(coords: Array): Array
		{
			var total: int = coords.length;
			if ((coords[0] is Coord))
			{
				var newPoints: Array = [];
				for (var i: int = 0; i < total; i++)
				{
					if (coords[i])
					{
						var c: Coord = coords[i] as Coord;
						newPoints.push(coordToPoint(c));
					} else {
						newPoints.push(null);
					}
				}
				return newPoints;
			}
			if ((coords[0] is EdgeCoord))
			{
				newPoints = [];
				for (i = 0; i < total; i++)
				{
					if (coords[i])
					{
						c = (coords[i] as EdgeCoord).coord;
						newPoints.push(coordToPoint(c));
					} else {
						newPoints.push(null);
					}
				}
				return newPoints;
			}
			return coords;
		}

		/**
		 * Draws polyline in current InteractiveWidget projection. It can draw open/close polylines, also with fill (but that's part of renderer). Coords array can contains Coords or Points (screen positions), points will be
		 * automatically converted to Coords. Algorithm assumes that all coords/points are of same type, so it check only first coord/point and convert (if needed) all points.
		 *
		 * @param rendererCreator function, which returns renderer for drawing polyline
		 * @param coords Array of coordinates (type of Coord). If there will be array of Point, algorithm will take them as screen coordinates and will convert them to Coord in current InteractiveWidget projection
		 * @param drawMode supports DrawMode constants
		 * @param b_closed is this is set to true, first coordinate in coords Array will be doubled and inserted at the end
		 * @param featureData if not null, algorithm will fill FeatureData class with all needed data (reflections / lines / lines segments)
		 *
		 */
		public function drawGeoPolyLine(rendererCreator: Function, coords: Array, drawMode: String, b_closed: Boolean = false, b_justCompute: Boolean = false, featureData: FeatureData = null): void
		{
			if (_drawingViewport == null)
			{
				// Check OW-331
				// when creating MultiView, _drawingViewport is null
				debug("Check OW-331, when creating MultiView, _drawingViewport is null");
				return;
			}
			var currTime: Number = getTimer();
//			debug("InteractiveWidget drawGeoPolyLine");
			var d_reflectionToSegmentPoints: Dictionary = new Dictionary();
			var cPrev: Coord = null;
			var total: int = coords.length;
			var cnt: int = 0;

			/**
			 * ATTENTION
			 *
			 * you need to remove all lines before you can draw feature, because there can be issue with lines if feature is crossing dateline
			 * E.g. Feature starts in reflection 0, than continue to reflection 1 and then back to reflection 0. In that case 2nd pass in reflection 0
			 * needs to start not at 0 position, but after already drawn lines (e.g - 1st refl. 0 -> 5 lines, refl. 1 -> 3 lines, 2nd refl.0 -> need to start at 6th line
			 */
			if (featureData)
			{
				cnt = featureData.linesLength;
			}


			//if coords Array is array of points, convert them to coordinates
			coords = pointsToCoords(coords);

			//if line is closed, add 1st coordinate at the end of coordinates array
			if (b_closed)
			{
				coords.push((coords[0] as Coord).clone());
			}


			var featureDataLine: FeatureDataLine;

			if (coords.length > 1)
			{
				//draw geoline as many small geolines
				for each (var c: Coord in coords)
				{
					if(cPrev && c) {
//						if (featureData)
//						{
//							featureDataLine = featureData.getLineAt(cnt-1);
//						}
						_drawGeoLine(cPrev, c, drawMode, d_reflectionToSegmentPoints, featureData, cnt);
					}
					cPrev = c;
					cnt++;
				}
			} else if (coords.length == 1) {
				if (featureData)
				{
//					featureDataLine = featureData.getLineAt(cnt);
					_drawGeoLine(coords[0] as Coord, null, drawMode, d_reflectionToSegmentPoints, featureData, cnt);
				}
			}

			//debug featureData;
//			if (featureData)
//				featureData.debug();

			if (!b_justCompute)
				_drawReflectedSegmentPoints(rendererCreator, d_reflectionToSegmentPoints);

//			debug("drawGeoPolyLine took " + (getTimer() - currTime) + "ms.");
		}

		/**
		 * Draw polyline with given curve renderer. If you just want all polyline reflections without drawing it, use getPolylineReflections function instead
		 * @param g
		 * @param coords
		 * @return
		 *
		 */
		[Deprecated(replacement = drawGeoline)]
		public function drawPolyline(g: ICurveRenderer, coords: Array, b_closed: Boolean = false): Array
		{
			var features: Array = m_featureSplitter.splitCoordPolyLineToArrayOfPointPolyLines(coords, b_closed, false, false);
			var p: Point;
			var oldPoint: Point;
			for each (var mPoints: Array in features)
			{
				var total: int = mPoints.length;
				if (total > 0)
				{
					p = mPoints[0] as Point;

					oldPoint = p;
					g.start(p.x, p.y);
					g.moveTo(p.x, p.y);
					for (var i: int = 1; i < total; i++)
					{
						p = mPoints[i] as Point;
						if (!lineIsOutside(p, oldPoint))
							g.lineTo(p.x, p.y);
						oldPoint = p;
					}
					g.finish(p.x, p.y);
				}
			}
			return features;
		}

		public function drawStyledPolyline(fromCoord: Coord, toCoord: Coord, graphics: Graphics, lineStyle: LineStyle = null, fillStyle: FillStyle = null): Array
		{
			var features: Array = m_featureSplitter.splitCoordPolyLineToArrayOfPointPolyLines([fromCoord, toCoord], false, false, false);
//			debug("drawStyledPolyline features: " + features.length);
			var p: Point;
			var oldPoint: Point;
			for each (var mPoints: Array in features)
			{
				var total: int = mPoints.length;
				if (total > 0)
				{
					p = mPoints[0] as Point;
					oldPoint = p;
					if (lineStyle)
					{
						graphics.lineStyle(lineStyle.thickness, lineStyle.color, lineStyle.alpha, lineStyle.pixelHinting, lineStyle.scaleMode, lineStyle.caps, lineStyle.joints, lineStyle.miterLimit );
//						graphics.lineStyle(1, uint(Math.random()*255*255*255)); //lineStyle.alpha, lineStyle.pixelHinting, lineStyle.scaleMode, lineStyle.caps, lineStyle.joints, lineStyle.miterLimit );
					}
					if (fillStyle)
						graphics.beginFill(fillStyle.color, fillStyle.alpha);

//					g.start(p.x, p.y);
					graphics.moveTo(int(p.x), int(p.y));
//					debug("\ndrawStyledPolyline moveTo("+int(p.x)+", "+p.y+")");
					for (var i: int = 1; i < mPoints.length; i++)
					{
						p = mPoints[i] as Point;
//						if (!lineIsOutside(p, oldPoint))
//						{
//							debug("drawStyledPolyline lineTo("+p.x+", "+p.y+")");
							graphics.lineTo(int(p.x), int(p.y));
//						}
						oldPoint = p;
					}
					if (fillStyle)
						graphics.endFill();
//					g.finish(p.x, p.y);
				}
			}
			return features;
		}

		public function getHermitSpline(_coords: Array, _closed: Boolean = false, _step: Number = 0.01): Array
		{
			var features: Array = m_featureSplitter.splitCoordHermitSplineToArrayOfPointPolyLines(_coords, _closed);
			return features;
		}

		/**
		 *
		 * @param g
		 * @param _coords Array of Coords, if there will be screen pixels (Point), it will be converted
		 * @param _closed
		 * @param _drawHiddenHitMask
		 * @param _step
		 * @return
		 *
		 */
		public function drawHermitSpline(g: ICurveRenderer, _coords: Array, _closed: Boolean = false, _drawHiddenHitMask: Boolean = false, // PREPARED PARAMETER FOR DRAWING HIT MASK AREA
				_step: Number = 0.01): Array
		{
			_coords = pointsToCoords(_coords);

			var features: Array = m_featureSplitter.splitCoordHermitSplineToArrayOfPointPolyLines(_coords, _closed);
			var p: Point;
			for each (var mPoints: Array in features)
			{
				var total: int = mPoints.length;
				if (total > 0)
				{
					p = mPoints[0] as Point;
					g.start(p.x, p.y);
					g.moveTo(p.x, p.y);
					for (var i: int = 1; i < mPoints.length; i++)
					{
						p = mPoints[i] as Point;
						g.lineTo(p.x, p.y);
					}
					g.finish(p.x, p.y);
				}
			}
			return features;
		}

		//*****************************************************************************************
		// AntiCollision functionality
		//*****************************************************************************************
		public function moveAnticollisionLayoutsObjects(widget: InteractiveWidget): void
		{
			m_labelLayout.moveObjectIntoAnticollisionLayout(widget.labelLayout);
			m_objectLayout.moveObjectIntoAnticollisionLayout(widget.objectLayout);
		}

		public function moveAnticollisionLayoutToTop(): void
		{
			removeElement(m_layerLayoutParent);
			addElement(m_layerLayoutParent);
		}

		private var _forceAnticollisionUpdate: Boolean;

		public function anticollisionObjectsVisibilityForLayer(layer: InteractiveLayer, visible: Boolean): void
		{
			var labelLayoutsObjects: Array =  m_labelLayout.getAnticollisionLayoutObjectsForLayer(layer);
			for each (var object1: AnticollisionLayoutObject in labelLayoutsObjects)
			{
				m_labelLayout.setObjectVisibility(object1.object, visible);
			}
			var objectLayoutsObjects: Array =  m_objectLayout.getAnticollisionLayoutObjectsForLayer(layer);
			for each (var object2: AnticollisionLayoutObject in objectLayoutsObjects)
			{
				m_objectLayout.setObjectVisibility(object2.object, visible);
			}
		}
		public function anticollisionObjectVisible(object: DisplayObject, visible: Boolean): void
		{
			m_labelLayout.setObjectVisibility(object, visible);
			m_objectLayout.setObjectVisibility(object, visible);
		}

		public function anticollisionForcedUpdate(): void
		{
			_forceAnticollisionUpdate = true;
			invalidateProperties();
		}
		private function anticollisionUpdate(): void
		{
			if (!m_suspendAnticollisionProcessing)
			{
				if (m_labelLayout.needsUpdate())
				{
					notifyAnticollisionUpdate();
					m_labelLayout.invalidateLayout();
				}
				if (m_objectLayout.needsUpdate())
				{
					notifyAnticollisionUpdate();
					m_objectLayout.invalidateLayout();
				}
			}
		}

		private function notifyAnticollisionUpdate(): void
		{
			dispatchEvent(new Event(AnticollisionLayout.ANTICOLLISTION_UPDATED));
		}

		private var _anticollisionVisible: Boolean;
		public function get anticollisionVisible(): Boolean
		{
			return _anticollisionVisible;
		}

		public function set anticollisionVisible(value: Boolean): void
		{
			if (!m_suspendAnticollisionProcessing)
			{
				if (_anticollisionVisible != value)
				{
					_anticollisionVisible = value;
					if (m_objectLayout)
					{
						m_objectLayout.visible = value;
					}
					if (m_labelLayout)
					{
						m_labelLayout.visible = value;
					}
				}
			}
		}

		/**
		 * do not need suspendResizeNotifying for now, but I'm just leaving it here for futre needs
		 *
		 */
		/*
		private var m_suspendResizeNotifying: Boolean = false;

		public function get suspendResizeNotifying(): Boolean
		{
			return m_suspendResizeNotifying;
		}
		public function set suspendResizeNotifying(value: Boolean): void
		{
			if (m_suspendResizeNotifying != value)
			{
				m_suspendResizeNotifying = value;
			}
		}
		*/

		private var m_suspendDataUpdating: Boolean;
		private var m_suspendDataUpdatingChanged: Boolean;

		public function get suspendDataUpdating(): Boolean
		{
			return m_suspendDataUpdating;
		}

		/**
		 * If there are lot of data invalidation and you do not want to update data and load them, set suspendDataUpdating = true.
		 * After suspendDataUpdating set to false if layer data was invalidated, layer will update its data
		 *
		 * @param value
		 *
		 */
		public function set suspendDataUpdating(value: Boolean): void
		{
			if (value != m_suspendDataUpdating)
			{
				m_suspendDataUpdating = value;
				m_suspendDataUpdatingChanged = true;

				debug("commitProperties suspendDataUpdating = " + m_suspendDataUpdating);

				invalidateProperties();
			}
		}

		public function get suspendAnticollisionProcessing(): Boolean
		{
			return m_suspendAnticollisionProcessing;
		}

		public function set suspendAnticollisionProcessing(value: Boolean): void
		{
			if (!FlexiWeatherConfiguration.USE_SUSPEND_ANTICOLLISION)
				return;

			if (m_suspendAnticollisionProcessing != value)
			{
				m_suspendAnticollisionProcessing = value;

				debug("suspendAnticollisionProcessing = " + value);
				if (m_objectLayout)
				{
					// set suspendAnticollisionProcessing to AnticollisionLayout as well (there is timer for auto update, which needs to be suspended)
					m_objectLayout.suspendAnticollisionProcessing = value;
				}
				if (m_labelLayout)
				{
					// set suspendAnticollisionProcessing to AnticollisionLayout as well (there is timer for auto update, which needs to be suspended)
					m_labelLayout.suspendAnticollisionProcessing = value;
				}
				anticollisionUpdate();
			}
		}

		private function debug(str: String, type: String = "Info", tag: String = " InteractiveWidget"): void
		{
			if (id != null)
			{
//				trace(this + "| " + type + "| " + str);
//				LoggingUtils.dispatchLogEvent(this, tag + "| " + type + "| " + str);
			}
		}

		//*****************************************************************************************
		// Getters & setters
		//*****************************************************************************************
		[Bindable(event = "crsChanged")]
		public function get crs(): String
		{
			return getCRS();
		}

		[Bindable(event = "crsChanged")]
		public function set srs(s_crs: String): void
		{
			return setCRS(s_crs, true);
		}

		public function set backgroundChessBoard(b: Boolean): void
		{
			mb_backgroundChessBoard = b;
			invalidateDisplayList();
		}
		private var m_interactiveLayerMap: InteractiveLayerMap;

		[Bindable(event = "interactiveLayerMapChanged")]
		public function get interactiveLayerMap(): InteractiveLayerMap
		{
			return m_interactiveLayerMap;
		}

		public function get layerContainer(): Group
		{
			return m_layerContainer;
		}

		public function get wmsCacheManager(): WMSCacheManager
		{
			return m_wmsCacheManager;
		}

		public function set wmsCacheManager(value: WMSCacheManager): void
		{
			m_wmsCacheManager = value;
		}

		public function get labelLayout(): AnticollisionLayout
		{
			return m_labelLayout;
		}

		public function get objectLayout(): AnticollisionLayout
		{
			return m_objectLayout;
		}

		override public function toString(): String
		{
			return "InteractiveWidget [" + id + "] ";
		}
		private var mb_autoLayoutChanged: Boolean;

		/**
		 * FitMap
		 * @param value
		 *
		 */
		public function set autoLayoutInParent(value: Boolean): void
		{
			if (mb_autoLayout != value)
			{
				mb_autoLayout = value;
				mb_autoLayoutChanged = true;
				invalidateProperties();

				debug(id + " autoLayoutInParent = " + mb_autoLayout);
			}
		}

		public function get autoLayoutInParent(): Boolean
		{
			return mb_autoLayout;
		}

	}
}
import com.iblsoft.flexiweather.FlexiWeatherConfiguration;
import com.iblsoft.flexiweather.ogc.BBox;
import com.iblsoft.flexiweather.ogc.editable.data.FeatureData;
import com.iblsoft.flexiweather.ogc.editable.data.FeatureDataLineSegment;
import com.iblsoft.flexiweather.ogc.kml.InteractiveLayerKML;
import com.iblsoft.flexiweather.proj.Coord;
import com.iblsoft.flexiweather.proj.Projection;
import com.iblsoft.flexiweather.utils.CubicBezier;
import com.iblsoft.flexiweather.utils.geometry.LineSegment;
import com.iblsoft.flexiweather.widgets.InteractiveLayerPan;
import com.iblsoft.flexiweather.widgets.InteractiveLayerZoom;
import com.iblsoft.flexiweather.widgets.InteractiveWidget;

import flash.events.Event;
import flash.geom.Point;
import flash.utils.getTimer;

class WidgetSize
{
	public var x: Number = 0;
	public var y: Number = 0;
	private var m_width: Number;
	private var m_height: Number;

	public function set width(value:Number):void
	{
		m_width = value;
	}
	public function get width():Number
	{
		return m_width;
	}

	public function set height(value:Number):void
	{
		m_height = value;
	}
	public function get height():Number
	{
		return m_height;
	}


	public function setBounds(x: Number, y: Number, width: Number, height: Number): void
	{
		this.x = x;
		this.y = y ;
		this.width = width;
		this.height = height;
	}
}

class KMLSpeedOptimization
{
	private var m_iw: InteractiveWidget;
	private var m_zoomLayer: InteractiveLayerZoom;
	private var m_panLayer: InteractiveLayerPan;
	private var m_kmlLayers: Array = [];

	private var _layoutVisibilityBeforePanning: Boolean;

	public function KMLSpeedOptimization(widget: InteractiveWidget)
	{
		m_iw = widget;
	}
	public function destroy(): void
	{
		if (m_zoomLayer)
		{
			m_zoomLayer.removeEventListener(InteractiveLayerZoom.START_ZOOMING, onStartZooming);
			m_zoomLayer.removeEventListener(InteractiveLayerZoom.STOP_ZOOMING, onStopZooming);
		}
		if (m_panLayer)
		{
			m_panLayer.removeEventListener(InteractiveLayerPan.START_PANNING, onStartPanning);
			m_panLayer.removeEventListener(InteractiveLayerPan.STOP_PANNING, onStopPanning);
		}

		if (m_kmlLayers)
			m_kmlLayers.splice(0, m_kmlLayers.length);
	}

	public function setPanLayer(layer: InteractiveLayerPan): void
	{
		m_panLayer = layer;

		if (FlexiWeatherConfiguration.USE_KML_BITMAP_PANNING)
		{
			m_panLayer.addEventListener(InteractiveLayerPan.START_PANNING, onStartPanning);
			m_panLayer.addEventListener(InteractiveLayerPan.STOP_PANNING, onStopPanning);
		}
	}
	public function setZoomLayer(layer: InteractiveLayerZoom): void
	{
		m_zoomLayer = layer;

		if (FlexiWeatherConfiguration.USE_KML_BITMAP_PANNING)
		{
			m_zoomLayer.addEventListener(InteractiveLayerZoom.START_ZOOMING, onStartZooming);
			m_zoomLayer.addEventListener(InteractiveLayerZoom.STOP_ZOOMING, onStopZooming);
		}
	}
	public function addKMLLayer(layer: InteractiveLayerKML): void
	{
		m_kmlLayers.push(layer);
	}

	private function onStartPanning(event: Event): void
	{
		startOptimization();
	}
	private function onStartZooming(event: Event): void
	{
		startOptimization();
	}

	private function startOptimization(): void
	{
		if (FlexiWeatherConfiguration.USE_KML_BITMAP_PANNING)
		{
			_layoutVisibilityBeforePanning = m_iw.labelLayout.visible;
			if (!_layoutVisibilityBeforePanning)
			{
				//trace("Check _layoutVisibilityBeforePanning == false");
			}
			m_iw.labelLayout.visible = false;

			for each (var layer: InteractiveLayerKML in m_kmlLayers)
			{
				layer.suspendUpdating = true;
			}

			m_iw.suspendAnticollisionProcessing = true;
		}
	}

	private function onStopZooming(event: Event): void
	{
		stopOptimization();
	}
	private function onStopPanning(event: Event): void
	{
		stopOptimization();
	}

	private function stopOptimization(): void
	{
		if (FlexiWeatherConfiguration.USE_KML_BITMAP_PANNING)
		{
			m_iw.suspendAnticollisionProcessing = false;
			m_iw.labelLayout.visible = _layoutVisibilityBeforePanning;

			for each (var layer: InteractiveLayerKML in m_kmlLayers)
			{
				layer.suspendUpdating = false;
			}
		}
	}
}

class EdgeCoord
{
	public var coord: Coord;
	public var edge: Boolean;
	public var editable: Boolean;

	public function EdgeCoord(coord: Coord, edge: Boolean, editable: Boolean)
	{
		this.coord = coord;
		this.edge = edge;
		this.editable = editable;
	}

	public function clone(): EdgeCoord
	{
		var ec: EdgeCoord = new EdgeCoord(new Coord(coord.crs, coord.x, coord.y), edge, editable);
		return ec;
	}
}

class SmoothRendererNew
{
	private var _iw: InteractiveWidget;
	public var distanceValidator: Function;
	public var pixelDistanceValidator: Function;
	public var discontinuityValidator: Function;

	public function SmoothRendererNew(iw: InteractiveWidget, distanceValidator: Function, pixelDistanceValidator: Function, discontinuityValidator: Function)
	{
		_iw = iw;
		this.distanceValidator = distanceValidator;
		this.pixelDistanceValidator = pixelDistanceValidator;
		this.discontinuityValidator = discontinuityValidator;
	}
	public function crossDateline(coords: Array): Boolean
	{
		if (coords.length < 1)
			return false;

		var projection: Projection = _iw.getCRSProjection();

		var cnt: int = 0;
		var coordFrom: Coord = (coords[0] as EdgeCoord).coord;
		coordFrom = Coord.convertCoordOnSphere(coordFrom, projection);
		var coordTo: Coord;
			cnt++;

		while (cnt < coords.length)
		{
			coordTo = (coords[cnt] as EdgeCoord).coord;
			coordTo = Coord.convertCoordOnSphere(coordTo, projection);

			if (_iw.coordsFarThanExtentWidth(coordFrom, coordTo) )
			{
				return true;
			}
			coordFrom = coordTo;
			cnt++;
		}
		return false;
	}

	/**
	 *
	 * @param coords
	 * @param b_fixDateline
	 * @return
	 *
	 */
	public function smoothDatelineOptimization(coords: Array, b_fixDateline: Boolean = false): Array
	{
		var currTime: Number = getTimer();

		var projection: Projection = _iw.getCRSProjection();
		var projectionWidth: Number = projection.extentBBox.width;

		var newCoords: Array = [];
		var tempCoords: Array = null;

		var coordFrom: Coord = coords.shift();
		coordFrom = Coord.convertCoordOnSphere(coordFrom, projection);
		var coordTo: Coord;

		var finalArray: Array = [];

		while (coords.length > 0)
		{
			tempCoords = null;
			coordTo = coords.shift();
			coordTo = Coord.convertCoordOnSphere(coordTo, projection);

//			debug("\n from: "+ coordFrom.x + ","+coordFrom.y + " to: " + coordTo.x + " , " + coordTo.y);

//			if (_iw.crossDateline(coordFrom, coordTo) || _iw.coordsFarThanExtentWidth(coordFrom, coordTo) )
			if (_iw.coordsFarThanExtentWidth(coordFrom, coordTo) )
			{
//				debug("\n\t crossing dateline");
				//create line1 in correct order
				if (coordFrom.x > coordTo.x)
					coordTo.x += projectionWidth;
				else {
					coordTo.x -= projectionWidth;
				}

				if (coordFrom.x > 180 && coordTo.x > 180)
				{
					trace("Test why both coords are outside zero reflection");
				}
				if (_iw.crossDateline(coordFrom, coordTo))
				{
					var useDatelineSplit: Boolean = false;

					if (useDatelineSplit)
					{

						var dateline: LineSegment = getDatelineForCoords(coordFrom, coordTo);

						var cFx: Number = coordFrom.x;
						var cFy: Number = coordFrom.y;
						var cTx: Number = coordTo.x;
						var cTy: Number = coordTo.y;

						var line1: FeatureDataLineSegment = new FeatureDataLineSegment(cFx, cFy, cTx, cTy, true, true, true);
						var intersection: Point = line1.intersectionWithInfiniteLineSegment(dateline);
						var direction: int = 1;
						if (cFx > cTx)
							direction = -1;
						var intersectionCoordLeft: Coord = new Coord(coordFrom.crs, dateline.x1 - direction * 0.00001, intersection.y);
						var intersectionCoordRight: Coord = new Coord(coordFrom.crs, dateline.x1 + direction * 0.00001, intersection.y);
	//					intersectionCoordRight = Coord.convertCoordOnSphere(intersectionCoordRight, projection);

						trace("smoothDatelineOptimization dateline: from: " + coordFrom.toString() + " to: " + coordTo.toString());
						tempCoords = [];
						tempCoords.push(new EdgeCoord(coordFrom, false, true));
						tempCoords.push(new EdgeCoord(intersectionCoordLeft, true, true));
						tempCoords.push(null);
						tempCoords.push(new EdgeCoord(intersectionCoordRight, true, true));
						tempCoords.push(new EdgeCoord(coordTo, true, true));


						var arcTempCoords: Array = [];

						var ec1: EdgeCoord;
						var ec2: EdgeCoord;
						while(tempCoords.length > 0)
						{
							if (tempCoords[0] == null)
								arcTempCoords.push(tempCoords.shift());

							if (!ec1 && tempCoords.length > 0)
								ec1 = tempCoords.shift();
							if (!ec2 && tempCoords.length > 0)
								ec2 = tempCoords.shift();

							if (ec1 && ec2)
							{
								var arcCoords: Array = Coord.interpolateGreatArc(ec1.coord, ec2.coord, distanceValidator, discontinuityValidator);
								for each (var c: Coord in arcCoords)
								{
									if (c)
										arcTempCoords.push(new EdgeCoord(c, false, true));
									else
										arcTempCoords.push(null);
//									arcTempCoords.push(new EdgeCoord(c, false, true));
								}

								ec1 = null;
								ec2 = null;
							}
						}

						tempCoords = arcTempCoords;

	//					tempCoords = _iw.splitCoordsOnDateline(coordFrom, coordTo);
						var len: int = tempCoords.length;
						for (var i: int = 0; i < len - 1; i++)
						{
							var ec: EdgeCoord = tempCoords[i] as EdgeCoord;
							if (ec)
								newCoords.push(ec);
							else {
								finalArray.push(newCoords);
								newCoords = [];
							}
						}
	//
						coordTo = (tempCoords[len - 1] as EdgeCoord).coord;
					} else {
						newCoords.push(new EdgeCoord(coordFrom, false, true));
					}

				} else {
					newCoords.push(new EdgeCoord(coordFrom, false, true));
				}
			} else {
//				debug("\n\n NOT crossing dateline");
//				debug("\t Adding COORD FROM coord: " + coordFrom.x + " , " + coordFrom.y);
				newCoords.push(new EdgeCoord(coordFrom, false, true));
			}
			coordFrom = coordTo;
		}
		finalArray.push(newCoords);

		if (coordTo)
		{
//			debug("\t Adding last COORD TO coord: " + coordTo.x + " , " + coordTo.y);
			newCoords.push(new EdgeCoord(coordTo, false, true));
		}

//		debug("smoothDatelineOptimization took " + (getTimer() - currTime) + "ms.");

//		return finalArray;
		return newCoords;
	}

	private function getDatelineForCoords(coordFrom: Coord, coordTo: Coord): LineSegment
	{
		var cF: Coord = coordFrom;
		var cT: Coord = coordTo;

		if (coordFrom.x > coordTo.x)
		{
			cF = coordTo;
			cT = coordFrom;
		}

		var datelineX: int = 180;
		if (cF.x <= datelineX && cT.x >= datelineX)
		{
			return new LineSegment(180,-90,180,90);
		}

		var direction: int;
		(cT.x < datelineX) ? direction = -1 : direction = 1;
		while (!(cF.x <= datelineX && cT.x >= datelineX))
		{
			datelineX += (direction * 360);
		}

		return new LineSegment(datelineX,-90,datelineX,90);

	}

	public function drawSmoothDatelineDividedParts(rendererCreator: Function, splittedReflectionCoords: Array, drawMode: String, b_closed: Boolean = false, b_justCompute: Boolean = false,  featureData: FeatureData = null, b_fixDateline: Boolean = false): void
	{
		var currTime: Number = getTimer();
		var splinePoints: Array;
		var splineCoords: Array

		//find all parts and create hermit spline for them
//		var tempCoords: Array = [];
//		while (coords.length > 0)
//		{
//			var p: Point = coords.shift();
//			if (p)
//			{
//				tempCoords.push(p)
//			} else {
//				//there is null, so previous part finished
//				if (tempCoords.length > 0)
//				{
//					splinePoints = CubicBezier.calculateHermitSpline(tempCoords, false);
//
//					//Convert pixel points to coordinates
//					splineCoords = _iw.pointsToCoords(splinePoints);
//
//					//TODO check b_closed, if it was split
//					_iw.drawGeoPolyLine(rendererCreator, splineCoords, drawMode, b_closed, b_justCompute, featureData);
//
//				}
//				tempCoords = [];
//			}
//		}
		//check last part
		if (splittedReflectionCoords.length > 0)
		{
//			splinePoints = CubicBezier.calculateHermitSpline(tempCoords, false);

			//if there is dateline (null), we need to split coords before hermit splin
//			for each (var coords: Array in splittedReflectionCoords)
//			{
				var coords: Array = splittedReflectionCoords;
//				for each (var q: * in coords)
//				{
//					trace("Q coord: "+ q.toString());
//				}

				splinePoints = CubicBezier.calculateHermitSpline(coords, b_closed, pixelDistanceValidator, discontinuityValidator);

				//clip to InteractiveWidget area
				/*

				//clipping was moved to FeatureDataReflection to compute method

				if (featureData.forceViewBBoxClipping)
				{
					var margin: int = -15;
					var rightMargin: int = 15;
					var clipPolygon: Array = [new Point(_iw.areaX + margin, _iw.areaY + margin), new Point(_iw.areaX + _iw.areaWidth + rightMargin, _iw.areaY + margin), new Point(_iw.areaX + _iw.areaWidth + rightMargin, _iw.areaHeight + rightMargin), new Point(_iw.areaX + margin, _iw.areaHeight + rightMargin)];

					//FIXME here is the problem, if points are off screen (0 reflection is off screen), then clipping removes points
					splinePoints = _iw.featureSplitter.polygonClipppingSutherlandHodgman(splinePoints, clipPolygon);
				}
				*/

				//Convert pixel points to coordinates
				//debug spliceCoontds

				splineCoords = _iw.pointsToCoords(splinePoints);

				/*var str: String = "";
				var str2: String = "";
				var leftX:  Number = 0;
				var rightX:  Number = 360;
				for each (var c: Coord in splineCoords)
				{
					if (c)
					{
						var p: Point = _iw.coordToPoint(c);
						if (c.x > leftX && c.x < 180)
							leftX = c.x;
						if (c.x < rightX && c.x > 180)
							rightX = c.x;
						str += c.x + ", ";
						str2 += p.x + ", ";
					} else {
						str += "null, ";
						str2 += "null, ";

					}
				}
				trace("leftX: " + leftX + " rightX: " + rightX);
				trace(str);
				trace(str2);*/

				var b_originalClosed: Boolean = b_closed;

				if (splineCoords.length == 0)
					return;

				var splittedSplinesCoords: Array = splitSplineCoords(splineCoords);
				var isDatelineSplit: Boolean = splittedSplinesCoords.length > 1;

				if (isDatelineSplit)
					b_closed = false;

				var splitPartID: int = 0;
				var firstCoord: Coord;

				for each (var currSplineCoords: Array in splittedSplinesCoords)
				{
					var addDatelineCrossing: Boolean = true;

					if (b_originalClosed)
					{
						if (splitPartID == 0)
							firstCoord = currSplineCoords[0] as Coord;

						//close last part with first coord of first part
						if (splitPartID == (splittedSplinesCoords.length - 1))
						{
							currSplineCoords.push(firstCoord);
							addDatelineCrossing = false;
						}
					}

//					if (addDatelineCrossing)
//					{
//						currSplineCoords.push(null);
//					}
					//TODO check b_closed, if it was split
	//				switch (splitPartID)
	//				{
	//					case 0:
	//					case 1:
	//					case 2:
							_iw.drawGeoPolyLine(rendererCreator, currSplineCoords, drawMode, b_closed, b_justCompute, featureData);
	//						break;
	//				}

					splitPartID++;

				}
//			}

		}
//		debug("drawSmoothDatelineDividedParts took " + (getTimer() - currTime) + "ms.");
	}

	private function splitSplineCoords(coords: Array): Array
	{
		var projection: Projection = _iw.getCRSProjection();
		var projectionLeft: Number = projection.extentBBox.xMin;
		var projectionWidth: Number = projection.extentBBox.width;

		var splines: Array = [];
		var currentSpline: Array = [];

		var coord: Coord = coords[0] as Coord;
		var initReflection: int = getReflectionForCoord(coord, projectionLeft, projectionWidth);

		currentSpline.push(coord);

		var total: int = coords.length;
		var bNextCoordToLastReflection: Boolean;
		var previousCoord: Coord;

		for (var i: int = 1; i < total; i++)
		{
			coord = coords[i] as Coord;
			if (coord)
			{
				var currReflection: int = getReflectionForCoord(coord, projectionLeft, projectionWidth);

				if (currReflection != initReflection)
				{
					//insert first from next reflection
	//				currentSpline.push(coord);
					splines.push(currentSpline);

	//				splines.push(lastSpline);

					//first coord is from previous reflection
					currentSpline = [];
					initReflection = currReflection;
	//			} else {
	//				lastSpline = null;
				}

				currentSpline.push(coord);

				previousCoord = coord;
			}
		}
		splines.push(currentSpline);

		return splines;
	}


	private function getReflectionForCoord(c: Coord, projectionLeft: Number, projectionWidth: Number): int
	{
		return int((c.x - projectionLeft) / projectionWidth)
	}
}