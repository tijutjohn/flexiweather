package com.iblsoft.flexiweather.ogc
{
	import com.iblsoft.flexiweather.utils.Serializable;
	import com.iblsoft.flexiweather.utils.Storage;
	
	import flash.events.TimerEvent;
	import flash.utils.Timer;
	import flash.utils.getTimer;
	
	import mx.collections.ArrayCollection;

	public class OGCServiceConfigurationManager implements Serializable
	{
		internal static var sm_instance: OGCServiceConfigurationManager;

		internal var ma_services: ArrayCollection = new ArrayCollection();
		
		internal var m_timer: Timer = new Timer(0.5);
		
		public function OGCServiceConfigurationManager()
		{
            if (sm_instance != null) {
                throw new Error("OGCServiceManager can only be accessed through OGCServiceManager.getIntstance()");
            }
            m_timer.stop();
            m_timer.addEventListener(TimerEvent.TIMER, onTimer);
		}
		
		public static function getInstance(): OGCServiceConfigurationManager
		{
			if(sm_instance == null) {
				sm_instance = new OGCServiceConfigurationManager();
			}			
			return sm_instance;
		}
		
		public function serialize(storage: Storage): void
		{
			storage.serializeNonpersistentArrayCollection("service", ma_services, WMSServiceConfiguration);
			if(storage.isLoading()) {
				if(ma_services.length > 0 && !m_timer.running)
					m_timer.start();
			}
		}
		
		public function getService(
				s_fullURL: String, version: Version,
				serviceConfigurationClass: Class): OGCServiceConfiguration
		{
			for each(var sc: Object in ma_services) {
				if(!(sc is serviceConfigurationClass))
					continue;	
				var osc: OGCServiceConfiguration = sc as OGCServiceConfiguration;
				if(osc.fullURL == s_fullURL && osc.version.equalsVersion(version))
					return osc;
			}
			osc = new serviceConfigurationClass(s_fullURL, version) as OGCServiceConfiguration;
			addService(osc);
			return osc;
		}
		
		public function addService(osc: OGCServiceConfiguration): void
		{
			ma_services.addItem(osc);
			if(ma_services.length == 1)
				m_timer.start();
		}

		public function removeService(sc: OGCServiceConfiguration): void
		{
			var i: int = ma_services.getItemIndex(sc);
			if(i >= 0)
				ma_services.removeItemAt(i);
			if(ma_services.length == 0)
				m_timer.stop();
		}
		
		protected function onTimer(event: TimerEvent): void
		{
			var i_currentFlashStamp: int = getTimer();
			for each(var osc: OGCServiceConfiguration in ma_services) {
				if(osc.updatePeriod == 0
						&& osc.mi_lastUpdateFlashStamp != -1000000)
					continue;
				if(osc.mi_lastUpdateFlashStamp + osc.updatePeriod < i_currentFlashStamp) {
					osc.update();
					osc.mi_lastUpdateFlashStamp = i_currentFlashStamp;
				}
			}
		}
		
		public function get services(): ArrayCollection
		{ return ma_services; }
	}
}