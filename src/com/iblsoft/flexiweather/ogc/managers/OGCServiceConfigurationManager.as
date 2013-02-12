package com.iblsoft.flexiweather.ogc.managers
{
	import com.iblsoft.flexiweather.ogc.Version;
	import com.iblsoft.flexiweather.ogc.configuration.services.OGCServiceConfiguration;
	import com.iblsoft.flexiweather.ogc.configuration.services.WMSServiceConfiguration;
	import com.iblsoft.flexiweather.utils.LoggingUtils;
	import com.iblsoft.flexiweather.utils.LoggingUtilsEvent;
	import com.iblsoft.flexiweather.utils.Serializable;
	import com.iblsoft.flexiweather.utils.Storage;
	
	import flash.events.DataEvent;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.TimerEvent;
	import flash.utils.Timer;
	import flash.utils.getTimer;
	
	import mx.collections.ArrayCollection;

	public class OGCServiceConfigurationManager extends EventDispatcher implements Serializable
	{
		private static var sm_instance: OGCServiceConfigurationManager;
		private var ma_services: ArrayCollection = new ArrayCollection();
		private var m_timer: Timer = new Timer(500);

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

		public function getServiceByName(serviceName: String): OGCServiceConfiguration
		{
			for each (var osc: OGCServiceConfiguration in ma_services)
			{
//				if (osc.id == serviceName)
				if (osc.baseURL == serviceName)
					return osc;
			}
			return null;
		}

		private function stopAllRunningServices(): void
		{
			for each (var wmsServiceConfiguration: WMSServiceConfiguration in _runningServices)
			{
				wmsServiceConfiguration.removeEventListener(WMSServiceConfiguration.CAPABILITIES_UPDATED, onCapabilitiesUpdated);
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
						wmsServiceConfiguration.addEventListener(WMSServiceConfiguration.CAPABILITIES_UPDATED, onCapabilitiesUpdated);
					}
					osc.update();
					osc.mi_lastUpdateFlashStamp = i_currentFlashStamp;
				}
			}
		}

		private function onCapabilitiesUpdated(event: DataEvent): void
		{
			var wmsServiceConfiguration: WMSServiceConfiguration = event.target as WMSServiceConfiguration;
//			wmsServiceConfiguration.capabilitiesUpdated = true;
			
			dispatchEvent(new Event(WMSServiceConfiguration.CAPABILITIES_UPDATED, true));
			m_servicesUpdating--;
			if (m_servicesUpdating == 0)
			{
				allCapabilitiesAreUpdated();
			}
		}
		
		private function allCapabilitiesAreUpdated(): void
		{
			dispatchEvent(new Event(WMSServiceConfiguration.ALL_CAPABILITIES_UPDATED, true));
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