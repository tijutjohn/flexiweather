package com.iblsoft.flexiweather.ogc
{
	import mx.collections.ArrayCollection;
	
	public class WMSLayerGroup extends WMSLayerBase
	{
		internal var ma_layers: ArrayCollection = new ArrayCollection();
		 
		public function WMSLayerGroup(parent: WMSLayerGroup, xml: XML, wms: Namespace, version: Version)
		{
			super(parent, xml, wms, version);
			for each(var layer: XML in xml.wms::Layer) {
				if(layer.wms::Layer.length() == 0)
					ma_layers.addItem(new WMSLayer(this, layer, wms, version));
				else
					ma_layers.addItem(new WMSLayerGroup(this, layer, wms, version));
			}
		}

		public function getLayerByName(s_name: String): WMSLayer
		{
			for each(var l: WMSLayerBase in ma_layers) {
				if(l is WMSLayerGroup) {
					var wl: WMSLayer = WMSLayerGroup(l).getLayerByName(s_name);
					if(wl != null)
						return wl;
				}
				else {
					if(WMSLayer(l).name == s_name)
						return WMSLayer(l);
				}
			}
			return null;
		}

		// getters & setters

		public function get layers(): ArrayCollection
		{ return ma_layers; }		
	}
}