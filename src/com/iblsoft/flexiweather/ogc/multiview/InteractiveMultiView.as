package com.iblsoft.flexiweather.ogc.multiview
{
	import com.iblsoft.flexiweather.events.InteractiveLayerEvent;
	import com.iblsoft.flexiweather.events.InteractiveLayerMapEvent;
	import com.iblsoft.flexiweather.events.InteractiveWidgetEvent;
	import com.iblsoft.flexiweather.ogc.BBox;
	import com.iblsoft.flexiweather.ogc.ISynchronisedObject;
	import com.iblsoft.flexiweather.ogc.InteractiveLayerMSBase;
	import com.iblsoft.flexiweather.ogc.InteractiveLayerMapLayersInitializationWatcher;
	import com.iblsoft.flexiweather.ogc.SynchronisedVariableChangeEvent;
	import com.iblsoft.flexiweather.ogc.cache.WMSCacheManager;
	import com.iblsoft.flexiweather.ogc.configuration.MapTimelineConfiguration;
	import com.iblsoft.flexiweather.ogc.configuration.layers.interfaces.ILayerConfiguration;
	import com.iblsoft.flexiweather.ogc.data.GlobalVariable;
	import com.iblsoft.flexiweather.ogc.editable.IInteractiveLayerProvider;
	import com.iblsoft.flexiweather.ogc.multiview.data.MultiViewConfiguration;
	import com.iblsoft.flexiweather.ogc.multiview.data.SynchronizationChangeType;
	import com.iblsoft.flexiweather.ogc.multiview.events.InteractiveMultiViewChangeEvent;
	import com.iblsoft.flexiweather.ogc.multiview.events.InteractiveMultiViewEvent;
	import com.iblsoft.flexiweather.ogc.multiview.skins.InteractiveMultiViewSkin;
	import com.iblsoft.flexiweather.ogc.multiview.synchronization.AreaSynchronizator;
	import com.iblsoft.flexiweather.ogc.multiview.synchronization.GlobalVariablesSynchronizator;
	import com.iblsoft.flexiweather.ogc.multiview.synchronization.ISynchronizator;
	import com.iblsoft.flexiweather.ogc.multiview.synchronization.MapLayersPropertiesSynchronizator;
	import com.iblsoft.flexiweather.ogc.multiview.synchronization.MapSynchronizator;
	import com.iblsoft.flexiweather.ogc.multiview.synchronization.events.SynchronisationEvent;
	import com.iblsoft.flexiweather.plugins.IConsole;
	import com.iblsoft.flexiweather.proj.Projection;
	import com.iblsoft.flexiweather.utils.LoggingUtils;
	import com.iblsoft.flexiweather.utils.XMLStorage;
	import com.iblsoft.flexiweather.widgets.IConfigurableLayer;
	import com.iblsoft.flexiweather.widgets.InteractiveLayer;
	import com.iblsoft.flexiweather.widgets.InteractiveLayerComposer;
	import com.iblsoft.flexiweather.widgets.InteractiveLayerCoordinate;
	import com.iblsoft.flexiweather.widgets.InteractiveLayerLabel;
	import com.iblsoft.flexiweather.widgets.InteractiveLayerMap;
	import com.iblsoft.flexiweather.widgets.InteractiveLayerPan;
	import com.iblsoft.flexiweather.widgets.InteractiveLayerZoom;
	import com.iblsoft.flexiweather.widgets.InteractiveWidget;
	
	import flash.display.DisplayObject;
	import flash.display.Graphics;
	import flash.events.DataEvent;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.sampler.NewObjectSample;
	import flash.utils.Dictionary;
	import flash.utils.clearInterval;
	import flash.utils.clearTimeout;
	import flash.utils.setTimeout;
	
	import mx.collections.ArrayCollection;
	import mx.collections.IList;
	import mx.controls.Alert;
	import mx.core.UIComponent;
	import mx.events.CollectionEvent;
	import mx.events.CollectionEventKind;
	import mx.events.DynamicEvent;
	import mx.events.FlexEvent;
	import mx.events.PropertyChangeEvent;
	import mx.events.ResizeEvent;
	
	import spark.components.Group;
	import spark.components.SkinnableContainer;
	import spark.components.SkinnableDataContainer;
	import spark.components.supportClasses.SkinnableComponent;
	import spark.layouts.TileLayout;
	import spark.layouts.supportClasses.LayoutBase;
	import spark.primitives.Graphic;
	import spark.primitives.Rect;
	import spark.primitives.supportClasses.StrokedElement;

	/**
	 *  Color of selected border.
	 *
	 *  @default 0x70B2EE
	 *
	 *  @langversion 3.0
	 *  @playerversion Flash 10
	 *  @playerversion AIR 1.5
	 *  @productversion Flex 4
	 */
	[Style(name = "selectedBorderColor", type = "uint", format = "Color", inherit = "yes", theme = "spark, mobile")]
	/**
	 *  The alpha of the content background for this component.
	 *
	 *  @langversion 3.0
	 *  @playerversion Flash 10
	 *  @playerversion AIR 1.5
	 *  @productversion Flex 4
	 */
	[Style(name = "selectedBorderAlpha", type = "Number", inherit = "yes", theme = "spark, mobile", minValue = "0.0", maxValue = "1.0")]
	[Event(name = "multiViewSelectionChange", type = "com.iblsoft.flexiweather.ogc.multiview.events.InteractiveMultiViewChangeEvent")]
	[Event(name = "multiViewReady", type = "com.iblsoft.flexiweather.ogc.multiview.events.InteractiveMultiViewEvent")]
	[Event(name = "multiViewMapsLoadingStarted", type = "com.iblsoft.flexiweather.ogc.multiview.events.InteractiveMultiViewEvent")]
	[Event(name = "multiViewMapsLoaded", type = "com.iblsoft.flexiweather.ogc.multiview.events.InteractiveMultiViewEvent")]
	[Event(name = "multiViewSingleMapLayersInitialized", type = "com.iblsoft.flexiweather.ogc.multiview.events.InteractiveMultiViewEvent")]
	[Event(name = "multiViewAllMapsLayersInitialized", type = "com.iblsoft.flexiweather.ogc.multiview.events.InteractiveMultiViewEvent")]
	public class InteractiveMultiView extends SkinnableDataContainer
	{
		public static var debugConsole: IConsole;
		private var _selectedInteractiveWidget: InteractiveWidget;
		private var _interactiveWidgets: WidgetCollection;

		[Bindable(event = "interactiveWidgetsChanged")]
		public function get interactiveWidgets(): WidgetCollection
		{
			return _interactiveWidgets;
		}
		private var _configuration: MultiViewConfiguration;

		public function get configuration(): MultiViewConfiguration
		{
			return _configuration;
		}
		
		[Bindable(event = "configurationChanged")]
		public function get isMultiViewConfigured(): Boolean
		{
			return _configuration != null
		}
		private var _widgetsCountToBeReady: ArrayCollection;
		
		private var _areaSynchronizator: AreaSynchronizator;
		private var _globalFrameSynchronizator: GlobalVariablesSynchronizator;
		private var _mapLayersPropertiesSynchronizator: MapLayersPropertiesSynchronizator;
		
		
		private var _cacheManager: WMSCacheManager;
		[SkinPart(required = "true")]
		public var selectedBorder: Rect;

		[SkinPart(required = "true")]
		public var disabledUI: Group;

		[Bindable(event = "interactiveLayerMapChanged")]
		public function get interactiveLayerMap(): InteractiveLayerMap
		{
			return _selectedInteractiveWidget.interactiveLayerMap;
		}
		private var _loadingMapsCount: int;
		private var _initializingMapsCount: int;

		override public function set enabled(value:Boolean):void
		{
			trace("IMV enabled = " + value);
			super.enabled = value;
			invalidateDisplayList();
		}
		override public function set dataProvider(value: IList): void
		{
			if (value)
			{
				value.removeEventListener(CollectionEvent.COLLECTION_CHANGE, onDataProviderChange);
			}
			super.dataProvider = value;
			if (value)
			{
				value.addEventListener(CollectionEvent.COLLECTION_CHANGE, onDataProviderChange);
			}
		}
		private var ms_crs: String = Projection.CRS_EPSG_GEOGRAPHIC;
		private var m_crsProjection: Projection = Projection.getByCRS(ms_crs);
		private var m_viewBBox: BBox = new BBox(-180, -90, 180, 90);
		private var m_extentBBox: BBox = new BBox(-180, -90, 180, 90);

		private var m_widgetCommonLayers: Array;
		
		public function InteractiveMultiView()
		{
			super();
			_interactiveWidgets = new WidgetCollection();
			setStyle('skinClass', InteractiveMultiViewSkin);
			_cacheManager = new WMSCacheManager();
			
			_areaSynchronizator = new AreaSynchronizator();
			_globalFrameSynchronizator = new GlobalVariablesSynchronizator();
			_mapLayersPropertiesSynchronizator = new MapLayersPropertiesSynchronizator();
			
			addEventListener(MouseEvent.CLICK, onMouseClick);
			dispatchEvent(new Event("interactiveWidgetsChanged"));
			
			m_widgetCommonLayers = [];
		}

		private function createDefaultConfiguration(): void
		{
			var config: MultiViewConfiguration = new MultiViewConfiguration();
			config.columns = 1;
			config.rows = 1;
			config.customData = {selectedIndex: 0};
			createInteractiveWidgetsFromConfiguration(config);
		}

		override protected function createChildren(): void
		{
			super.createChildren();
			createDefaultConfiguration();
		}

		private function onMouseClick(event: MouseEvent): void
		{
			var displayObject: DisplayObject = event.target as DisplayObject
			var ok: Boolean = true;
			var iw: InteractiveWidget;
			while (ok)
			{
				if (displayObject is InteractiveWidget)
				{
					iw = displayObject as InteractiveWidget;
					ok = false;
				}
				if (!(displayObject is DisplayObject))
					ok = false;
				else
					displayObject = displayObject.parent;
			}
			if (iw)
			{
				if (selectedInteractiveWidget != iw)
				{
					selectedInteractiveWidget = iw;
				}
			}
		}

		public function setViewBBox(bbox: BBox, b_finalChange: Boolean, b_negotiateBBox: Boolean = true): void
		{
			m_viewBBox = bbox;
			for each (var currIW: InteractiveWidget in _interactiveWidgets.widgets)
				currIW.setViewBBox(bbox, b_finalChange, b_negotiateBBox);
		}

		public function setExtentBBOXRaw(xmin: Number, ymin: Number, xmax: Number, ymax: Number, b_finalChange: Boolean = true): void
		{
			m_extentBBox = new BBox(xmin, ymin, xmax, ymax);
			for each (var currIW: InteractiveWidget in _interactiveWidgets.widgets)
				currIW.setExtentBBox(m_extentBBox, b_finalChange);
		}

		public function setCRS(s_crs: String, b_finalChange: Boolean = true): void
		{
			ms_crs = s_crs;
			for each (var currIW: InteractiveWidget in _interactiveWidgets.widgets)
				currIW.setCRS(s_crs, b_finalChange);
		}

		public function getConfigurationSynchronizator(configuration: MultiViewConfiguration): ISynchronizator
		{
			if (configuration && configuration.synchronizators && configuration.synchronizators.length > 0)
				return configuration.synchronizators[0] as ISynchronizator;
			
			return null;
		}
		public function setConfiguration(configuration: MultiViewConfiguration): void
		{
			_configuration = configuration;
			configurationChanged();
		}

		private function configurationChanged(): void
		{
			dispatchEvent(new Event("configurationChanged"));
		}


		/**
		 * Create all Interactive Widget from configuration. This is optional method, you can set your dataProvider from outside of multi view.
		 *
		 * @param newConfiguration
		 * @return
		 *
		 */
		public function createInteractiveWidgetsFromConfiguration(newConfiguration: MultiViewConfiguration = null): void
		{
			enabled = true;
			
			if (!newConfiguration)
				newConfiguration = _configuration
			else
				setConfiguration(newConfiguration);
			if (!newConfiguration)
				return;
			var iw: InteractiveWidget;
			var ac: ArrayCollection = new ArrayCollection();
			if (dataGroup)
			{
				if (dataGroup.layout is TileLayout)
				{
					var tileLayout: TileLayout = (dataGroup.layout as TileLayout);
					(dataGroup.layout as TileLayout).requestedColumnCount = newConfiguration.columns;
					(dataGroup.layout as TileLayout).requestedRowCount = newConfiguration.rows;
					(dataGroup.layout as TileLayout).columnWidth = dataGroup.width / tileLayout.columnCount;
					(dataGroup.layout as TileLayout).rowHeight = dataGroup.height / tileLayout.rowCount;
				}
			}
			
			stopWatchingChanges();
			
			var cnt: int = 0;
			var oldIW: InteractiveWidget
			var alreadyExistingWidgetsCount: int = _interactiveWidgets.widgets.length;
			var i: int;
			var j: int;
			//remove all widgets
			while (cnt < _interactiveWidgets.widgets.length)
			{
				oldIW = _interactiveWidgets.getWidgetAt(cnt);
				if (_selectedInteractiveWidget == oldIW)
				{
					selectedInteractiveWidget = null;
				}
				removeWidget(oldIW);
			}
			_widgetsCountToBeReady = new ArrayCollection();
			var newSelectedIndex: int = 0;
			var synchronizator: ISynchronizator = getConfigurationSynchronizator(_configuration);
			
			if (synchronizator)
				synchronizator.initializeSynchronizator();
			
			for (j = 0; j < newConfiguration.rows; j++)
			{
				for (i = 0; i < newConfiguration.columns; i++)
				{
					iw = _interactiveWidgets.getWidgetAt(cnt);
					if (iw)
					{
						resetWidget(iw);
						ac.addItem(iw);
					}
					else
					{
						iw = createInteractiveWidget();
						ac.addItem(iw);
						_widgetsCountToBeReady.addItem(iw);
					}
					if (newConfiguration.customData && cnt == newConfiguration.customData.selectedIndex)
					{
						selectedInteractiveWidget = iw;
					}
					cnt++;
				}
			}
//			if (!_selectedInteractiveWidget && ac.length > 0)
//			{
//				selectedInteractiveWidget = (ac.getItemAt(0) as InteractiveWidget);
//			}
			//debug
//			cnt = 0;
//			for each (var currIW: InteractiveWidget in ac)
//			{
//				cnt++;
//				currIW.interactiveLayerMap.invalidateProperties();
//			}
			dataProvider = ac;
			invalidateDisplayList();
			if (_widgetsCountToBeReady.length == 0)
			{
				synchronizator = getConfigurationSynchronizator(newConfiguration);	
				notifyWidgetsReady(synchronizator);
			}
		}
		private static var WIDGET_UI: int = 0;

		private function createInteractiveWidget(): InteractiveWidget
		{
			var id: int = WIDGET_UI++
			var iw: InteractiveWidget = new InteractiveWidget();
			iw.id = 'm_iw' + id;
			iw.name = 'Widget ' + id;
			var mapLabel: InteractiveLayerLabel = new InteractiveLayerLabel(_synchronizator, iw);
			mapLabel.zOrder = 3;
			var layerMap: InteractiveLayerMap = new InteractiveLayerMap(iw);
			iw.addLayer(mapLabel);
			iw.addLayer(layerMap);
			return iw;
		}

		private function onDataProviderChange(event: CollectionEvent): void
		{
			if (event.items && event.items.length > 0)
			{
				var item: PropertyChangeEvent;
				var iw: InteractiveWidget;
				switch (event.kind)
				{
					case CollectionEventKind.REMOVE:
						for each (iw in event.items)
						{
//							if (item.source is InteractiveWidget)
//							{
//								iw = item.source as InteractiveWidget;
							_interactiveWidgets.removeWidget(iw);
							unregisterInteractiveWidget(iw);
//							} else {
//								Alert.show("MultiView can consists just InteractiveWidget instances");
//							}
						}
						break;
					case CollectionEventKind.ADD:
					case CollectionEventKind.UPDATE:
						addWidgetsToDataProvider(event.items);
						break;
				}
			}
		}

		private function addWidgetsToDataProvider(items: Array): void
		{
			var iw: InteractiveWidget;
			var item: PropertyChangeEvent;
			for each (item in items)
			{
				if (item.source is InteractiveWidget)
				{
					iw = item.source as InteractiveWidget;
					if (!iw.wmsCacheManager)
					{
						iw.wmsCacheManager = _cacheManager;
					}
					if (!_interactiveWidgets.widgetExists(iw))
					{
						_interactiveWidgets.addWidget(iw);
						registerInteractiveWidget(iw);
						//we need to invalidate synchronizator, when new widget is added
						invalidateSychronizator();
					}
					//check if there is selection
					if (!selectedInteractiveWidget)
					{
						selectedInteractiveWidget = iw;
					}
					else
					{
						if (selectedInteractiveWidget.id == iw.id)
						{
							//iw is registered, and it was previously selected, so we need to call eveything which is called on selectedInteractive
							_selectedInteractiveWidget.enableMouseMove = true;
							_selectedInteractiveWidget.enableMouseClick = true;
							_selectedInteractiveWidget.enableMouseWheel = true;
						}
					}
					if (!iw.hasEventListener(InteractiveWidgetEvent.WIDGET_SELECTED))
						iw.addEventListener(InteractiveWidgetEvent.WIDGET_SELECTED, onWidgetSelected);
				}
			}
			//check if all widgets are ready as last action
			for each (item in items)
			{
				if (item.source is InteractiveWidget)
				{
					iw = item.source as InteractiveWidget;
					if (_widgetsCountToBeReady && _widgetsCountToBeReady.length > 0)
					{
						var iwID: int = _widgetsCountToBeReady.getItemIndex(iw);
						if (iwID > -1)
						{
							_widgetsCountToBeReady.removeItemAt(iwID);
							if (_widgetsCountToBeReady.length == 0)
							{
								callLater(notifyWidgetsReady, [getConfigurationSynchronizator(_configuration)]);
							}
						}
					}
				}
			}
		}

		private function notifyWidgetsMapsLoadingStarted(): void
		{
			dispatchEvent(new InteractiveMultiViewEvent(InteractiveMultiViewEvent.MULTI_VIEW_MAPS_LOADING_STARTED));
		}

		private function notifyAllWidgetsMapLayersInitialized(): void
		{
			dispatchEvent(new InteractiveMultiViewEvent(InteractiveMultiViewEvent.MULTI_VIEW_ALL_MAPS_LAYERS_INITIALIZED));
		}

		private function notifyWidgetsMapLayersInitialized(): void
		{
			dispatchEvent(new InteractiveMultiViewEvent(InteractiveMultiViewEvent.MULTI_VIEW_SINGLE_MAP_LAYERS_INITIALIZED));
		}

		private function notifyWidgetsMapLoaded(): void
		{
			dispatchEvent(new InteractiveMultiViewEvent(InteractiveMultiViewEvent.MULTI_VIEW_MAPS_LOADED));
		}

		private function notifyWidgetsReady(synchronizator: ISynchronizator = null): void
		{
			dispatchEvent(new InteractiveMultiViewEvent(InteractiveMultiViewEvent.MULTI_VIEW_READY));
			//load maps from previous multiView state
			callLater(loadMapsForAllWidgets, [_serializedMapXML, synchronizator]);
//			startWatchingChanges();
		}
		private var _serializedMapXML: XML;
		private var _oldCRS: String;
		private var _oldViewBBox: BBox;
		private var _oldExtentBBox: BBox;

		private function saveMapBeforeChangingToNewLayout(widget: InteractiveWidget): void
		{
			var _serializedMap: XMLStorage = new XMLStorage();
			_oldCRS = widget.getCRS();
			_oldViewBBox = widget.getViewBBox().clone();
			_oldExtentBBox = widget.getExtentBBox().clone();
			widget.interactiveLayerMap.serialize(_serializedMap);
			_serializedMapXML = _serializedMap.xml;
		}

		
		public function getWidgetIndex(widget: InteractiveWidget): int
		{
			return _interactiveWidgets.getWidgetIndex(widget);
		}
		
		/**
		 * Load map for all widget at once
		 * @param mapXML
		 *
		 */
		public function loadMap(mapXML: XML, itemData: Object): void
		{
			if (synchronizator && !synchronizator.isSynchronisingChangeType(SynchronizationChangeType.MAP_LAYER_ADDED))
				loadMapsForAllWidgets(mapXML);
			else {
				//load map just for currently selected widget
				if (selectedInteractiveWidget) {
					_loadingMapsCount = 1;
					_initializingMapsCount = 1;
					
					
					var position: int = _interactiveWidgets.getWidgetIndex(selectedInteractiveWidget);
					
					//update map configuration
					
					if (_configuration && _configuration.customData && _configuration.customData.hasOwnProperty('dataProvider'))
					{
						var dp: ArrayCollection = _configuration.customData.dataProvider as ArrayCollection;
						if (dp)
						{
							dp.setItemAt(itemData, position);
						}
					}
					loadMapForWidget(selectedInteractiveWidget, mapXML, position);
				}
			}
			
		}

		private function loadMapsForAllWidgets(mapXML: XML, synchronizator: ISynchronizator = null): void
		{
			if (mapXML)
			{
				stopWatchingChanges();
				notifyWidgetsMapsLoadingStarted();
//				var _serializedMap: XMLStorage = new XMLStorage(mapXML);
				_loadingMapsCount = _interactiveWidgets.widgets.length;
				_initializingMapsCount = _interactiveWidgets.widgets.length;
				
				var cnt: int = 0;
				for each (var currIW: InteractiveWidget in _interactiveWidgets.widgets)
				{
					/*
					if (_oldCRS)
						currIW.setCRS(_oldCRS, false);
					if (_oldExtentBBox)
						currIW.setExtentBBox(_oldExtentBBox, false);
					if (_oldViewBBox)
						currIW.setViewBBox(_oldViewBBox, true);
					currIW.stopListenForChanges();
					
					if (!synchronizator || !synchronizator.canCreateMap(currIW))
					{
						createMapFromSerialization(currIW, mapXML);
//						currIW.interactiveLayerMap.addEventListener(InteractiveLayerMap.LAYERS_SERIALIZED_AND_READY, onMapFromXMLReady);
//						currIW.interactiveLayerMap.serialize(_serializedMap);
					} else {
						synchronizator.updateMapAction(currIW, cnt, _configuration);
						synchronizator.addEventListener(SynchronisationEvent.MAP_READY, onSynchronizatorMapReady);
						synchronizator.createMap(currIW);
						
					}
					*/
					
					loadMapForWidget(currIW, mapXML, cnt);
					cnt++;
				}
			}
		}
		
		private function loadMapForWidget(widget: InteractiveWidget, mapXML: XML, position: int): void
		{
			if (_oldCRS)
				widget.setCRS(_oldCRS, false);
			if (_oldExtentBBox)
				widget.setExtentBBox(_oldExtentBBox, false);
			if (_oldViewBBox)
				widget.setViewBBox(_oldViewBBox, true);
			widget.stopListenForChanges();
			
			if (!synchronizator || !synchronizator.canCreateMap(widget))
			{
				createMapFromSerialization(widget, mapXML);
				//						widget.interactiveLayerMap.addEventListener(InteractiveLayerMap.LAYERS_SERIALIZED_AND_READY, onMapFromXMLReady);
				//						widget.interactiveLayerMap.serialize(_serializedMap);
			} else {
				synchronizator.updateMapAction(widget, position, _configuration);
				synchronizator.addEventListener(SynchronisationEvent.MAP_READY, onSynchronizatorMapReady);
				synchronizator.createMap(widget);
				
			}
		}
		
		private function createMapFromSerialization(iw: InteractiveWidget, mapXML: XML): void
		{
			var _serializedMap: XMLStorage = new XMLStorage(mapXML);
			iw.interactiveLayerMap.addEventListener(InteractiveLayerMap.LAYERS_SERIALIZED_AND_READY, onMapFromXMLReady);
			iw.interactiveLayerMap.serialize(_serializedMap);
		}

//		public function removeAllLayers(removeLayerCallback: Function = null): void
//		{
//			for each (var iw: InteractiveWidget in _interactiveWidgets.widgets)
//			{
//				var im: InteractiveLayerMap = iw.interactiveLayerMap;
//				if (im)
//				{
//					while ( im.layers.length > 0)
//					{
//						var l: InteractiveLayer = im.layers.getItemAt(0) as InteractiveLayer;
//						im.removeLayer(l);
//						
//						removeLayer(l, removeLayerCallback);
//					}
//				}
//			}
//		}
//		
//		public function removeLayer(l: InteractiveLayer, removeLayerCallback: Function = null): void
//		{
//			for each (var iw: InteractiveWidget in _interactiveWidgets.widgets)
//			{
//				if (iw && iw.interactiveLayerMap)
//				{
//					iw.interactiveLayerMap.removeLayer(l);
//					if (removeLayerCallback != null)
//					{
//						removeLayerCallback(l);
//					}
//				}
//			}
//		}
//		
//		public function addLayer(ilp: IInteractiveLayerProvider, layerAddedCallback: Function = null): void
//		{
//			for each (var iw: InteractiveWidget in _interactiveWidgets.widgets)
//			{
//				var l: InteractiveLayer = ilp.createInteractiveLayer(iw);
//				iw.interactiveLayerMap.addLayer(l);
//				if (layerAddedCallback != null)
//				{
//					layerAddedCallback(l);
//				}
//			}
//		}
		public function refresh(b_force: Boolean): void
		{
			for each (var iw: InteractiveWidget in _interactiveWidgets.widgets)
			{
				iw.interactiveLayerMap.refresh(b_force);
			}
		}
		private var _mapLayersWatchers: Dictionary = new Dictionary(true);

		private function onSynchronizatorMapReady(event: SynchronisationEvent): void
		{
			_loadingMapsCount--;
			if (_loadingMapsCount == 0)
			{
				startWatchingChanges();
				notifyWidgetsMapLoaded();
			}
		}
		
		private function onMapFromXMLReady(event: DynamicEvent): void
		{
			var interactiveLayerMap: InteractiveLayerMap = event.target as InteractiveLayerMap;
			interactiveLayerMap.removeEventListener(InteractiveLayerMap.LAYERS_SERIALIZED_AND_READY, onMapFromXMLReady);
			var layers: Array = event['layers'] as Array;
			if (_mapLayersWatchers[interactiveLayerMap] == null)
			{
				_mapLayersWatchers[interactiveLayerMap] = new InteractiveLayerMapLayersInitializationWatcher();
			}
			var watcher: InteractiveLayerMapLayersInitializationWatcher = _mapLayersWatchers[interactiveLayerMap] as InteractiveLayerMapLayersInitializationWatcher;
			watcher.addEventListener(InteractiveLayerMapLayersInitializationWatcher.MAP_LAYERS_INITIALIZED, onMapLayersInitialized);
			watcher.onMapFromXMLReady(interactiveLayerMap, layers);
			_loadingMapsCount--;
			if (_loadingMapsCount == 0)
			{
				notifyWidgetsMapLoaded();
			}
		}

		private function onMapLayersInitialized(event: Event): void
		{
			notifyWidgetsMapLayersInitialized();
			_initializingMapsCount--;
			if (_initializingMapsCount == 0)
			{
				setTimeout(allWidgetsMapLayersAreInitialized, 2000);
			}
		}

		private function allWidgetsMapLayersAreInitialized(): void
		{
			notifyAllWidgetsMapLayersInitialized();
			callLater(startWatchingChanges);
		}

		private function onWidgetSelected(event: InteractiveWidgetEvent): void
		{
			selectedInteractiveWidget = event.currentTarget as InteractiveWidget;
		}

		[Bindable(event = "interactiveLayerMapChanged")]
		public function get selectedInteractiveWidget(): InteractiveWidget
		{
			return _selectedInteractiveWidget;
		}

		public function set selectedInteractiveWidget(value: InteractiveWidget): void
		{
			if (value != _selectedInteractiveWidget)
			{
				
				var imvce: InteractiveMultiViewChangeEvent = new InteractiveMultiViewChangeEvent(InteractiveMultiViewChangeEvent.SELECTION_CHANGE);
				imvce.oldInteractiveWidget = _selectedInteractiveWidget;
				
				
				if (_selectedInteractiveWidget)
				{
					unregisterSelectedInteractiveWidget();
				}
				_selectedInteractiveWidget = value;
				if (_selectedInteractiveWidget)
				{
					trace("selectedInteractiveWidget: " + _selectedInteractiveWidget.id);
					registerSelectedInteractiveWidget();
				}
				
				imvce.newInteractiveWidget = _selectedInteractiveWidget;
				dispatchEvent(imvce);
				
				dispatchEvent(new FlexEvent(FlexEvent.SELECTION_CHANGE));
				dispatchEvent(new Event("interactiveLayerMapChanged"));
				invalidateDisplayList();
			}
		}

		public function startWatchingChanges(bStartListenForWidgetChanges: Boolean = true, bInvalidateDisplayList: Boolean = true): void
		{
			_watchChanges = true;
			if (bStartListenForWidgetChanges)
			{
				for each (var widget: InteractiveWidget in _interactiveWidgets.widgets)
				{
					widget.startListenForChanges(bInvalidateDisplayList);
				}
			}
			dispatchEvent(new Event('watchChangesChanged'));
			
			if (bInvalidateDisplayList)
				invalidateDisplayList();
		}

		public function stopWatchingChanges(bStopListenForWidgetChanges: Boolean = true, bInvalidateDisplayList: Boolean = true): void
		{
			_watchChanges = false;
			if (bStopListenForWidgetChanges)
			{
				for each (var widget: InteractiveWidget in _interactiveWidgets.widgets)
				{
					widget.stopListenForChanges(bInvalidateDisplayList);
				}
			}
			dispatchEvent(new Event('watchChangesChanged'));
			
			if (bInvalidateDisplayList)
				invalidateDisplayList();
		}
		
		private var _watchChanges: Boolean = true;

		[Bindable(event = "watchChangesChanged")]
		public function get watchForChanges(): Boolean
		{
			return _watchChanges;
		}

		private function onWidgetChanged(event: InteractiveWidgetEvent): void
		{
			//if there is single widget, it's not needed to do any rebuilding
			if (_interactiveWidgets && _interactiveWidgets.widgets.length < 2)
				return;
			
			if (_watchChanges)
			{
				var iw: InteractiveWidget = event.target as InteractiveWidget;
				if (iw != _selectedInteractiveWidget)
				{
					trace("We are not doing synchronization from others widget, but currently selected");
				}
				else
				{
					var changeCause: String = event.changeDescription;
					
					//check global variable synchronizator
					var globalFrameSynchronizationAllowed: Boolean = true;
					var globalLevelSynchronizationAllowed: Boolean = true;
					if (_configuration && _configuration.customData && _configuration.customData.synchronizeFrame)
					{
						globalFrameSynchronizationAllowed = _configuration.customData.synchronizeFrame
					}
					var needToSynchronizeGlobalFrame: Boolean = globalFrameSynchronizationAllowed && !synchronizator.isSynchronisingChangeType(SynchronizationChangeType.GLOBAL_FRAME_CHANGED) && changeCause == SynchronizationChangeType.GLOBAL_FRAME_CHANGED;
					var needToSynchronizeGlobalLevel: Boolean = globalLevelSynchronizationAllowed && !synchronizator.isSynchronisingChangeType(SynchronizationChangeType.GLOBAL_LEVEL_CHANGED) && changeCause == SynchronizationChangeType.GLOBAL_LEVEL_CHANGED;
					
					if (needToSynchronizeGlobalFrame || needToSynchronizeGlobalLevel)
					{
						// in case synchronizator is not synchronizing FRAME, global frame synchronizator will synchronize FRAME instead
						enabled = false;
						_globalFrameSynchronizator.synchronizeFrame = needToSynchronizeGlobalFrame;
						_globalFrameSynchronizator.synchronizeLevel = needToSynchronizeGlobalLevel;
						
						_globalFrameSynchronizator.addEventListener(SynchronisationEvent.SYNCHRONISATION_DONE, onGlobalFrameSynchronizationDone);
						_globalFrameSynchronizator.synchronizeWidgets(_selectedInteractiveWidget, _interactiveWidgets.widgets);
						return;
					}
					if (changeCause == SynchronizationChangeType.ALPHA_CHANGED || 
						changeCause == SynchronizationChangeType.VISIBILITY_CHANGED ||
						changeCause == SynchronizationChangeType.SYNCHRONIZE_LEVEL_CHANGED ||
						changeCause == SynchronizationChangeType.LEVEL_CHANGED)
					{
						if (!synchronizator.isSynchronisingChangeType(changeCause))
						{	
							_mapLayersPropertiesSynchronizator.synchronizeWidgets(_selectedInteractiveWidget, _interactiveWidgets.widgets);
							return;
						}
					}
					if (!synchronizator.isSynchronisingChangeType(changeCause))
					{
						stopWatchingChanges();
						rebuildWidgets();
					} else {
						trace("onWidgetChanged: There were change : " + changeCause + " but synchronizator: "  + synchronizator.labelString + " already synchronize this");
					}
				}
			}
			else
			{
				trace("\n	widget changes, but multiview is not watching changes now");
			}
		}

		private function onGlobalFrameSynchronizationDone(event: SynchronisationEvent): void
		{
			enabled = true;
			_globalFrameSynchronizator.removeEventListener(SynchronisationEvent.SYNCHRONISATION_DONE, onGlobalFrameSynchronizationDone);
		}
		
		private function rebuildGlobalVariables(changeDescription: String): void
		{
			var currWidget: InteractiveWidget
			if (changeDescription != GlobalVariable.LEVEL)
			{
				if (!synchronizator.hasSynchronisedVariable(changeDescription))
				{
					var level: String = _selectedInteractiveWidget.interactiveLayerMap.level;
					//synchronisator does not synchronize this global variable, so it's needs to be set (because it was changed)
					for each (currWidget in _interactiveWidgets.widgets)
					{
						if (_selectedInteractiveWidget == currWidget)
						{
							//do not anything with selected widget, change came from it
						}
						else
						{
							if (currWidget.interactiveLayerMap.level != level)
								currWidget.interactiveLayerMap.setLevel(level, true);
						}
					}
				}
			}
			if (changeDescription != GlobalVariable.FRAME)
			{
				if (!synchronizator.hasSynchronisedVariable(changeDescription))
				{
					var frame: Date = _selectedInteractiveWidget.interactiveLayerMap.frame as Date;
					//synchronisator does not synchronize this global variable, so it's needs to be set (because it was changed)
					for each (currWidget in _interactiveWidgets.widgets)
					{
						if (_selectedInteractiveWidget == currWidget)
						{
							//do not anything with selected widget, change came from it
						}
						else
						{
							currWidget.interactiveLayerMap.setFrame(frame, true);
						}
					}
				}
			}
		}
		private var _widgetsWaitingForRebuild: int;

		private function rebuildWidgets(): void
		{
			//first loop will check how many widgets need to be changed
			_widgetsWaitingForRebuild = 0;
			for each (var currWidget: InteractiveWidget in _interactiveWidgets.widgets)
			{
				if (_selectedInteractiveWidget == currWidget)
				{
					//do not anything with selected widget, change came from it
				}
				else
				{
					_widgetsWaitingForRebuild++;
				}
			}
			for each (currWidget in _interactiveWidgets.widgets)
			{
				if (_selectedInteractiveWidget == currWidget)
				{
					//do not anything with selected widget, change came from it
					trace("\t do not anything with selected widget, change came from it");
				}
				else
				{
					//do not listen for changes, because widget is going to be recreated
					currWidget.stopListenForChanges();
					//wait for event, which id dispatched when map is rebuild and start listening for changes again
					currWidget.addEventListener(InteractiveLayerMapEvent.MAP_LOADED, onWidgetMapRebuild);
					currWidget.interactiveLayerMap.removeAllLayers();
					_selectedInteractiveWidget.interactiveLayerMap.cloneLayersForComposer(currWidget.interactiveLayerMap);
				}
			}
		}

		/**
		 * When InteractiveLayerMap in InteractiveWidget is rebuilded, start to listen for changes inside widget
		 * @param event
		 *
		 */
		private function onWidgetMapRebuild(event: InteractiveLayerMapEvent): void
		{
			var widget: InteractiveWidget = event.currentTarget as InteractiveWidget;
			widget.startListenForChanges();
			_widgetsWaitingForRebuild--;
			if (_widgetsWaitingForRebuild == 0)
			{
				//all widgets are rebuildt
				startWatchingChanges();
			}
		}

		/**
		 * When new interactive widget is added, all needed registrations need to be done. E.g. Adding event listeners and so
		 *
		 */
		private function registerInteractiveWidget(iw: InteractiveWidget): void
		{
			//TODO should be this done only if synchronization is ON?
			iw.enableMouseMove = true;
			iw.enableMouseClick = false;
			iw.enableMouseWheel = false;
			if (ms_crs)
				iw.setCRS(ms_crs);
			var finalChange: Boolean;
			if (m_extentBBox)
			{
				finalChange = (m_viewBBox == null)
				iw.setExtentBBox(m_extentBBox, finalChange);
			}
			if (m_viewBBox)
				iw.setViewBBox(m_viewBBox, true);
		}

		/**
		 * When new interactive widget is added, all needed registrations need to be done. E.g. Adding event listeners and so
		 *
		 */
		private function unregisterInteractiveWidget(iw: InteractiveWidget): void
		{
			iw.enableMouseMove = true;
			iw.enableMouseClick = true;
			iw.enableMouseWheel = true;
		}

		/**
		 * When new interactive widget is selected, all needed registrations need to be done. E.g. Adding event listeners and so
		 *
		 */
		private function registerSelectedInteractiveWidget(): void
		{
			unregisterSelectedInteractiveWidget();
			if (_selectedInteractiveWidget)
			{
				_selectedInteractiveWidget.enableMouseMove = true;
				_selectedInteractiveWidget.enableMouseClick = true;
				_selectedInteractiveWidget.enableMouseWheel = true;
				_selectedInteractiveWidget.addEventListener(InteractiveWidgetEvent.WIDGET_CHANGED, onWidgetChanged);
				_selectedInteractiveWidget.addEventListener(InteractiveWidgetEvent.AREA_CHANGED, onAreaChanged);
				_selectedInteractiveWidget.addEventListener(InteractiveLayerMap.PRIMARY_LAYER_CHANGED, onPrimaryLayerChanged);
				_selectedInteractiveWidget.addEventListener(InteractiveLayerMapEvent.LAYER_SELECTION_CHANGED, onMapLayerSelectionChanged);
				_selectedInteractiveWidget.addEventListener(ResizeEvent.RESIZE, onSelectedWidgetResize);
				
				onPrimaryLayerChanged();
				_selectedInteractiveWidget.startListenForChanges();
				if (_selectedInteractiveWidget.interactiveLayerMap)
				{
					var layerMap: InteractiveLayerMap = _selectedInteractiveWidget.interactiveLayerMap;
//					layerMap.addEventListener(InteractiveLayerMap.TIME_AXIS_UPDATED, onTimeAxisUpdated);
//					layerMap.addEventListener(InteractiveLayerMap.TIME_AXIS_ADDED, onTimeAxisAdded);
//					layerMap.addEventListener(InteractiveLayerMap.TIME_AXIS_REMOVED, onTimeAxisRemoved);
					layerMap.invalidateTimeline();
				}
				
				if (m_widgetCommonLayers && m_widgetCommonLayers.length > 0)
				{
					while (m_widgetCommonLayers.length > 0)
					{
						var layer: InteractiveLayer = m_widgetCommonLayers.shift() as InteractiveLayer;
						
						if (layer)
							_selectedInteractiveWidget.addLayer(layer);
						
					}
				}
			}
		}

		/**
		 * When currently selected interactive widget is unselected, all needed unregistrations need to be done. E.g. Removing event listeners and so
		 *
		 */
		private function unregisterSelectedInteractiveWidget(): void
		{
			if (_selectedInteractiveWidget)
			{
				_selectedInteractiveWidget.enableMouseMove = true;
				_selectedInteractiveWidget.enableMouseClick = false;
				_selectedInteractiveWidget.enableMouseWheel = false;
				_selectedInteractiveWidget.removeEventListener(InteractiveWidgetEvent.WIDGET_CHANGED, onWidgetChanged);
				_selectedInteractiveWidget.removeEventListener(InteractiveWidgetEvent.AREA_CHANGED, onAreaChanged);
				_selectedInteractiveWidget.removeEventListener(InteractiveLayerMapEvent.LAYER_SELECTION_CHANGED, onMapLayerSelectionChanged);
				_selectedInteractiveWidget.removeEventListener(InteractiveLayerMap.PRIMARY_LAYER_CHANGED, onPrimaryLayerChanged);
				_selectedInteractiveWidget.removeEventListener(ResizeEvent.RESIZE, onSelectedWidgetResize);
				onPrimaryLayerChanged();
				
				var coordinateLayer: InteractiveLayerCoordinate = _selectedInteractiveWidget.getLayerByType(InteractiveLayerCoordinate) as InteractiveLayerCoordinate;
				if (coordinateLayer)
				{
					_selectedInteractiveWidget.removeLayer(coordinateLayer);
					m_widgetCommonLayers.push(coordinateLayer);
				}
			}
		}
		
		
		private function onMapLayerSelectionChanged(event: InteractiveLayerMapEvent): void
		{
			trace("onMapLayerSelectionChanged selected index: " + selectedInteractiveWidget.interactiveLayerMap.selectedLayerIndex);	
		}
		
		private var _previousPrimaryLayer: InteractiveLayerMSBase;

		private function onPrimaryLayerChanged(event: DataEvent = null): void
		{
			stopListenForSynchronisedVariableChange(_previousPrimaryLayer);
			if (_selectedInteractiveWidget.interactiveLayerMap)
				_previousPrimaryLayer = _selectedInteractiveWidget.interactiveLayerMap.primaryLayer;
			startListenForSynchronisedVariableChange(_previousPrimaryLayer);
		}

		private function startListenForSynchronisedVariableChange(layer: InteractiveLayerMSBase): void
		{
			if (layer)
			{
				layer.addEventListener(SynchronisedVariableChangeEvent.SYNCHRONISED_VARIABLE_DOMAIN_CHANGED, onSychronisedVariableChanged);
				layer.addEventListener(SynchronisedVariableChangeEvent.SYNCHRONISED_VARIABLE_CHANGED, onSychronisedVariableChanged);
			}
		}

		private function stopListenForSynchronisedVariableChange(layer: InteractiveLayerMSBase): void
		{
			if (layer)
			{
				layer.removeEventListener(SynchronisedVariableChangeEvent.SYNCHRONISED_VARIABLE_DOMAIN_CHANGED, onSychronisedVariableChanged);
				layer.removeEventListener(SynchronisedVariableChangeEvent.SYNCHRONISED_VARIABLE_CHANGED, onSychronisedVariableChanged);
			}
		}

		private function onSychronisedVariableChanged(event: SynchronisedVariableChangeEvent): void
		{
			var layer: InteractiveLayerMSBase = event.target as InteractiveLayerMSBase;
			var layerWidget: InteractiveWidget = layer.container;
			
			if (layerWidget && selectedInteractiveWidget)
			{
				var synchronizedVariable: String = event.variableId;
				if (_synchronizator && _synchronizator.hasSynchronisedVariable(synchronizedVariable))
				{
					synchronizeWidgets(_synchronizator, layerWidget);
				}
			} else {
				debug("onSychronisedVariableChanged WIDGETS missing ");
			}
		}

		private function changeTileLayoutToSingleView(): void
		{
			if (dataGroup)
			{
				if (dataGroup.layout is TileLayout)
				{
					var tileLayout: TileLayout = (dataGroup.layout as TileLayout);
					(dataGroup.layout as TileLayout).requestedColumnCount = 1;
					(dataGroup.layout as TileLayout).requestedRowCount = 1;
					(dataGroup.layout as TileLayout).columnWidth = dataGroup.width;
					(dataGroup.layout as TileLayout).rowHeight = dataGroup.height;
				}
			}
		}

		/**
		 * Reset widget to prepare it for new map
		 *
		 * @param widget
		 *
		 */
		private function resetWidget(widget: InteractiveWidget): void
		{
			widget.stopListenForChanges();
			widget.removeAllLayers();
			widget.interactiveLayerMap.removeAllLayers();
		}

		/**
		 * You can reset multiView to one view (InteractiveWidget). If you specify interactiveWidget it will reset to that specified widget.
		 * If you do not specify interactiveWidget, it will be reset to currently selected widget
		 *
		 * Difference between switching and reseting is in removing widgets. Reset will remove other widgets, switch will just hide them and you can switchToMultiView back
		 * @param widget
		 *
		 */
		public function resetView(widget: InteractiveWidget = null): void
		{
			if (!widget)
				widget = selectedInteractiveWidget;
			saveMapBeforeChangingToNewLayout(widget);
			//all views are removed, so forget this configuration
			_configuration = null;
			configurationChanged();
//			changeTileLayoutToSingleView();
//			var cnt: int = 0;
//			var ok: Boolean = true;
//			while (ok)
//			{
//				var currWidget: InteractiveWidget = _interactiveWidgets.widgets.getItemAt(cnt) as InteractiveWidget;
//				if (widget != currWidget)
//				{
//					removeWidget(currWidget);
//				} else {
//					cnt++;
//				}
//				if (cnt == _interactiveWidgets.widgets.length)
//					ok = false;
//			}
			invalidateDisplayList();
		}

		/**
		 * You can switch multiView to one view (InteractiveWidget). If you specify interactiveWidget it will switch to that specified widget.
		 * If you do not specify interactiveWidget, it will be switched to currently selected widget.
		 *
		 * Difference between switching and reseting is in removing widgets. Reset will remove other widgets, switch will just hide them and you can switchToMultiView back
		 * @param widget
		 *
		 */
		public function switchToSingleView(widget: InteractiveWidget = null): void
		{
			if (!widget)
				widget = selectedInteractiveWidget;
			changeTileLayoutToSingleView();
			for each (var currWidget: InteractiveWidget in _interactiveWidgets.widgets)
			{
				if (widget == currWidget)
				{
					currWidget.visible = true;
					currWidget.includeInLayout = true;
				}
				else
				{
					currWidget.visible = false;
					currWidget.includeInLayout = false;
				}
			}
			invalidateDisplayList();
		}

		/**
		 * Switch back to multi view if InteractiveMultiView is switched to single view.
		 *
		 * @param widget
		 *
		 */
		public function switchToMultiView(): void
		{
			if (dataGroup)
			{
				if (dataGroup.layout is TileLayout)
				{
					var tileLayout: TileLayout = (dataGroup.layout as TileLayout);
					(dataGroup.layout as TileLayout).requestedColumnCount = _configuration.columns;
					(dataGroup.layout as TileLayout).requestedRowCount = _configuration.rows;
					(dataGroup.layout as TileLayout).columnWidth = dataGroup.width / tileLayout.columnCount;
					(dataGroup.layout as TileLayout).rowHeight = dataGroup.height / tileLayout.rowCount;
				}
			}
			for each (var currWidget: InteractiveWidget in _interactiveWidgets.widgets)
			{
				currWidget.visible = true;
				currWidget.includeInLayout = true;
			}
			invalidateDisplayList();
		}

		private function removeWidgetAt(position: int): void
		{
			removeWidget(_interactiveWidgets.getWidgetAt(position));
		}

		private function removeWidget(widget: InteractiveWidget): void
		{
			if (widget)
			{
				widget.stopListenForChanges();
				widget.interactiveLayerMap.removeAllLayers();
				_interactiveWidgets.removeWidget(widget);
				var ac: ArrayCollection = dataProvider as ArrayCollection;
				if (ac)
				{
					var id: int = ac.getItemIndex(widget);
					if (id > -1)
					{
						ac.removeItemAt(id);
					}
				}
				widget.interactiveLayerMap.removeAllLayers();
				widget.destroy();
			}
		}

		/**
		 * When selected interactiveWidget changed its size, we need to redraw selection
		 * @param event
		 *
		 */
		private function onSelectedWidgetResize(event: ResizeEvent): void
		{
			invalidateDisplayList();
		}
		public var selectionL: int;
		public var selectionT: int;
		public var selectionR: int;
		public var selectionB: int;

		override protected function updateDisplayList(unscaledWidth: Number, unscaledHeight: Number): void
		{
			super.updateDisplayList(unscaledWidth, unscaledHeight);
			if (dataGroup)
			{
				if (dataGroup.layout is TileLayout)
				{
					var tileLayout: TileLayout = (dataGroup.layout as TileLayout);
					(dataGroup.layout as TileLayout).columnWidth = dataGroup.width / tileLayout.columnCount;
					(dataGroup.layout as TileLayout).rowHeight = dataGroup.height / tileLayout.rowCount;
				}
			}
			debugWidgets();
			if (selectedInteractiveWidget)
			{
				selectionL = selectedInteractiveWidget.x;
				selectionT = selectedInteractiveWidget.y;
				selectionR = unscaledWidth - (selectionL + selectedInteractiveWidget.width) - 1;
				selectionB = unscaledHeight - (selectionT + selectedInteractiveWidget.height) - 1;
				skin.invalidateDisplayList();
			}
			
			disabledUI.includeInLayout = disabledUI.visible = !enabled || !_watchChanges;
		}
		
		private function debugWidgets(): void
		{
		}

		private function onAreaChanged(event: InteractiveWidgetEvent): void
		{
			//check what was changed
			var widget: InteractiveWidget = event.target as InteractiveWidget;
			if (widget && _selectedInteractiveWidget)
			{
				//TODO do not change it for selected widget, it was already changed
				if (widget.id == _selectedInteractiveWidget.id)
				{
					var newCRS: String = widget.getCRS();
					var newViewBBox: BBox = widget.getViewBBox();
					var newExtentBBox: BBox = widget.getExtentBBox();
					var viewBBoxChanged: Boolean;
					var extentBBoxChanged: Boolean;
					var crsChanged: Boolean;
					var crsProjectionChanged: Boolean;
					var changes: int = 0;
					if (!m_viewBBox.equals(newViewBBox))
					{
						viewBBoxChanged = true;
						changes++;
					}
					if (m_extentBBox.equals(newExtentBBox))
					{
						extentBBoxChanged = true;
						changes++;
					}
					if (ms_crs != newCRS)
					{
						crsChanged = true;
						changes++;
					}
					if (changes > 0)
					{
						if (crsChanged)
						{
//							setCRS(newCRS, changes == 1);
							ms_crs = newCRS;
							m_crsProjection = widget.getCRSProjection();
							changes--;
						}
						if (extentBBoxChanged)
						{
//							setExtentBBOXRaw(newExtentBBox.xMax, newExtentBBox.yMin, newExtentBBox.xMax, newExtentBBox.yMax, changes == 1);
							m_extentBBox = newExtentBBox.clone();
							changes--;
						}
						if (m_viewBBox)
						{
							m_viewBBox = newViewBBox.clone();
//							setViewBBox(newViewBBox, changes == 1);
							changes--;
						}
						if (changes > 0)
						{
							trace("InteractiveMultiView onAreaChange: something is wrong");
						}
					}
				}
			}
			synchronizeWidgets(_areaSynchronizator, event.target as InteractiveWidget, false);
		}
		private var _synchronizator: ISynchronizator;

		public function invalidateSychronizator(): void
		{
			registerSynchronizator(_synchronizator);
		}

		public function get synchronizator(): ISynchronizator
		{
			return _synchronizator;
		}

		public function set synchronizator(synchronizator: ISynchronizator): void
		{
			_synchronizator = synchronizator;
			invalidateSychronizator();
		}

		public function synchronize(): void
		{
			if (synchronizator)
			{
				if (synchronizator.willSynchronisePrimaryLayer)
				{
					/**
					 * If primary layer will be synchronised, we need to stop listen for synchronization and call synchronize method again, othewise it will be infinite loop.
					 * Instead we will listen for synchronisation and after receiving SynchronisedVariableChangeEvent.SYNCHRONISED_VARIABLE_CHANGED we will start again previous listener.
					 *
					 * Just to avoid infinity synchronisation loop
					 *
					 */
					var primaryLayer: InteractiveLayerMSBase = selectedInteractiveWidget.interactiveLayerMap.primaryLayer;
					if (primaryLayer)
					{
						stopListenForSynchronisedVariableChange(primaryLayer);
						primaryLayer.addEventListener(SynchronisedVariableChangeEvent.SYNCHRONISED_VARIABLE_DOMAIN_CHANGED, waitForSynchronisedVariableChange);
						primaryLayer.addEventListener(SynchronisedVariableChangeEvent.SYNCHRONISED_VARIABLE_CHANGED, waitForSynchronisedVariableChange);
					}
				}
				
				if (primaryLayer && isLayerInSelectedWidget(primaryLayer))
					synchronizeWidgets(synchronizator, primaryLayer.container);
			}
		}

		private function isLayerInSelectedWidget(layer: InteractiveLayerMSBase): Boolean
		{
			if (layer)
			{
				var layerWidget: InteractiveWidget = layer.container;
				
				if (layerWidget && selectedInteractiveWidget)
				{
					if (layerWidget != selectedInteractiveWidget)
					{
						debug("isLayerInSelectedWidget WIDGETS ARE NOT SAME!!: layer " + layerWidget.name + " selected: " + selectedInteractiveWidget.name);
						return false;		
					} else {
						return true;
					}
				} else {
					debug("isLayerInSelectedWidget NO Widgets to synchronize ");
				}
			}
			return false;
		}
		private function waitForSynchronisedVariableChange(event: SynchronisedVariableChangeEvent): void
		{
			var primaryLayer: InteractiveLayerMSBase = selectedInteractiveWidget.interactiveLayerMap.primaryLayer;
			primaryLayer.removeEventListener(SynchronisedVariableChangeEvent.SYNCHRONISED_VARIABLE_DOMAIN_CHANGED, waitForSynchronisedVariableChange);
			primaryLayer.removeEventListener(SynchronisedVariableChangeEvent.SYNCHRONISED_VARIABLE_CHANGED, waitForSynchronisedVariableChange);
//			startListenForSynchronisedVariableChange(primaryLayer);
		}

		/**
		 * This function is just for test purposing and has not be used in normal development 
		 * 
		 */		
		public function debugStartListeningAgain(): void
		{
			enabled = true;
			if (selectedInteractiveWidget)
			{
				var layer: InteractiveLayerMSBase = selectedInteractiveWidget.interactiveLayerMap.primaryLayer;
				if (layer)
					startListenForSynchronisedVariableChange(layer);
			}
		}
		public function synchronizeWidgets(synchronizator: ISynchronizator, interactiveWidget: InteractiveWidget, bWaitForSynchronizationFinish: Boolean = true): void
		{
			if (!enabled)
			{
				debug("synchronizeWidgets, but synchronisation is in progress!!!");
				return;
			}
			if (_interactiveWidgets.widgets && _interactiveWidgets.widgets.length > 1)
			{
				synchronizator.invalidateSynchronizator();
				
				var selectedIndex: int = -1;
				if (_configuration && _configuration.customData && _configuration.customData.hasOwnProperty('selectedIndex'))
					selectedIndex = _configuration.customData.selectedIndex;
				
				//stop listening to changes and start after synchronization is done
				if (bWaitForSynchronizationFinish)
				{
					var primaryLayer: InteractiveLayerMSBase = selectedInteractiveWidget.interactiveLayerMap.primaryLayer;
					stopListenForSynchronisedVariableChange(primaryLayer);
				
					//and wait for synchronization to be done
					enabled = false;
					synchronizator.addEventListener(SynchronisationEvent.SYNCHRONISATION_DONE, onSynchronizationDone);
//				} else {
//					trace(this + " do not wait for synchronization end");
				}
					
				synchronizator.synchronizeWidgets(interactiveWidget, _interactiveWidgets.widgets, selectedIndex);
			}
		}
		
		private function onSynchronizationDone(event: SynchronisationEvent): void
		{
			synchronizator.removeEventListener(SynchronisationEvent.SYNCHRONISATION_DONE, onSynchronizationDone);
			
			var primaryLayer: InteractiveLayerMSBase = selectedInteractiveWidget.interactiveLayerMap.primaryLayer;
			
			startListenForSynchronisedVariableChange(primaryLayer);
			enabled = true;
		}

		private function registerSynchronizator(synchronizator: ISynchronizator): void
		{
			if (!synchronizator)
				return;
			var syncVars: Array = synchronizator.getSynchronisedVariables();
			if (syncVars && syncVars.length > 0)
			{
				for each (var iw: InteractiveWidget in _interactiveWidgets.widgets)
				{
					var labelLayer: InteractiveLayerLabel = iw.getLayerByType(InteractiveLayerLabel) as InteractiveLayerLabel;
					if (labelLayer)
					{
						labelLayer.synchronizator = synchronizator;
//						for each (var syncVarName: String in syncVars)
//						{
//							labelLayer.addSynchronisedVariable(syncVarName);		
//						}
					}
					else
					{
						trace("there is no labelLayer");
					}
				}
			}
		}

		private function debug(str: String, type: String = "Info", tag: String = " InteractiveMultiView"): void
		{
			if (debugConsole)
				debugConsole.print(str, type, tag);
			
			trace(tag + "| " + type + "| " + str);
			LoggingUtils.dispatchLogEvent(this, tag + "| " + type + "| " + str);
		}

		override public function toString(): String
		{
			return 'InteractiveMultiView: ';
		}
	}
}
import com.iblsoft.flexiweather.events.InteractiveLayerEvent;
import com.iblsoft.flexiweather.ogc.configuration.layers.interfaces.ILayerConfiguration;
import com.iblsoft.flexiweather.ogc.data.GlobalVariable;
import com.iblsoft.flexiweather.widgets.IConfigurableLayer;
import com.iblsoft.flexiweather.widgets.InteractiveLayer;
import com.iblsoft.flexiweather.widgets.InteractiveLayerMap;
import com.iblsoft.flexiweather.widgets.InteractiveWidget;

