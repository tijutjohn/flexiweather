package com.iblsoft.flexiweather.ogc
{
	import com.iblsoft.flexiweather.ILayerConfiguration;
	import com.iblsoft.flexiweather.utils.Storage;
	
	public class OGCLayerConfiguration extends LayerConfiguration implements ILayerConfiguration
	{
		// runtime variable
		protected var m_service: OGCServiceConfiguration;

		public function OGCLayerConfiguration(service: OGCServiceConfiguration = null)
		{
			super();
			m_service = service;
		}

		override public function serialize(storage: Storage): void
		{
			super.serialize(storage);
			if(storage.isLoading()) {
				// dynamically link to OGCServiceConfiguration instance  
				var s_url: String = storage.serializeString("service-url", null);
				var s_version: String = storage.serializeString("protocol-version", null);

				m_service = OGCServiceConfigurationManager.getInstance().getService(
						s_url, Version.fromString(s_version), WMSServiceConfiguration) as
								WMSServiceConfiguration;
			} else {
				// serialise properties of linked OGCServiceConfiguration instance  
				storage.serializeString("service-url", m_service.fullURL);
				storage.serializeString("protocol-version", m_service.version.toString());
			}
		}
		
		public function get serviceType(): String
		{ return "WMS"; }
	}
}