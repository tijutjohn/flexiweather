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
	import com.iblsoft.flexiweather.utils.Operators;
	import com.iblsoft.flexiweather.widgets.InteractiveLayer;
	import com.iblsoft.flexiweather.widgets.InteractiveLayerMap;

	import flash.events.DataEvent;
	import flash.events.Event;
	import flash.events.EventDispatcher;

	import mx.collections.ArrayCollection;

	public class GlobalVariablesManager extends EventDispatcher
	{
		public static const SELECTED_FRAME_CHANGED: String = 'selectedFrameChanged';
		public static const SELECTED_RUN_CHANGED: String = 'selectedRunChanged';
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

		[Bindable(event = RUNS_CHANGED)]
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
			if (frame && value && frame.time == value.time)
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
				onInteractiveLayerRunVariableChanged();
				onInteractiveLayerFrameVariableChanged();
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
				onInteractiveLayerLevelVariableChanged();
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

		public function resetGlobalVariables(): void
		{
			run = null;
			frame = null;
			level = null;

		}
		public function reinitializeGlobalVariables(): void
		{
			debug("reinitializeGlobalVariables");
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
				_interactiveLayerMap.removeEventListener(InteractiveLayerMap.TIMELINE_FRAMES_ENUMERATED, onInteractiveLayerMapFramesEnumerated);

				_interactiveLayerMap.removeEventListener(InteractiveLayerMap.FRAME_VARIABLE_CHANGED, onInteractiveLayerFrameVariableChanged);
				_interactiveLayerMap.removeEventListener(InteractiveLayerMap.LEVEL_VARIABLE_CHANGED, onInteractiveLayerLevelVariableChanged);
				_interactiveLayerMap.removeEventListener(InteractiveLayerMap.RUN_VARIABLE_CHANGED, onInteractiveLayerRunVariableChanged);
				_interactiveLayerMap.removeEventListener(SynchronisationEvent.START_GLOBAL_VARIABLE_SYNCHRONIZATION, onGlobalVariableSynchronisationChanged);
				_interactiveLayerMap.removeEventListener(SynchronisationEvent.STOP_GLOBAL_VARIABLE_SYNCHRONIZATION, onGlobalVariableSynchronisationChanged);
				_interactiveLayerMap.removeEventListener(InteractiveLayerMap.PRIMARY_LAYER_CHANGED, onPrimaryLayerChanged);
			}

			_interactiveLayerMap = interactiveMap;

			_interactiveLayerMap.addEventListener(InteractiveLayerMap.TIMELINE_FRAMES_ENUMERATED, onInteractiveLayerMapFramesEnumerated);

			_interactiveLayerMap.addEventListener(InteractiveLayerMap.FRAME_VARIABLE_CHANGED, onInteractiveLayerFrameVariableChanged);
			_interactiveLayerMap.addEventListener(InteractiveLayerMap.LEVEL_VARIABLE_CHANGED, onInteractiveLayerLevelVariableChanged);
			_interactiveLayerMap.addEventListener(InteractiveLayerMap.RUN_VARIABLE_CHANGED, onInteractiveLayerRunVariableChanged);

			_interactiveLayerMap.addEventListener(SynchronisationEvent.START_GLOBAL_VARIABLE_SYNCHRONIZATION, onGlobalVariableSynchronisationChanged);
			_interactiveLayerMap.addEventListener(SynchronisationEvent.STOP_GLOBAL_VARIABLE_SYNCHRONIZATION, onGlobalVariableSynchronisationChanged);
			_interactiveLayerMap.addEventListener(InteractiveLayerMap.PRIMARY_LAYER_CHANGED, onPrimaryLayerChanged);
			checkGlobalVariableChange();
		}

		private function checkGlobalVariableChange(): void
		{
			debug("checkGlobalVariableChange");
			var bFramesExist: Boolean = true;
			var bRunsExist: Boolean = true;
			var bLevelsExist: Boolean = true;

			if (_interactiveLayerMap)
			{
				onInteractiveLayerLevelVariableChanged();
				onInteractiveLayerRunVariableChanged();

				if (_interactiveLayerMap.primaryLayer)
					onInteractiveLayerFrameVariableChanged();
				else {
					bFramesExist = false;
				}
			} else {
				bFramesExist = false;
				bRunsExist = false;
				bLevelsExist = false;
			}

			if (!bFramesExist)
			{
				_frames = null;
				_lastFrameNotified = null;

				//frames changed
				notifyFramesChanged();
				notifySelectedFrameChanged(null);
			}

			if (!bRunsExist)
			{
				//levels changed
				notifyRunsChanged();
				notifySelectedRunChanged(null);
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
			_lastFrameNotified = null;
			_cachedFrames = null;
			checkGlobalVariableChange();

			notifyFramesChanged();
			notifyLevelsChanged();
			notifyRunsChanged();

			notifySelectedRunChanged(_interactiveLayerMap.run);
			notifySelectedFrameChanged(_interactiveLayerMap.frame);
			notifySelectedLevelChanged(_interactiveLayerMap.level);
		}

		/**
		 * Check if value of global variable is in current list of values for given global variable.
		 * This check can be done, when layers in map are changed.
		 *
		 * @param globalVariable
		 * @param value
		 * @return
		 *
		 */
		public function isGlobalVariableValid(globalVariable: String, value: Object): Boolean
		{
			switch (globalVariable)
			{
				case GlobalVariable.LEVEL:
				{
					var levelToCheck: String = value as String;
					if (levels && levels.length > 0)
					{
						//check if level is inside levels
						for each (var currLevel: Object in levels)
						{
							if (currLevel is GlobalVariableValue)
							{
								if (((currLevel as GlobalVariableValue).value as String) == levelToCheck)
									return true;
							} else if (currLevel is String) {
								if ((currLevel as String) == levelToCheck)
									return true;
							}
						}
					}
					break;
				}
				case GlobalVariable.RUN:
				{
					var runToCheck: Date = value as Date;
					if (runs && runs.length > 0)
					{
						//check if level is inside levels
						for each (var currRun: Object in runs)
						{
							if (currRun is GlobalVariableValue)
							{
								if (((currRun as GlobalVariableValue).value as Date) == runToCheck)
									return true;
							} else if (currRun is Date) {
								if ((currRun as Date) == runToCheck)
									return true;
							}
						}
					}
					break;
				}
				case GlobalVariable.FRAME:
				{
					var frameToCheck: Date = value as Date;
					if (frames && frames.length > 0)
					{
						//check if level is inside levels
						for each (var currFrame: Object in frames)
						{
							if (currFrame is GlobalVariableValue)
							{
								if (((currFrame as GlobalVariableValue).value as Date) == frameToCheck)
									return true;
							} else if (currFrame is Date) {
								if ((currFrame as Date) == frameToCheck)
									return true;
							}
						}
					}
					break;
				}
			}
			return false;
		}

		private function onGlobalVariableSynchronisationChanged(event: SynchronisationEvent): void
		{
			debug("onGlobalVariableSynchronisationChanged");
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
					onInteractiveLayerLevelVariableChanged();
					break;
				}
				case GlobalVariable.RUN:
				{
					if (event.type == SynchronisationEvent.START_GLOBAL_VARIABLE_SYNCHRONIZATION)
						run = event.globalVariableValue as Date;
					onInteractiveLayerRunVariableChanged();
					onInteractiveLayerFrameVariableChanged();
					break;
				}
				case GlobalVariable.FRAME:
				{
					onInteractiveLayerFrameVariableChanged();
					break;
				}
			}
		}

		public function equalsByGlobalRUN(g1: GlobalVariableValue, g2: GlobalVariableValue): Boolean
		{
			if (!(g1 is GlobalVariableValue) || !(g2 is GlobalVariableValue))
				return false;
			if (!(g1.data is Date) || !(g2.data is Date))
				return false;
			return g1.data.time == g2.data.time;
		}

		private function onInteractiveLayerRunVariableChanged(event: Event = null): void
		{
			if (_interactiveLayerMap)
			{
				var _layerRuns: Array = _interactiveLayerMap.getRuns();
				var tempArr: Array = [];
				for each (var runVariable: Object in _layerRuns)
				{
					if (runVariable is GlobalVariableValue)
						tempArr.push(runVariable.data as Date);
					if (runVariable is Date)
						tempArr.push(runVariable as Date);
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


		private function onInteractiveLayerLevelVariableChanged(event: Event = null): void
		{
			debug("onInteractiveLayerLevelVariableChanged");
			if (_interactiveLayerMap)
			{
				var _layerLevels: Array = _interactiveLayerMap.getLevels();
				var tempArr: Array = [];
				for each (var globalLevelVariable: GlobalVariableValue in _layerLevels)
				{
//					tempArr.push({data: globalLevelVariable.data as String, label: globalLevelVariable.label as String});
					tempArr.push(globalLevelVariable);
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

		private var _cachedFrames: Array;
		private var _timelineFramesChanged: Boolean;

		private function onInteractiveLayerMapFramesEnumerated(event: Event = null): void
		{
			var frames: Array = _interactiveLayerMap.getFrames();

			if (_cachedFrames == frames)
			{
				_timelineFramesChanged = false;
			} else {
				var framesAC: ArrayCollection = new ArrayCollection();
//				for each (var frameVariable: Object in _cachedFrames)
				for each (var frameVariable: Object in frames)
				{
					if (frameVariable is GlobalVariableValue)
						framesAC.addItem(frameVariable.data as Date);
					if (frameVariable is Date)
						framesAC.addItem(frameVariable as Date);
				}

				//TODO sameCollection takes to long
				_timelineFramesChanged = !sameCollection(framesAC, _frames);
				if (_timelineFramesChanged)
				{
					_frames = framesAC;
					notifyFramesChanged();
				}
			}

//			_cachedFrames = frames;
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

				if (!_cachedFrames)
				{
					onInteractiveLayerMapFramesEnumerated();
				}

//				var framesObjects: Array = _interactiveLayerMap.primaryLayer.getSynchronisedVariableValuesList(GlobalVariable.FRAME);
//				if (!_cachedFrames)
//					_cachedFrames = _interactiveLayerMap.getFrames();
//
//
//				var framesAC: ArrayCollection = new ArrayCollection();
//				for each (var frameVariable: Object in framesObjects)
//				{
//					if (frameVariable is GlobalVariableValue)
//						framesAC.addItem(frameVariable.data as Date);
//					if (frameVariable is Date)
//						framesAC.addItem(frameVariable as Date);
//				}
//
//				//TODO sameCollection takes to long
//				var collectionChanged: Boolean = !sameCollection(framesAC, _frames);
//				if (collectionChanged)
//					_frames = framesAC;
//				else {
//					trace("GlobalVariablesManager ["+_interactiveLayerMap+"] _frames are same: ");
//				}
				var selectedFrame: Date = _interactiveLayerMap.frame;
				if (!selectedFrame)
				{
					//TODO this selection can be done, only if primary layer is examined
					selectedFrame = _interactiveLayerMap.primaryLayer.getSynchronisedVariableClosetsValue(GlobalVariable.FRAME, null) as Date;
					if (!selectedFrame)
						return;
				}

				if (_lastFrameNotified && _lastFrameNotified.time == selectedFrame.time)
				{
					//same time as last time
					if (!_timelineFramesChanged)
						return;
				}
				_lastFrameNotified = selectedFrame;

//				trace("GlobalVariablesManager ["+_interactiveLayerMap+"] onInteractiveLayerFrameVariableChanged selectedFrame: " + selectedFrame + " _frame: " + _frame);
				if (_frame)
				{
					if (_frame.time != selectedFrame.time)
					{
						//frame is changed
//						framesChanged = true;
						notifySelectedFrameChanged(selectedFrame);
					}
//					else
//						trace("Global frame is not changed, do not notify");
				}
				else {
					if (selectedFrame)
					{
						framesChanged = true;
						notifySelectedFrameChanged(selectedFrame);
					}
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
				notifyFramesChanged();
			}
		}
		private var _lastFrameNotified: Date;


		private function notifyFramesChanged(): void
		{
			dispatchEvent(new Event(FRAMES_CHANGED, true));
		}
		private function notifyRunsChanged(): void
		{
			dispatchEvent(new Event(RUNS_CHANGED, true));
		}
		private function notifyLevelsChanged(): void
		{
			debug("notifyLevelsChanged");
			dispatchEvent(new Event(LEVELS_CHANGED, true));
		}

		private function notifySelectedFrameChanged(selectedFrame: Date): void
		{
//			if (selectedFrame)
//			{
//				trace("notifySelectedFrameChanged: " + selectedFrame);
				var bChanged: Boolean = true;
				//if (_frame && selectedFrame && _frame.time == selectedFrame.time)
				//	bChanged = false;

				if (bChanged)
				{
					_frame = selectedFrame;
					var gvce: GlobalVariableChangeEvent = new GlobalVariableChangeEvent(GlobalVariableChangeEvent.DIMENSION_VALUE_CHANGED, GlobalVariable.FRAME, selectedFrame);
					dispatchEvent(gvce);
				}
//			}
		}
		private function notifySelectedRunChanged(selectedRun: Date): void
		{
//			trace("notifySelectedRunChanged: " + selectedRun);

			var bChanged: Boolean = true;
			//if (_run && selectedRun && _run.time == selectedRun.time)
			//	bChanged = false;

			if (bChanged)
			{
				_run = selectedRun;
				var gvce: GlobalVariableChangeEvent = new GlobalVariableChangeEvent(GlobalVariableChangeEvent.DIMENSION_VALUE_CHANGED, GlobalVariable.RUN, selectedRun);
				dispatchEvent(gvce);
			}
		}
		private function notifySelectedLevelChanged(selectedLevel: String): void
		{
			debug("notifySelectedLevelChanged");
			var bChanged: Boolean = true;
			//if (_level && selectedLevel && _level == selectedLevel)
			//	bChanged = false;

			if (bChanged)
			{
				_level = selectedLevel;
				var gvce: GlobalVariableChangeEvent = new GlobalVariableChangeEvent(GlobalVariableChangeEvent.DIMENSION_VALUE_CHANGED, GlobalVariable.LEVEL, selectedLevel);
				dispatchEvent(gvce);
			}
		}

		public function getPreviousGlobalVariableValue(globalVariable: String): Object
		{
			return getGlobalVariableValue(globalVariable, -1);
		}
		public function getNextGlobalVariableValue(globalVariable: String): Object
		{
			return getGlobalVariableValue(globalVariable, 1);
		}

		private function getGlobalVariableValue(globalVariable: String, positionDiff: int): Object
		{
			debug("getGlobalVariableValue globalVariable:" + globalVariable + " positionDiff: " + positionDiff );
			var arr: ArrayCollection;
			var selectedValue: Object;

			switch (globalVariable)
			{
				case GlobalVariable.FRAME:
					arr = frames;
					selectedValue = _frame;
					break;
				case GlobalVariable.RUN:
					arr = runs;
					selectedValue = _run;
					break;
				case GlobalVariable.LEVEL:
					arr = levels;
					selectedValue = _level;
					break;
			}

			var selectedPosition: int = -1;

			var total: int = arr.length;
			for (var i: int = 0; i < total; i++)
			{
				var value: Object = arr.getItemAt(i);
				if (selectedValue == value)
				{
					selectedPosition = i;
					break;
				}
			}

			var requestedPosition: int = selectedPosition + positionDiff;
			if (requestedPosition > -1 && requestedPosition < (total - 1))
			{
				return arr.getItemAt(requestedPosition);
			}

			return null;
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
						var val1: Date = collection1.getItemAt(i) as Date;
						var val2: Date = collection2.getItemAt(i) as Date;

						if (val1.time != val2.time) //if (val1.toString() != val2.toString())
							return false;
					}
				} else {
					return false;
				}

				return true;
			}
			return false;
		}

		private function debug(str: String, type: String = "Info", tag: String = "GlobalVariablesManager"): void
		{
//			trace(tag + "| " + type + "| " + str);
			//			LoggingUtils.dispatchLogEvent(this, " ILM: " + str);
		}

		override public function toString(): String
		{
			return "GlobalVariablesManager ["+id+"]: " + _interactiveLayerMap;
		}
	}
}
