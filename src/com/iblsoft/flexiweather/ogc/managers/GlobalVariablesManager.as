package com.iblsoft.flexiweather.ogc.managers
{
	import com.iblsoft.flexiweather.data.SetOperationType;
	import com.iblsoft.flexiweather.ogc.WMSDimension;
	import com.iblsoft.flexiweather.widgets.InteractiveLayerMap;
	
	import flash.events.DataEvent;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	
	import mx.collections.ArrayCollection;

	public class GlobalVariablesManager extends EventDispatcher
	{
		public static const VARIABLE_FRAME: String = 'frame';
		public static const VARIABLE_LEVEL: String = 'level';
		
		public static const FRAMES_CHANGED: String = 'framesChanged';
		public static const LEVELS_CHANGED: String = 'levelsChanged';
	
		private var _frames: ArrayCollection;
		private var _levels: ArrayCollection;
		
		[Bindable (event=FRAMES_CHANGED)]
		public function get frames(): ArrayCollection
		{
			return _frames;	
		}
		[Bindable (event=FRAMES_CHANGED)]
		public function get levels(): ArrayCollection
		{
			return _levels;	
		}

		private var _interactiveLayerMap: InteractiveLayerMap;
		
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
				
			}

			_interactiveLayerMap = interactiveMap;
			_interactiveLayerMap.addEventListener(InteractiveLayerMap.FRAME_VARIABLE_CHANGED, onFrameVariableChanged);
			_interactiveLayerMap.addEventListener(InteractiveLayerMap.LEVEL_VARIABLE_CHANGED, onLevelVariableChanged);

			if (_interactiveLayerMap && _interactiveLayerMap.primaryLayer)
			{
				onFrameVariableChanged();
				onLevelVariableChanged();
			}
		}
		
		private function onLevelVariableChanged(event: Event = null): void
		{
			if (_interactiveLayerMap && _interactiveLayerMap.primaryLayer)
			{
				var levels: Array = _interactiveLayerMap.primaryLayer.getSynchronisedVariableValuesList('level');
				_levels = new ArrayCollection(levels);
				dispatchEvent(new Event(LEVELS_CHANGED, true));
			}
		}
		private function onFrameVariableChanged(event: Event = null): void
		{
			if (_interactiveLayerMap && _interactiveLayerMap.primaryLayer)
			{
				var frames: Array = _interactiveLayerMap.primaryLayer.getSynchronisedVariableValuesList('frame');
				_frames = new ArrayCollection(frames);
				dispatchEvent(new Event(FRAMES_CHANGED, true));
			}
			
		}
	}
}