package com.iblsoft.flexiweather.widgets.data
{
	/**
	 * This class holds all flags which are needed for saving InteractiveLayerMap with special settings.
	 * It's used and input parameter in InteractiveLayerMap.serializeMapWithCustomSettings and it's used for saving or loading
	 * map for external animator or multi view
	 *  
	 * @author fkormanak
	 * 
	 */	
	public class InteractiveLayerMapSaveSettings
	{
		public var saveFrame: Boolean;
		
		/**
		 * This function will set all flags for saving map to external animator 
		 * 
		 */		
		public function useForExternalAnimator(): void
		{
			saveFrame = false;
		}
		
		/**
		 * This function will set all flags for saving map to external animator 
		 * 
		 */		
		public function useForMultiView(): void
		{
			saveFrame = true;
		}
	}
}