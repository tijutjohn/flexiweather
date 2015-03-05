package com.iblsoft.flexiweather.ogc.configuration.services
{
	import com.iblsoft.flexiweather.ogc.wfs.WFSServiceConfiguration;
	import com.iblsoft.flexiweather.utils.SerializableSelector;
	import com.iblsoft.flexiweather.utils.Storage;

	/**
	 * This class is just helper class for serialization "service" tag from configuration and let
	 * Storage serialization process know which class should be used for service serialization dependent on service type
	 * "wms" for WMSServiceConfiguration
	 * "wfs" for WFSServiceConfiguration
	 * @author fkormanak
	 *
	 */
	public class ServiceSerializableSelector implements SerializableSelector
	{
		public var serviceType: String;

		public function ServiceSerializableSelector()
		{
		}

		public function geSerializableClass():Class
		{
			if (serviceType.toLowerCase() == 'wfs')
				return com.iblsoft.flexiweather.ogc.wfs.WFSServiceConfiguration;

			return WMSServiceConfiguration;
		}

		public function serialize(storage:Storage):void
		{
			serviceType = storage.serializeString('service-type', serviceType);
		}
	}
}