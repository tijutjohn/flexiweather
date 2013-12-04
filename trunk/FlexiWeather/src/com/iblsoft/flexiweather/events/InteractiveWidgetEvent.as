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
		 * Dispatch event in InteractiveWidget when user clicks inside InteractiveWidget
		 */
		public static const WIDGET_SELECTED: String = 'widgetSelected';
		/**
		 * Dispatch event in InteractiveWidget when some property which can be synchronized (e.g. in InteractiveMultiView) was changed
		 */
		public static const WIDGET_CHANGED: String = 'widgetChanged';
		/**
		 * How many layers are currently loading
		 */
		public var layersLoading: int;
		public var changeDescription: String;

		public var data: Object;
		
		public function InteractiveWidgetEvent(type: String, bubbles: Boolean = false, cancelable: Boolean = false)
		{
			super(type, bubbles, cancelable);
		}

		override public function clone(): Event
		{
			var iwe: InteractiveWidgetEvent = new InteractiveWidgetEvent(type);
			iwe.layersLoading = layersLoading;
			iwe.changeDescription = changeDescription;
			iwe.data = data;
			return iwe;
		}
	}
}
