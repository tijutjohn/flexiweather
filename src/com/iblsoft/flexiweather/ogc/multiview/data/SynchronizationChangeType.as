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
		 * Layer level (not global level) is changed 
		 */		
		public static const LEVEL_CHANGED: String = 'levelChanged';
		
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
		
		public static const WMS_STYLE_CHANGED: String = 'wmsStyleChanged';
		public static const MAP_CHANGED: String = 'mapChanged';
		public static const MAP_LAYER_ADDED: String = 'mapLayerAdded';
		public static const MAP_LAYER_REMOVED: String = 'mapLayerRemoved';
		
	}
}