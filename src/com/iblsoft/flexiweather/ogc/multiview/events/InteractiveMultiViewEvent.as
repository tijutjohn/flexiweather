package com.iblsoft.flexiweather.ogc.multiview.events
{
    import flash.events.Event;

    public class InteractiveMultiViewEvent extends Event
    {
        public static const CLOSE_MULTI_VIEW:String = 'closeMultiView';
		
        public static const MULTI_VIEW_READY:String = 'multiViewReady';

        public static const MULTI_VIEW_MAPS_LOADING_STARTED:String = 'multiViewMapsLoadingStarted';

        public static const MULTI_VIEW_MAPS_LOADED:String = 'multiViewMapsLoaded';

        public static const MULTI_VIEW_SINGLE_MAP_LAYERS_INITIALIZED:String = 'multiViewSingleMapLayersInitialized';
        
		public static const MULTI_VIEW_ALL_MAPS_LAYERS_INITIALIZED:String = 'multiViewAllMapsLayersInitialized';

        public static const MULTI_VIEW_BEFORE_REFRESH:String = 'multiViewBeforeRefresh';
        
		public static const MULTI_VIEW_REFRESHED:String = 'multiViewRefreshed';
		
		public function InteractiveMultiViewEvent(type:String, bubbles:Boolean = false, cancelable:Boolean = false)
        {
            super(type, bubbles, cancelable);
        }
    }
}

