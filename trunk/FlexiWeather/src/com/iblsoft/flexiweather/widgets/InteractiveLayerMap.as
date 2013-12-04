package com.iblsoft.flexiweather.widgets
{
	import com.iblsoft.flexiweather.FlexiWeatherConfiguration;
	import com.iblsoft.flexiweather.events.GetFeatureInfoEvent;
	import com.iblsoft.flexiweather.events.InteractiveLayerEvent;
	import com.iblsoft.flexiweather.events.InteractiveLayerMapEvent;
	import com.iblsoft.flexiweather.ogc.BBox;
	import com.iblsoft.flexiweather.ogc.ISynchronisedObject;
	import com.iblsoft.flexiweather.ogc.InteractiveLayerMSBase;
	import com.iblsoft.flexiweather.ogc.InteractiveLayerQTTMS;
	import com.iblsoft.flexiweather.ogc.InteractiveLayerWMS;
	import com.iblsoft.flexiweather.ogc.SynchronisationRole;
	import com.iblsoft.flexiweather.ogc.SynchronisedVariableChangeEvent;
	import com.iblsoft.flexiweather.ogc.cache.ICache;
	import com.iblsoft.flexiweather.ogc.configuration.MapTimelineConfiguration;
	import com.iblsoft.flexiweather.ogc.data.GlobalVariable;
	import com.iblsoft.flexiweather.ogc.managers.GlobalVariablesManager;
	import com.iblsoft.flexiweather.ogc.synchronisation.SynchronisationResponse;
	import com.iblsoft.flexiweather.ogc.tiling.ITiledLayer;
	import com.iblsoft.flexiweather.plugins.IConsole;
	import com.iblsoft.flexiweather.proj.Coord;
	import com.iblsoft.flexiweather.utils.ArrayUtils;
	import com.iblsoft.flexiweather.utils.DateUtils;
	import com.iblsoft.flexiweather.utils.HTMLUtils;
	import com.iblsoft.flexiweather.utils.ISO8601Parser;
	import com.iblsoft.flexiweather.utils.LoggingUtils;
	import com.iblsoft.flexiweather.utils.Serializable;
	import com.iblsoft.flexiweather.utils.Storage;
	import com.iblsoft.flexiweather.utils.XMLStorage;
	import com.iblsoft.flexiweather.widgets.data.InteractiveLayerMapSaveSettings;
	
	import flash.events.DataEvent;
	import flash.events.Event;
	import flash.events.TimerEvent;
	import flash.utils.Dictionary;
	import flash.utils.Timer;
	
	import mx.collections.ArrayCollection;
	import mx.controls.Alert;
	import mx.core.IVisualElement;
	import mx.events.CollectionEvent;
	import mx.events.CollectionEventKind;
	import mx.events.DynamicEvent;
	import mx.events.PropertyChangeEvent;
	
	import spark.events.ElementExistenceEvent;

	[Event(name = "mapLoadingStarted", type = "com.iblsoft.flexiweather.events.InteractiveLayerMapEvent")]
	[Event(name = "mapLoadingFinished", type = "com.iblsoft.flexiweather.events.InteractiveLayerMapEvent")]
	[Event(name = "frameVariableChanged", type = "flash.events.Event")]
	[Event(name = PRIMARY_LAYER_CHANGED, type = "flash.events.DataEvent")]
	[Event(name = LAYERS_SERIALIZED_AND_READY, type = "mx.events.DynamicEvent")]
	[Event(name = TIME_AXIS_UPDATED, type = "flash.events.DataEvent")]
	[Event(name = TIME_AXIS_ADDED, type = "mx.events.DynamicEvent")]
	[Event(name = LEVEL_VARIABLE_CHANGED, type = "mx.events.DynamicEvent")]
	[Event(name = RUN_VARIABLE_CHANGED, type = "mx.events.DynamicEvent")]
	[Event(name = TIME_AXIS_REMOVED, type = "mx.events.DynamicEvent")]
	[Event(name = SYNCHRONISE_WITH, type = "mx.events.DynamicEvent")]
	[Event(name = MAP_LAYERS_INITIALIZED, type = "flash.events.Event")]
	[Event(name = MAP_CHANGED, type = "flash.events.Event")]
	
	[DefaultProperty("mxmlContent")] 
	
	public class InteractiveLayerMap extends InteractiveLayerComposer implements Serializable
	{
		public static const MAP_CHANGED: String = "mapChanged";
		
		public static const TIMELINE_FRAMES_ENUMERATED: String = "timelineFramesEnumerated";
		
		public static const TIMELINE_CONFIGURATION_CHANGE: String = "timelineConfigurationChange";
		
		public static const LAYERS_SERIALIZED_AND_READY: String = "layersSerializedAndReady";
		
		public static const TIME_AXIS_UPDATED: String = "timeAxisUpdated";
		
		public static const TIME_AXIS_ADDED: String = "timeAxisAdded";
		
		public static const TIME_AXIS_REMOVED: String = "timeAxisRemoved";
		
		public static const PRIMARY_LAYER_CHANGED: String = "primaryLayerChanged";
		
		public static const FRAME_VARIABLE_CHANGED: String = "frameVariableChanged";
		
		public static const RUN_VARIABLE_CHANGED: String = "runVariableChanged";
		
		public static const LEVEL_VARIABLE_CHANGED: String = "levelVariableChanged";
		
		public static const SYNCHRONISE_WITH: String = "synchroniseWith";
		
		public static const LOADING_STATUS_READY: String = 'loadingStatusReady';
		public static const LOADING_STATUS_LOADING: String = 'loadingStatusLoading';
		
		public static const MAP_LAYERS_INITIALIZED: String = 'mapLayersInitialized';
		
		public static var debugConsole: IConsole;
		private static var mapUID: int = 0;
		public var mapID: int;
		/**
		 * first frame date from last periodical check
		 */
		private var _currentFirstFrame: Date;
		/**
		 * last frame date from last periodical check
		 */
		private var _currentLastFrame: Date;
		/**
		 * now frame date from last periodical check
		 */
		private var _currentNowFrame: Date;
		private var _periodicTimer: Timer;
		private var _dateFormat: String;

		private var _suspendTimeAxisNotify: Boolean;
		
		
		public function get suspendTimeAxisNotify():Boolean
		{
			return _suspendTimeAxisNotify;
		}

		public function set suspendTimeAxisNotify(value:Boolean):void
		{
			_suspendTimeAxisNotify = value;
		}

		public var loadingStatus: String;
		public function get mapIsLoading(): Boolean
		{
			return loadingStatus == LOADING_STATUS_LOADING;
		}
		
		/**
		 * Name of map. 
		 */		
		public var mapName: String;
		
		public function get dateFormat(): String
		{
			return _dateFormat;
		}

		public function set dateFormat(value: String): void
		{
			_dateFormat = value;
			notifyFrameVariableChanged();
		}

		[Bindable(event = RUN_VARIABLE_CHANGED)]
		public function get run(): Date
		{
			var runDate: Date = getSynchronizedRunValue();
//			var runString: String = _globalVariablesManager.run;
			return runDate;
		}
		
		[Bindable(event = LEVEL_VARIABLE_CHANGED)]
		public function get level(): String
		{
			var levelString: String = getSynchronizedLevelValue();
//			var levelString: String = _globalVariablesManager.level;
			return levelString;
		}

		[Bindable(event = FRAME_VARIABLE_CHANGED)]
		public function get frame(): Date
		{
			var frameDate: Date = getSynchronizedFrameValue();
//			var frameDate: Date = _globalVariablesManager.frame;
			return frameDate;
		}

		[Bindable(event = FRAME_VARIABLE_CHANGED)]
		public function get frameString(): String
		{
			if (dateFormat && dateFormat.length > 0)
				return DateUtils.strftime(frame, dateFormat);
			return frame.toString();
		}
		private var m_timelineConfiguration: MapTimelineConfiguration;
		private var m_timelineConfigurationChanged: Boolean;

		[Bindable]
		public function get timelineConfiguration(): MapTimelineConfiguration
		{
			return m_timelineConfiguration;
		}

		public function set timelineConfiguration(value: MapTimelineConfiguration): void
		{
			if (m_timelineConfiguration != value)
			{
				if (m_timelineConfiguration)
					m_timelineConfiguration.removeEventListener(Event.CHANGE, onTimelineConfigurationChange);
				
				m_timelineConfiguration = value;
				m_timelineConfigurationChanged = true;
				
				if (m_timelineConfiguration)
					m_timelineConfiguration.addEventListener(Event.CHANGE, onTimelineConfigurationChange);
				
				notifyTimelineConfigurationChanged();
			}
		}
		private var _globalVariablesManager: GlobalVariablesManager;

		[Bindable(event = "globalVariablesManagerChanged")]
		public function get globalVariablesManager(): GlobalVariablesManager
		{
			return _globalVariablesManager;
		}
		
		private var m_selectedLayerIndex: int;
		private var m_selectedLayerIndexChanged: Boolean
		
		public function get selectedLayerIndex():int
		{
			return m_selectedLayerIndex;
		}
		
		public function set selectedLayerIndex(value:int):void
		{
			if (m_selectedLayerIndex != value)
			{
				m_selectedLayerIndex = value;
				m_selectedLayerIndexChanged = true;
				invalidateProperties();
			}
		}
		
		protected var _tempMapStorage: MapTemporaryParameterStorage = new MapTemporaryParameterStorage();

		override public function set container(value:InteractiveWidget):void
		{
			super.container = value;
			
			if (m_layers)
			{
				for each (var layer: InteractiveLayer in m_layers)
				{
					layer.container = value;
				}
			}
		}
		
		public function InteractiveLayerMap(container: InteractiveWidget = null)
		{
			super(container);
		
			mapUID++;
			mapID = mapUID;
			
			selectedLayerIndex = -1;
			
			resetTimelineConfiguration();
			
//			addEventListener(ElementExistenceEvent.ELEMENT_ADD, onElementAdd);
			
			_globalVariablesManager = new GlobalVariablesManager();
			_globalVariablesManager.registerInteractiveLayerMap(this);
			
			_periodicTimer = new Timer(FlexiWeatherConfiguration.INTERACTIVE_LAYER_MAP_PERIODIC_CHECK_INTERVAL * 1000);
			_periodicTimer.addEventListener(TimerEvent.TIMER, onPeriodicTimerTick);
			
			if (FlexiWeatherConfiguration.INTERACTIVE_LAYER_MAP_PERIODIC_CHECK)
				_periodicTimer.start();
			
			dispatchEvent(new Event("globalVariablesManagerChanged"));
		}

		public function resetTimelineConfiguration(): void
		{
			if (!timelineConfiguration)
				timelineConfiguration = new MapTimelineConfiguration();
			
			timelineConfiguration.reset();
			
		}
		private function onPeriodicTimerTick(event: TimerEvent): void
		{
			periodicCheck();
		}

		/**
		 * Function is called periodically to check if there are changes in frames. It checks current first, last and now frames and compares
		 * them with lastly first, last and now frames and if there is any change, it dispatch proper events
		 *
		 */
		private function periodicCheck(): void
		{
			var firstDate: Date = getFirstFrame();
			var lastDate: Date = getLastFrame();
			var nowDate: Date = getNowFrame();
			var ilme: InteractiveLayerMapEvent;
			if (firstDate && (!_currentFirstFrame || _currentFirstFrame.time != firstDate.time))
			{
				//there were change in first frame
				_currentFirstFrame = firstDate;
				ilme = new InteractiveLayerMapEvent(InteractiveLayerMapEvent.FIRST_FRAME_CHANGED);
				ilme.frameDate = firstDate;
				dispatchEvent(ilme);
			}
			if (lastDate && (!_currentLastFrame || _currentLastFrame.time != lastDate.time))
			{
				//there were change in last frame
				_currentLastFrame = lastDate;
				ilme = new InteractiveLayerMapEvent(InteractiveLayerMapEvent.LAST_FRAME_CHANGED);
				ilme.frameDate = lastDate;
				dispatchEvent(ilme);
			}
			if (nowDate && (!_currentNowFrame || _currentNowFrame.time != nowDate.time))
			{
				//there were change in now frame
				_currentNowFrame = nowDate;
				ilme = new InteractiveLayerMapEvent(InteractiveLayerMapEvent.NOW_FRAME_CHANGED);
				ilme.frameDate = nowDate;
				dispatchEvent(ilme);
			}
		}

		private function onSerializedLayerInitialized(event: InteractiveLayerEvent): void
		{
			var layer: InteractiveLayer = event.target as InteractiveLayer;
			layer.removeEventListener(InteractiveLayerEvent.LAYER_INITIALIZED, onSerializedLayerInitialized);
			
			var msBaselayer: InteractiveLayerMSBase = layer as InteractiveLayerMSBase;
			
			if (msBaselayer && msBaselayer.isPrimaryLayer())
			{
				setPrimaryLayer(layer as InteractiveLayerMSBase);
			}
		}
		
		/**
		 * This method serialize map for storing single map layers with aditional info as animation setting and current area.
		 * If you need serialized map without aditional information please use serialize method instead.
		 *   
		 * @param storage
		 * 
		 */		
		public function serializeMapWithCustomSettings(storage: Storage): void
		{
			var wrappers: ArrayCollection;
			var wrapper: LayerSerializationWrapper;
			var layer: InteractiveLayer;
			debug("InteractiveLayerMap serializeAnimatedMap [IW: " + container.id + "] serialize loading: " + storage.isLoading());
			LayerSerializationWrapper.m_iw = container;
			LayerSerializationWrapper.map = this;
			if (storage.isLoading())
			{
				debug("serializeAnimatedMap : " + (storage as XMLStorage).xml.toXMLString());
				wrappers = new ArrayCollection();
				storage.serializeNonpersistentArrayCollection("layer", wrappers, LayerSerializationWrapper);
				m_layers.removeAll();
				var total: int = wrappers.length - 1;
				var newLayers: Array = [];
				for (var i: int = total; i >= 0; i--)
				{
					wrapper = wrappers.getItemAt(i) as LayerSerializationWrapper;
					debug("InteractiveLayerMap serialize wrapper: " + wrapper);
					layer = wrapper.m_layer;
					if (layer is InteractiveLayer)
					{
						layer.addEventListener(InteractiveLayerEvent.LAYER_INITIALIZED, onSerializedLayerInitialized);
						
						debug("InteractiveLayerMap serialize add layer: " + layer + " name: " + layer.name);
						newLayers.push(layer);
					}
				}
				
				selectedLayerIndex = storage.serializeInt('selected-layer-index', m_selectedLayerIndex);
				
				var globalLevel: String = storage.serializeString('global-level', null);
				if (globalVariablesManager)
				{
					if (globalLevel)
						globalVariablesManager.level = globalLevel;
				} else {
					trace("ILM serialize, problem to set global-level: " + globalLevel);
				}
				
				try {
					mapName = storage.serializeString('name', null);
				} catch (error: Error) {
					debug("Problem to serialize 'animation' mode");
				}
				try {
					storage.serialize('animation', timelineConfiguration);
				} catch (error: Error) {
					debug("Problem to serialize 'animation' mode");
				}
					
				
				try {
					storage.serializeWithCustomFunction('area', loadSerializedArea);
				} catch (error: Error) {
					debug("Problem to serialize 'area' mode");
				}
					
				var de: DynamicEvent = new DynamicEvent(LAYERS_SERIALIZED_AND_READY);
				de['layers'] = newLayers;
				dispatchEvent(de);
				
				//set global vars
			}
			else
			{
				var currentMapName: String = mapName;
				if (!currentMapName)
					currentMapName = "Map";
				
				storage.serializeString('name', currentMapName);
				
				//create wrapper collection
				wrappers = new ArrayCollection();
				for each (layer in m_layers)
				{
					wrapper = new LayerSerializationWrapper();
					wrapper.m_layer = layer;
					wrappers.addItem(wrapper);
				}
				storage.serializeNonpersistentArrayCollection("layer", wrappers, LayerSerializationWrapper);
				if (globalVariablesManager)
				{
//					if (settings.saveFrame)
//					{
//						var frameDateString: String;
//						if (globalVariablesManager.frame)
//							frameDateString = ISO8601Parser.dateToString(globalVariablesManager.frame);
//						storage.serializeString('global-frame', frameDateString);
//						storage.serializeString('run', frameDateString);
//					}
					storage.serializeString('global-level', globalVariablesManager.level);
				}
				
				if (selectedLayerIndex > -1)
				{
					storage.serializeInt('selected-layer-index', m_selectedLayerIndex);
				}
				
				storage.serialize('animation', timelineConfiguration);
				storage.serializeWithCustomFunction('area', saveSerializedArea);
				
				debug("serializeAnimatedMap" + (storage as XMLStorage).xml);
			}
			
			
		}
		
		public function loadSerializedArea(storage: Storage): void
		{
			if (container)
			{
				var extentBBoxXMin: Number = storage.serializeNumber('extent-x-min', 0);
				var extentBBoxXMax: Number = storage.serializeNumber('extent-x-max', 0);
				var extentBBoxYMin: Number = storage.serializeNumber('extent-y-min', 0);
				var extentBBoxYMax: Number = storage.serializeNumber('extent-y-max', 0);
				
				var viewBBoxXMin: Number = storage.serializeNumber('view-x-min', 0);
				var viewBBoxXMax: Number = storage.serializeNumber('view-x-max', 0);
				var viewBBoxYMin: Number = storage.serializeNumber('view-y-min', 0);
				var viewBBoxYMax: Number = storage.serializeNumber('view-y-max', 0);
				
				var crs: String = storage.serializeString('crs', null);
				var viewBBox: BBox = new BBox(viewBBoxXMin, viewBBoxYMin, viewBBoxXMax, viewBBoxYMax);
				var extentBBox: BBox = new BBox(extentBBoxXMin, extentBBoxYMin, extentBBoxXMax, extentBBoxYMax);
				
				container.setExtentBBox(extentBBox, false);
				container.setViewBBox(viewBBox, false);
				container.setCRS(crs);
			}
			
		}
		public function saveSerializedArea(storage: Storage): void
		{
			var extentBBox: BBox = container.getExtentBBox();
			var viewBBox: BBox = container.getViewBBox();
			var crs: String = container.getCRS();
			
			storage.serializeNumber('extent-x-min', extentBBox.xMin);
			storage.serializeNumber('extent-x-max', extentBBox.xMax);
			storage.serializeNumber('extent-y-min', extentBBox.yMin);
			storage.serializeNumber('extent-y-max', extentBBox.yMax);

			storage.serializeNumber('view-x-min', viewBBox.xMin);
			storage.serializeNumber('view-x-max', viewBBox.xMax);
			storage.serializeNumber('view-y-min', viewBBox.yMin);
			storage.serializeNumber('view-y-max', viewBBox.yMax);
			
			storage.serializeString('crs', crs);
			
		}
		
		public function startMapLoading(): void
		{
			loadingStatus = InteractiveLayerMap.LOADING_STATUS_LOADING;
			var ilme: InteractiveLayerMapEvent = new InteractiveLayerMapEvent(InteractiveLayerMapEvent.MAP_LOADING_STARTED);
			dispatchEvent(ilme);
		}
		public function progressMapInitializing(loadedLayers: uint, totalLayers: uint): void
		{
			var ilme: InteractiveLayerMapEvent = new InteractiveLayerMapEvent(InteractiveLayerMapEvent.MAP_INITIALIZING_PROGRESS);
			ilme.loadedLayers = loadedLayers;
			ilme.totalLayers = totalLayers;
			dispatchEvent(ilme);
		}
		public function progressMapLoading(loadedLayers: uint, totalLayers: uint): void
		{
			var ilme: InteractiveLayerMapEvent = new InteractiveLayerMapEvent(InteractiveLayerMapEvent.MAP_LOADING_PROGRESS);
			ilme.loadedLayers = loadedLayers;
			ilme.totalLayers = totalLayers;
			dispatchEvent(ilme);
		}
		public function finishMapLoading(): void
		{
			loadingStatus = InteractiveLayerMap.LOADING_STATUS_READY;
			
			_tempMapStorage.updateMapFromStorage(this, true);
			
			var ilme: InteractiveLayerMapEvent = new InteractiveLayerMapEvent(InteractiveLayerMapEvent.MAP_LOADING_FINISHED);
			dispatchEvent(ilme);
			
			//ask for map frames
			notifyTimeAxisUpdate();
			
			notifyMapChanged();
		}
		/**
		 * This method serialize map for storing single map layers without any aditional info (e.g. animation data, area).
		 * If you need serialized map with aditional information please use serializeAnimatedMap method instead.
		 *   
		 * @param storage
		 * 
		 */		
		override public function serialize(storage: Storage): void
		{
			var wrappers: ArrayCollection;
			var wrapper: LayerSerializationWrapper;
			var layer: InteractiveLayer;
//			debug("InteractiveLayerMap [IW: " + container.id + "] serialize loading: " + storage.isLoading());
			LayerSerializationWrapper.m_iw = container;
			LayerSerializationWrapper.map = this;
			var globalLevel: String;
			var globalRun: String;
			
			if (storage.isLoading())
			{
				wrappers = new ArrayCollection();
				storage.serializeNonpersistentArrayCollection("layer", wrappers, LayerSerializationWrapper);
				m_layers.removeAll();
				var total: int = wrappers.length - 1;
				var newLayers: Array = [];
				for (var i: int = total; i >= 0; i--)
				{
					wrapper = wrappers.getItemAt(i) as LayerSerializationWrapper;
					debug("InteractiveLayerMap serialize wrapper: " + wrapper);
					layer = wrapper.m_layer;
					if (layer is InteractiveLayer)
					{
						layer.addEventListener(InteractiveLayerEvent.LAYER_INITIALIZED, onSerializedLayerInitialized);
						
						debug("InteractiveLayerMap serialize add layer: " + layer + " name: " + layer.name);
						newLayers.push(layer);
					}
				}
				selectedLayerIndex = storage.serializeInt('selected-layer-index', m_selectedLayerIndex);
				
				globalLevel = storage.serializeString('global-level', null);
				globalRun = storage.serializeString('global-run', null);
				if (globalVariablesManager)
				{
					if (globalLevel)
					{
						setLevel(globalLevel);
					}
					if (globalRun)
					{
						var globalRunDate: Date = ISO8601Parser.stringToDate(globalRun);
						setRun(globalRunDate);
					}
				} else {
					trace("ILM serialize, problem to set global-level: " + globalLevel);
				}
				
				var de: DynamicEvent = new DynamicEvent(LAYERS_SERIALIZED_AND_READY);
				de['layers'] = newLayers;
				dispatchEvent(de);
			}
			else
			{
				//create wrapper collection
				wrappers = new ArrayCollection();
				for each (layer in m_layers)
				{
					wrapper = new LayerSerializationWrapper();
					wrapper.m_layer = layer;
					wrappers.addItem(wrapper);
				}
				storage.serializeNonpersistentArrayCollection("layer", wrappers, LayerSerializationWrapper);
				if (globalVariablesManager)
				{
//					var frameDateString: String;
//					if (globalVariablesManager.frame)
//						frameDateString = ISO8601Parser.dateToString(globalVariablesManager.frame)
//					storage.serializeString('global-frame', frameDateString);
					
					var synchronizableLevel: String = level;
					globalLevel = globalVariablesManager.level;
					
					storage.serializeString('global-level', globalVariablesManager.level);
					var runString: String = null;
					var synchronizableRun: Date = globalVariablesManager.run;
					if (synchronizableRun)
						runString = ISO8601Parser.dateToString(synchronizableRun);
					
					storage.serializeString('global-run', runString);
				}
				
				if (selectedLayerIndex > -1)
				{
					storage.serializeInt('selected-layer-index', m_selectedLayerIndex);
				}
				
//				debug("Map serialize: " + (storage as XMLStorage).xml);
			}
		}
		private var _frameInvalidated: Boolean;
		private var _runInvalidated: Boolean;
		private var _levelInvalidated: Boolean;

		public function invalidateFrame(): void
		{
			_frameInvalidated = true;
			invalidateProperties();
		}

		public function invalidateRun(): void
		{
			_runInvalidated = true;
			invalidateProperties();
		}
		public function invalidateLevel(): void
		{
			_levelInvalidated = true;
			invalidateProperties();
		}

		public function notifyAllLayersAreInitialized(): void
		{
//			trace("\n" + this + " notifyAllLayersAreInitialized");
			dispatchEvent(new Event(MAP_LAYERS_INITIALIZED));
			notifyMapChanged();
		}
			
		private function notifyTimeAxisFrameUpdate(): void
		{
			if (!_suspendTimeAxisNotify)
			{
//				trace("\n" + this + " notifyTimeAxisFrameUpdate");
				dispatchEvent(new DataEvent(TIME_AXIS_UPDATED));
			}
			
		}
		private function notifyTimeAxisUpdate(): void
		{
			if (!_suspendTimeAxisNotify)
			{
//				trace("\n" + this + " notifyTimeAxisUpdate");
				dispatchEvent(new DataEvent(TIME_AXIS_UPDATED));
			}
		}

		private var _timelineInvalidate: Boolean;
		
		public function invalidateTimeline(): void
		{
			_timelineInvalidate = true;
			invalidateProperties();
		}

		override protected function onLayerCollectionChanged(event: CollectionEvent): void
		{
			super.onLayerCollectionChanged(event);
			
			var bNotifyTimeAxisUpdate: Boolean = true;
			
			if (event.kind == CollectionEventKind.UPDATE)
			{
				if (event.items.length == 1)
				{
					var pce: PropertyChangeEvent = event.items[0] as PropertyChangeEvent;
					if (!pce.newValue && !pce.oldValue)
						bNotifyTimeAxisUpdate = false;
				}
			}
			if (bNotifyTimeAxisUpdate)
				notifyTimeAxisUpdate();
		}

		public function onLayerDeselected(layer: InteractiveLayer): void
		{
			selectedLayerIndex = -1;	
		}
		
		public function onLayerSelected(layer: InteractiveLayer): void
		{
			var total: int = layers.length;
			
			for (var i: int = 0; i < total; i++)
			{
				var currLayer: InteractiveLayer = layers.getItemAt(i) as InteractiveLayer;
				
				if (currLayer == layer)
				{
					selectedLayerIndex = i;
					return;
				}
			}
			
			selectedLayerIndex = -1;
		}
		
		private var _firstDataReceived: Dictionary = new Dictionary();
		
		private function resynchronizeOnStart(event: SynchronisedVariableChangeEvent): void
		{
			var layer: InteractiveLayerMSBase = event.currentTarget as InteractiveLayerMSBase
			resynchronize();
			
//			if (_firstDataReceived[layer])
//			{
//				if (!_firstDataReceived[layer].firstDataReceived)
//				{
//					_firstDataReceived[layer] = {firstDataReceived: true};
//					resynchronize();
//				}
//			}
		}
		
		private function invalidateEnumTimeAxis(): void
		{
			//delete enumTimeAxis cache and retrieve tham again
			_cachedEnumTimeAxis = null;
			enumTimeAxis();
		}
		
		protected function onSynchronisedVariableChanged(event: SynchronisedVariableChangeEvent): void
		{
			var layerSynchronized: InteractiveLayerMSBase = event.target as InteractiveLayerMSBase;
			if (layerSynchronized && layerSynchronized != primaryLayer)
			{
				//if synchronization was done in non Primary Layer, dispatch InteractiveLayerMap.TIME_AXIS_UPDATED event to updated selection
				dispatchEvent(new DataEvent(InteractiveLayerMap.TIME_AXIS_UPDATED));
				return;
			}
			
//			trace("ILM onSynchronisedVariableChanged: " + event.variableId);
			invalidateEnumTimeAxis();
			
			if (event.variableId == GlobalVariable.FRAME)
			{
//				resynchronizeOnStart(event);
				periodicCheck();
				notifyFrameVariableChanged();
			}
			if (event.variableId == GlobalVariable.LEVEL)
				notifyLevelVariableChanged();
			
			if (event.variableId == GlobalVariable.RUN)
			{
				periodicCheck();
				notifyRunVariableChanged();
			}
		}

		private function notifyRunVariableChanged(): void
		{
			dispatchEvent(new Event(RUN_VARIABLE_CHANGED));
		}
		private function notifyFrameVariableChanged(): void
		{
			dispatchEvent(new Event(FRAME_VARIABLE_CHANGED));
		}
		private function notifyLevelVariableChanged(): void
		{
			dispatchEvent(new Event(LEVEL_VARIABLE_CHANGED));
		}
		protected function onSynchronisedVariableDomainChanged(event: SynchronisedVariableChangeEvent): void
		{
//			trace("ILM onSynchronisedVariableDomainChanged: " + event.variableId);
			invalidateEnumTimeAxis();
			
			if (event.variableId == GlobalVariable.FRAME)
			{
				notifyTimeAxisUpdate();
				resynchronizeOnStart(event);
				periodicCheck();
				notifyFrameVariableChanged();
			}
			if (event.variableId == GlobalVariable.LEVEL)
				notifyLevelVariableChanged();
			
			if (event.variableId == GlobalVariable.RUN)
			{
				notifyTimeAxisUpdate();
				periodicCheck();
				notifyRunVariableChanged();
			}
		}

		public function getLayersOrderString(): String
		{
			var str: String = '';
			for each (var l: InteractiveLayer in m_layers)
			{
				str += "\t layer: " + l.layerName + "\n";
			}
			return str;
		}

		override protected function commitProperties(): void
		{
			super.commitProperties();
			if (_frameInvalidated)
			{
				_frameInvalidated = false;
				//it will set frame again. This is done by purpose when adding new layer, to synchronise frame with newly added layer
				if (frame)
				{
					setFrame(frame);
					notifyFrameVariableChanged();
				}
			}
			if (_runInvalidated)
			{
				_runInvalidated = false;
				
				//it will set run again. This is done by purpose when adding new layer, to synchronise level with newly added layer
				setRun(_globalVariablesManager.run);
				notifyRunVariableChanged();
			}
			if (_levelInvalidated)
			{
				_levelInvalidated = false;
				
				//it will set level again. This is done by purpose when adding new layer, to synchronise level with newly added layer
				setLevel(_globalVariablesManager.level);
				notifyLevelVariableChanged();
			}
			
			if (m_selectedLayerIndexChanged)
			{
				var ilme: InteractiveLayerMapEvent = new InteractiveLayerMapEvent(InteractiveLayerMapEvent.LAYER_SELECTION_CHANGED, true);
				dispatchEvent(ilme);
				m_selectedLayerIndexChanged = false;
			}
			
			if (_timelineInvalidate)
			{
				notifyTimeAxisUpdate();
				_timelineInvalidate = false;
			}
				
		}

		//----------------------------------
		//  mxmlContent
		//----------------------------------
		
		private var mxmlContentChanged:Boolean = false;
		private var _mxmlContent:Array;
		
		[ArrayElementType("mx.core.IVisualElement")]
		
		/**
		 *  The visual content children for this Group.
		 * 
		 *  This method is used internally by Flex and is not intended for direct
		 *  use by developers.
		 *
		 *  <p>The content items should only be IVisualElement objects.  
		 *  An <code>mxmlContent</code> Array should not be shared between multiple
		 *  Group containers because visual elements can only live in one container 
		 *  at a time.</p>
		 * 
		 *  <p>If the content is an Array, do not modify the Array 
		 *  directly. Use the methods defined by the Group class instead.</p>
		 *
		 *  @default null
		 *
		 *  @langversion 3.0
		 *  @playerversion Flash 10
		 *  @playerversion AIR 1.5
		 *  @productversion Flex 4
		 */
		public function set mxmlContent(value:Array):void
		{
			if (createChildrenCalled)
			{
				setMXMLContent(value);
			}
			else
			{
				mxmlContentChanged = true;
				_mxmlContent = value;
				// we will validate this in createChildren();
			}
		}
		
		
		/**
		 *  @private
		 *  Whether createChildren() has been called or not.
		 *  We use this in the setter for mxmlContent to know 
		 *  whether to validate the value immediately, or just 
		 *  wait to let createChildren() do it.
		 */
		private var createChildrenCalled:Boolean = false;
		
		override protected function createChildren():void
		{
			super.createChildren();
			
			createChildrenCalled = true;
			
			if (mxmlContentChanged)
			{
				mxmlContentChanged = false;
				setMXMLContent(_mxmlContent);
			}
		}
		
//		override protected function childrenCreated(): void
//		{
//			super.childrenCreated();
//		}
		
		private function setMXMLContent(layers: Array): void
		{
			for each (var layer: InteractiveLayer in layers)
			{
				addLayer(layer);
			}
		}
		
		/**
		 *  @private
		 *  Adds the elements in <code>mxmlContent</code> to the Group.
		 *  Flex calls this method automatically; you do not call it directly.
		 *  
		 *  @langversion 3.0
		 *  @playerversion Flash 10
		 *  @playerversion AIR 1.5
		 *  @productversion Flex 4
		 */ 
/*		private function setMXMLContent(value:Array):void
		{
			var i:int;
			
			// if there's old content and it's different than what 
			// we're trying to set it to, then let's remove all the old 
			// elements first.
			if (_mxmlContent != null && _mxmlContent != value)
			{
				for (i = _mxmlContent.length - 1; i >= 0; i--)
				{
					removeLayerAt(_mxmlContent[i], i);
				}
			}
			
			_mxmlContent = (value) ? value.concat() : null;  // defensive copy
			
			if (_mxmlContent != null)
			{
				var n:int = _mxmlContent.length;
				for (i = 0; i < n; i++)
				{   
					var elt:IVisualElement = _mxmlContent[i];
					
					// A common mistake is to bind the viewport property of a Scroller
					// to a group that was defined in the MXML file with a different parent    
					if (elt.parent && (elt.parent != this))
						throw new Error(resourceManager.getString("components", "mxmlElementNoMultipleParents", [elt]));
					
					addLayerAt(elt, i);
				}
			}
		}*/
		
		
		override public function addLayer(l: InteractiveLayer): void
		{
			if (l)
			{
				super.addLayer(l);
				if (!_firstDataReceived[l])
				{
					_firstDataReceived[l] = {layer: l, firstDataReceived: false};
				}
				callLater(resynchronize);
			}
			else
			{
				debug("Layer is null, do not add it to InteractiveLayerMap");
			}
		}

		override protected function layerAdded(layer: InteractiveLayer): void
		{
			super.layerAdded(layer);
			
			debug(this + " ADD LAYER: " + layer.toString());
			
			if (layer)
			{
				
				var so: ISynchronisedObject = layer as ISynchronisedObject;
				var isReadyForSynchronisation: Boolean = true;
				//need to wait when synchronizaed variables will be update (set FRAME and LEVEL)
				if (so)
				{
					isReadyForSynchronisation = so.isReadyForSynchronisation;
					
					if (isReadyForSynchronisation)
					{
						layerSynchronisationReady(layer);
					} else {
						waitForLayerSynchronisationReady(layer);
					}
				} else {
					addLayerToTimeAxis(layer);
					invalidateAreaForLayer(layer);
				}
				
				notifyMapChanged();
			}
			else
			{
				debug("Layer is null, do not add it to InteractiveLayerMap");
			}
		}
		
		private function waitForLayerSynchronisationReady(layer: InteractiveLayer): void
		{
			var checker: LayerSynchronisationStatusChecker = new LayerSynchronisationStatusChecker(layer as ISynchronisedObject);
			checker.addEventListener(LayerSynchronisationStatusChecker.LAYER_READY, onLayerSynchronisedIsReady);
		}
		private function onLayerSynchronisedIsReady(event: Event): void
		{
			var checker: LayerSynchronisationStatusChecker = event.target as LayerSynchronisationStatusChecker;
			layerSynchronisationReady(checker.layer as InteractiveLayer);
		}
		
		private function addLayerToTimeAxis(layer: InteractiveLayer): void
		{
			invalidateEnumTimeAxis();
			
			var dynamicEvent: DynamicEvent = new DynamicEvent(TIME_AXIS_ADDED);
			dynamicEvent['layer'] = layer;
			dispatchEvent(dynamicEvent);
		}
		
		private function layerSynchronisationReady(layer: InteractiveLayer): void
		{
			var synchronisableFrame: Boolean = false;
			var synchronisableRun: Boolean = false;
			var synchronisableLevel: Boolean = false;
			var so: ISynchronisedObject = layer as ISynchronisedObject;
			var isReadyForSynchronisation: Boolean = true;
			
			addLayerToTimeAxis(layer);
			
			//need to wait when synchronizaed variables will be update (set FRAME and LEVEL)
			if (so)
			{
				isReadyForSynchronisation = so.isReadyForSynchronisation;
				
				var synchronisedVariables: Array = so.getSynchronisedVariables();
				if (synchronisedVariables)
				{
					synchronisableFrame = synchronisedVariables.indexOf(GlobalVariable.FRAME) >= 0;
					synchronisableRun = synchronisedVariables.indexOf(GlobalVariable.RUN) >= 0;
					synchronisableLevel = synchronisedVariables.indexOf(GlobalVariable.LEVEL) >= 0;
				}
			}
			
			if (getPrimaryLayer() == null && isReadyForSynchronisation)
			{
				if (!so || !synchronisableFrame)
				{
					invalidateAreaForLayer(layer);
					return;
				}
				//this layer can be primary layer and there is no primary layer set, set this one as primaty layer	
				setPrimaryLayer(layer as InteractiveLayerMSBase);
			}
			else
			{
				invalidateFrame();
				//					if (synchronisableLevel && (layer as InteractiveLayerMSBase).synchroniseLevel)
				//					{
				//						invalidateLevel();
				//					}
			}
			if (layer is InteractiveLayerMSBase)
			{
				var msBaseLayer: InteractiveLayerMSBase = layer as InteractiveLayerMSBase;
				
				//TODO check that frame is synchronized twice (for RUN and LEVEL as well)
				if (synchronisableRun && msBaseLayer.synchroniseRun)
				{
					var globalRun: Date = run;
					var bSynchronized: Boolean = false;
					if (frame) {
						var frameSynchronisationResponse: String = so.synchroniseWith(GlobalVariable.FRAME, frame);
						bSynchronized = bSynchronized || SynchronisationResponse.wasSynchronised(frameSynchronisationResponse);
					}
					if (run) {
						var runSynchronisationResponse: String = so.synchroniseWith(GlobalVariable.RUN, run);
						bSynchronized = bSynchronized || SynchronisationResponse.wasSynchronised(runSynchronisationResponse);
					}
					if (bSynchronized)
					{
						layer.refresh(false);
					}
				} else {
					invalidateRun();
				}
				
				
				if (synchronisableLevel && msBaseLayer.synchroniseLevel)
				{
					var globalLevel: String = level;
					bSynchronized = false;
					if (frame) {
						frameSynchronisationResponse = so.synchroniseWith(GlobalVariable.FRAME, frame);
						bSynchronized = bSynchronized || SynchronisationResponse.wasSynchronised(frameSynchronisationResponse);
					}
					if (level) {
						var levelSynchronisationResponse: String = so.synchroniseWith(GlobalVariable.LEVEL, level);
						bSynchronized = bSynchronized || SynchronisationResponse.wasSynchronised(levelSynchronisationResponse);
					}
					if (bSynchronized)
					{
						layer.refresh(false);
					}
				} else {
					invalidateLevel();
				}
			}
			
			
			if (so && isReadyForSynchronisation && so.isPrimaryLayer())
			{
				invalidateAreaForLayer(layer);
			}
			
			//wms layers without any dimension
			if (so && isReadyForSynchronisation && synchronisedVariables.length == 0)
			{
				invalidateAreaForLayer(layer);
			}
		}

		/**
		 * Function find first suitable layer, which can primary layer (can have frames)
		 *
		 */
		private function findNewPrimaryLayer(): void
		{
			for each (var l: InteractiveLayer in m_layers)
			{
				if (l is InteractiveLayerMSBase)
				{
					var lWMS: InteractiveLayerMSBase = l as InteractiveLayerMSBase;
					var so: ISynchronisedObject = lWMS as ISynchronisedObject;
					if (so == null)
						continue;
					var test: * = so.getSynchronisedVariables();
					if (!test)
						continue;
					if (so.getSynchronisedVariables().indexOf(GlobalVariable.FRAME) < 0)
						continue;
					//this layer can be primary layer and there is no primary layer set, set this one as primaty layer	
					setPrimaryLayer(lWMS);
					return;
				}
			}
		}

		override public function removeLayer(l: InteractiveLayer): void
		{
			super.removeLayer(l);
			if ((l is InteractiveLayerMSBase) && (l as InteractiveLayerMSBase).isPrimaryLayer())
			{
				setPrimaryLayer(null);
				findNewPrimaryLayer();
			}
			var dynamicEvent: DynamicEvent = new DynamicEvent(TIME_AXIS_REMOVED);
			dynamicEvent['layer'] = l;
			dispatchEvent(dynamicEvent);
			
			invalidateEnumTimeAxis();
			
			notifyMapChanged();
		}

		private function getSynchronizedFrameValue(): Date
		{
			if (primaryLayer)
				return (primaryLayer as ISynchronisedObject).getSynchronisedVariableValue(GlobalVariable.FRAME) as Date;
			return null;
		}
		
		private function getSynchronizedRunValue(): Date
		{
			if (primaryLayer)
				return (primaryLayer as ISynchronisedObject).getSynchronisedVariableValue(GlobalVariable.RUN) as Date;
			return null;
		}
		
		private function getSynchronizedLevelValue(): String
		{
			if (primaryLayer)
				return (primaryLayer as ISynchronisedObject).getSynchronisedVariableValue(GlobalVariable.LEVEL) as String;
			return null;
		}

		private var m_primaryLayer: InteractiveLayerMSBase;

		[Bindable(event = PRIMARY_LAYER_CHANGED)]
		public function get primaryLayer(): InteractiveLayerMSBase
		{
			return m_primaryLayer;
		}

		public function getPrimaryLayer(): InteractiveLayerMSBase
		{
			for each (var layer: InteractiveLayer in m_layers)
			{
				if (layer is InteractiveLayerMSBase)
				{
					var layerMSBase: InteractiveLayerMSBase = layer as InteractiveLayerMSBase;
					if (layerMSBase.isPrimaryLayer())
						return layerMSBase;
				}
			}
			return null;
		}

		public function setPrimaryLayer(layer: InteractiveLayerMSBase): void
		{
			if (m_primaryLayer != layer)
			{
				if (m_primaryLayer)
				{
					//previous primary layer is not primary layer anymore, set synchronisation role to NONE
					m_primaryLayer.synchronisationRole.setRole(SynchronisationRole.NONE);
				}
				m_primaryLayer = layer;
				if (m_primaryLayer)
				{
					//there is new primary layer, set synchronisation role to PRIMARY
					m_primaryLayer.synchronisationRole.setRole(SynchronisationRole.PRIMARY);
				}
				primaryLayerHasChanged();
			}
		}

		/**
		 * Layer composer need to dispatch event when new layer becomes primary
		 *
		 */
		private function primaryLayerHasChanged(): void
		{
			invalidateEnumTimeAxis();
			
			invalidateRun();
			invalidateFrame();
			invalidateLevel();
			
			dispatchEvent(new DataEvent(PRIMARY_LAYER_CHANGED, true));
			
			notifyMapChanged();
		}

		private var _cachedEnumTimeAxis: Array;
		private var _cachedSyncLayers: Array;
		
		// data global variables synchronisation
		public function enumTimeAxis(l_syncLayers: Array = null): Array
		{
			
			/**
			 * enumTimeAxis is very time expensive function, which is called many times, so we can rather cache it and when
			 * there is any change (add/remove layer, add/remove frames in any layer, we will reenumarate frame
			 */
			
			if (!_cachedEnumTimeAxis)
			{
				_cachedSyncLayers = [];
				_cachedEnumTimeAxis = reenumTimeAxis(_cachedSyncLayers);
			}
			if (l_syncLayers)
			{
				var so: ISynchronisedObject;
				for each (so in _cachedSyncLayers)
				{
					l_syncLayers.push(so);
				}
			}
			return _cachedEnumTimeAxis;
		}
		
		private function notifyTimeAxisReenumerated(): void
		{
			if (!_suspendTimeAxisNotify)
			{
				dispatchEvent(new Event(TIMELINE_FRAMES_ENUMERATED));
			}
		}
		
		private function reenumTimeAxis(l_syncLayers: Array = null): Array
		{
//			if (l_syncLayers == null)
//				l_syncLayers = [];
			
			var l_timeAxis: Array = null;
			for each (var l: InteractiveLayer in m_layers)
			{
				var so: ISynchronisedObject = l as ISynchronisedObject;
				if (so == null)
					continue;
				var test: * = so.getSynchronisedVariables();
				//debug("enumTimeAxis so: " + (so as Object).name + " synchro vars: " + test.toString());
				if (test == null)
					continue;
				if (test.indexOf(GlobalVariable.FRAME) < 0)
					continue;
				if (!so.isPrimaryLayer())
					continue;
				var l_frames: Array = so.getSynchronisedVariableValuesList(GlobalVariable.FRAME);
				if (l_frames == null)
					continue;
				l_syncLayers.push(so);
				if (l_timeAxis == null)
					l_timeAxis = l_frames;
				else
					ArrayUtils.unionArrays(l_timeAxis, l_frames);
			}
			callLater(notifyTimeAxisReenumerated);
			return l_timeAxis;
		}
		
		public function enumRuns(l_syncLayers: Array = null): Array
		{
			if (l_syncLayers == null)
				l_syncLayers = [];
			var l_timeAxis: Array = null;
			for each (var l: InteractiveLayer in m_layers)
			{
				var so: ISynchronisedObject = l as ISynchronisedObject;
				if (so == null)
					continue;
				var test: * = so.getSynchronisedVariables();
				//debug("enumTimeAxis so: " + (so as Object).name + " synchro vars: " + test.toString());
				if (test == null)
					continue;
				if (so.getSynchronisedVariables().indexOf(GlobalVariable.RUN) < 0)
					continue;
//				if (!so.isPrimaryLayer())
				if (!so.synchroniseRun)
					continue;
				var l_runs: Array = so.getSynchronisedVariableValuesList(GlobalVariable.RUN);
				if (l_runs == null)
					continue;
				l_syncLayers.push(so);
				if (l_timeAxis == null)
					l_timeAxis = l_runs;
				else {
//					ArrayUtils.unionArrays(l_timeAxis, l_runs);
					ArrayUtils.intersectedArrays(l_timeAxis, l_runs);
				}
			}
			return l_timeAxis;
		}
		public function enumLevels(l_syncLayers: Array = null): Array
		{
			if (l_syncLayers == null)
				l_syncLayers = [];
			var l_timeAxis: Array = null;
			for each (var l: InteractiveLayer in m_layers)
			{
				var so: ISynchronisedObject = l as ISynchronisedObject;
				if (so == null)
					continue;
				var test: * = so.getSynchronisedVariables();
				//debug("enumTimeAxis so: " + (so as Object).name + " synchro vars: " + test.toString());
				if (test == null)
					continue;
				if (so.getSynchronisedVariables().indexOf(GlobalVariable.LEVEL) < 0)
					continue;
//				if (!so.isPrimaryLayer())
				if (!so.synchroniseLevel)
					continue;
				var l_levels: Array = so.getSynchronisedVariableValuesList(GlobalVariable.LEVEL);
				if (l_levels == null)
					continue;
				l_syncLayers.push(so);
				if (l_timeAxis == null)
					l_timeAxis = l_levels;
				else {
//					ArrayUtils.unionArrays(l_timeAxis, l_levels);
					ArrayUtils.intersectedArrays(l_timeAxis, l_levels);
				}
			}
			return l_timeAxis;
		}

		public function getDimensionDefaultValue(dimName: String): Object
		{
			var l_syncLayers: Array = [];
			var l_timeAxis: Array = enumTimeAxis(l_syncLayers);
			var i: int;
			var so: ISynchronisedObject;
			for each (so in l_syncLayers)
			{
				var value: Object = (so as InteractiveLayerMSBase).getWMSDimensionDefaultValue(dimName);
			}
			return value;
		}

		/**
		 * get all dimensions for this layer map
		 *
		 * @param dimName
		 * @param b_intersection
		 * @return
		 *
		 */
		public function getDimensions(b_intersection: Boolean = true): Array
		{
			var l_syncLayers: Array = [];
			var l_timeAxis: Array = enumTimeAxis(l_syncLayers);
			if (l_timeAxis == null) // no time axis
				return null;
			var i: int;
			var so: ISynchronisedObject;
			var a_dimensions: Array;
			for each (so in l_syncLayers)
			{
				//debug("\n Composer getDimensionValues ["+dimName+"] get values for layer: " + (so as Object).name);
				var values: Array = (so as InteractiveLayerMSBase).getWMSDimensionsNames()
				if (a_dimensions == null)
					a_dimensions = values;
				else
				{
					if (b_intersection)
						a_dimensions = ArrayUtils.intersectedArrays(a_dimensions, values);
					else
						ArrayUtils.unionArrays(a_dimensions, values);
				}
			}
			return a_dimensions;
		}

		/**
		 * get all WMS layers, which support dimension
		 *
		 * @param dimName
		 * @return
		 *
		 */
		public function getWMSLayersForDimension(dimName: String): Array
		{
			var l_syncLayers: Array = [];
			var l_timeAxis: Array = enumTimeAxis(l_syncLayers);
			if (l_timeAxis == null) // no time axis
				return null;
			var i: int;
			var so: ISynchronisedObject;
			var a_layers: Array = [];
			for each (so in l_syncLayers)
			{
				//debug("\n Composer getDimensionValues ["+dimName+"] get values for layer: " + (so as Object).name);
				if ((so as InteractiveLayerMSBase).supportWMSDimension(dimName))
					a_layers.push(so);
			}
			return a_layers;
		}

		/**
		 * get all dimension values for this layer map
		 *
		 * @param dimName
		 * @param b_intersection
		 * @return
		 *
		 */
		public function getDimensionValues(dimName: String, b_intersection: Boolean = true): Array
		{
			var l_syncLayers: Array = [];
			var l_timeAxis: Array = enumTimeAxis(l_syncLayers);
			if (l_timeAxis == null) // no time axis
				return null;
			var i: int;
			var so: ISynchronisedObject;
			var a_dimValues: Array;
			for each (so in l_syncLayers)
			{
				//debug("\n Composer getDimensionValues ["+dimName+"] get values for layer: " + (so as Object).name);
				var values: Array = (so as InteractiveLayerMSBase).getWMSDimensionsValues(dimName, b_intersection);
				if (a_dimValues == null)
					a_dimValues = values;
				else
				{
					if (b_intersection)
						a_dimValues = ArrayUtils.intersectedArrays(a_dimValues, values);
					else
						ArrayUtils.unionArrays(a_dimValues, values);
				}
			}
			return a_dimValues;
		}

		public function areFramesInsideTimePeriod(startDate: Date, endDate: Date): Boolean
		{
			if (!startDate || !endDate)
				return false;
				
			var l_syncLayers: Array = [];
			var l_timeAxis: Array = enumTimeAxis(l_syncLayers);
			if (l_timeAxis == null) // no time axis
				return false;
			var i: int;
			var so: ISynchronisedObject;
			for each (so in l_syncLayers)
			{
				if (so)
				{
					var frame: Date = so.getSynchronisedVariableValue(GlobalVariable.FRAME) as Date;
					if (frame == null)
						continue;
					for (i = 0; i < l_timeAxis.length; ++i)
					{
						var currDate: Date = l_timeAxis[i] as Date;
						if (startDate.time <= currDate.time && currDate.time <= endDate.time)
						{
							return true;
						}
					}
				}
			}
			return false;
		}

		/**
		 * return first available frame
		 * @return
		 *
		 */
		public function getFirstFrame(): Date
		{
			var l_syncLayers: Array = [];
			var l_timeAxis: Array = enumTimeAxis(l_syncLayers);
			if (l_timeAxis == null) // no time axis
			{
				return null;
			}
			return l_timeAxis[0] as Date;
		}

		public function getLastFrame(): Date
		{
			var l_syncLayers: Array = [];
			var l_timeAxis: Array = enumTimeAxis(l_syncLayers);
			if (l_timeAxis == null) // no time axis
			{
				return null;
			}
			return l_timeAxis[l_timeAxis.length - 1] as Date;
		}

		public function getNowFrame(): Date
		{
			var l_syncLayers: Array = [];
			var l_timeAxis: Array = enumTimeAxis(l_syncLayers);
			if (l_timeAxis == null) // no time axis
			{
				return null;
			}
			var i: int;
			var so: ISynchronisedObject;
			var now: Date = DateUtils.convertToUTCDate(new Date());
			var nowDistance: Number = Number.MAX_VALUE;
			var nowFrame: Date;
			for each (so in l_syncLayers)
			{
				var frame: Date = so.getSynchronisedVariableValue(GlobalVariable.FRAME) as Date;
				if (frame == null)
					continue;
				for (i = 0; i < l_timeAxis.length; ++i)
				{
					var currDate: Date = l_timeAxis[i] as Date;
					if (Math.abs(currDate.time - now.time) < nowDistance)
					{
						nowDistance = Math.abs(currDate.time - now.time);
						nowFrame = currDate;
					}
				}
			}
			return nowFrame;
		}

		public function get canAnimate(): Boolean
		{
			var l_syncLayers: Array = [];
			var l_timeAxis: Array = enumTimeAxis(l_syncLayers);
			if (l_timeAxis == null) // no time axis
				return false;
			var i: int;
			var so: ISynchronisedObject;
			var i_currentIndex: int = -1;
			
			for each (var l: InteractiveDataLayer in m_layers)
			{
//				var so: ISynchronisedObject = l as ISynchronisedObject;
//				if (so == null)
//					continue;
//				var variables: * = so.getSynchronisedVariables();
//				if (variables == null)
//					continue;
//				if (variables.indexOf(GlobalVariable.FRAME) < 0)
//					continue;
				
				var status: String = l.status;
				
				if (l.visible && status != InteractiveDataLayer.STATE_DATA_LOADED && status != InteractiveDataLayer.STATE_NO_SYNCHRONISATION_DATA_AVAILABLE)
				{
					return false;
				}
			}
			return true;
		}

		public function moveFrame(i_offset: int): Boolean
		{
			var l_syncLayers: Array = [];
			var l_timeAxis: Array = enumTimeAxis(l_syncLayers);
			if (l_timeAxis == null) // no time axis
				return false;
			var i: int;
			var so: ISynchronisedObject;
			var i_currentIndex: int = -1;
			for each (so in l_syncLayers)
			{
				var frame: Date = so.getSynchronisedVariableValue(GlobalVariable.FRAME) as Date;
				if (frame == null)
					continue;
				for (i = 0; i < l_timeAxis.length; ++i)
				{
					if ((l_timeAxis[i] as Date).time == frame.time)
					{
						i_currentIndex = i;
						break;
					}
				}
				if (i_currentIndex >= 0)
					break;
			}
			if (i_currentIndex < 0)
				return false;
			i_currentIndex += i_offset;
			if (i_currentIndex < 0)
				return false;
			if (i_currentIndex >= l_timeAxis.length)
				return false;
			var newFrame: Date = l_timeAxis[i_currentIndex];
			for each (so in l_syncLayers)
			{
				if (SynchronisationResponse.wasSynchronised(so.synchroniseWith(GlobalVariable.FRAME, newFrame)))
					InteractiveLayer(so).refresh(false);
			}
			return true;
		}

		/**
		 * Return frames count
		 * @return
		 *
		 */
		public function get framesLength(): int
		{
			var l_syncLayers: Array = [];
			var l_timeAxis: Array = enumTimeAxis(l_syncLayers);
			if (l_timeAxis == null) // no time axis
				return 0;
			return l_timeAxis.length;
		}

		public function getFrame(index: int): Date
		{
			var l_syncLayers: Array = [];
			var l_timeAxis: Array = enumTimeAxis(l_syncLayers);
			if (l_timeAxis == null) // no time axis
				return null;
			if (l_timeAxis.length > index)
			{
				return l_timeAxis[index] as Date;
			}
			return null;
		}
		public function getFramePosition(frame: Date): int
		{
			if (!frame)
				return -1;
			
			var l_syncLayers: Array = [];
			var l_timeAxis: Array = enumTimeAxis(l_syncLayers);
			if (l_timeAxis == null) // no time axis
				return -1;
			
			var total: int = l_timeAxis.length;
			for (var i: int = 0; i < total; i++)
			{
				var currDate: Date = l_timeAxis[i] as Date;
				if (currDate.time == frame.time)
					return i;
			}
			
			return -1;
		}
		
		public function getFrames(): Array
		{
			var l_syncLayers: Array = [];
			var l_timeAxis: Array = enumTimeAxis(l_syncLayers);
			if (l_timeAxis == null) // no time axis
				return null;
			
			return l_timeAxis;
		}
		
		public function getRuns(): Array
		{
			var l_syncLayers: Array = [];
			var l_runs: Array = enumRuns(l_syncLayers);
			if (l_runs == null)
				return null;
			
			return l_runs;
		}
		public function getLevels(): Array
		{
			var l_syncLayers: Array = [];
			var l_levels: Array = enumLevels(l_syncLayers);
			if (l_levels == null)
				return null;
			
			return l_levels;
		}

		public function setRun(newRun: Date, b_nearrest: Boolean = true): Boolean
		{
			if (newRun == null)
				return false;
			
			if (mapIsLoading)
			{
				_tempMapStorage.setRun(newRun, b_nearrest);
				return false;
			}
			
			
			//we need to remember old frame and synchronize frame after RUN is synchronized
			var oldFrame: Date = frame;
			
			trace(this + " SET RUN: " + newRun + " OLD FRAME: " + oldFrame);
			
			var bGlobalSynchronization: Boolean = false;
			for each (var l: InteractiveLayer in m_layers)
			{
				var so: ISynchronisedObject = l as ISynchronisedObject;
				if (so == null)
					continue;
				if (!so.hasSynchronisedVariable(GlobalVariable.RUN))
					continue;
				
				var bSynchronized: Boolean = SynchronisationResponse.wasSynchronised(so.synchroniseWith(GlobalVariable.RUN, newRun));
				
				bGlobalSynchronization = bGlobalSynchronization || bSynchronized;
				
				debug("setRun [" + newRun + "] newRun: " + newRun + " for: " + l.name + " bSynchronized: " + bSynchronized + " bGlobalSynchronization: " + bGlobalSynchronization);
				if (bSynchronized)
				{
//					l.refresh(false);
					so.refreshForSynchronisation(false);
				}
				else
				{
					error("InteractiveLayerMap setRun [" + newRun + "] NO SYNCHRONIZATION for " + l.name);
				}
			}
			
			if (bGlobalSynchronization)
				_globalVariablesManager.run = newRun;
			else {
				debug("!!setRun, bGlobalSynchronization = false, do not set global variables manager run");
			}
			
			
			//now synchronize frame to same frame as it was synchronized before
			if (oldFrame)
				setFrame(oldFrame);
			
			
			return true;
		}
		
		
		/**
		 * 
		 * @param newLevel
		 * @param b_nearrest
		 * @param bGlobalValueChange
		 * @return 
		 * 
		 */
		public function setLevel(newLevel: String, b_nearrest: Boolean = true): Boolean
		{
			if (newLevel == null)
				return false;
			
			if (mapIsLoading)
			{
				_tempMapStorage.setLevel(newLevel, b_nearrest);
				return false;
			}
			
			var bGlobalSynchronization: Boolean = false;
			for each (var l: InteractiveLayer in m_layers)
			{
				var so: ISynchronisedObject = l as ISynchronisedObject;
				if (so == null)
					continue;
				if (!so.hasSynchronisedVariable(GlobalVariable.LEVEL))
					continue;
				
				var bSynchronized: Boolean = SynchronisationResponse.wasSynchronised(so.synchroniseWith(GlobalVariable.LEVEL, newLevel));
				
				bGlobalSynchronization = bGlobalSynchronization || bSynchronized;
				
				debug("setLevel [" + newLevel + "] newLevel: " + newLevel + " for: " + l.name + " bSynchronized: " + bSynchronized + " bGlobalSynchronization: " + bGlobalSynchronization);
				if (bSynchronized)
				{
//					l.refresh(false);
					so.refreshForSynchronisation(false);
				}
				else
				{
					error("InteractiveLayerMap setLevel [" + newLevel + "] NO SYNCHRONIZATION for " + l.name);
				}
			}
			
			if (bGlobalSynchronization)
				_globalVariablesManager.level = newLevel;
			else {
				debug("!!setLevel, bGlobalSynchronization = false, do not set global variables manager level");
			}
			
			return true;
		}

		/**
		 * This function should be called when InteractiveLayerMap needs to be synchronized again, e.g. new layer is added 
		 * 
		 */		
		public function resynchronize(): void
		{
			var synchronizedFrame: Date = frame;
			
			trace(this + " resynchronize to frame: " + synchronizedFrame);
			if (synchronizedFrame)
				setFrame(synchronizedFrame);
		}
		
		public function setFrame(newFrame: Date, b_nearrest: Boolean = true, bGlobalValueChange: Boolean = true): Boolean
		{
//			trace(this + " SET FRAME 1: " + newFrame);
			
			if (bGlobalValueChange)
				_globalVariablesManager.frame = newFrame;
			
//			trace(this + "SET FRAME 2: " + newFrame);
			
			var layersForRefresh: Array = [];
			var so: ISynchronisedObject;
			for each (var l: InteractiveLayer in m_layers)
			{
				so = l as ISynchronisedObject;
				if (so == null)
					continue;
				if (!so.hasSynchronisedVariable(GlobalVariable.FRAME))
					continue;
//				debug(this + " setFrame try to synchronize: [" + newFrame.toTimeString() + "]  for " + l.name, 'Info', 'Layer Map');
				
				var bSynchronized: Boolean = SynchronisationResponse.wasSynchronised(so.synchroniseWith(GlobalVariable.FRAME, newFrame));
				if (bSynchronized)
				{
					layersForRefresh.push(so);
				}
				else
				{
					if (l is InteractiveLayerMSBase)
					{
						var msBaseLayer: InteractiveLayerMSBase = l as InteractiveLayerMSBase;
						if (msBaseLayer.isPrimaryLayer())
						{
							/**
							 * primary layer has not FRAME for synchronizatio, new FRAME musct be found and call setFrame method again.
							 * Because primary layer need to have always FRAME set.
							 */ 
							var closestFrame: Date = getClosestFrame(msBaseLayer, newFrame);
							setFrame(closestFrame);
							notifyFrameVariableChanged();
							return false;
						}
					}
					debug(this + " setFrame [" + newFrame.toTimeString() + "] FRAME NOT FOUND for " + l.name);
				}
			}
			
			for each (so in layersForRefresh)
			{
				so.refreshForSynchronisation(false);				
			}
			
			
			return true;
		}

		private function getClosestFrame(l: InteractiveLayerMSBase, requiredFrame: Date): Date
		{
			return l.getSynchronisedVariableClosetsValue(GlobalVariable.FRAME, requiredFrame) as Date; 
		}
		
		// helper methods        
		override protected function bindSubLayer(l: InteractiveLayer): void
		{
			super.bindSubLayer(l);
			var so: ISynchronisedObject = l as ISynchronisedObject;
			if (so != null)
			{
				l.addEventListener(SynchronisedVariableChangeEvent.SYNCHRONISED_VARIABLE_CHANGED,
						onSynchronisedVariableChanged);
				l.addEventListener(SynchronisedVariableChangeEvent.SYNCHRONISED_VARIABLE_DOMAIN_CHANGED,
						onSynchronisedVariableDomainChanged);
			}
		}

		override protected function unbindSubLayer(l: InteractiveLayer): void
		{
			super.unbindSubLayer(l);
			var so: ISynchronisedObject = l as ISynchronisedObject;
			if (so != null)
			{
				l.removeEventListener(SynchronisedVariableChangeEvent.SYNCHRONISED_VARIABLE_CHANGED,
						onSynchronisedVariableChanged);
				l.removeEventListener(SynchronisedVariableChangeEvent.SYNCHRONISED_VARIABLE_DOMAIN_CHANGED,
						onSynchronisedVariableDomainChanged);
			}
		}
		private var _featureTooltipCallsRunning: Boolean;
		private var _featureTooltipCallsTotalCount: int;
		private var _featureTooltipCallsCount: int;
		private var _featureTooltipString: String;

		public function getFeatureTooltipForAllLayers(coord: Coord): void
		{
			if (!_featureTooltipCallsRunning)
			{
				_featureTooltipCallsTotalCount = 0;
				_featureTooltipCallsCount = 0;
				_featureTooltipString = '';
				for each (var layer: InteractiveLayer in layers)
				{
					if (layer.hasFeatureInfo() && layer.visible)
					{
						_featureTooltipCallsTotalCount++;
						_featureTooltipCallsCount++;
						layer.getFeatureInfo(coord, onFeatureInfoAvailable);
					}
				}
				if (_featureTooltipCallsCount > 0)
					_featureTooltipCallsRunning = true;
			}
		}

		private function onFeatureInfoAvailable(s: String, layer: InteractiveLayer): void
		{
			if (s.indexOf('small') >= 0)
			{
				debug("Stop tag <small> is included in feature info");
			}
			debug("InteractiveLayerMap onFeatureInfoAvailable _featureTooltipCallsCount: " + _featureTooltipCallsCount + " _featureTooltipCallsTotalCount: " + _featureTooltipCallsTotalCount);
			var firstFeatureInfo: Boolean = (_featureTooltipCallsCount == _featureTooltipCallsTotalCount);
			_featureTooltipCallsCount--;
			s = HTMLUtils.fixFeatureInfoHTML(s);
			var parsingCorrect: Boolean = true;
//			try {
//				var infoXML: XML = new XML(s);
//			} catch (error: Error) {
//				parsingCorrect = false;
//				debug("ERROR parsing FEatureINFO");
//				Alert.show(error.message, "Problem with parsing GetFeatureInfo request", Alert.OK);
//			}
			if (_featureTooltipCallsCount < 1)
			{
				_featureTooltipCallsRunning = false;
			}
			var gfie: GetFeatureInfoEvent;
			if (parsingCorrect)
			{
				//var info: String = infoXML.text();
				var info: String = s;
				_featureTooltipString += '<p><b><font color="#3080c0">' + layer.name + '</font></b>';
				_featureTooltipString += s + '</p>';
				debug("InteractiveLayerMap onFeatureInfoAvailable _featureTooltipCallsRunning: " + _featureTooltipCallsRunning);
			}
			else
			{
				_featureTooltipString += '<p><b><font color="#3080c0">' + layer.name + '</font></b>';
				_featureTooltipString += 'parsing problem</p>'
			}
			gfie = new GetFeatureInfoEvent(GetFeatureInfoEvent.FEATURE_INFO_RECEIVED, true);
			gfie.text = _featureTooltipString;
			gfie.firstFeatureInfo = firstFeatureInfo;
			gfie.lastFeatureInfo = !_featureTooltipCallsRunning;
			dispatchEvent(gfie);
			debug("InteractiveLayerMap onFeatureInfoAvailable event gfie.firstFeatureInfo: " + gfie.firstFeatureInfo + " gfie.lastFeatureInfo: " + gfie.lastFeatureInfo);
		}

		/**
		* Clone interactiveLayer
		*
		*/
		override public function clone(): InteractiveLayer
		{
			var map: InteractiveLayerMap = new InteractiveLayerMap(container);
			for each (var l: InteractiveLayer in layers)
			{
				var newLayer: InteractiveLayer = l.clone();
				map.addLayer(newLayer);
			}
			return map;
		}

		public function getLayersInfo(functionName: String): String
		{
			var retStr: String = "InteractiveLayerMap getLayersInfo: " + functionName;
			for each (var l: InteractiveLayer in layers)
			{
				try
				{
					var str: String = l[functionName]();
					retStr += "\n\t" + str;
				}
				catch (error: Error)
				{
				}
			}
			return retStr;
		}

		
		public function changePrintQuality(printQuality: String): void
		{
			for each (var layer: InteractiveLayer in m_layers)
			{
				layer.printQuality = printQuality;
			}
			
			refresh(true);
		}
		
		
		public function isInitialized(): Boolean
		{
			for each (var layer: InteractiveLayer in m_layers)
			{
				if (!layer.layerInitialized)
					return false;
			}
			return true;
		}
		
		
		public function toStringWithLayers(): String
		{
			var retStr: String = "InteractiveLayerMap [" + mapID + "] ";
			for each (var l: InteractiveLayer in layers)
			{
				retStr += "\n\t"+l;
			}
			return retStr;
		}
		override public function toString(): String
		{
			var retStr: String = "InteractiveLayerMap [" + mapID + "] ";
			return retStr;
		}

		private function error(str: String, type: String = "Error", tag: String = "InteractiveLayerMap"): void
		{
			trace(tag + "| " + type + "| " + str);
			LoggingUtils.dispatchErrorEvent(this, "InteractiveLayerMap ", str);
		}
		private function debug(str: String, type: String = "Info", tag: String = "InteractiveLayerMap"): void
		{
			if (debugConsole)
				debugConsole.print(str, type, tag);
//			trace(tag + "| " + type + "| " + str);
//			LoggingUtils.dispatchLogEvent(this, " ILM: " + str);
		}
		
		private function notifyMapChanged(): void
		{
			dispatchEvent(new Event(MAP_CHANGED));
		}
		private function notifyTimelineConfigurationChanged(): void
		{
			dispatchEvent(new Event(TIMELINE_CONFIGURATION_CHANGE));
		}
		
		private function onTimelineConfigurationChange(event: Event): void
		{
			notifyTimelineConfigurationChanged();
		}
	}
}
import com.iblsoft.flexiweather.ogc.ISynchronisedObject;
import com.iblsoft.flexiweather.ogc.configuration.layers.WMSLayerConfiguration;
import com.iblsoft.flexiweather.ogc.configuration.layers.interfaces.ILayerConfiguration;
import com.iblsoft.flexiweather.ogc.managers.LayerConfigurationManager;
import com.iblsoft.flexiweather.utils.LoggingUtils;
import com.iblsoft.flexiweather.utils.Serializable;
import com.iblsoft.flexiweather.utils.Storage;
import com.iblsoft.flexiweather.widgets.IConfigurableLayer;
import com.iblsoft.flexiweather.widgets.InteractiveLayer;
import com.iblsoft.flexiweather.widgets.InteractiveLayerMap;
import com.iblsoft.flexiweather.widgets.InteractiveWidget;

