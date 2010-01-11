package com.iblsoft.flexiweather.ogc
{
	import com.iblsoft.flexiweather.utils.Serializable;
	import com.iblsoft.flexiweather.utils.Storage;
	
	import mx.collections.ArrayCollection;

	public class LayerConfigurationManager implements Serializable
	{
		internal static var sm_instance: LayerConfigurationManager;

		internal var ma_layers: ArrayCollection = new ArrayCollection();
		
		public function LayerConfigurationManager()
		{
            if (sm_instance != null)
                throw new Error(
                		"LayerConfigurationManager can only be accessed through "
                		+ "LayerConfigurationManager.getInstance()");
		}
		
		public static function getInstance(): LayerConfigurationManager
		{
			if(sm_instance == null) {
				sm_instance = new LayerConfigurationManager();
			}			
			return sm_instance;
		}
		
		public function serialize(storage: Storage): void
		{
			storage.serializeNonpersistentArrayCollection("layer", ma_layers, WMSLayerConfiguration);
		}
		
		public function addLayer(l: WMSLayerConfiguration): void
		{
			ma_layers.addItem(l);
		}
		
		public function removeLayer(l: WMSLayerConfiguration): void
		{
			var i: int = ma_layers.getItemIndex(l);
			if(i >= 0) {
				ma_layers.removeItemAt(i);
			}
		}
		
		// getters & setters
		public function get layers(): ArrayCollection
		{ return ma_layers; }
	}
}