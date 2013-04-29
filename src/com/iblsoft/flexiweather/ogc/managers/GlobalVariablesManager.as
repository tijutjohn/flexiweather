package com.iblsoft.flexiweather.ogc.managers
{
	import com.iblsoft.flexiweather.data.SetOperationType;
	import com.iblsoft.flexiweather.ogc.InteractiveLayerMSBase;
	import com.iblsoft.flexiweather.ogc.WMSDimension;
	import com.iblsoft.flexiweather.ogc.data.GlobalVariable;
	import com.iblsoft.flexiweather.ogc.data.GlobalVariableValue;
	import com.iblsoft.flexiweather.ogc.events.GlobalVariableChangeEvent;
	import com.iblsoft.flexiweather.ogc.multiview.synchronization.events.SynchronisationEvent;
	import com.iblsoft.flexiweather.utils.ArrayUtils;
	import com.iblsoft.flexiweather.widgets.InteractiveLayer;
	import com.iblsoft.flexiweather.widgets.InteractiveLayerMap;
	
	import flash.events.DataEvent;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	
	import mx.collections.ArrayCollection;

	public class GlobalVariablesManager extends EventDispatcher
	{
		public static const SELECTED_FRAME_CHANGED: String = 'selectedFrameChanged';
		public static const SELECTED_LEVEL_CHANGED: String = 'selectedLevelChanged';
		public static const FRAMES_CHANGED: String = 'framesChanged';
		public static const RUNS_CHANGED: String = 'runsChanged';
		public static const LEVELS_CHANGED: String = 'levelsChanged';
		
		public static var uid: int = 0;
		public var id: int;
		
		private var _frames: ArrayCollection;
		private var _levels: ArrayCollection;
		private var _runs: ArrayCollection;

		[Bindable(event = FRAMES_CHANGED)]
		public function get frames(): ArrayCollection
		{
			return _frames;
		}

		[Bindable(event = LEVELS_CHANGED)]
		public function get runs(): ArrayCollection
		{
			return _runs;
		}
		
		[Bindable(event = LEVELS_CHANGED)]
		public function get levels(): ArrayCollection
		{
			return _levels;
		}
		
		private var _interactiveLayerMap: InteractiveLayerMap;
		public function get interactiveLayerMap(): InteractiveLayerMap
		{
			return _interactiveLayerMap;
		}
		
		private var _frame: Date;
		private var _level: String;
		private var _run: Date;
		
		private var _levelChanged: Boolean;
		private var _runChanged: Boolean;

		public function get frame(): Date
		{
			return _frame;
		}

		public function set frame(value: Date): void
		{
			var change: Boolean = !_frame;
			if (frame && frame.time == value.time)
				change = false;
			
			if (change)
			{
				_frame = value;
				notifySelectedFrameChanged(value);
				onInteractiveLayerFrameVariableChanged();
			}
		}

		public function get run(): Date
		{
			return _run;
		}

		public function set run(value: Date): void
		{
			if (_run != value)
			{
				_run = value;
				_runChanged = true;
				onRunVariableChanged();
			}
		}
		public function get level(): String
		{
			return _level;
		}

		public function set level(value: String): void
		{
			if (_level != value)
			{
				_level = value;
				_levelChanged = true;
				onLevelVariableChanged();
			}
		}
		/**
		 * Should be one of SetOperationType constants
		 */
		private var _operationType: String;

		public function GlobalVariablesManager()
		{
			id = uid++;
			
			_operationType = SetOperationType.UNION;
			_frames = new ArrayCollection();
			_runs = new ArrayCollection();
			_levels = new ArrayCollection();
		}
		
		public function reinitialize(): void
		{
			if (_frames)
				_frames.removeAll();
			if (_runs)
				_runs.removeAll();
			if (_levels)
				_levels.removeAll();
			checkGlobalVariableChange();
		}

		public function getDimensionDefaultValue(dimensionName: String): Object
		{
			if (_interactiveLayerMap)
				return _interactiveLayerMap.getDimensionDefaultValue(dimensionName);
			return null;
		}

		public function getDimensionValues(dimensionName: String): Array
		{
			if (_interactiveLayerMap)
				return _interactiveLayerMap.getDimensionValues(dimensionName, false);
			return null;
		}

		public function registerInteractiveLayerMap(interactiveMap: InteractiveLayerMap): void
		{
			if (_interactiveLayerMap)
			{
				//unregister old map
				_interactiveLayerMap.removeEventListener(InteractiveLayerMap.FRAME_VARIABLE_CHANGED, onInteractiveLayerFrameVariableChanged);
				_interactiveLayerMap.removeEventListener(InteractiveLayerMap.LEVEL_VARIABLE_CHANGED, onLevelVariableChanged);
				_interactiveLayerMap.removeEventListener(SynchronisationEvent.START_GLOBAL_VARIABLE_SYNCHRONIZATION, onGlobalVariableSynchronisationChanged);
				_interactiveLayerMap.removeEventListener(SynchronisationEvent.STOP_GLOBAL_VARIABLE_SYNCHRONIZATION, onGlobalVariableSynchronisationChanged);
				_interactiveLayerMap.removeEventListener(InteractiveLayerMap.PRIMARY_LAYER_CHANGED, onPrimaryLayerChanged);
			}
			_interactiveLayerMap = interactiveMap;
			_interactiveLayerMap.addEventListener(InteractiveLayerMap.FRAME_VARIABLE_CHANGED, onInteractiveLayerFrameVariableChanged);
			_interactiveLayerMap.addEventListener(InteractiveLayerMap.LEVEL_VARIABLE_CHANGED, onLevelVariableChanged);
			_interactiveLayerMap.addEventListener(SynchronisationEvent.START_GLOBAL_VARIABLE_SYNCHRONIZATION, onGlobalVariableSynchronisationChanged);
			_interactiveLayerMap.addEventListener(SynchronisationEvent.STOP_GLOBAL_VARIABLE_SYNCHRONIZATION, onGlobalVariableSynchronisationChanged);
			_interactiveLayerMap.addEventListener(InteractiveLayerMap.PRIMARY_LAYER_CHANGED, onPrimaryLayerChanged);
			checkGlobalVariableChange();
		}

		private function checkGlobalVariableChange(): void
		{
			var bFramesExist: Boolean = true;
			var bLevelsExist: Boolean = true;
			
			if (_interactiveLayerMap)
			{
				onLevelVariableChanged();
				
				if (_interactiveLayerMap.primaryLayer)
					onInteractiveLayerFrameVariableChanged();
				else {
					bFramesExist = false;
				}
			} else {
				bFramesExist = false;
				bLevelsExist = false;
			}
			
			if (!bFramesExist)
			{
				_frames = null;
				_lastFrameNotified = null;
				
				//frames changed
				notifySelectedFrameChanged(null);
				dispatchEvent(new Event(FRAMES_CHANGED, true));
			}
			
			if (!bLevelsExist)
			{
				//levels changed
				notifyLevelsChanged();
				notifySelectedLevelChanged(null);
			}
		}

		private function onPrimaryLayerChanged(event: DataEvent): void
		{
			checkGlobalVariableChange();
		}

		private function onGlobalVariableSynchronisationChanged(event: SynchronisationEvent): void
		{
			/** this can be called when these 2 event are dispatched
			 * SynchronisationEvent.START_GLOBAL_VARIABLE_SYNCHRONIZATION
			 * SynchronisationEvent.STOP_GLOBAL_VARIABLE_SYNCHRONIZATION
			 */
			switch (event.globalVariable)
			{
				case GlobalVariable.LEVEL:
				{
					if (event.type == SynchronisationEvent.START_GLOBAL_VARIABLE_SYNCHRONIZATION)
						level = event.globalVariableValue as String;
					onLevelVariableChanged();
					break;
				}
				case GlobalVariable.FRAME:
				{
					onInteractiveLayerFrameVariableChanged();
					break;
				}
			}
		}

		private function onRunVariableChanged(event: Event = null): void
		{
			if (_interactiveLayerMap)
			{
				var _layerRuns: Array = [];
				for each (var layer: InteractiveLayer in _interactiveLayerMap.layers)
				{
					if (layer is InteractiveLayerMSBase)
					{
						var layerMSBase: InteractiveLayerMSBase = layer as InteractiveLayerMSBase;
						if (layerMSBase.synchroniseRun)
						{
							var _layerRunsNew: Array = layerMSBase.getSynchronisedVariableValuesList(GlobalVariable.RUN);
							ArrayUtils.unionArrays(_layerRuns, _layerRunsNew);
						}
					}
				}
				var tempArr: Array = [];
				for each (var globalLevelVariable: GlobalVariableValue in _layerRuns)
				{
					tempArr.push(globalLevelVariable.data as String);
				}
				_runs = new ArrayCollection(tempArr);
				_runs.refresh();
			}
			else 
			{
				if (!_runs)
					_runs = new ArrayCollection();
				else
					_runs.removeAll();
			}
			notifyRunsChanged();
			if (_runChanged)
			{
				_runChanged = false;
				notifySelectedRunChanged(_run);
			}
		}
		
		
		private function onLevelVariableChanged(event: Event = null): void
		{
			if (_interactiveLayerMap)
			{
				var _layerLevels: Array = [];
				for each (var layer: InteractiveLayer in _interactiveLayerMap.layers)
				{
					if (layer is InteractiveLayerMSBase)
					{
						var layerMSBase: InteractiveLayerMSBase = layer as InteractiveLayerMSBase;
						if (layerMSBase.synchroniseLevel)
						{
							var _layerLevelsNew: Array = layerMSBase.getSynchronisedVariableValuesList(GlobalVariable.LEVEL);
							ArrayUtils.unionArrays(_layerLevels, _layerLevelsNew);
						}
					}
				}
				var tempArr: Array = [];
				for each (var globalLevelVariable: GlobalVariableValue in _layerLevels)
				{
					tempArr.push(globalLevelVariable.data as String);
				}
				_levels = new ArrayCollection(tempArr);
				_levels.refresh();
			}
			else 
			{
				if (!_levels)
					_levels = new ArrayCollection();
				else
					_levels.removeAll();
			}
			notifyLevelsChanged();
			if (_levelChanged)
			{
				_levelChanged = false;
				notifySelectedLevelChanged(_level);
			}
		}

		private function onInteractiveLayerFrameVariableChanged(event: Event = null): void
		{
			var framesChanged: Boolean;
			
			if (_interactiveLayerMap && _interactiveLayerMap.primaryLayer)
			{
				//check, if this is received from selected widget
				if (event)
				{
					var eventILM: InteractiveLayerMap = event.target as InteractiveLayerMap;
					
//					trace("GlobalVariablesManager onInteractiveLayerFrameVariableChanged from: " + eventILM + " current: " + _interactiveLayerMap)
					if (eventILM != _interactiveLayerMap)
					{
						//Frame change was received from non-selected layer, ignore it
						return;
					}
				}
				
				var framesObjects: Array = _interactiveLayerMap.primaryLayer.getSynchronisedVariableValuesList(GlobalVariable.FRAME);
				var framesAC: ArrayCollection = new ArrayCollection();
				for each (var frameVariable: Object in framesObjects)
				{
					if (frameVariable is GlobalVariableValue)
						framesAC.addItem(frameVariable.data as Date);
					if (frameVariable is Date)
						framesAC.addItem(frameVariable as Date);
				}
				
				var collectionChanged: Boolean = !sameCollection(framesAC, _frames); 
				if (collectionChanged)
					_frames = framesAC;
//				else {
//					trace("GlobalVariablesManager ["+_interactiveLayerMap+"] _frames are same: ");
//				}
				var selectedFrame: Date = _interactiveLayerMap.frame;
				if (!selectedFrame)
					return;
				
				if (_lastFrameNotified && _lastFrameNotified.time == selectedFrame.time)
				{
					//same time as last time
					if (!collectionChanged)
						return;
				}
				_lastFrameNotified = selectedFrame;
				
//				trace("GlobalVariablesManager ["+_interactiveLayerMap+"] onInteractiveLayerFrameVariableChanged selectedFrame: " + selectedFrame + " _frame: " + _frame);
				if (_frame)
				{
					if (_frame.time != selectedFrame.time)
					{
						//frame is changed
						framesChanged = true;
						notifySelectedFrameChanged(selectedFrame);
					}
//					else
//						trace("Global frame is not changed, do not notify");
				}
				else {
					framesChanged = true;
					notifySelectedFrameChanged(selectedFrame);
				}
			}
			else {
				framesChanged = true;
				if (!_frames)
					_frames = new ArrayCollection();
				else
					_frames.removeAll();
			}
			
			if (framesChanged)
			{
				dispatchEvent(new Event(FRAMES_CHANGED, true));
			}
		}
		private var _lastFrameNotified: Date;

		private function notifySelectedFrameChanged(selectedFrame: Date): void
		{
//			if (selectedFrame)
//			{
				_frame = selectedFrame;
				var gvce: GlobalVariableChangeEvent = new GlobalVariableChangeEvent(GlobalVariableChangeEvent.DIMENSION_VALUE_CHANGED, GlobalVariable.FRAME, selectedFrame);
				dispatchEvent(gvce);
//			}
		}

		private function notifyRunsChanged(): void
		{
			dispatchEvent(new Event(RUNS_CHANGED, true));
		}
		private function notifyLevelsChanged(): void
		{
			dispatchEvent(new Event(LEVELS_CHANGED, true));
		}
		private function notifySelectedRunChanged(selectedRun: Date): void
		{
			_run = selectedRun;
			var gvce: GlobalVariableChangeEvent = new GlobalVariableChangeEvent(GlobalVariableChangeEvent.DIMENSION_VALUE_CHANGED, GlobalVariable.RUN, selectedRun);
			dispatchEvent(gvce);
		}
		private function notifySelectedLevelChanged(selectedLevel: String): void
		{
			_level = selectedLevel;
			var gvce: GlobalVariableChangeEvent = new GlobalVariableChangeEvent(GlobalVariableChangeEvent.DIMENSION_VALUE_CHANGED, GlobalVariable.LEVEL, selectedLevel);
			dispatchEvent(gvce);
		}
		
		private function sameCollection(collection1: ArrayCollection, collection2: ArrayCollection): Boolean
		{
			if (collection1 && collection2)
			{
				if (collection1.length != collection2.length)
					return false;
				
				if (collection1.length > 0)
				{
					var total: int = collection1.length;
					for (var i: int = 0; i < total; i++)
					{
						var val1: * = collection1.getItemAt(i);
						var val2: * = collection2.getItemAt(i);
						
						if (val1.toString() != val2.toString())
							return false;
					}
				} else {
					return false;
				}
				
				return true;
			}
			return false;
		}
		
		override public function toString(): String
		{
			return "GlobalVariablesManager ["+id+"]: " + _interactiveLayerMap;
		}
	}
}
