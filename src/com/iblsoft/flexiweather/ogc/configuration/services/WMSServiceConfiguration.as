package com.iblsoft.flexiweather.ogc.configuration.services
{
	import com.iblsoft.flexiweather.net.events.UniURLLoaderErrorEvent;
	import com.iblsoft.flexiweather.net.events.UniURLLoaderEvent;
	import com.iblsoft.flexiweather.net.loaders.UniURLLoader;
	import com.iblsoft.flexiweather.net.loaders.XMLLoader;
	import com.iblsoft.flexiweather.ogc.BBox;
	import com.iblsoft.flexiweather.ogc.CRSWithBBox;
	import com.iblsoft.flexiweather.ogc.Version;
	import com.iblsoft.flexiweather.ogc.WMSLayer;
	import com.iblsoft.flexiweather.ogc.WMSLayerBase;
	import com.iblsoft.flexiweather.ogc.WMSLayerGroup;
	import com.iblsoft.flexiweather.ogc.configuration.ProjectionConfiguration;
	import com.iblsoft.flexiweather.ogc.configuration.layers.WMSLayerConfiguration;
	import com.iblsoft.flexiweather.ogc.events.ServiceCapabilitiesEvent;
	import com.iblsoft.flexiweather.ogc.managers.OGCServiceConfigurationManager;
	import com.iblsoft.flexiweather.ogc.managers.ProjectionConfigurationManager;
	import com.iblsoft.flexiweather.utils.ArrayUtils;
	import com.iblsoft.flexiweather.utils.AsyncManager;
	import com.iblsoft.flexiweather.utils.LoggingUtils;
	import com.iblsoft.flexiweather.utils.Storage;
	import com.iblsoft.flexiweather.widgets.BackgroundJob;
	import com.iblsoft.flexiweather.widgets.BackgroundJobManager;
	
	import flash.events.DataEvent;
	import flash.events.Event;
	import flash.net.URLRequest;
	import flash.utils.Dictionary;
	import flash.utils.getTimer;
	
	import mx.collections.ArrayCollection;
	import mx.effects.easing.Exponential;

	[Event(name = CAPABILITIES_UPDATED, type = "flash.events.DataEvent")]
	
	/**
	 * WMSServiceConfiguration is base class for all service WMS configurations.
	 * 
	 * WMSServiceConfiguration can load and parse GetCapabilities request.
	 * 
	 * There are 2 experimental modes for parsing GetCapabilities request
	 * 
	 * 
	 * 
	 */
	public class WMSServiceConfiguration extends OGCServiceConfiguration
	{
		Storage.addChangedClass('com.iblsoft.flexiweather.ogc.WMSServiceConfiguration', 'com.iblsoft.flexiweather.ogc.configuration.services.WMSServiceConfiguration', new Version(1, 6, 0));
	
		public static var EXPERIMENTAL_LAYERS_INITIALIZING: Boolean = false;
		/**
		 * Set to "true" if GetCapabilities request needs to be parsed immediately. If it is set to "false" GetCapabilities items will be parsed when they will be needed 
		 */		
		public static var PARSE_GET_CAPABILITIES: Boolean = true;
		/**
		 * Set to "true" if GetCapabilities will be parsed asynchronous and not in one loop 
		 */		
		public static var USE_ASYNCHRONOUS_PARSING: Boolean = false;
		
		private var m_capabilitiesLoader: XMLLoader = new XMLLoader();
		private var m_capabilities: XML = null;
		private var _m_capabilitiesLoadJob: BackgroundJob = null;
		private var mb_capabilitiesUpdated: Boolean;


		public function get m_capabilitiesLoadJob():BackgroundJob
		{
			return _m_capabilitiesLoadJob;
		}

		public function set m_capabilitiesLoadJob(value:BackgroundJob):void
		{
//			trace("WMSServiceConfiguration load job = " + value);
			_m_capabilitiesLoadJob = value;
		}

		public function get capabilitiesUpdated(): Boolean
		{
			return mb_capabilitiesUpdated;
		}
		private var m_layersXMLDictionary: Dictionary;
		
//		private var m_layers: WMSLayerGroup = null;
		private var ma_rootLayers: Array;
		private var ma_allLayers: Array;
		
		private var _imageFormats: Array = [];

		public function get imageFormats(): Array
		{
			return _imageFormats;
		}
		
		private var wms: Namespace
		
		public function WMSServiceConfiguration(s_url: String = null, version: Version = null)
		{
			super(s_url, "wms", version);
			
			m_layersXMLDictionary = new Dictionary();
			ma_rootLayers = [];
			
			m_capabilitiesLoader.addEventListener(UniURLLoaderEvent.DATA_LOADED, onCapabilitiesLoaded);
			m_capabilitiesLoader.addEventListener(UniURLLoaderErrorEvent.DATA_LOAD_FAILED, onCapabilitiesLoadFailed);
		}

		override public function destroy(): void
		{
			super.destroy();
			if (m_capabilitiesLoader)
				m_capabilitiesLoader.destroy();
			m_capabilitiesLoader = null;
			
//			if (m_layers)
//				m_layers.destroy();
//			m_layers = null;
			
			//TODO destroy m_layersXMLDictionary
			
			
			_imageFormats = null;
			m_capabilitiesLoadJob = null;
		}

		
		public function getLayerByName(s_name: String): WMSLayer
		{
			var wmsLayer: WMSLayer;
			
			var layerTemp: Object = m_layersXMLDictionary[s_name];
			
			if (EXPERIMENTAL_LAYERS_INITIALIZING)
			{
				if (layerTemp)
				{
					if (layerTemp is XML)
					{
						var tempLayerXML: LayerXMLHelper = new LayerXMLHelper(m_layersXMLDictionary, wms, version);
						wmsLayer = tempLayerXML.createLayer(s_name, layerTemp as XML);
//						trace("WMSServiceConfig getLayerByName 1: "+ wmsLayer + " parent: "+ wmsLayer.parent);
						return wmsLayer;
						
					} else if (layerTemp is WMSLayer) {
	//					trace("WMSServiceConfig getLayerByName 2: "+ layerTemp + " parent: "+ (layerTemp as WMSLayer).parent);
						return layerTemp as WMSLayer
					}
					
				}
				return null;
			} 
			
//			if (m_layers == null)
//				return null;
//			
//			wmsLayer = m_layers.getLayerByName(s_name);
//			return wmsLayer;
			for each (var layer: WMSLayerBase in ma_allLayers)
			{
				if (layer.name == s_name)
					return layer as WMSLayer;
			}
			
			return null;
			
		}

		public function toGetCapabilitiesRequest(): URLRequest
		{
			var r: URLRequest = toRequest("GetCapabilities");
			return r;
		}

		public function queryCapabilities(): void
		{
//			trace(this + ' queryCapabilities: ' + fullURL);
			var r: URLRequest = toGetCapabilitiesRequest();
			m_capabilitiesLoader.load(r);
			if (m_capabilitiesLoadJob != null)
				m_capabilitiesLoadJob.finish();
			m_capabilitiesLoadJob = BackgroundJobManager.getInstance().startJob(
					"Getting WMS capabilities for " + baseURL);
		}

		protected function onCapabilitiesLoaded(event: UniURLLoaderEvent): void
		{
			if (!m_capabilitiesLoadJob)
			{
				trace("ERROR m_capabilitiesLoadJob IS null:" + id)
				//				return;
			} else {
				//				trace("m_capabilitiesLoadJob loaded:" + id);
				m_capabilitiesLoadJob.finish();
				m_capabilitiesLoadJob = null;
			}
			
			//			LoggingUtils.dispatchLogEvent(this, 'WMSServiceConfiguration onCapabilitiesLoaded: ' + fullURL);
			
			mb_capabilitiesUpdated = true;
			//			trace(this + " onCapabilitiesLoaded");
			if (event.result is XML)
			{
				_xml = event.result as XML;
				var sce: ServiceCapabilitiesEvent = new ServiceCapabilitiesEvent(ServiceCapabilitiesEvent.CAPABILITIES_LOADED, true);
				sce.service = this;
				sce.xml = _xml;
				dispatchEvent(sce);
				parseGetCapabilities(_xml);
			}
		}
		
		protected function onCapabilitiesLoadFailed(event: UniURLLoaderErrorEvent): void
		{
			if (m_capabilitiesLoadJob)
				m_capabilitiesLoadJob.finish();
			m_capabilitiesLoadJob = null;
			// keep old m_capabilities
			
			var e: ServiceCapabilitiesEvent = new ServiceCapabilitiesEvent(ServiceCapabilitiesEvent.CAPABILITIES_UPDATE_FAILED, true);
			e.errorString = 'Can not load "'+event.request.url+'" service';
			dispatchEvent(e);
		}
		
		override public function update(): void
		{
			super.update();
			if (enabled)
				queryCapabilities();
		}

		public function get rootLayers(): Array
		{
			return ma_rootLayers;
		}
		public function get allLayers(): Array
		{
			return ma_allLayers;
		}
		

		public function populateLayerCapabilities(layerXML: XML): void
		{
//			trace("\n populateLayerCapabilities");
			var s_version: String = layerXML.@version;
			var version: Version = Version.fromString(s_version);
			var wms: Namespace = version.isLessThan(1, 3, 0)
				? new Namespace() : new Namespace("http://www.opengis.net/wms");
			
			try
			{
				var layerGroup: WMSLayerGroup = new WMSLayerGroup(null, layerXML, wms, version);
                new GetCapabilitiesParser().createLayersXMLDictionary(layerXML, m_layersXMLDictionary, wms);
			}
			catch (e: Error)
			{
				trace("WMSServiceConfiguration error: " + e.message);
			}
				
			layerGroup.initialize();
			layerGroup.parse();
			
			//TODO add it to layers
			addParseLayer(layerGroup);
		}
		
		private function addParseLayer(layer: WMSLayerBase): void
		{
			ma_rootLayers.push(layer);
			enumerateAllLayers();
		}
		private function enumerateAllLayers(): void
		{
			var allLayers: Array = [];
			for each (var layer: WMSLayerBase in ma_rootLayers)
			{
				var currLayers: Array = [];
				if (layer is WMSLayerGroup)
				{
					enumerateLayerGrop(allLayers, layer as WMSLayerGroup);
//					ArrayUtils.unionArrays(allLayers, .layers);
				} else if (layer is WMSLayer) {
					ArrayUtils.unionArrays(allLayers, [layer]);
				}
			}
			ma_allLayers = allLayers;
		}
		private function enumerateLayerGrop(destArray: Array, layerGroup: WMSLayerGroup): void
		{
			var groupLayers: Array = layerGroup.layers;
			for each (var layer: WMSLayerBase in groupLayers)
			{
//				var currLayers: Array = [];
				if (layer is WMSLayerGroup)
				{
					enumerateLayerGrop(destArray, layer as WMSLayerGroup);
				} else if (layer is WMSLayer) {
					ArrayUtils.unionArrays(destArray, [layer]);
				}
			}
		}
		
		public function populateGetCapabilities(xml: XML): void
		{
			var currAllowedParsing: Boolean = PARSE_GET_CAPABILITIES;
			
			PARSE_GET_CAPABILITIES = true;
			parseGetCapabilities(xml);
			PARSE_GET_CAPABILITIES = currAllowedParsing;
		}
		
		protected function beforeParseGetCapabilities(): void
		{
			if (ma_rootLayers)
				ma_rootLayers.splice(0, ma_rootLayers.length);
			if (ma_allLayers)
				ma_allLayers.splice(0, ma_allLayers.length);
		}
		public function parseGetCapabilities(xml: XML): void
		{
			beforeParseGetCapabilities();
			
//			trace("\nparseGetCapabilities fullURL: " + fullURL);
			var s_version: String = xml.@version;
			version = Version.fromString(s_version);
			wms = version.isLessThan(1, 3, 0) ? new Namespace() : new Namespace("http://www.opengis.net/wms");
			
			var capability: XML = xml.wms::Capability[0];
			
			var time: Number = getTimer();
			
			getGetMapImageFormats(capability);
			
			if (capability != null)
			{
				
				var layerGroup: WMSLayerGroup
				if (USE_ASYNCHRONOUS_PARSING)
				{
					var parsingManager: WMSServiceParsingManager = new WMSServiceParsingManager('wmsServiceParsingManager');
					parsingManager.maxCallsPerTick = 50;
					parsingManager.xml = xml;
					parsingManager.addEventListener(AsyncManager.EMPTY, onGetCapabilitiesInitialized);
				}
				
				try
				{
					
					var layer: XML = capability.wms::Layer[0];
					
					if (EXPERIMENTAL_LAYERS_INITIALIZING)
					{
						new GetCapabilitiesParser().createLayersXMLDictionary(layer, m_layersXMLDictionary, wms);
					} else {
						layerGroup = new WMSLayerGroup(null, layer, wms, version);
					
						if (USE_ASYNCHRONOUS_PARSING) {
							layerGroup.initialize(parsingManager);
							parsingManager.start();
						} else
							layerGroup.initialize();
					}
					
					
				}
				catch (e: Error)
				{
					trace("WMSServiceConfiguration error: " + e.message);
				}
				
				if (!EXPERIMENTAL_LAYERS_INITIALIZING && !USE_ASYNCHRONOUS_PARSING && PARSE_GET_CAPABILITIES)
				{
					layerGroup.parse();
				}
			}
			
			
			//TODO add layerGroup to layers
			addParseLayer(layerGroup);
			
			
			if (!USE_ASYNCHRONOUS_PARSING && PARSE_GET_CAPABILITIES)
			{
				addSupportedProjections();
				
				m_capabilities = xml;
				dispatchEvent(new ServiceCapabilitiesEvent(ServiceCapabilitiesEvent.CAPABILITIES_UPDATED, true));
			}
			
//			trace("WMSServiceConfiguration: " + fullURL + " parsing time: " + (getTimer() - time) + "ms\n");
		}
		
		
		
		private function onGetCapabilitiesInitialized(event: Event): void
		{
//			trace("onGetCapabilitiesInitialized");
			
			if (PARSE_GET_CAPABILITIES) {
//				trace("Start PARSING");
			
				var parsingManager: WMSServiceParsingManager = event.target as WMSServiceParsingManager;
				parsingManager.removeEventListener(AsyncManager.EMPTY, onGetCapabilitiesInitialized);
				
				parsingManager.maxCallsPerTick = 5;
				parsingManager.addEventListener(AsyncManager.EMPTY, onGetCapabilitiesParsed);
			
				//TODO what should be parsed here
//				m_layers.parse(parsingManager);
				for each (var layer: WMSLayerBase in ma_rootLayers)
				{
					layer.parse(parsingManager);
				}
				
				parsingManager.start();
				
			} else {
				finishGetCapabitilitiesParsing(parsingManager.xml, parsingManager);
			}
			
		}
		private function onGetCapabilitiesParsed(event: Event): void
		{
			trace("onGetCapabilitiesParsed");
			var parsingManager: WMSServiceParsingManager = event.target as WMSServiceParsingManager;
			parsingManager.removeEventListener(AsyncManager.EMPTY, onGetCapabilitiesParsed);
			
			finishGetCapabitilitiesParsing(parsingManager.xml, parsingManager);
		}
		
		private function finishGetCapabitilitiesParsing(xml: XML, parsingManager: WMSServiceParsingManager = null): void
		{
			
			m_capabilities = xml;
			dispatchEvent(new ServiceCapabilitiesEvent(ServiceCapabilitiesEvent.CAPABILITIES_UPDATED, true));
			
			if (USE_ASYNCHRONOUS_PARSING) {
				parsingManager.xml = null;
				parsingManager = null;
			}
		}
		
		private function addSupportedProjections(): void
		{
			//check all crs
//			if (m_layers && m_layers.layers)
//			{
//				var allLayers: Array = m_layers.layers;
				//TODO how we get all layers
				var allLayers: Array = ma_allLayers;
				
//				trace(this + " addSupportedProjections: " + ma_allLayers.length + " total: " + ma_rootLayers.length);
				var projectionManager: ProjectionConfigurationManager = ProjectionConfigurationManager.getInstance();
				projectionManager.removeParsedProjections();
				var projConfig: ProjectionConfiguration;
				for each (var currLayer: WMSLayerBase in allLayers)
				{
					var crsColl: Array = currLayer.crsWithBBoxes;
					var newBBox: BBox;
					for each (var crs: CRSWithBBox in crsColl)
					{
						if (crs.bbox)
							newBBox = crs.bbox.clone();
						projConfig = new ProjectionConfiguration(crs.crs, newBBox);
						projectionManager.addParsedProjectionByCRS(projConfig);
					}
				}
				projectionManager.initializeParsedProjections();
//			}
		}

		private function getGetMapImageFormats(xml: XML): void
		{
			if (xml)
			{
				var wms: Namespace = version.isLessThan(1, 3, 0)
					? new Namespace() : new Namespace("http://www.opengis.net/wms");
				var xml1: XML = xml.wms::Request[0] as XML;
				var xml2: XML = xml1.wms::GetMap[0] as XML;
				var formatsXML: XMLList = xml2.wms::Format;
				if (formatsXML)
				{
					for each (var format: XML in formatsXML)
					{
						var imageFormat: String = format.valueOf();
						if (imageFormat && (imageFormat.indexOf('png') >= 0 || imageFormat.indexOf('jpg') >= 0 || imageFormat.indexOf('jpeg') >= 0 || imageFormat.indexOf('x-shockwave-flash') >= 0))
						{
							if (!imageFormatExist(imageFormat))
								_imageFormats.push(imageFormat);
						}
					}
				}
			}
		}
		
		private function imageFormatExist(imageFormat: String): Boolean
		{
			for each (var format: String in _imageFormats)
			{
				if (format == imageFormat)
					return true;
			}
			return false;
		}
		
		

//		public function get rootLayerGroup(): WMSLayerGroup
//		{
//			return m_layers;
//		}
		
		override public function toString(): String
		{
			return "WMSServiceConfiguration " + id + " / " + fullURL + " capabilitiesUpdated: " + capabilitiesUpdated;
		}
	}
}
import com.iblsoft.flexiweather.ogc.Version;
import com.iblsoft.flexiweather.ogc.WMSLayer;
import com.iblsoft.flexiweather.ogc.WMSLayerBase;
import com.iblsoft.flexiweather.ogc.WMSLayerGroup;

