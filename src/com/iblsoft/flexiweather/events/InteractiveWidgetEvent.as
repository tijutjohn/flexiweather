package com.iblsoft.flexiweather.events
{
	import flash.events.Event;
	
	public class InteractiveWidgetEvent extends Event
	{
		/**
		 * Dispatch event in InteractiveWidget when any single layer starts load data 
		 */		
		public static const DATA_LAYER_LOADING_STARTED: String = 'dataLayerLoadingStarted';
		
		/**
		 * Dispatch event in InteractiveWidget when any single layer finish load data 
		 */		
		public static const DATA_LAYER_LOADING_FINISHED: String = 'dataLayerLoadingFinished';
		
		/**
		 * Dispatch event in InteractiveWidget when finished loading data from all layers. 
		 */		
		public static const ALL_DATA_LAYERS_LOADED: String = 'allDataLayersLoaded';
		
		public static const AREA_CHANGED: String = 'areaChanged';
		
		
		/**
		 * How many layers are currently loading 
		 */		
		public var layersLoading: int;
		
		public function InteractiveWidgetEvent(type:String, bubbles:Boolean=false, cancelable:Boolean=false)
		{
			super(type, bubbles, cancelable);
		}
	}
}