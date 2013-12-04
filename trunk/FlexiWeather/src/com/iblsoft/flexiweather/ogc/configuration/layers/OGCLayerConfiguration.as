package com.iblsoft.flexiweather.ogc.configuration.layers
{
	import com.iblsoft.flexiweather.ogc.Version;
	import com.iblsoft.flexiweather.ogc.configuration.layers.interfaces.ILayerConfiguration;
	import com.iblsoft.flexiweather.ogc.configuration.services.OGCServiceConfiguration;
	import com.iblsoft.flexiweather.ogc.managers.OGCServiceConfigurationManager;
	import com.iblsoft.flexiweather.utils.Storage;
	import com.iblsoft.flexiweather.ogc.configuration.services.WMSServiceConfiguration;

	public class OGCLayerConfiguration extends LayerConfiguration implements ILayerConfiguration
	{
		Storage.addChangedClass('com.iblsoft.flexiweather.ogc.OGCLayerConfiguration', 'com.iblsoft.flexiweather.ogc.configuration.layers.OGCLayerConfiguration', new Version(1, 6, 0));
		// runtime variable
		protected var m_service: OGCServiceConfiguration;

		public function OGCLayerConfiguration(service: OGCServiceConfiguration = null)
		{
			super();
			m_service = service;
		}


		public function get service():OGCServiceConfiguration
		{
			return m_service;
		}

		public function set service(value:OGCServiceConfiguration):void
		{
			unregisterService();
			
			m_service = value;
			
			registerService();
		}

		override public function destroy(): void
		{
			super.destroy();
			m_service = null;
		}

		override public function serialize(storage: Storage): void
		{
			super.serialize(storage);
			if (storage.isLoading())
			{
				// dynamically link to OGCServiceConfiguration instance  
//				var s_id: String = storage.serializeString("id", null);
				var s_url: String = storage.serializeString("service-url", null);
				var s_version: String = storage.serializeString("protocol-version", null);
				//FRANTO change s_id to s_url
				m_service = OGCServiceConfigurationManager.getInstance().getService(
						s_url,
						s_url, Version.fromString(s_version), WMSServiceConfiguration) as
						WMSServiceConfiguration;
			}
			else
			{
				// serialise properties of linked OGCServiceConfiguration instance  
				storage.serializeString("service-url", m_service.fullURL);
				storage.serializeString("protocol-version", m_service.version.toString());
			}
		}

		protected function registerService(): void
		{
		}
		
		protected function unregisterService(): void
		{
		}
		
		public function get serviceType(): String
		{
			return "WMS";
		}
	}
}