import flash.utils.Dictionary;

/**
 * This class is helper class to fill m_layersXMLDictionary Dictionary with XML for each layer or Group
 *  
 * @author Franto
 * 
 */
class GetCapabilitiesParser 
{
	private var wms: Namespace;
	
	public function createLayersXMLDictionary(layerXML: XML, m_layersXMLDictionary: Dictionary, wms: Namespace): void
	{
		this.wms = wms;
		
		var bQueryable: Boolean = layerXML.@queryable;
		var layers: XMLList = layerXML.wms::Layer;
		var total: int = layers.length();
		
		if (bQueryable)
		{
			var name: String = getLayerXMLName(layerXML);
			m_layersXMLDictionary[name] = layerXML;
		}
		if (total > 0) {
			//it's subgroup
			for (var i: int = 0; i < total; i++)
			{
				var layer: XML = layers[i] as XML;
				createLayersXMLDictionary(layer, m_layersXMLDictionary, wms);
			}
		} 
	}
	
	private function getLayerXMLName(layerXML: XML): String
	{
		var name: String = String(layerXML.wms::Name);
		if (name == '')
			name = String(layerXML.wms::Title);
		
		return name;
	}
}

class LayerXMLHelper
{
	public var name: String;
	public var xml: XML;
	public var layer: WMSLayerBase;
	
