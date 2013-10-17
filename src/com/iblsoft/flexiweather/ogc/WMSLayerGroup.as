package com.iblsoft.flexiweather.ogc
{
	import com.iblsoft.flexiweather.ogc.configuration.services.WMSServiceParsingManager;
	
	import flash.utils.Dictionary;
	import flash.utils.getTimer;
	
	import mx.collections.ArrayCollection;

	public class WMSLayerGroup extends WMSLayerBase
	{
		private var ma_layers: ArrayCollection;
		private var ma_layersDictionary: Dictionary
		private var _groups: int;
		
		public function WMSLayerGroup(parent: WMSLayerGroup, xml: XML, wms: Namespace, version: Version)
		{
			super(parent, xml, wms, version);
		
			_groups = 0;
		}
		
		/**
		 * all layers and groups within this group will be created and stored in dictionary, and bParse variable will be "true", also content will be parsed 
		 * @param bParse
		 * 
		 */		
		override public function initialize(parsingManager: WMSServiceParsingManager = null):void
		{
			var currTime: Number = getTimer();

			super.initialize(parsingManager);

			ma_layers = new ArrayCollection();
			ma_layersDictionary = new Dictionary();
			
			for each (var layer: XML in m_itemXML.wms::Layer)
			{
				if (parsingManager)
					parsingManager.addCall({obj: this.toString()+"Initialize"}, initializeLayer, [layer, parsingManager]);
				else
					initializeLayer(layer);
			}
			
//			trace(this + " initialize total time: " + (getTimer() - currTime) + "ms");
		}
		
		public function initializeLayer(layer: XML, parsingManager: WMSServiceParsingManager = null): void
		{
			var layerTime: Number = getTimer();
			
			if (layer.wms::Layer.length() == 0) {
				var wmsLayer: WMSLayer = new WMSLayer(this, layer, wms, m_version);
				
				/**
				 * we call initialize() instead of parse() method to create instances, but not parse whole data.
				 * They will be parsed, when they will be needed
				 */
				wmsLayer.initialize(parsingManager);
				
				ma_layersDictionary[wmsLayer.name] = new LayerDataItem(wmsLayer, LayerDataItem.LAYER);
				ma_layers.addItem(wmsLayer);
				//					trace("\n" + this + " initialize layer: "+ wmsLayer.toString() + " total time: " + (getTimer() - layerTime) + "ms");
			} else {
				var wmsLayerGroup: WMSLayerGroup = new WMSLayerGroup(this, layer, wms, m_version);
				
				wmsLayerGroup.initialize(parsingManager);
				
				_groups++;
				
				ma_layersDictionary["group"+_groups] = new LayerDataItem(wmsLayerGroup, LayerDataItem.LAYER_GROUP);
				ma_layers.addItem(wmsLayerGroup);
				//					trace("\n" + this + " initialize layerGroup: "+ wmsLayerGroup.toString() + " total time: " + (getTimer() - layerTime) + "ms");
			}
		}
		
		override public function parse(parsingManager: WMSServiceParsingManager = null):void
		{
			var currTime: Number = getTimer();

			super.parse(parsingManager);
			
//			for each (var layer: XML in m_itemXML.wms::Layer)
			for each (var wmsLayerItem: LayerDataItem in ma_layersDictionary)
			{
//				var layerTime: Number = getTimer();
//				if (wmsLayerItem.layer.name.indexOf("temper") > 0)
//				{
//					trace("debug Temperature layer");
//				}

				if (parsingManager)
					parsingManager.addCall({obj: this.toString()+"Parse"}, parseLayerItem, [wmsLayerItem, parsingManager]);
				else
					wmsLayerItem.layer.parse();
				
//				trace("\n" + this + " parse layer: "+ wmsLayerItem.layer.toString() + " total time: " + (getTimer() - layerTime) + "ms");
			}
			
//			trace(this + " parse total time: " + (getTimer() - currTime) + "ms");
		}
		
		public function parseLayerItem(wmsLayerItem: LayerDataItem, parsingManager: WMSServiceParsingManager): void
		{
//			var layerTime: Number = getTimer();
			if (wmsLayerItem.type == LayerDataItem.LAYER)
				wmsLayerItem.layer.parse(parsingManager);
			else
				parsingManager.addCall(this, wmsLayerItem.layer.parse, [parsingManager]);
				
		}

		override public function toString(): String
		{
			return "WMSLayerGroup: "+ name + " title: " + title;
		}
		
		override public function destroy(): void
		{
			if (ma_layers && ma_layers.length > 0)
			{
				for each (var l: WMSLayerBase in ma_layers)
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
			
			var item: LayerDataItem =  ma_layersDictionary[s_name] as LayerDataItem;
			if (item)
				return item.layer as WMSLayer;
			
			var groupLayer: WMSLayer;
			for each (item in ma_layersDictionary)
			{
				if (item.type == LayerDataItem.LAYER_GROUP)
				{
					groupLayer = (item.layer as WMSLayerGroup).getLayerByName(s_name);
					if (groupLayer)
						return groupLayer;
				}
			}
			return null;
			
			
			/*
			var total: int = ma_layers.length;
//			for each(var l: WMSLayerBase in ma_layers) {
			for (var i: int = 0; i < total; i++)
			{
				var l: WMSLayerBase = ma_layers.getItemAt(i) as WMSLayerBase
				if (l is WMSLayerGroup)
				{
					var wl: WMSLayer = WMSLayerGroup(l).getLayerByName(s_name);
					if (wl != null)
						return wl;
				}
				else
				{
					if (WMSLayer(l).name == s_name)
						return WMSLayer(l);
				}
			}
			return null;
			*/
		}

		// getters & setters
		public function get layers(): ArrayCollection
		{
			return ma_layers;
		}
	}
}


import com.iblsoft.flexiweather.ogc.WMSLayerBase;


class LayerDataItem
{
	public static const LAYER: String = 'layer';
	public static const LAYER_GROUP: String = 'layerGroup';
	
	public var layer: WMSLayerBase;
	public var type: String;
	
	public function LayerDataItem(l: WMSLayerBase, t: String)
	{
		layer = l;
		type = t;
	}
}