import flash.events.Event;
import flash.events.EventDispatcher;

import mx.collections.ArrayCollection;
import mx.collections.Sort;
import mx.collections.SortField;

class WidgetCollection
{
	private var _collection: ArrayCollection;

	public function get widgets(): ArrayCollection
	{
		return _collection;
	}
	private var _sort: Sort;

	public function WidgetCollection(): void
	{
		_collection = new ArrayCollection();
//		/* Create the SortField object for the "data" field in the ArrayCollection object, and make sure we do a numeric sort. */
		var dataSortField: SortField = new SortField();
		dataSortField.compareFunction = sortWidgets;
		_sort = new Sort();
		_sort.fields = [dataSortField];
//		
		/* Set the ArrayCollection object's sort property to our custom sort, and refresh the ArrayCollection. */
		_collection.sort = _sort;
	}

	public function widgetsExcept(iw: InteractiveWidget): ArrayCollection
	{
		var ac: ArrayCollection = new ArrayCollection();
		for each (var currIW: InteractiveWidget in _collection)
		{
			if (currIW.id != iw.id)
				ac.addItem(currIW);
		}
		return ac;
	}

	public function widgetExists(widget: InteractiveWidget): Boolean
	{
		return _collection.getItemIndex(widget) > -1;
	}

	public function removeWidget(widget: InteractiveWidget): void
	{
		if (widgetExists(widget))
			_collection.removeItemAt(_collection.getItemIndex(widget));
	}

