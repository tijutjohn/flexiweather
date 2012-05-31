package com.iblsoft.flexiweather.ogc
{
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

		override public function destroy(): void
		{
			super.destroy();	
			
			m_service = null;
		}
		
		override public function serialize(storage: Storage): void
		{
			super.serialize(storage);
			if(storage.isLoading()) {
				// dynamically link to OGCServiceConfiguration instance  
//				var s_id: String = storage.serializeString("id", null);
				var s_url: String = storage.serializeString("service-url", null);
				var s_version: String = storage.serializeString("protocol-version", null);

				//FRANTO change s_id to s_url
				m_service = OGCServiceConfigurationManager.getInstance().getService(
						s_url,
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