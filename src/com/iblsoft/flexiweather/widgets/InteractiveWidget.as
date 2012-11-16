package com.iblsoft.flexiweather.widgets
{
	import com.iblsoft.flexiweather.events.InteractiveLayerEvent;
	import com.iblsoft.flexiweather.events.InteractiveWidgetEvent;
	import com.iblsoft.flexiweather.ogc.BBox;
	import com.iblsoft.flexiweather.ogc.cache.WMSCacheKey;
	import com.iblsoft.flexiweather.ogc.cache.WMSCacheManager;
	import com.iblsoft.flexiweather.proj.Coord;
	import com.iblsoft.flexiweather.proj.Projection;
	import com.iblsoft.flexiweather.utils.CubicBezier;
	import com.iblsoft.flexiweather.utils.ICurveRenderer;
	import com.iblsoft.flexiweather.utils.anticollision.AnticollisionLayout;
	import com.iblsoft.flexiweather.utils.wfs.FeatureSplitter;
	import flash.display.DisplayObject;
	import flash.display.GradientType;
	import flash.display.Graphics;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.events.TimerEvent;
	import flash.geom.Matrix;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.system.Capabilities;
	import flash.utils.Timer;
	import flash.utils.clearTimeout;
	import flash.utils.getTimer;
	import flash.utils.setTimeout;
	import mx.containers.Canvas;
	import mx.core.IVisualElement;
	import mx.core.UIComponent;
	import mx.core.mx_internal;
	import mx.events.DynamicEvent;
	import mx.events.FlexEvent;
	import mx.events.ResizeEvent;
	import spark.components.Group;
	import spark.components.SkinnableContainer;
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
		private var ms_crs: String = Projection.CRS_EPSG_GEOGRAPHIC;
		private var m_crsProjection: Projection = Projection.getByCRS(ms_crs);
		private var m_viewBBox: BBox = new BBox(-180, -90, 180, 90);
		private var m_extentBBox: BBox = new BBox(-180, -90, 180, 90);
		private var mb_orderingLayers: Boolean = false;
		private var mb_autoLayout: Boolean = false;
		private var mb_backgroundChessBoard: Boolean = true;
		private var m_resizeTimer: Timer;
		private var m_layerBackground: UIComponent;
		private var m_layerContainer: Group = new Group();
		private var m_layerLayoutParent: UIComponent;
		private var m_lastResizeTime: Number;
		private var m_wmsCacheManager: WMSCacheManager;
		/**
		 * anticollision layout for Labels
		 */
		private var m_labelLayout: AnticollisionLayout = new AnticollisionLayout('Label Layout');
		/**
		 * anticollision layout for Labels
		 */
		private var m_objectLayout: AnticollisionLayout = new AnticollisionLayout('Object Layout');
		/**
		 * Set it to true when you want suspend anticaollision processing (e.g. user is dragging map)
		 */
		private var m_suspendAnticollisionProcessing: Boolean;
		private var _enableMouseClick: Boolean;
		private var _enableMouseMove: Boolean;
		private var _enableMouseWheel: Boolean;
		private var _enableGestures: Boolean;

		override public function set enabled(value: Boolean): void
		{
			super.enabled = value;
//			trace("\t\t InteractiveWidget ["+id+"] enabled = " + value);
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

		public function InteractiveWidget()
		{
			super();
			enableGestures = true;
			enableMouseClick = true;
			enableMouseMove = true;
			enableMouseWheel = true;
			mouseEnabled = true;
			mouseFocusEnabled = true;
			doubleClickEnabled = true;
			clipAndEnableScrolling = true;
			m_layerContainer.x = m_layerContainer.y = 0;
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
			m_lastResizeTime = getTimer();
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
				m_resizeTimer.removeEventListener(TimerEvent.TIMER_COMPLETE, afterDelayedResize);
			}
			m_featureSplitter.destroy();
		}

		override protected function createChildren(): void
		{
			super.createChildren();
			m_layerBackground = new UIComponent();
			m_layerLayoutParent = new UIComponent();
			m_featureSplitter = new FeatureSplitter(this);
		}

		override protected function childrenCreated(): void
		{
			super.childrenCreated();
			addElement(m_layerBackground);
			addElement(m_layerContainer);
			addElement(m_layerLayoutParent);
			m_layerLayoutParent.addChild(m_labelLayout);
		}

		override protected function commitProperties(): void
		{
			super.commitProperties();
			if (mb_autoLayoutChanged)
			{
				var widgetParent: Group = parent as Group;
				if (widgetParent)
				{
					if (mb_autoLayout)
						widgetParent.addEventListener(ResizeEvent.RESIZE, onParentResize);
					else
						widgetParent.removeEventListener(ResizeEvent.RESIZE, onParentResize);
				}
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
			for each (var layer: InteractiveLayer in _mxmlContentElements)
			{
				addLayer(layer);
			}
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
				orderLayers();
				return o;
			}
			else
				return super.addElementAt(element, index);
		}
		private var m_layersLoading: int = 0;

		private function onLayerLoadingStart(event: InteractiveLayerEvent): void
		{
			m_layersLoading++;
			var ile: InteractiveWidgetEvent = new InteractiveWidgetEvent(InteractiveWidgetEvent.DATA_LAYER_LOADING_STARTED);
			ile.layersLoading = m_layersLoading;
			dispatchEvent(ile);
		}

		private function onLayerLoaded(event: InteractiveLayerEvent): void
		{
			m_layersLoading--;
			var ile: InteractiveWidgetEvent
			ile = new InteractiveWidgetEvent(InteractiveWidgetEvent.DATA_LAYER_LOADING_FINISHED);
			ile.layersLoading = m_layersLoading;
			dispatchEvent(ile);
			if (m_layersLoading <= 0)
			{
				ile = new InteractiveWidgetEvent(InteractiveWidgetEvent.ALL_DATA_LAYERS_LOADED);
				dispatchEvent(ile);
			}
		}

		private function onLayerInInteractiveLayerMapAdded(event: DynamicEvent): void
		{
			notifyWidgetChanged('layerAddedInInteractiveLayerMap');
		}

		private function onLayerInInteractiveLayerMapRemoved(event: DynamicEvent): void
		{
			notifyWidgetChanged('layerRemovedInInteractiveLayerMap');
		}

		private function registerInteractiveLayerMap(ilm: InteractiveLayerMap): void
		{
			if (ilm)
			{
//				ilm.addEventListener(InteractiveLayerMap.TIME_AXIS_UPDATED, onTimeAxisUpdated);
				ilm.addEventListener(InteractiveLayerMap.TIME_AXIS_ADDED, onLayerInInteractiveLayerMapAdded);
				ilm.addEventListener(InteractiveLayerMap.TIME_AXIS_REMOVED, onLayerInInteractiveLayerMapRemoved);
			}
		}

		private function unregisterInteractiveLayerMap(ilm: InteractiveLayerMap): void
		{
			if (ilm)
			{
//				ilm.addEventListener(InteractiveLayerMap.TIME_AXIS_UPDATED, onTimeAxisUpdated);
				ilm.addEventListener(InteractiveLayerMap.TIME_AXIS_ADDED, onLayerInInteractiveLayerMapAdded);
				ilm.addEventListener(InteractiveLayerMap.TIME_AXIS_REMOVED, onLayerInInteractiveLayerMapRemoved);
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
			l.addEventListener(InteractiveDataLayer.LOADING_FINISHED, onLayerLoaded);
			l.addEventListener(InteractiveDataLayer.LOADING_STARTED, onLayerLoadingStart);
			l.addEventListener(InteractiveLayerEvent.LAYER_INITIALIZED, onLayerInitialized);
//			var bAddLayer: Boolean = false;
			//all map data layer have to go to interactiveLayerMap, all others just to interactiveWidget
			if (l is InteractiveLayerMap)
				setInteractiveLayerMap(l as InteractiveLayerMap);
			l.container = this;
			if (index >= 0)
				addElementAt(l, index);
			else
				addElement(l);
			//all other functionality will be done after layer will be initialized in onLayerInitialized function
		}

		private function onLayerInitialized(event: InteractiveLayerEvent): void
		{
			var l: InteractiveLayer = event.target as InteractiveLayer;
			//when new layer is added to container, call onAreaChange to notify layer, that layer is already added to container, so it can render itself
			l.onAreaChanged(true);
			orderLayers();
			notifyWidgetChanged('addLayer');
		}

		public function removeLayer(l: InteractiveLayer, b_destroy: Boolean = false): void
		{
			if (l is InteractiveLayerMap && m_interactiveLayerMap == l)
				setInteractiveLayerMap(null);
			l.removeEventListener(InteractiveDataLayer.LOADING_FINISHED, onLayerLoaded);
			l.removeEventListener(InteractiveDataLayer.LOADING_STARTED, onLayerLoadingStart);
			if (l.parent == m_layerContainer)
			{
				l.container = null;
				m_layerContainer.removeElement(l);
				l.destroy();
			}
			notifyWidgetChanged('removeLayer');
		}

		public function removeAllLayers(): void
		{
			while (m_layerContainer.numElements)
			{
				var i: int = m_layerContainer.numElements - 1;
				var l: InteractiveLayer = InteractiveLayer(m_layerContainer.getElementAt(i));
				l.removeEventListener(InteractiveDataLayer.LOADING_FINISHED, onLayerLoaded);
				l.removeEventListener(InteractiveDataLayer.LOADING_STARTED, onLayerLoadingStart);
				l.destroy();
				m_layerContainer.removeElementAt(i);
			}
		}

		public function orderLayers(): void
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
							m_layerContainer.swapElements(ilJ, ilI);
						}
					}
				}
			}
			catch (error: Error)
			{
				trace("InteractiveLayer.orderLayer: catch: " + error.message);
			}
			finally
			{
				mb_orderingLayers = false;
			}
			if (interactiveLayerMap)
				interactiveLayerMap.orderLayers();
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
			g.beginFill(0);
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
			m_layerContainer.width = width;
			m_layerContainer.height = height;
			if (m_labelLayout.m_placementBitmap == null)
				m_labelLayout.setBoundary(new Rectangle(0, 0, width, height));
			var g: Graphics = m_layerBackground.graphics;
			g.clear();
			if (!enabled)
			{
				drawDisabledState();
				return;
			}
			else
			{
				if (_disableUI)
				{
					_disableUI.includeInLayout = false;
					_disableUI.visible = false;
				}
			}
			anticollisionUpdate();
			if (mb_backgroundChessBoard)
			{
				var i_squareSize: uint = 10;
				var i_row: uint = 0;
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
		}

		protected function signalAreaChanged(b_finalChange: Boolean): void
		{
			onAreaChanged(b_finalChange);
		}
		private var _oldViewBBox: BBox = new BBox(0, 0, 0, 0);

		protected function onAreaChanged(b_finalChange: Boolean): void
		{
			if (_oldViewBBox.equals(m_viewBBox))
			{
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
			//dispatch area change event
			dispatchEvent(new InteractiveWidgetEvent(InteractiveWidgetEvent.AREA_CHANGED));
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

		/** Converts screen point (pixels) into Coord with current CRS. */
		public function pointToCoord(x: Number, y: Number): Coord
		{
			return new Coord(ms_crs, x * m_viewBBox.width / (width - 1) + m_viewBBox.xMin, (height - 1 - y) * m_viewBBox.height / (height - 1) + m_viewBBox.yMin)
		}

		public function coordInside(c: Coord): Boolean
		{
			if (!Projection.equalCRSs(c.crs, ms_crs))
			{
				//same projectsion
				c = c.convertToProjection(m_crsProjection);
			}
			return m_viewBBox.coordInside(c);
		}

		/** Converts Coord into screen point (pixels) with current CRS. */
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
				var pX: Number = (ptInOurCRS.x - m_viewBBox.xMin) * (width - 1) / m_viewBBox.width;
				var pY: Number = height - 1 - (ptInOurCRS.y - m_viewBBox.yMin) * (height - 1) / m_viewBBox.height;
				return new Point(pX, pY);
			}
			return null;
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
//					trace("\t mapBBoxToViewParts delta: " + i_delta);
					var reflectedBBox: BBox = bbox.translated(f_crsExtentBBoxWidth * i_delta, 0)
					var intersectionOfReflectedBBoxWithCRSExtentBBox: BBox =
							reflectedBBox.intersected(m_crsProjection.extentBBox);

//					trace("\t mapBBoxToViewParts ............reflectedBBox: " + reflectedBBox);
//					trace("\t mapBBoxToViewParts inters. of reflected BBox: " + intersectionOfReflectedBBoxWithCRSExtentBBox);
					if(intersectionOfReflectedBBoxWithCRSExtentBBox && intersectionOfReflectedBBoxWithCRSExtentBBox.width > 0 && intersectionOfReflectedBBoxWithCRSExtentBBox.height > 0) {
						var b_foundEnvelopingBBox: Boolean = false;
						for each(var otherBBox: BBox in a) {
							if(otherBBox.contains(intersectionOfReflectedBBoxWithCRSExtentBBox)) {
								b_foundEnvelopingBBox = true;
								break;
							}
						}
						if(!b_foundEnvelopingBBox) {
//							trace("InteractiveWidget.mapBBoxToViewParts(): reflected "
//								+ i_delta + " part " + intersectionOfReflectedBBoxWithCRSExtentBBox.toString());
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
//				var viewBBoxWest: Number = m_viewBBox.xMin;
//				var viewBBoxEast: Number = m_viewBBox.xMax;
				var viewBBoxWest: Number = vBBox.xMin;
				var viewBBoxEast: Number = vBBox.xMax;
				var extentBBoxWest: Number = extentBox.xMin;
				var extentBBoxEast: Number = extentBox.xMax;
				var px: Number = point.x;
				var py: Number = point.y;
				var refCount: int;
				var reflectionX: Number;
				if (px >= viewBBoxWest)
				{
					refCount = int((px - viewBBoxWest) / f_crsExtentBBoxWidth);
					reflectionX = px - refCount * f_crsExtentBBoxWidth;
				}
				else
				{
					refCount = Math.ceil(Math.abs((px - viewBBoxWest) / f_crsExtentBBoxWidth));
					reflectionX = px + refCount * f_crsExtentBBoxWidth;
				}
				var i_delta: int = int((reflectionX - extentBBoxWest) / f_crsExtentBBoxWidth);
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
				var pX0: Number = reflections[0].point.x;
				var a: Array = [];
				for each (var i_delta: int in deltas)
				{
					var p: Point = new Point(pX0 + f_crsExtentBBoxWidth * i_delta, point.y)
					a.push({point: p, reflection: i_delta});
				}
				return a;
			}
			return [{point: point, reflection: 0}];
		}
		private var mb_listenForChanges: Boolean;

		[Bindable(event = "listeningForChangesChanged")]
		public function get listeningForChanges(): Boolean
		{
			return mb_listenForChanges;
		}

		public function startListenForChanges(): void
		{
			mb_listenForChanges = true;
			dispatchEvent(new Event("listeningForChangesChanged"));
		}

		public function stopListenForChanges(): void
		{
			mb_listenForChanges = false;
			dispatchEvent(new Event("listeningForChangesChanged"));
		}

		/**
		 * InteractiveWidget needs to call this function is anything, what needs to be synchronized was changed
		 *
		 */
		public function notifyWidgetChanged(change: String): void
		{
			if (mb_listenForChanges)
			{
				var iwe: InteractiveWidgetEvent = new InteractiveWidgetEvent(InteractiveWidgetEvent.WIDGET_CHANGED);
				iwe.changeDescription = change;
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

		protected function onMouseUp(event: MouseEvent): void
		{
			if (!_enableMouseClick)
				return;
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

		protected function onMouseMove(event: MouseEvent): void
		{
			if (!_enableMouseMove)
				return;
			for (var i: int = m_layerContainer.numElements - 1; i >= 0; --i)
			{
				var l: InteractiveLayer = InteractiveLayer(m_layerContainer.getElementAt(i));
				if (!l.enabled)
					continue;
				if (l.onMouseMove(event))
					break;
			}
			postUserActionUpdate();
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
			m_labelLayout.setBoundary(new Rectangle(0, 0, width, height));
			if (!m_resizeTimer)
			{
				m_resizeTimer = new Timer(500, 1);
				m_resizeTimer.addEventListener(TimerEvent.TIMER_COMPLETE, afterDelayedResize);
			}
			m_resizeTimer.stop();
			m_resizeTimer.start();
		}

		private function afterDelayedResize(event: TimerEvent = null): void
		{
//        	setViewBBox(m_viewBBox, true); // set the view bbox to update the aspects 
			setViewBBox(m_viewBBox, false); // set the view bbox to update the aspects 
			for (var i: int = 0; i < m_layerContainer.numElements; ++i)
			{
				var l: InteractiveLayer = InteractiveLayer(m_layerContainer.getElementAt(i));
				l.width = width;
				l.height = height;
				l.onContainerSizeChanged();
				if (!l.isDynamicPartInvalid())
					l.invalidateDynamicPart();
			}
			scrollRect = new Rectangle(0, 0, width, height);
			postUserActionUpdate();
		}

		private function postUserActionUpdate(): void
		{
			for (var i: int = 0; i < m_layerContainer.numElements; ++i)
			{
				var l: InteractiveLayer = InteractiveLayer(m_layerContainer.getElementAt(i));
				if (l.isDynamicPartInvalid())
					l.validateNow();
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

		public function getMapScale(): Number
		{
			var w: int = width;
			var h: int = height;
			var bbox: BBox = m_viewBBox;
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
					trace("InteractiveWidget.isVisible.setViewBBox: f_newBBoxHeight is NaN");
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
				/*
	//	        if(!m_viewBBox.equals(newBBox)) {
					m_viewBBox = newBBox;
					signalAreaChanged(b_finalChange);
	//	        }
				*/
				if (b_negotiateBBox)
					negotiateBBox(newBBox, b_finalChange, b_changeZoom);
				else
					setViewBBoxAfterNegotiation(newBBox, b_finalChange);
			}
			else
			{
				//auto layout in widget parent
				autoLayoutViewBBox(bbox, b_finalChange, true);
			}
		}
		private var _oldWidgetWidth: Number = 0;
		private var _oldWidgetHeight: Number = 0;

		private function autoLayoutViewBBox(bbox: BBox, b_finalChange: Boolean, b_setViewBBox: Boolean = false): void
		{
			//auto layout in widget parent
			var widgetParent: Group = parent as Group;
			if (widgetParent)
			{
				var f_bboxApect: Number = bbox.width / bbox.height;
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
				var widthDiff: Number = Math.abs(_oldWidgetWidth - widgetWidth);
				var heightDiff: Number = Math.abs(_oldWidgetHeight - widgetHeight);
				if (widgetWidth > 1 || widgetHeight > 1)
				{
					this.width = widgetWidth;
					this.height = widgetHeight;
					this.x = widgetXPosition;
					this.y = widgetYPosition;
					_oldWidgetWidth = widgetWidth;
					_oldWidgetHeight = widgetHeight;
					if (b_setViewBBox)
						setViewBBoxAfterNegotiation(bbox, b_finalChange);
				}
				else
					trace("InteractiveWidget.autoLayoutViewBBox(): View BBox is too small: " + widthDiff + " , " + heightDiff);
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
					trace("InteractiveWidget.negotiateBBox(): bbox changed by layer " + l.layerName);
				newBBox = latestBBox;
			}
			setViewBBoxAfterNegotiation(newBBox, b_finalChange);
		}

		private function setViewBBoxAfterNegotiation(newBBox: BBox, b_finalChange: Boolean): void
		{
			//dispath view bbox changed event to notify about change
			m_viewBBox = newBBox;
			dispatchEvent(new Event(VIEW_BBOX_CHANGED));
			signalAreaChanged(b_finalChange);
		}

		public function setExtentBBox(bbox: BBox, b_finalChange: Boolean = true): void
		{
			m_extentBBox = bbox;
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
			var features: Array = m_featureSplitter.splitCoordPolyLineToArrayOfPointPolyLines(coords, b_closed);
			return features;
		}

		public function pointIsOutside(p: Point): Boolean
		{
			if (p.x < 0 || p.x > width)
				return true;
			if (p.y < 0 || p.y > height)
				return true;
			return false;
		}

		public function lineIsOutside(p1: Point, p2: Point): Boolean
		{
			return pointIsOutside(p1) && pointIsOutside(p2);
		}

		/**
		 * Draw polyline with given curve renderer. If you just want all polyline reflections without drawing it, use getPolylineReflections function instead
		 * @param g
		 * @param coords
		 * @return
		 *
		 */
		public function drawPolyline(g: ICurveRenderer, coords: Array, b_closed: Boolean = false): Array
		{
			var features: Array = m_featureSplitter.splitCoordPolyLineToArrayOfPointPolyLines(coords, b_closed);
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
					for (var i: int = 1; i < mPoints.length; i++)
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

		public function drawHermitSpline(g: ICurveRenderer, _coords: Array, _closed: Boolean = false, _drawHiddenHitMask: Boolean = false, // PREPARED PARAMETER FOR DRAWING HIT MASK AREA
				_step: Number = 0.01): Array
		{
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
		public function moveAnticollisionLayoutToTop(): void
		{
			removeElement(m_layerLayoutParent);
			addElement(m_layerLayoutParent);
		}

		private function anticollisionUpdate(): void
		{
			if (!m_suspendAnticollisionProcessing)
			{
				if (m_labelLayout.needsUpdate())
				{
					notifyAnticollisionUpdate();
					m_labelLayout.update();
				}
				if (m_objectLayout.needsUpdate())
				{
					notifyAnticollisionUpdate();
					m_objectLayout.update();
				}
			}
		}

		private function notifyAnticollisionUpdate(): void
		{
			dispatchEvent(new Event(AnticollisionLayout.ANTICOLLISTION_UPDATED));
		}

		public function get suspendAnticollisionProcessing(): Boolean
		{
			return m_suspendAnticollisionProcessing;
		}

		public function set suspendAnticollisionProcessing(value: Boolean): void
		{
			if (m_suspendAnticollisionProcessing != value)
			{
				m_suspendAnticollisionProcessing = value;
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

		public function set autoLayoutInParent(value: Boolean): void
		{
			mb_autoLayout = value;
			mb_autoLayoutChanged = true;
			invalidateProperties();
		}

		public function get autoLayoutInParent(): Boolean
		{
			return mb_autoLayout;
		}
	}
}