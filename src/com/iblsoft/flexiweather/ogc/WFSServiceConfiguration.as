package com.iblsoft.flexiweather.ogc
{
	import com.iblsoft.flexiweather.utils.UniURLLoader;
	import com.iblsoft.flexiweather.utils.UniURLLoaderEvent;
	import com.iblsoft.flexiweather.widgets.BackgroundJob;
	import com.iblsoft.flexiweather.widgets.BackgroundJobManager;
	
	import flash.net.URLRequest;
	
	import mx.collections.ArrayCollection;
	
	public class WFSServiceConfiguration extends OGCServiceConfiguration
	{
		public var id: String;
		
		internal var m_capabilitiesLoader: UniURLLoader = new UniURLLoader();
		internal var m_capabilities: XML = null;
		internal var m_capabilitiesLoadJob: BackgroundJob = null;
		
		internal var m_featureTypes: ArrayCollection = null;
		
		public static const CAPABILITIES_UPDATED: String = "capabilitiesUpdated";

		[Event(name = CAPABILITIES_UPDATED, type = "flash.events.DataEvent")]
		
		public function WFSServiceConfiguration(s_url: String = null, version: Version = null)
		{
			super(s_url, "wfs", version);
			m_capabilitiesLoader.addEventListener(UniURLLoader.DATA_LOADED, onCapabilitiesLoaded);
			m_capabilitiesLoader.addEventListener(UniURLLoader.DATA_LOAD_FAILED, onCapabilitiesLoadFailed);
		}
		
		public function getFeatureTypeByName(s_name: String): WFSFeatureType
		{
			if(m_featureTypes == null)
				return null;
				
			if (m_featureTypes.length > 0)
			{
				for each (var featureType: WFSFeatureType in m_featureTypes)
				{
					if (featureType.name == s_name)
						return featureType;
				}
			}
			return null;
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
					"Getting WFS capabilities for " + ms_baseURL);
		}
		
		override internal function update(): void
		{
			super.update();
			if(enabled)
				queryCapabilities();
		}
		
		public function get featurTypes(): ArrayCollection
		{ return m_featureTypes; }
		
		protected function onCapabilitiesLoaded(event: UniURLLoaderEvent): void
		{
			if (!m_capabilitiesLoadJob)
			{
				trace("ERROR WFS m_capabilitiesLoadJob IS null")
				return;
			}
			m_capabilitiesLoadJob.finish();
			m_capabilitiesLoadJob = null;
			if(event.result is XML) {
				/*
				var xml: XML = event.result as XML;
				
				var s_version: String = xml.@version;
				var version: Version = Version.fromString(s_version);
				var wms: Namespace = version.isLessThan(1, 3, 0)
						? new Namespace() : new Namespace("http://www.opengis.net/wfs"); 
				var capability: XML = xml.wms::Capability[0];
				if(capability != null) {
					var layer: XML = capability.wms::Layer[0];
					m_layers = new WMSLayerGroup(null, layer, wms, version);
	
					m_capabilities = xml;
					dispatchEvent(new DataEvent(CAPABILITIES_UPDATED));
				}
				*/
			}
		}

		protected function onCapabilitiesLoadFailed(event: UniURLLoaderEvent): void
		{
			m_capabilitiesLoadJob.finish();
			m_capabilitiesLoadJob = null;
			// keep old m_capabilities
		}
		
	}
}