import flash.events.Event;
import flash.events.EventDispatcher;
import flash.events.TimerEvent;
import flash.utils.Dictionary;
import flash.utils.Timer;

import mx.controls.Alert;

class LayerSerializationWrapper implements Serializable
{
	public var m_layer: InteractiveLayer;
	public static var map: InteractiveLayerMap;
	public static var m_iw: InteractiveWidget;

	public function serialize(storage: Storage): void
	{
		if (storage.isLoading())
		{
			var s_layerName: String = storage.serializeString("layer-name", null, null)
			var s_layerType: String = storage.serializeString("layer-type", null, s_layerName);
			
			var config: ILayerConfiguration = LayerConfigurationManager.getInstance().getLayerConfigurationByLabel(s_layerType);
			if (config == null)
			{
				Alert.show("Can not recreate layer: " + s_layerName, "Load Map Error", Alert.OK);
			} else {
				m_layer = config.createInteractiveLayer(m_iw);
				m_layer.layerName = s_layerName;
				if (m_layer is Serializable)
				{
					(m_layer as Serializable).serialize(storage);
				}
			}
		}
		else
		{
			if (m_layer is Serializable)
			{
				storage.serializeString("layer-name", m_layer.layerName, null);
				var config2: ILayerConfiguration = (m_layer as IConfigurableLayer).configuration
				storage.serializeString("layer-type", config2.label, null);
				(m_layer as Serializable).serialize(storage);
			}
		}
	}
	
