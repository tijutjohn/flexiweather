package com.iblsoft.flexiweather.ogc
{
	import com.iblsoft.flexiweather.net.events.UniURLLoaderErrorEvent;
	import com.iblsoft.flexiweather.net.events.UniURLLoaderEvent;
	import com.iblsoft.flexiweather.net.loaders.UniURLLoader;
	import com.iblsoft.flexiweather.net.loaders.XMLLoader;
	import com.iblsoft.flexiweather.widgets.BackgroundJob;
	import com.iblsoft.flexiweather.widgets.BackgroundJobManager;
	
	import flash.events.DataEvent;
	import flash.net.URLRequest;
	
	import mx.collections.ArrayCollection;
	
	public class WMSServiceConfiguration extends OGCServiceConfiguration
	{
		private var m_capabilitiesLoader: XMLLoader = new XMLLoader();
		private var m_capabilities: XML = null;
		private var m_capabilitiesLoadJob: BackgroundJob = null;
		
		private var mb_capabilitiesUpdated: Boolean;
		public function get capabilitiesUpdated(): Boolean
		{
			return mb_capabilitiesUpdated;
		}
		
		private var m_layers: WMSLayerGroup = null;
		private var _imageFormats: Array = [];
		public function get imageFormats(): Array
		{
			return _imageFormats;
		}
		
		public static const CAPABILITIES_UPDATED: String = "capabilitiesUpdated";

		[Event(name = CAPABILITIES_UPDATED, type = "flash.events.DataEvent")]

		public function WMSServiceConfiguration(s_url: String = null, version: Version = null)
		{
			super(s_url, "wms", version);
			m_capabilitiesLoader.addEventListener(UniURLLoaderEvent.DATA_LOADED, onCapabilitiesLoaded);
			m_capabilitiesLoader.addEventListener(UniURLLoaderErrorEvent.DATA_LOAD_FAILED, onCapabilitiesLoadFailed);
		}
		
		override public function destroy(): void
		{
			super.destroy();
			
			if (m_capabilitiesLoader)
				m_capabilitiesLoader.destroy();
			
			m_capabilitiesLoader = null;
			
			if (m_layers)
				m_layers.destroy();
			m_layers = null;
			_imageFormats = null;
			m_capabilitiesLoadJob = null;
				
			
		}
		public function getLayerByName(s_name: String): WMSLayer
		{
			if(m_layers == null)
				return null;
			return m_layers.getLayerByName(s_name);
		}

		public function toGetCapabilitiesRequest(): URLRequest
		{
			var r: URLRequest = toRequest("GetCapabilities");
			return r;
		}

		public function queryCapabilities(): void
		{
			var r: URLRequest = toGetCapabilitiesRequest();
			m_capabilitiesLoader.load(r);
			
			if(m_capabilitiesLoadJob != null)
				m_capabilitiesLoadJob.finish();
			
			m_capabilitiesLoadJob = BackgroundJobManager.getInstance().startJob(
					"Getting WMS capabilities for " + baseURL);
		}
		
		override public function update(): void
		{
			super.update();
			if(enabled)
				queryCapabilities();
		}
		
		public function get layers(): WMSLayerGroup
		{ return m_layers; }
		
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
						if (imageFormat && (imageFormat.indexOf('png') >= 0 || imageFormat.indexOf('jpg') >= 0 || imageFormat.indexOf('jpeg') >= 0))
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
		
		protected function onCapabilitiesLoaded(event: UniURLLoaderEvent): void
		{
			if (!m_capabilitiesLoadJob)
			{
				trace("ERROR m_capabilitiesLoadJob IS null")
				return;
			}
			
			mb_capabilitiesUpdated = true;
			
//			trace("onCapabilitiesLoaded: " + event.request.url);
			m_capabilitiesLoadJob.finish();
			m_capabilitiesLoadJob = null;
			if(event.result is XML) {
				var xml: XML = event.result as XML;
				
				var s_version: String = xml.@version;
				var version: Version = Version.fromString(s_version);
				var wms: Namespace = version.isLessThan(1, 3, 0)
						? new Namespace() : new Namespace("http://www.opengis.net/wms"); 
				var capability: XML = xml.wms::Capability[0];
				getGetMapImageFormats(capability);
				
				if(capability != null) {
					try {
						var layer: XML = capability.wms::Layer[0];
						m_layers = new WMSLayerGroup(null, layer, wms, version);
					} catch (e: Error) {
						trace("WMSServiceConfiguration error: " + e.message);
					}
					m_capabilities = xml;
					dispatchEvent(new DataEvent(CAPABILITIES_UPDATED, true));
				}
			}
			
			//check all crs
			if (m_layers && m_layers.layers)
			{
				var projectionManager: ProjectionConfigurationManager = ProjectionConfigurationManager.getInstance();
				
				projectionManager.removeParsedProjections();
				var projConfig: ProjectionConfiguration;
				
				for each (var currLayer: WMSLayerBase in m_layers.layers)
				{
					var crsColl: ArrayCollection = currLayer.crsWithBBoxes;
//					trace("Layer: " + currLayer.ms_name + " crs: " + crsColl.length);	
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
			}
		}

		protected function onCapabilitiesLoadFailed(event: UniURLLoaderErrorEvent): void
		{
			if (m_capabilitiesLoadJob)
			{
				m_capabilitiesLoadJob.finish();
			}
			m_capabilitiesLoadJob = null;
			// keep old m_capabilities
		}

		public function get rootLayerGroup(): WMSLayerGroup
		{ return m_layers; }
	}
}
