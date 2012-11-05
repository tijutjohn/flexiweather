package com.iblsoft.flexiweather.widgets
{
	import com.iblsoft.flexiweather.events.GetFeatureInfoEvent;
	import com.iblsoft.flexiweather.events.InteractiveLayerEvent;
	import com.iblsoft.flexiweather.events.InteractiveLayerMapEvent;
	import com.iblsoft.flexiweather.ogc.ISynchronisedObject;
	import com.iblsoft.flexiweather.ogc.InteractiveLayerMSBase;
	import com.iblsoft.flexiweather.ogc.InteractiveLayerQTTMS;
	import com.iblsoft.flexiweather.ogc.InteractiveLayerWMS;
	import com.iblsoft.flexiweather.ogc.SynchronisationRole;
	import com.iblsoft.flexiweather.ogc.SynchronisedVariableChangeEvent;
	import com.iblsoft.flexiweather.ogc.cache.ICache;
	import com.iblsoft.flexiweather.ogc.data.GlobalVariable;
	import com.iblsoft.flexiweather.ogc.managers.GlobalVariablesManager;
	import com.iblsoft.flexiweather.ogc.tiling.ITiledLayer;
	import com.iblsoft.flexiweather.plugins.IConsole;
	import com.iblsoft.flexiweather.proj.Coord;
	import com.iblsoft.flexiweather.utils.ArrayUtils;
	import com.iblsoft.flexiweather.utils.DateUtils;
	import com.iblsoft.flexiweather.utils.HTMLUtils;
	import com.iblsoft.flexiweather.utils.ISO8601Parser;
	import com.iblsoft.flexiweather.utils.Serializable;
	import com.iblsoft.flexiweather.utils.Storage;
	import com.iblsoft.flexiweather.utils.XMLStorage;
	import flash.events.DataEvent;
	import flash.events.Event;
	import flash.events.TimerEvent;
	import flash.utils.Timer;
	import mx.collections.ArrayCollection;
	import mx.controls.Alert;
	import mx.events.CollectionEvent;
	import mx.events.DynamicEvent;

	public class InteractiveLayerMap extends InteractiveLayerComposer implements Serializable
	{
		public static const TIMELINE_CONFIGURATION_CHANGE: String = "timelineConfigurationChange";
		public static const LAYERS_SERIALIZED_AND_READY: String = "layersSerializedAndReady";
		[Event(name = LAYERS_SERIALIZED_AND_READY, type = "mx.events.DynamicEvent")]
		public static const TIME_AXIS_UPDATED: String = "timeAxisUpdated";
		[Event(name = TIME_AXIS_UPDATED, type = "flash.events.DataEvent")]
		public static const TIME_AXIS_ADDED: String = "timeAxisAdded";
		[Event(name = TIME_AXIS_ADDED, type = "mx.events.DynamicEvent")]
		public static const TIME_AXIS_REMOVED: String = "timeAxisRemoved";
		[Event(name = TIME_AXIS_REMOVED, type = "mx.events.DynamicEvent")]
		public static const PRIMARY_LAYER_CHANGED: String = "primaryLayerChanged";
		[Event(name = PRIMARY_LAYER_CHANGED, type = "flash.events.DataEvent")]
		public static const FRAME_VARIABLE_CHANGED: String = "frameVariableChanged";
		[Event(name = FRAME_VARIABLE_CHANGED, type = "mx.events.DynamicEvent")]
		public static const LEVEL_VARIABLE_CHANGED: String = "levelVariableChanged";
		[Event(name = LEVEL_VARIABLE_CHANGED, type = "mx.events.DynamicEvent")]
		public static const SYNCHRONISE_WITH: String = "synchroniseWith";
		[Event(name = SYNCHRONISE_WITH, type = "mx.events.DynamicEvent")]
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

		public function get dateFormat(): String
		{
			return _dateFormat;
		}

		public function set dateFormat(value: String): void
		{
			_dateFormat = value;
			dispatchEvent(new Event(FRAME_VARIABLE_CHANGED));
		}

		[Bindable(event = LEVEL_VARIABLE_CHANGED)]
		public function get level(): String
		{
//			var levelString: String = getSynchronizedLevelValue();
			var levelString: String = _globalVariablesManager.level;
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
//			var frameDate: Date = getSynchronizedFrameValue();
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
			m_timelineConfiguration = value;
			m_timelineConfigurationChanged = true;
			dispatchEvent(new Event(TIMELINE_CONFIGURATION_CHANGE));
		}
		private var _globalVariablesManager: GlobalVariablesManager;

		[Bindable(event = "globalVariablesManagerChanged")]
		public function get globalVariablesManager(): GlobalVariablesManager
		{
			return _globalVariablesManager;
		}

		public function InteractiveLayerMap(container: InteractiveWidget = null)
		{
			super(container);
			mapUID++;
			mapID = mapUID;
			timelineConfiguration = new MapTimelineConfiguration();
			_globalVariablesManager = new GlobalVariablesManager();
			_globalVariablesManager.registerInteractiveLayerMap(this);
			_periodicTimer = new Timer(10 * 1000);
			_periodicTimer.addEventListener(TimerEvent.TIMER, onPeriodicTimerTick);
			_periodicTimer.start();
			dispatchEvent(new Event("globalVariablesManagerChanged"));
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

		override public function serialize(storage: Storage): void
		{
			var wrappers: ArrayCollection;
			var wrapper: LayerSerializationWrapper;
			var layer: InteractiveLayer;
			trace("InteractiveLayerMap [IW: " + container.id + "] serialize loading: " + storage.isLoading());
			LayerSerializationWrapper.m_iw = container;
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
					layer = wrapper.m_layer;
					if (layer is InteractiveLayerMSBase)
					{
						if ((layer as InteractiveLayerMSBase).isPrimaryLayer())
						{
							setPrimaryLayer(layer as InteractiveLayerMSBase);
						}
					}
					newLayers.push(layer);
				}
				var de: DynamicEvent = new DynamicEvent(LAYERS_SERIALIZED_AND_READY);
				de['layers'] = newLayers;
				dispatchEvent(de);
				var globalFrame8601: String = storage.serializeString('global-frame', null);
				var globalLevel: String = storage.serializeString('global-level', null);
				if (globalVariablesManager)
				{
					if (globalFrame8601)
						globalVariablesManager.frame = ISO8601Parser.stringToDate(globalFrame8601);
					if (globalLevel)
						globalVariablesManager.level = globalLevel;
				}
					//set global vars
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
					var frameDateString: String;
					if (globalVariablesManager.frame)
						frameDateString = ISO8601Parser.dateToString(globalVariablesManager.frame)
					storage.serializeString('global-frame', frameDateString);
					storage.serializeString('global-level', globalVariablesManager.level);
				}
				trace("Map serialize: " + (storage as XMLStorage).xml);
			}
		}
		private var _frameInvalidated: Boolean;
		private var _levelInvalidated: Boolean;

		public function invalidateFrame(): void
		{
			_frameInvalidated = true;
			invalidateProperties();
		}

		public function invalidateLevel(): void
		{
			_levelInvalidated = true;
			invalidateProperties();
		}

		private function notifyTimeAxisUpdate(): void
		{
			dispatchEvent(new DataEvent(TIME_AXIS_UPDATED));
		}

		public function invalidateTimeline(): void
		{
			notifyTimeAxisUpdate();
		}

		override protected function onLayerCollectionChanged(event: CollectionEvent): void
		{
			super.onLayerCollectionChanged(event);
			notifyTimeAxisUpdate();
		}

		protected function onSynchronisedVariableChanged(event: SynchronisedVariableChangeEvent): void
		{
			notifyTimeAxisUpdate();
			if (event.variableId == GlobalVariable.FRAME)
				dispatchEvent(new Event(FRAME_VARIABLE_CHANGED));
			if (event.variableId == GlobalVariable.LEVEL)
				dispatchEvent(new Event(LEVEL_VARIABLE_CHANGED));
		}

		protected function onSynchronisedVariableDomainChanged(event: SynchronisedVariableChangeEvent): void
		{
			notifyTimeAxisUpdate();
			if (event.variableId == GlobalVariable.FRAME)
				dispatchEvent(new Event(FRAME_VARIABLE_CHANGED));
			if (event.variableId == GlobalVariable.LEVEL)
				dispatchEvent(new Event(LEVEL_VARIABLE_CHANGED));
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
//			trace("InteractiveLayerMap commitProperties: _frameInvalidated: " + _frameInvalidated + " _levelInvalidated: " + _levelInvalidated);
			if (_frameInvalidated)
			{
				_frameInvalidated = false;
				//it will set frame again. This is done by purpose when adding new layer, to synchronise frame with newly added layer
				if (frame)
					setFrame(frame);
			}
			if (_levelInvalidated)
			{
				_levelInvalidated = false;
				//it will set level again. This is done by purpose when adding new layer, to synchronise level with newly added layer
				setLevel(level);
			}
		}

		override public function addLayer(l: InteractiveLayer): void
		{
			if (l)
			{
				super.addLayer(l);
			}
			else
			{
				trace("Layer is null, do not add it to InteractiveLayerMap");
			}
		}

		override protected function layerAdded(layer: InteractiveLayer): void
		{
			super.layerAdded(layer);
//				trace(this + " ADD LAYER: " + l.toString());
			if (layer)
			{
				var dynamicEvent: DynamicEvent = new DynamicEvent(TIME_AXIS_ADDED);
//				trace("InteractiveLayerMap addlayer: " + l.name);
				dynamicEvent['layer'] = layer;
				dispatchEvent(dynamicEvent);
				var synchronisableFrame: Boolean = false;
				var synchronisableLevel: Boolean = false;
				var so: ISynchronisedObject = layer as ISynchronisedObject;
				//need to wait when synchronizaed variables will be update (set FRAME and LEVEL)
				if (so && so.getSynchronisedVariables())
				{
					synchronisableFrame = so.getSynchronisedVariables().indexOf(GlobalVariable.FRAME) >= 0;
					synchronisableLevel = so.getSynchronisedVariables().indexOf(GlobalVariable.LEVEL) >= 0;
				}
				if (getPrimaryLayer() == null)
				{
					if (!so || !synchronisableFrame)
						return;
					//this layer can be primary layer and there is no primary layer set, set this one as primaty layer	
					setPrimaryLayer(layer as InteractiveLayerMSBase);
				}
				else
				{
					invalidateFrame();
					if (synchronisableLevel && (layer as InteractiveLayerMSBase).synchroniseLevel)
					{
						invalidateLevel();
					}
				}
				if (layer is InteractiveLayerMSBase)
				{
					var msBaseLayer: InteractiveLayerMSBase = layer as InteractiveLayerMSBase;
					if (synchronisableLevel && msBaseLayer.synchroniseLevel)
					{
						var globalLevel: String = level;
						var bSynchronized: Boolean = so.synchroniseWith(GlobalVariable.FRAME, frame);
						bSynchronized = bSynchronized || so.synchroniseWith(GlobalVariable.LEVEL, level);
						if (bSynchronized)
						{
							layer.refresh(false);
						}
					}
				}
			}
			else
			{
				trace("Layer is null, do not add it to InteractiveLayerMap");
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
//			l.destroy();
		}

		private function getSynchronizedFrameValue(): Date
		{
			if (primaryLayer)
				return (primaryLayer as ISynchronisedObject).getSynchronisedVariableValue(GlobalVariable.FRAME) as Date;
			return null;
		}
//		
//		private function getSynchronizedLevelValue(): String
//		{
//			return getSynchronizedVariableValue(GlobalVariable.LEVEL) as String;	
//		}
//		
//		private function getSynchronizedVariableValue(variable: String): Object
//		{
//			var l_syncLayers: Array = [];
//			var l_timeAxis: Array = enumTimeAxis(l_syncLayers);
//          	if(l_timeAxis == null) // no time axis
//          		return null;
//          		
//			var so: ISynchronisedObject;
//			
//          	for each(so in l_syncLayers) 
//          	{
//          		var frame: Date = so.getSynchronisedVariableValue(variable) as Date;
//          	}
//
//			return frame;
//		}
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
			dispatchEvent(new DataEvent(PRIMARY_LAYER_CHANGED, true));
		}

		// data global variables synchronisation
		public function enumTimeAxis(l_syncLayers: Array = null): Array
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
				//trace("enumTimeAxis so: " + (so as Object).name + " synchro vars: " + test.toString());
				if (test == null)
					continue;
				if (so.getSynchronisedVariables().indexOf(GlobalVariable.FRAME) < 0)
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
				//trace("\n Composer getDimensionValues ["+dimName+"] get values for layer: " + (so as Object).name);
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
				//trace("\n Composer getDimensionValues ["+dimName+"] get values for layer: " + (so as Object).name);
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
				//trace("\n Composer getDimensionValues ["+dimName+"] get values for layer: " + (so as Object).name);
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
			var l_syncLayers: Array = [];
			var l_timeAxis: Array = enumTimeAxis(l_syncLayers);
			if (l_timeAxis == null) // no time axis
				return false;
			var i: int;
			var so: ISynchronisedObject;
			for each (so in l_syncLayers)
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
				return null;
			return l_timeAxis[0] as Date;
		}

		public function getLastFrame(): Date
		{
			var l_syncLayers: Array = [];
			var l_timeAxis: Array = enumTimeAxis(l_syncLayers);
			if (l_timeAxis == null) // no time axis
				return null;
			return l_timeAxis[l_timeAxis.length - 1] as Date;
		}

		public function getNowFrame(): Date
		{
			var l_syncLayers: Array = [];
			var l_timeAxis: Array = enumTimeAxis(l_syncLayers);
			if (l_timeAxis == null) // no time axis
				return null;
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
			for each (so in l_syncLayers)
			{
				var status: String = InteractiveDataLayer(so).status;
				if (status == InteractiveDataLayer.STATE_LOADING_DATA)
					return false;
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
				if (so.synchroniseWith(GlobalVariable.FRAME, newFrame))
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

		public function setLevel(newLevel: String, b_nearrest: Boolean = true): Boolean
		{
			for each (var l: InteractiveLayer in m_layers)
			{
				var so: ISynchronisedObject = l as ISynchronisedObject;
				if (so == null)
					continue;
				if (!so.hasSynchronisedVariable(GlobalVariable.LEVEL))
					continue;
				var bSynchronized: Boolean = so.synchroniseWith(GlobalVariable.LEVEL, newLevel);
				if (bSynchronized)
				{
					l.refresh(false);
				}
				else
				{
					trace("InteractiveLayerMap setLevel [" + newLevel + "] LEVEL NOT FOUND for " + l.name);
				}
			}
			return true;
		}

		public function setFrame(newFrame: Date, b_nearrest: Boolean = true): Boolean
		{
			for each (var l: InteractiveLayer in m_layers)
			{
				var so: ISynchronisedObject = l as ISynchronisedObject;
				if (so == null)
					continue;
				if (!so.hasSynchronisedVariable(GlobalVariable.FRAME))
					continue;
				debug(this + " setFrame try to synchronize: [" + newFrame.toTimeString() + "]  for " + l.name, 'Info', 'Layer Map');
				var bSynchronized: Boolean = so.synchroniseWith(GlobalVariable.FRAME, newFrame);
				if (bSynchronized)
				{
					l.refresh(false);
				}
				else
				{
					trace(this + " setFrame [" + newFrame.toTimeString() + "] FRAME NOT FOUND for " + l.name);
				}
			}
			return true;
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
				trace("Stop tag <small> is included in feature info");
			}
			trace("InteractiveLayerMap onFeatureInfoAvailable _featureTooltipCallsCount: " + _featureTooltipCallsCount + " _featureTooltipCallsTotalCount: " + _featureTooltipCallsTotalCount);
			var firstFeatureInfo: Boolean = (_featureTooltipCallsCount == _featureTooltipCallsTotalCount);
			_featureTooltipCallsCount--;
			s = HTMLUtils.fixFeatureInfoHTML(s);
			var parsingCorrect: Boolean = true;
//			try {
//				var infoXML: XML = new XML(s);
//			} catch (error: Error) {
//				parsingCorrect = false;
//				trace("ERROR parsing FEatureINFO");
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
				trace("InteractiveLayerMap onFeatureInfoAvailable _featureTooltipCallsRunning: " + _featureTooltipCallsRunning);
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
			trace("InteractiveLayerMap onFeatureInfoAvailable event gfie.firstFeatureInfo: " + gfie.firstFeatureInfo + " gfie.lastFeatureInfo: " + gfie.lastFeatureInfo);
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

		override public function toString(): String
		{
			var retStr: String = "InteractiveLayerMap [" + mapID + "] ";
//			for each (var l: InteractiveLayer in layers)
//			{
//				retStr += "\n\t"+l;
//			}
			return retStr;
		}

		private function debug(str: String, type: String, tag: String): void
		{
			if (debugConsole)
				debugConsole.print(str, type, tag);
			trace(tag + "| " + type + "| " + str);
		}
	}
}
import com.iblsoft.flexiweather.ogc.configuration.layers.interfaces.ILayerConfiguration;
import com.iblsoft.flexiweather.ogc.managers.LayerConfigurationManager;
import com.iblsoft.flexiweather.utils.Serializable;
import com.iblsoft.flexiweather.utils.Storage;
import com.iblsoft.flexiweather.widgets.IConfigurableLayer;
import com.iblsoft.flexiweather.widgets.InteractiveLayer;
import com.iblsoft.flexiweather.widgets.InteractiveWidget;

class LayerSerializationWrapper implements Serializable
{
	public var m_layer: InteractiveLayer;
	public static var m_iw: InteractiveWidget;

	public function serialize(storage: Storage): void
	{
		if (storage.isLoading())
		{
			var s_layerName: String = storage.serializeString("layer-name", null, null)
			var s_layerType: String = storage.serializeString("layer-type", null, s_layerName);
			var config: ILayerConfiguration = LayerConfigurationManager.getInstance().getLayerConfigurationByLabel(s_layerType);
			m_layer = config.createInteractiveLayer(m_iw);
			m_layer.layerName = s_layerName;
			if (m_layer is Serializable)
			{
				(m_layer as Serializable).serialize(storage);
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
}
