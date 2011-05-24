package com.iblsoft.flexiweather.ogc
{
	import com.iblsoft.flexiweather.utils.Serializable;
	import com.iblsoft.flexiweather.utils.Storage;
	
	import flash.events.EventDispatcher;
	import flash.net.URLRequest;
	import flash.net.URLVariables;
	
	public class OGCServiceConfiguration extends EventDispatcher implements Serializable
	{
		internal var ms_fullURL: String;
		internal var ms_service: String;
		internal var m_version: Version;

		internal var mi_updatePeriod: uint; // in ms
		internal var mb_enabled: Boolean =  true;

		// runtime variables
		internal var ms_baseURL: String;
		internal var m_data: URLVariables;
		internal var mi_lastUpdateFlashStamp: int = -1000000;

		public function OGCServiceConfiguration(s_url: String, s_service: String, version: Version)
		{
			ms_fullURL = s_url;
			parseFullURL(s_url);
			ms_service = s_service;
			m_version = version;
		}
		
		public function serialize(storage: Storage): void
		{
			ms_service = storage.serializeString("service-type", ms_service);
			fullURL = storage.serializeString("service-url", ms_fullURL); // set via property
			var s_versionCurrent: String = m_version != null ? m_version.toString() : null;
			var s_version: String = storage.serializeString("protocol-version", s_versionCurrent);
			if(s_version != s_versionCurrent)
				m_version = Version.fromString(s_version);
			mi_updatePeriod = storage.serializeUInt("update-period", mi_updatePeriod, 0);
			mb_enabled = storage.serializeBool("enabled", mb_enabled, true);
//			if(storage.isLoading()) {
//				var s_data: String = storage.serializeString("arguments", null);
//				m_data = s_data != null ? new URLVariables(s_data) : null;
//			}
//			else
//				storage.serializeString("arguments", m_data != null ? m_data.toString() : null);
		}

		public function toRequest(s_request: String): URLRequest
		{
			var r: URLRequest = new URLRequest(ms_baseURL);
			if(m_data == null)
				r.data = new URLVariables();
			else
				r.data = new URLVariables(m_data.toString());
			r.data.SERVICE = ms_service.toUpperCase();
			r.data.VERSION = m_version.toString();
			r.data.REQUEST = s_request;
			return r;
		}
		
		internal function update(): void
		{
		}
		
		private function parseFullURL(s_url: String): void
		{
			if(s_url == null) {
				m_data = null;
				ms_baseURL = null;
				return;
			}
			var i: int = s_url.indexOf("?");
			if(i < 0) {
				m_data = null;
				ms_baseURL = s_url;
			}
			else {
				m_data = new URLVariables(s_url.substr(i + 1));
				ms_baseURL = s_url.substr(0, i + 1);
			}
		}
		
		public function get fullURL(): String
		{ return ms_fullURL; }

		public function set fullURL(s_fullUrl: String): void
		{
			ms_fullURL = s_fullUrl;
			parseFullURL(s_fullUrl);
		}

		public function get version(): Version
		{ return m_version; }

		public function set version(version: Version): void 
		{ m_version = version; }

		public function get updatePeriod(): uint
		{ return mi_updatePeriod; } 

		public function set updatePeriod(i_period: uint): void
		{ mi_updatePeriod = i_period; } 

		public function get enabled(): Boolean
		{ return mb_enabled; } 

		public function set enabled(b: Boolean): void
		{ mb_enabled = b; } 

		public function get baseURL(): String
		{ return ms_baseURL; }

		public function get lastUpdateFlashStamp(): int
		{ return mi_lastUpdateFlashStamp; }

		public function get label(): String
		{ return ms_service.toUpperCase() + " " + fullURL + " (" + version.toString() + ")"; }
				
		public function get serviceType(): String
		{ return ms_service.toUpperCase(); }		
	}
}