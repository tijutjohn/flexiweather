package com.iblsoft.flexiweather.ogc.managers
{
	import com.iblsoft.flexiweather.net.events.UniURLLoaderErrorEvent;
	import com.iblsoft.flexiweather.ogc.Version;
	import com.iblsoft.flexiweather.ogc.configuration.services.OGCServiceConfiguration;
	import com.iblsoft.flexiweather.ogc.configuration.services.WMSServiceConfiguration;
	import com.iblsoft.flexiweather.ogc.events.ServiceCapabilitiesEvent;
	import com.iblsoft.flexiweather.utils.LoggingUtils;
	import com.iblsoft.flexiweather.utils.Serializable;
	import com.iblsoft.flexiweather.utils.Storage;
	
	import flash.events.DataEvent;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.TimerEvent;
	import flash.utils.Timer;
	import flash.utils.getTimer;
	
	import mx.collections.ArrayCollection;

	[Event (name="serviceCapabilitiesUpdated", type="flash.events.Event")]
	
	[Event (name="allServicesCapabilitiesUpdated", type="flash.events.Event")]
	
	public class OGCServiceConfigurationManager extends EventDispatcher implements Serializable
	{
		private static var sm_instance: OGCServiceConfigurationManager;
		private var ma_services: ArrayCollection = new ArrayCollection();
		private var m_timer: Timer = new Timer(60000);

		private var m_servicesUpdating: int;
		
		public function OGCServiceConfigurationManager()
		{
			if (sm_instance != null)
				throw new Error("OGCServiceManager can only be accessed through OGCServiceManager.getIntstance()");
			m_timer.stop();
			m_timer.addEventListener(TimerEvent.TIMER, onTimer);
		}

		public static function getInstance(): OGCServiceConfigurationManager
		{
			if (sm_instance == null)
				sm_instance = new OGCServiceConfigurationManager();
			return sm_instance;
		}

		public function serialize(storage: Storage): void
		{
			storage.serializeNonpersistentArrayCollection("service", ma_services, WMSServiceConfiguration);
			if (storage.isLoading())
			{
				if (ma_services.length > 0 && !m_timer.running)
					m_timer.start();
			}
		}

		public function destroy(): void
		{
			if (m_timer)
			{
				m_timer.stop();
				m_timer.removeEventListener(TimerEvent.TIMER, onTimer);
				m_timer = null;
			}
			_runningServices = null;
			_currentServices = null;
			for each (var osc: OGCServiceConfiguration in ma_services)
			{
				osc.destroy();
			}
			ma_services.removeAll();
			ma_services = null;
		}

		/**
		 * Will return array of all services baseURLs (prviously IDs) to be able to pair services with layers
		 * @return
		 *
		 */
		public function getAllServicesNames(): Array
		{
			var arr: Array = [];
			for each (var osc: OGCServiceConfiguration in ma_services)
			{
				arr.push(osc.baseURL);
			}
			return arr;
		}

		public function getService(serviceID: String,
				s_fullURL: String, version: Version,
				serviceConfigurationClass: Class): OGCServiceConfiguration
		{
			for each (var sc: Object in ma_services)
			{
				if (!(sc is serviceConfigurationClass))
					continue;
				var osc: OGCServiceConfiguration = sc as OGCServiceConfiguration;
				if (osc.fullURL == s_fullURL && osc.version.equalsVersion(version))
					return osc;
			}
			osc = new serviceConfigurationClass(s_fullURL, version) as OGCServiceConfiguration;
			osc.id = serviceID;
			addService(osc);
			return osc;
		}

		public function addService(osc: OGCServiceConfiguration): void
		{
			ma_services.addItem(osc);
			if (ma_services.length == 1)
				m_timer.start();
		}

		public function removeService(sc: OGCServiceConfiguration): void
		{
			var i: int = ma_services.getItemIndex(sc);
			if (i >= 0)
				ma_services.removeItemAt(i);
			if (ma_services.length == 0)
				m_timer.stop();
		}
		private var _currentServices: Array = [];
		private var _runningServices: Array = [];

		/**
		 * Returns OGCServiceConfiguration defined by name, which is baseURL of OGCServiceConfiguration. If you want just look for string inside baseURL, set bExactName to "false"
		 *  
		 * @param serviceName - name of service (currently is baseURL used)
		 * @param bExactName - if true, name must match exactly, if false it will returns first service with serviceName substring in baseURL
		 * @return 
		 * 
		 */		
		public function getServiceByName(serviceName: String, bExactName: Boolean = true): OGCServiceConfiguration
		{
			for each (var osc: OGCServiceConfiguration in ma_services)
			{
//				if (osc.id == serviceName)
				
				if (bExactName)
				{
					if (osc.baseURL == serviceName)
						return osc;
				} else {
					if (osc.baseURL.indexOf(serviceName) >= 0)
					{
						return osc;
					}
				}
			}
			return null;
		}

		private function stopAllRunningServices(): void
		{
			for each (var wmsServiceConfiguration: WMSServiceConfiguration in _runningServices)
			{
				wmsServiceConfiguration.removeEventListener(ServiceCapabilitiesEvent.CAPABILITIES_LOADED, onCapabilitiesLoaded);
				wmsServiceConfiguration.removeEventListener(ServiceCapabilitiesEvent.CAPABILITIES_UPDATED, onCapabilitiesUpdated);
				wmsServiceConfiguration.removeEventListener(ServiceCapabilitiesEvent.CAPABILITIES_UPDATE_FAILED, onCapabilitiesUpdateFailed);
			}
			_runningServices = [];
		}

		public function updateAllServices(): void
		{
			update(getAllServicesNames());
		}
		
		/**
		 * Update just services, which is in services argument, not all services stored in manager
		 * @param services
		 * @param b_force
		 *
		 */
		public function update(currServices: Array, b_force: Boolean = true): void
		{
			_currentServices = currServices;
			stopAllRunningServices();
			
			m_servicesUpdating = 0;
			var i_currentFlashStamp: int = getTimer();
//			for each(var osc: OGCServiceConfiguration in ma_services) 
			for each (var oscName: String in currServices)
			{
				var osc: OGCServiceConfiguration = getServiceByName(oscName);
				if (osc)
				{
					if (!b_force)
					{
						if (osc.updatePeriod == 0 && osc.mi_lastUpdateFlashStamp != -1000000)
							continue;
						if (osc.mi_lastUpdateFlashStamp + osc.updatePeriod >= i_currentFlashStamp)
							continue;
					}
					if (osc is WMSServiceConfiguration)
					{
						var wmsServiceConfiguration: WMSServiceConfiguration = osc as WMSServiceConfiguration;
						_runningServices.push(wmsServiceConfiguration);
						m_servicesUpdating++;
						wmsServiceConfiguration.addEventListener(ServiceCapabilitiesEvent.CAPABILITIES_LOADED, onCapabilitiesLoaded);
						wmsServiceConfiguration.addEventListener(ServiceCapabilitiesEvent.CAPABILITIES_UPDATED, onCapabilitiesUpdated);
						wmsServiceConfiguration.addEventListener(ServiceCapabilitiesEvent.CAPABILITIES_UPDATE_FAILED, onCapabilitiesUpdateFailed);
					}
					osc.update();
					osc.mi_lastUpdateFlashStamp = i_currentFlashStamp;
				}
			}
		}

		private function onCapabilitiesLoaded(event: ServiceCapabilitiesEvent): void
		{
			dispatchEvent(event);
		}
		
		private function onCapabilitiesUpdateFailed(event: ServiceCapabilitiesEvent): void
		{
			dispatchEvent(event);
			capabilitiesUpdated();
			
		}
		
		private function onCapabilitiesUpdated(event: ServiceCapabilitiesEvent): void
		{
			dispatchEvent(event);
			capabilitiesUpdated();
		}
		
		private function capabilitiesUpdated(): void
		{
//			var wmsServiceConfiguration: WMSServiceConfiguration = event.target as WMSServiceConfiguration;
//			wmsServiceConfiguration.capabilitiesUpdated = true;
			
//			dispatchEvent(new Event(WMSServiceConfiguration.CAPABILITIES_UPDATED, true));
			m_servicesUpdating--;
			if (m_servicesUpdating == 0)
			{
				allCapabilitiesAreUpdated();
			}
		}
		
		private function allCapabilitiesAreUpdated(): void
		{
			dispatchEvent(new ServiceCapabilitiesEvent(ServiceCapabilitiesEvent.ALL_CAPABILITIES_UPDATED, true));
		}

		protected function onTimer(event: TimerEvent): void
		{
			update(_currentServices, false);
		}

		public function get services(): ArrayCollection
		{
			return ma_services;
		}
	}
}