	public function getWidgetAt(position: int): InteractiveWidget
	{
		if (_collection && _collection.length > position)
			return _collection.getItemAt(position) as InteractiveWidget;
		return null;
	}

	private function debugWidgetsIDs(): void
	{
		var cnt: int = 0;
		for each (var widget: InteractiveWidget in _collection)
		{
			trace("WidgetCollection debugWidgetsIDs cnt: " + cnt + " widget: " + widget.id);
			cnt++;
		}
	}
	
	public function addWidget(widget: InteractiveWidget): void
	{
//		trace("WidgetCollection addWidget: " + widget.id + " frame: " + widget.frame);
		_collection.addItem(widget);
		_collection.refresh();
		debugWidgetsIDs();
	}
	
	public function getWidgetIndex(widget: InteractiveWidget): int
	{
		return _collection.getItemIndex(widget);
	}
	
	private function getWidgetNumberFromID(widget: InteractiveWidget): int
	{
		var idStart: String = 'm_iw';
		if (widget.id != null && widget.id.indexOf(idStart) == 0)
		{
			var idStr: String = widget.id.substring(idStart.length, widget.id.length);
			var id: int = parseInt(idStr);
			return id;
		}
		return -1;
	}

	private function sortWidgets(widget1: InteractiveWidget, widget2: InteractiveWidget): int
	{
		var id1: int = getWidgetNumberFromID(widget1);
		var id2: int = getWidgetNumberFromID(widget2);
		if (id1 < id2)
			return -1;
		if (id1 > id2)
			return 1;
		return 0;
	}
}