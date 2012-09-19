package com.iblsoft.flexiweather.ogc.managers
{
	import com.iblsoft.flexiweather.data.SetOperationType;
	import com.iblsoft.flexiweather.ogc.InteractiveLayerMSBase;
	import com.iblsoft.flexiweather.ogc.WMSDimension;
	import com.iblsoft.flexiweather.ogc.data.GlobalVariable;
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
		public static const LEVELS_CHANGED: String = 'levelsChanged';
	
		private var _frames: ArrayCollection;
		private var _levels: ArrayCollection;
		
		[Bindable (event=FRAMES_CHANGED)]


		

		public function get frames(): ArrayCollection
		{
			return _frames;	
		}
		[Bindable (event=LEVELS_CHANGED)]
		public function get levels(): ArrayCollection
		{
			return _levels;	
		}

		private var _interactiveLayerMap: InteractiveLayerMap;
		
		private var _frame: Date;
		private var _level: String;
		
		public function get frame():Date
		{
			return _frame;
		}
		
		public function set frame(value:Date):void
		{
			_frame = value;
		}
		
		public function get level():String
		{
			return _level;
		}
		
		public function set level(value:String):void
		{
			_level = value;
		}
		
		/**
		 * Should be one of SetOperationType constants
		 */		
		private var _operationType: String;
		
		public function GlobalVariablesManager()
		{
			_operationType = SetOperationType.UNION;
			_frames = new ArrayCollection();
			_levels = new ArrayCollection();
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
				_interactiveLayerMap.removeEventListener(InteractiveLayerMap.FRAME_VARIABLE_CHANGED, onFrameVariableChanged);
				_interactiveLayerMap.removeEventListener(InteractiveLayerMap.LEVEL_VARIABLE_CHANGED, onLevelVariableChanged);
				_interactiveLayerMap.removeEventListener(SynchronisationEvent.START_GLOBAL_VARIABLE_SYNCHRONIZATION, onGlobalVariableSynchronisationChanged);
				_interactiveLayerMap.removeEventListener(SynchronisationEvent.STOP_GLOBAL_VARIABLE_SYNCHRONIZATION, onGlobalVariableSynchronisationChanged);
				_interactiveLayerMap.removeEventListener(InteractiveLayerMap.PRIMARY_LAYER_CHANGED, onPrimaryLayerChanged);
				
			}

			_interactiveLayerMap = interactiveMap;
			_interactiveLayerMap.addEventListener(InteractiveLayerMap.FRAME_VARIABLE_CHANGED, onFrameVariableChanged);
			_interactiveLayerMap.addEventListener(InteractiveLayerMap.LEVEL_VARIABLE_CHANGED, onLevelVariableChanged);
			_interactiveLayerMap.addEventListener(SynchronisationEvent.START_GLOBAL_VARIABLE_SYNCHRONIZATION, onGlobalVariableSynchronisationChanged);
			_interactiveLayerMap.addEventListener(SynchronisationEvent.STOP_GLOBAL_VARIABLE_SYNCHRONIZATION, onGlobalVariableSynchronisationChanged);
			_interactiveLayerMap.addEventListener(InteractiveLayerMap.PRIMARY_LAYER_CHANGED, onPrimaryLayerChanged);

			checkGlobalVariableChange();
		}
		
		private function checkGlobalVariableChange(): void
		{
			if (_interactiveLayerMap && _interactiveLayerMap.primaryLayer)
			{
				onFrameVariableChanged();
				onLevelVariableChanged();
			}
		}
		
		private function onPrimaryLayerChanged(event: DataEvent): void
		{
			checkGlobalVariableChange();
		}
		
		private function onGlobalVariableSynchronisationChanged(event: SynchronisationEvent): void
		{
			switch (event.globalVariable)
			{
				case GlobalVariable.LEVEL:
					onLevelVariableChanged();
					break;
				case GlobalVariable.FRAME:
					onFrameVariableChanged();
					break;
			}
		}
		
		private function onLevelVariableChanged(event: Event = null): void
		{
			_levels = new ArrayCollection();
			if (_interactiveLayerMap )
			{
				for each (var layer: InteractiveLayer in _interactiveLayerMap.layers)
				{
					if (layer is InteractiveLayerMSBase)
					{
						var layerMSBase: InteractiveLayerMSBase = layer as InteractiveLayerMSBase;
						if ( layerMSBase.synchroniseLevel )
						{
							
							var _layerLevels: Array = layerMSBase.getSynchronisedVariableValuesList(GlobalVariable.LEVEL);
							ArrayUtils.unionArrays(_levels.source, _layerLevels);
						}
					}
				}
				_levels.refresh();
			}
			dispatchEvent(new Event(LEVELS_CHANGED, true));
		}
		
		private function onFrameVariableChanged(event: Event = null): void 
		{
			if (_interactiveLayerMap && _interactiveLayerMap.primaryLayer)
			{
				var frames: Array = _interactiveLayerMap.primaryLayer.getSynchronisedVariableValuesList(GlobalVariable.FRAME);
				_frames = new ArrayCollection(frames);
				
				var selectedFrame: Date = _interactiveLayerMap.frame;
				if (!selectedFrame)
					return;
				
				if (_frame)
				{
					if (_frame.time != selectedFrame.time)
					{
						//frame is changed
						notifySelectedFrameChanged(selectedFrame);
					} else {
						trace("Global frame is not changed, do not notify");
					}
				} else {
					notifySelectedFrameChanged(selectedFrame);
				}
			} else {
				_frames = new ArrayCollection();
			}
			dispatchEvent(new Event(FRAMES_CHANGED, true));
		}
		
		private function notifySelectedFrameChanged(selectedFrame: Date): void
		{
			if (selectedFrame)
			{
				_frame = selectedFrame;
				var gvce: GlobalVariableChangeEvent = new GlobalVariableChangeEvent(GlobalVariableChangeEvent.DIMENSION_VALUE_CHANGED, GlobalVariable.FRAME, selectedFrame);
				dispatchEvent(gvce);
			}
		}
		private function notifySelectedLevelChanged(selectedLevel: String): void
		{
			_level = selectedLevel;
			var gvce: GlobalVariableChangeEvent = new GlobalVariableChangeEvent(GlobalVariableChangeEvent.DIMENSION_VALUE_CHANGED, GlobalVariable.LEVEL, selectedLevel);
			dispatchEvent(gvce);
		}
	}
}