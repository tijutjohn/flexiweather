package com.iblsoft.flexiweather.ogc
{
	import com.iblsoft.flexiweather.utils.UniURLLoader;
	import com.iblsoft.flexiweather.utils.UniURLLoaderEvent;
	import com.iblsoft.flexiweather.widgets.BackgroundJob;
	import com.iblsoft.flexiweather.widgets.BackgroundJobManager;
	
	import flash.events.DataEvent;
	import flash.net.URLRequest;
	
	public class WMSServiceConfiguration extends OGCServiceConfiguration
	{
		public var id: String;
		
		internal var m_capabilitiesLoader: UniURLLoader = new UniURLLoader();
		internal var m_capabilities: XML = null;
		internal var m_capabilitiesLoadJob: BackgroundJob = null;
		
		internal var m_layers: WMSLayerGroup = null;
		
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
			//r.data.FORMAT = "image/png"; 
			return r;
		}

		public function queryCapabilities(): void
		{
			var r: URLRequest = toGetCapabilitiesRequest();
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
		
		protected function onCapabilitiesLoaded(event: UniURLLoaderEvent): void
		{
			if (!m_capabilitiesLoadJob)
			{
				trace("ERROR m_capabilitiesLoadJob IS null")
				return;
			}
			m_capabilitiesLoadJob.finish();
			m_capabilitiesLoadJob = null;
			if(event.result is XML) {
				var xml: XML = event.result as XML;
				
				var s_version: String = xml.@version;
				var version: Version = Version.fromString(s_version);
				var wms: Namespace = version.isLessThan(1, 3, 0)
						? new Namespace() : new Namespace("http://www.opengis.net/wms"); 
				var capability: XML = xml.wms::Capability[0];
				if(capability != null) {
					var layer: XML = capability.wms::Layer[0];
					m_layers = new WMSLayerGroup(null, layer, wms, version);
	
					m_capabilities = xml;
					dispatchEvent(new DataEvent(CAPABILITIES_UPDATED));
				}
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