	public function toString(): String
	{
		if (m_layer)
			return "LayerSerializationWrapper: " + m_layer.name;
		
			return "LayerSerializationWrapper: Layer undefined";
	}
}

class MapTemporaryParameterStorage {
	
	private var _dimension: Dictionary = new Dictionary(true);
	private var _customParameter: Dictionary = new Dictionary(true);
	
	public function MapTemporaryParameterStorage() {
		
	}
	
	public function updateMapFromStorage(map: InteractiveLayerMap, bEmptyStorage: Boolean = true): void
	{
		if (map)
		{
			if (_dimension['run'])
			{
				var runObject: Object = _dimension['run'];
				map.setRun(runObject.run);
				
				if (bEmptyStorage)
					delete _dimension['run'];
			}
			if (_dimension['level'])
			{
				var levelObject: Object = _dimension['level'];
				map.setLevel(levelObject.level);
				
				if (bEmptyStorage)
					delete _dimension['level'];
			}
		}
	}
	public function setRun(newRun: Date, b_nearrest: Boolean = true): void
	{
		_dimension['run'] = {run: newRun, nearest: b_nearrest};
	}
	public function setLevel(newLevel: String, b_nearrest: Boolean = true): void
	{
		_dimension['level'] = {level: newLevel, nearest: b_nearrest};
	}
	
}

class LayerSynchronisationStatusChecker extends EventDispatcher
{
	public static const LAYER_READY: String = 'layerReady';

	public function get layer(): ISynchronisedObject
	{
		return m_layer;
	}
	
	private var m_layer: ISynchronisedObject;
	private var m_timer: Timer;
	
	public function LayerSynchronisationStatusChecker(layer: ISynchronisedObject)
	{
		m_layer = layer;
		initializeTimer();
	}
	
	private function initializeTimer(): void
	{
		m_timer = new Timer(100);
		m_timer.addEventListener(TimerEvent.TIMER, onTimerTick);
		m_timer.start();
	}
	
	private function onTimerTick(event: TimerEvent): void
	{
		if (m_layer.isReadyForSynchronisation)
		{
			m_timer.stop();
			m_timer.removeEventListener(TimerEvent.TIMER, onTimerTick);
			m_timer = null;
			
			dispatchEvent(new Event(LAYER_READY));
		}
	}
}