package com.iblsoft.flexiweather.ogc.multiview.data
{
	public class SynchronizationChangeType
	{
		/**
		 * Global frame is changed 
		 */		
		public static const GLOBAL_FRAME_CHANGED: String = 'globalFrameChanged';
		
		/**
		 * Global level is changed 
		 */		
		public static const GLOBAL_LEVEL_CHANGED: String = 'globalLevelChanged';
		
		/**
		 * Global run is changed 
		 */		
		public static const GLOBAL_RUN_CHANGED: String = 'globalRunChanged';
		
		
		/**
		 * Layer level (not global level) is changed 
		 */		
		public static const LEVEL_CHANGED: String = 'levelChanged';
		
		/**
		 * Layer run (not global run) is changed 
		 */		
		public static const RUN_CHANGED: String = 'runChanged';
		
		/**
		 * Alpha is changed 
		 */		
		public static const ALPHA_CHANGED: String = 'alphaChanged';
		
		/**
		 * Visibility is changed 
		 */		
		public static const VISIBILITY_CHANGED: String = 'visibilityChanged';
		
		/**
		 * "synchronizeLevel" property of InteractiveLayerMSBase is changed 
		 */		
		public static const SYNCHRONIZE_LEVEL_CHANGED: String = 'synchronizeLevelChanged';
		
		/**
		 * "synchronizeRun" property of InteractiveLayerMSBase is changed 
		 */		
		public static const SYNCHRONIZE_RUN_CHANGED: String = 'synchronizeRunChanged';
		
		/**
		 * Animator Settings are changed 
		 */		
		public static const ANIMATOR_SETTINGS_CHANGED: String = 'animatorSettingsChanged';
		
		public static const WMS_STYLE_CHANGED: String = 'wmsStyleChanged';
		public static const MAP_CHANGED: String = 'mapChanged';
		public static const MAP_LAYER_ADDED: String = 'mapLayerAdded';
		public static const MAP_LAYER_REMOVED: String = 'mapLayerRemoved';
		
	}
}