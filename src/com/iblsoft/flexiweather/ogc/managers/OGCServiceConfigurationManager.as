package com.iblsoft.flexiweather.ogc.managers
{
	import com.iblsoft.flexiweather.net.events.UniURLLoaderErrorEvent;
	import com.iblsoft.flexiweather.ogc.Version;
	import com.iblsoft.flexiweather.ogc.configuration.services.OGCServiceConfiguration;
	import com.iblsoft.flexiweather.ogc.configuration.services.ServiceSerializableSelector;
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
		/**
		 * Interval in miliseconds, which will manager wait after completing service update and calling update method of next service waiting in queue
		 * Implement for OW-428
		 */
		public static var INTERVAL_BEFORE_UPDATE_NEXT_SERVICE: int = 300;
		public static var PARALLEL_LOADING: Boolean = true;

		private static var sm_instance: OGCServiceConfigurationManager;
		private var ma_services: ArrayCollection = new ArrayCollection();

		private var _currentServices: Array = [];

		private var m_timer: Timer;

		private var m_capabilitiesLoader: GetCapabilitiesLoader;

		[Bindable (event="servicesUpdatingChanged")]
		public function get servicesUpdating():int
		{
			if (m_capabilitiesLoader)
				return m_capabilitiesLoader.servicesUpdating;

			return 0;
		}

		[Bindable (event="currentServicesChanged")]
		public function get totalServices():int
		{
			if (_currentServices)
				return _currentServices.length;

			return 0;
		}

		public function OGCServiceConfigurationManager(timeInterval: int = 60000)
		{
			if (sm_instance != null)
				throw new Error("OGCServiceManager can only be accessed through OGCServiceManager.getIntstance()");

			m_timer = new Timer(timeInterval);
			m_timer.stop();
			m_timer.addEventListener(TimerEvent.TIMER, onTimer);

			m_capabilitiesLoader = new GetCapabilitiesLoader(this);
			m_capabilitiesLoader.addEventListener(ServiceCapabilitiesEvent.CAPABILITIES_LOADED, onCapabilitiesLoaded);
			m_capabilitiesLoader.addEventListener(ServiceCapabilitiesEvent.CAPABILITIES_UPDATED, onCapabilitiesUpdated);
			m_capabilitiesLoader.addEventListener(ServiceCapabilitiesEvent.CAPABILITIES_UPDATE_FAILED, onCapabilitiesUpdateFailed);
			m_capabilitiesLoader.addEventListener(ServiceCapabilitiesEvent.ALL_CAPABILITIES_UPDATED, allCapabilitiesAreUpdated);

		}



		public static function getInstance(): OGCServiceConfigurationManager
		{
			if (sm_instance == null)
				sm_instance = new OGCServiceConfigurationManager();
			return sm_instance;
		}

		public function serialize(storage: Storage): void
		{
			storage.serializeNonpersistentArrayCollection("service", ma_services, ServiceSerializableSelector);
			if (storage.isLoading())
			{
				if (ma_services.length > 0 && !m_timer.running)
					m_timer.start();
			}
		}

		public function destroy(): void
		{
			trace("OGCServiceConfigurationManager destroy");
			if (m_timer)
			{
				m_timer.stop();
				m_timer.removeEventListener(TimerEvent.TIMER, onTimer);
				m_timer = null;
			}

			_currentServices = null;

			m_capabilitiesLoader.removeEventListener(ServiceCapabilitiesEvent.CAPABILITIES_LOADED, onCapabilitiesLoaded);
			m_capabilitiesLoader.removeEventListener(ServiceCapabilitiesEvent.CAPABILITIES_UPDATED, onCapabilitiesUpdated);
			m_capabilitiesLoader.removeEventListener(ServiceCapabilitiesEvent.CAPABILITIES_UPDATE_FAILED, onCapabilitiesUpdateFailed);
			m_capabilitiesLoader.removeEventListener(ServiceCapabilitiesEvent.ALL_CAPABILITIES_UPDATED, allCapabilitiesAreUpdated);
			m_capabilitiesLoader.destroy();

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
			trace("OGCServiceManager addService: " + osc.toString());
			if (osc.name.indexOf('obser') >= 0)
				trace("check observations");

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
			m_capabilitiesLoader.stopAllRunningServices();

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
//					if (osc is WMSServiceConfiguration)
//					{
//						var wmsServiceConfiguration: WMSServiceConfiguration = osc as WMSServiceConfiguration;
//					}
//					trace("OGCServiceManager udpate: " + osc.toString());
					m_capabilitiesLoader.addToQueue(osc);
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
//			capabilitiesUpdated();

		}

		private function onCapabilitiesUpdated(event: ServiceCapabilitiesEvent): void
		{
			dispatchEvent(event);
//			capabilitiesUpdated();
		}

		private function capabilitiesUpdated(): void
		{
//			var wmsServiceConfiguration: WMSServiceConfiguration = event.target as WMSServiceConfiguration;
//			wmsServiceConfiguration.capabilitiesUpdated = true;

//			dispatchEvent(new Event(WMSServiceConfiguration.CAPABILITIES_UPDATED, true));
//			servicesUpdating--;
//			if (servicesUpdating == 0)
//			{
//				allCapabilitiesAreUpdated();
//			}
		}

		private function allCapabilitiesAreUpdated(event: ServiceCapabilitiesEvent): void
		{
			dispatchEvent(event);
//			dispatchEvent(new ServiceCapabilitiesEvent(ServiceCapabilitiesEvent.ALL_CAPABILITIES_UPDATED, true));
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
import com.iblsoft.flexiweather.ogc.configuration.services.OGCServiceConfiguration;
import com.iblsoft.flexiweather.ogc.configuration.services.WMSServiceConfiguration;
import com.iblsoft.flexiweather.ogc.events.ServiceCapabilitiesEvent;
import com.iblsoft.flexiweather.ogc.managers.OGCServiceConfigurationManager;

import flash.events.EventDispatcher;
import flash.utils.getTimer;
import flash.utils.setTimeout;

class GetCapabilitiesLoader extends EventDispatcher
{
	private var _runningServices: Array = [];
	private var _queuedServices: Array = [];
	private var _manager: OGCServiceConfigurationManager;

	private var mb_allServicesUpdated: Boolean;

	private var m_timeOfLastUpdate: Number;
	private var m_currentService: OGCServiceConfiguration;

	private var m_servicesUpdating: int;

	public function get servicesUpdating():int
	{
		return m_servicesUpdating;
	}

	public function set servicesUpdating(value:int):void
	{
		m_servicesUpdating = value;
	}

	public function GetCapabilitiesLoader(manager: OGCServiceConfigurationManager)
	{
		_manager = manager;
		m_timeOfLastUpdate = getTimer();
	}

	public function addToQueue(osc: OGCServiceConfiguration): void
	{
		debug("addToQueue: " + osc);
		if (osc is WMSServiceConfiguration)
		{
			mb_allServicesUpdated = false;

			var wmsServiceConfiguration: WMSServiceConfiguration = osc as WMSServiceConfiguration;
			_queuedServices.push(wmsServiceConfiguration);
			servicesUpdating++;

			scheduleUpdateNextService();

		}
	}

	private function scheduleUpdateNextService(): void
	{
		var currTime: Number = getTimer();
		var diffTime: Number = currTime - m_timeOfLastUpdate;

		debug("scheduleUpdateNextService: " + diffTime + "ms, m_currentService: " + m_currentService);

		if (OGCServiceConfigurationManager.PARALLEL_LOADING)
		{
			updateNextService();
		} else {
			if (diffTime >= OGCServiceConfigurationManager.INTERVAL_BEFORE_UPDATE_NEXT_SERVICE)
			{
				if (!m_currentService)
				{
					updateNextService();
				}
			} else {
				//need wait
				var waitTime: Number = OGCServiceConfigurationManager.INTERVAL_BEFORE_UPDATE_NEXT_SERVICE - diffTime;
				setTimeout(scheduleUpdateNextService, waitTime);
			}
		}
	}

	private function updateNextService(): void
	{
		if (_queuedServices.length > 0)
		{
			var osc: OGCServiceConfiguration = _queuedServices.shift();
			if (osc)
				updateServiceGetCapabilities(osc);
			else
				trace("why there is null");
		} else {
			if (servicesUpdating > 0)
				setTimeout(checkQueueAfterUpdate, 300);
		}
	}

	private function updateServiceGetCapabilities(osc: OGCServiceConfiguration): void
	{
		debug("updateServiceGetCapabilities: " + osc);

		if (osc is WMSServiceConfiguration)
		{
			var wmsServiceConfiguration: WMSServiceConfiguration = osc as WMSServiceConfiguration;
			_runningServices.push(wmsServiceConfiguration);
			wmsServiceConfiguration.addEventListener(ServiceCapabilitiesEvent.CAPABILITIES_LOADED, onCapabilitiesLoaded);
			wmsServiceConfiguration.addEventListener(ServiceCapabilitiesEvent.CAPABILITIES_UPDATED, onCapabilitiesUpdated);
			wmsServiceConfiguration.addEventListener(ServiceCapabilitiesEvent.CAPABILITIES_UPDATE_FAILED, onCapabilitiesUpdateFailed);
		}

		m_currentService = osc;
		osc.update();
		osc.mi_lastUpdateFlashStamp = getTimer();
	}

	private function onCapabilitiesLoaded(event: ServiceCapabilitiesEvent): void
	{
		debug("onCapabilitiesLoaded: " + event.service);

		dispatchEvent(event);
	}

	private function onCapabilitiesUpdateFailed(event: ServiceCapabilitiesEvent): void
	{
		debug("onCapabilitiesUpdateFailed: " + event.service);
		dispatchEvent(event);
		capabilitiesUpdated();

	}

	private function onCapabilitiesUpdated(event: ServiceCapabilitiesEvent): void
	{
		debug("onCapabilitiesUpdated: " + event.service);
		dispatchEvent(event);
		capabilitiesUpdated();
	}

	private function capabilitiesUpdated(): void
	{
		servicesUpdating--;
		debug("capabilitiesUpdated servicesUpdating: " + servicesUpdating);
		checkQueueAfterUpdate();
	}

	private function checkQueueAfterUpdate(): void
	{
		debug("checkQueueAfterUpdate: servicesUpdating: " + servicesUpdating + " _queuedServices.length: " + _queuedServices.length);
		m_currentService = null;
		if (servicesUpdating == 0 && _queuedServices.length == 0 && !mb_allServicesUpdated)
		{
			mb_allServicesUpdated = true
			dispatchEvent(new ServiceCapabilitiesEvent(ServiceCapabilitiesEvent.ALL_CAPABILITIES_UPDATED, true));
		} else {
			m_timeOfLastUpdate = getTimer();
			scheduleUpdateNextService();
		}
	}

	public function stopAllRunningServices(): void
	{
		debug("stopAllRunningServices: servicesUpdating: " + servicesUpdating);
//		for each (var wmsServiceConfiguration: WMSServiceConfiguration in _runningServices)
//		{
//			wmsServiceConfiguration.removeEventListener(ServiceCapabilitiesEvent.CAPABILITIES_LOADED, onCapabilitiesLoaded);
//			wmsServiceConfiguration.removeEventListener(ServiceCapabilitiesEvent.CAPABILITIES_UPDATED, onCapabilitiesUpdated);
//			wmsServiceConfiguration.removeEventListener(ServiceCapabilitiesEvent.CAPABILITIES_UPDATE_FAILED, onCapabilitiesUpdateFailed);
//		}
		_runningServices = [];
		_queuedServices = [];

		servicesUpdating = 0;
	}

	public function destroy(): void
	{
		debug("destroy");
		_runningServices = null;
	}

	private function debug(str: String, type: String = "Info", tag: String = " GetCapabilitiesLoader"): void
	{
		trace(this + "| " + type + "| " + str);
	}
}