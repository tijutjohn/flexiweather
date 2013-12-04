package com.iblsoft.flexiweather.ogc
{
	import com.iblsoft.flexiweather.ogc.configuration.services.WMSServiceConfiguration;
	import com.iblsoft.flexiweather.ogc.configuration.services.WMSServiceParsingManager;
	
	import flash.utils.Dictionary;
	import flash.utils.getTimer;
	
	import mx.collections.ArrayCollection;

	public class WMSLayerGroup extends WMSLayerBase
	{
		public static const LAYER_XML_STORED: int = 0;
		public static const LAYER_INITIALIZED: int = 1;
		public static const LAYER_PARSED: int = 2;
		
		private var ma_layers: Array;
		private var ma_layersDictionary: Dictionary
		private var ma_layersXMLDictionary: Dictionary
		private var _groups: int;
		private var _state: int;
		
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
//			var currTime: Number = getTimer();
			super.initialize(parsingManager);

			if (WMSServiceConfiguration.EXPERIMENTAL_LAYERS_INITIALIZING)
				return;
			
			ma_layers = new Array();
			ma_layersDictionary = new Dictionary();
			
//			ma_layersXMLDictionary = new Dictionary();
//			
			var layers: XMLList = m_itemXML.wms::Layer;
			var total: int = layers.length();
			for (var i: int = 0; i < total; i++)
			{
				var layer: XML = layers[i] as XML;
				var name: String = String(layer.wms::Name);
				var layersChildren: int = layer.wms::Layer.length();

//					if (layersChildren == 0)
//						ma_layersXMLDictionary[name] = layer;
//					else
//						initializeSubgroup(layer);
				
				
				if (parsingManager)
					parsingManager.addCall({obj: this.toString()+"Initialize"}, initializeLayer, [layer, parsingManager]);
				else
					initializeLayer(layer);
			}
			
//			trace(this + " initialize total time: " + (getTimer() - currTime) + "ms");
		}
		
		private function initializeSubgroup(layer: XML): void
		{
			
		}
		
		public function initializeLayer(layer: XML, parsingManager: WMSServiceParsingManager = null): void
		{
//			var layerTime: Number = getTimer();
			
			if (layer.wms::Layer.length() == 0) {
				var wmsLayer: WMSLayer = new WMSLayer(this, layer, wms, m_version);
				
				/**
				 * we call initialize() instead of parse() method to create instances, but not parse whole data.
				 * They will be parsed, when they will be needed
				 */
				wmsLayer.initialize(parsingManager);
				
				addLayer(wmsLayer);
				//					trace("\n" + this + " initialize layer: "+ wmsLayer.toString() + " total time: " + (getTimer() - layerTime) + "ms");
			} else {
				var wmsLayerGroup: WMSLayerGroup = new WMSLayerGroup(this, layer, wms, m_version);
				
				wmsLayerGroup.initialize(parsingManager);
				
				addLayer(wmsLayerGroup);
				
//				_groups++;
//				
//				ma_layersDictionary["group"+_groups] = new LayerDataItem(wmsLayerGroup, LayerDataItem.LAYER_GROUP);
//				ma_layers.push(wmsLayerGroup);
				//					trace("\n" + this + " initialize layerGroup: "+ wmsLayerGroup.toString() + " total time: " + (getTimer() - layerTime) + "ms");
			}
			
			_state = LAYER_INITIALIZED;
		}
		
		private function delayedInitialization(): void
		{
			if (!WMSServiceConfiguration.EXPERIMENTAL_LAYERS_INITIALIZING)
			{
				for each (var layer: XML in ma_layersDictionary)
				{
					initializeLayer(layer);
				}
			} else {
				ma_layers = new Array();
				ma_layersDictionary = new Dictionary();
			}
		}
		
		private function parsing(): void
		{
//			for each (var layer: XML in m_itemXML.wms::Layer)
			for each (var wmsLayerItem: LayerDataItem in ma_layersDictionary)
			{
//				if (parsingManager)
//					parsingManager.addCall({obj: this.toString()+"Parse"}, parseLayerItem, [wmsLayerItem, parsingManager]);
//				else
					wmsLayerItem.layer.parse();
			}
		}
		
		override public function parse(parsingManager: WMSServiceParsingManager = null):void
		{
			super.parse(parsingManager);
			
			if (_state == LAYER_XML_STORED)
			{
				delayedInitialization();
			}
			
			_state = LAYER_INITIALIZED;
			
			if (!WMSServiceConfiguration.EXPERIMENTAL_LAYERS_INITIALIZING)
				parsing();
			
			_state = LAYER_PARSED;
		}
		
		public function parseLayerItem(wmsLayerItem: LayerDataItem, parsingManager: WMSServiceParsingManager): void
		{
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
				removeAllArrayItems(ma_layers);
				ma_layers = null;
			}
			super.destroy();
		}

		public function addLayer(wmsLayer: WMSLayerBase): void
		{
			
			wmsLayer.parent = this;
			
//			trace(this + " addLayer: "+ wmsLayer + " parent: "+ wmsLayer.parent);
			if (wmsLayer is WMSLayer)
			{
				ma_layersDictionary[wmsLayer.name] = new LayerDataItem(wmsLayer, LayerDataItem.LAYER);
				
			} else if (wmsLayer is WMSLayerGroup) {
				_groups++;
				ma_layersDictionary["group"+_groups] = new LayerDataItem(wmsLayer, LayerDataItem.LAYER_GROUP);
			}
			ma_layers.push(wmsLayer);
		}
			
		public function getLayerByName(s_name: String): WMSLayer
		{
			if (_state != LAYER_PARSED)
			{
				parse();
			}
			
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
		public function get layers(): Array
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