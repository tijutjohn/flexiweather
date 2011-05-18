package com.iblsoft.flexiweather.ogc
{
	import com.iblsoft.flexiweather.utils.UniURLLoader;
	import com.iblsoft.flexiweather.utils.UniURLLoaderEvent;
	import com.iblsoft.flexiweather.widgets.BackgroundJob;
	import com.iblsoft.flexiweather.widgets.BackgroundJobManager;
	
	import flash.events.DataEvent;
	import flash.net.URLRequest;
	
	import mx.collections.ArrayCollection;
	
	public class WMSServiceConfiguration extends OGCServiceConfiguration
	{
		public var id: String;
		
		internal var m_capabilitiesLoader: UniURLLoader = new UniURLLoader();
		internal var m_capabilities: XML = null;
		internal var m_capabilitiesLoadJob: BackgroundJob = null;
		
		internal var m_layers: WMSLayerGroup = null;
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
			m_capabilitiesLoader.addEventListener(UniURLLoader.DATA_LOADED, onCapabilitiesLoaded);
			m_capabilitiesLoader.addEventListener(UniURLLoader.DATA_LOAD_FAILED, onCapabilitiesLoadFailed);
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
//			trace("queryCapabilities: " + r.url);
			m_capabilitiesLoader.load(r);
			if(m_capabilitiesLoadJob != null)
				m_capabilitiesLoadJob.finish();
			m_capabilitiesLoadJob = BackgroundJobManager.getInstance().startJob(
					"Getting WMS capabilities for " + ms_baseURL);
		}
		
		override internal function update(): void
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
				
				if (xml2)
				{
					var formatsXML: XMLList = xml2.wms::Format;
					if (formatsXML)
					{
						for each (var format: XML in formatsXML)
						{
							var imageFormat: String = format.valueOf();
							if (imageFormat && (imageFormat.indexOf('png') >= 0 || imageFormat.indexOf('jpg') >= 0 || imageFormat.indexOf('jpeg') >= 0))
							{
								_imageFormats.push(imageFormat);
							}
						}
					}
				}
			}
		}
		protected function onCapabilitiesLoaded(event: UniURLLoaderEvent): void
		{
			if (!m_capabilitiesLoadJob)
			{
				trace("ERROR m_capabilitiesLoadJob IS null")
				return;
			}
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
					var layer: XML = capability.wms::Layer[0];
					m_layers = new WMSLayerGroup(null, layer, wms, version);
	
					m_capabilities = xml;
					dispatchEvent(new DataEvent(CAPABILITIES_UPDATED));
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
					for each (var crs: CRSWithBBox in crsColl)
					{
						projConfig = new ProjectionConfiguration(crs.crs, crs.bbox.clone());
						projectionManager.addParsedProjectionByCRS(projConfig);
					}
				}
				projectionManager.initializeParsedProjections();
			}
		}

		protected function onCapabilitiesLoadFailed(event: UniURLLoaderEvent): void
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