	private var wms: Namespace;
	private var version: Version;
	private var m_layersXMLDictionary: Dictionary;
	
	public function LayerXMLHelper(layersXMLDictionary: Dictionary, wms: Namespace, version: Version)
	{
		this.wms = wms;
		this.version = version;
		this.m_layersXMLDictionary = layersXMLDictionary;
	}
	
	public function createLayerGroup(s_name: String, layerXML: XML): WMSLayerGroup
	{
		var wmsLayerGroup: WMSLayerGroup = new WMSLayerGroup(null, layerXML, wms, version);
		
		var parentLayer: WMSLayerBase = getLayerXMLParent(s_name, wmsLayerGroup);
		
		wmsLayerGroup.initialize();
		wmsLayerGroup.parse();
		
		m_layersXMLDictionary[s_name] = wmsLayerGroup;
		
		return wmsLayerGroup;
	}
	public function createLayer(s_name: String, layerXML: XML): WMSLayer
	{
		var wmsLayer: WMSLayer = new WMSLayer(null, layerXML as XML, wms, version);
		
		var parentLayer: WMSLayerBase = getLayerXMLParent(s_name, wmsLayer);
		
		wmsLayer.initialize();
		wmsLayer.parse();
		
		m_layersXMLDictionary[s_name] = wmsLayer;
		
		return wmsLayer as WMSLayer;
	}
	
