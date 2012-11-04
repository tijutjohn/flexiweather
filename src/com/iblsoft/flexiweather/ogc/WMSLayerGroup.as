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

		override public function destroy():void
		{
			
			if (ma_layers && ma_layers.length > 0)
			{
				for each(var l: WMSLayerBase in ma_layers) 
				{
					l.destroy();
				}
				ma_layers.removeAll();
				ma_layers = null;
			}
			super.destroy();
		}
		public function getLayerByName(s_name: String): WMSLayer
		{
			var total: int = ma_layers.length;
//			for each(var l: WMSLayerBase in ma_layers) {
			for (var i: int = 0; i < total; i++)
			{
				var l: WMSLayerBase = ma_layers.getItemAt(i) as WMSLayerBase
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