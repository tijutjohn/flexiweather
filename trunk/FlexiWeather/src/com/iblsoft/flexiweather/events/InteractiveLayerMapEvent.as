package com.iblsoft.flexiweather.events
{
	import flash.events.Event;

	public class InteractiveLayerMapEvent extends Event
	{
		public static const FIRST_FRAME_CHANGED: String = "firstFrameChanged";
		[Event(name = FIRST_FRAME_CHANGED, type = "com.iblsoft.flexiweather.events.InteractiveLayerMapEvent")]
		public static const LAST_FRAME_CHANGED: String = "lastFrameChanged";
		[Event(name = LAST_FRAME_CHANGED, type = "com.iblsoft.flexiweather.events.InteractiveLayerMapEvent")]
		public static const NOW_FRAME_CHANGED: String = "nowFrameChanged";
		[Event(name = NOW_FRAME_CHANGED, type = "com.iblsoft.flexiweather.events.InteractiveLayerMapEvent")]
		
		public static const MAP_LOADED: String = "mapLoaded";
		
		public static const LAYER_SELECTION_CHANGED: String = "layerSelectionChanged";
		
		public static const MAP_LOADING_STARTED: String = "mapLoadingStarted";
		public static const MAP_LOADING_PROGRESS: String = "mapLoadingProgress";
		public static const MAP_INITIALIZING_PROGRESS: String = "mapInitializingProgress";
		public static const MAP_LOADING_FINISHED: String = "mapLoadingFinished";
		
		public static const BEFORE_REFRESH: String = "mapBeforeRefresh";
		public static const MAP_REFRESHED: String = "mapRefreshed";
		
		public var frameDate: Date;
		
		public var loadedLayers: uint;
		public var totalLayers: uint;

		public function InteractiveLayerMapEvent(type: String, bubbles: Boolean = false, cancelable: Boolean = false)
		{
			super(type, bubbles, cancelable);
		}
	}
}