	private function getLayerXMLParent(s_layerName: String, layer: WMSLayerBase): WMSLayerBase
	{
		var layerXML: XML = layer.itemXML;
		var parentLayer: WMSLayerGroup;
		
		if(layerXML)
		{
			var parentXML: XML = (layerXML as XML).parent();
			if (parentXML)
			{
				var currLayerName: String = getLayerXMLName(parentXML);
				var dictionaryItem: Object = m_layersXMLDictionary[currLayerName];
				if (dictionaryItem is XML)
				{
					var isGroup: Boolean = isLayerXMLGroup(currLayerName);
					if (isGroup)
					{
						parentLayer = createLayerGroup(currLayerName, parentXML);
					} else {
						trace("Parent should be always group and has layer children");
						//parentLayer = createLayer(currLayerName, parentXML);
					}
				} else if (dictionaryItem is WMSLayerBase) {
					parentLayer = dictionaryItem as WMSLayerGroup;
				}
				
				if (parentLayer)
				{
					//check if layer is already in parent group;
					var childLayer: WMSLayerBase = parentLayer.getLayerByName(s_layerName);
					if (!childLayer)
					{
						//layer is not there, add it to the parent
						parentLayer.addLayer(layer);
						
					}
//					getLayerXMLParent(currLayerName, parentLayer);
				}
			}
		}
		return parentLayer;
		
	}
	
	private function isLayerXMLGroup(s_name: String): Boolean
	{
		var item: Object = m_layersXMLDictionary[s_name];
		if (item && item is XML)
		{
			var currXML: XML = item as XML;
			var layers: XMLList = currXML.wms::Layer;
			var total: int = layers.length();
			
			
			return total > 0;
		}
		return false;
	}
	
	private function getLayerXMLName(layerXML: XML = null): String
	{
		if (!layerXML)
			layerXML = xml;
		
		var name: String = String(layerXML.wms::Name);
		if (name == '')
			name = String(layerXML.wms::Title);
		
		return name;
	}
}
