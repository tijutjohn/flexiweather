package com.iblsoft.flexiweather.ogc
{
	public class GetCapabilitiesXMLItem
	{
		protected var ms_name: String;
		
		protected var wms: Namespace;
		protected var m_version: Version;
		
		protected var m_itemXML: XML;
		
		protected var mb_isInitialized: Boolean;
		protected var mb_isParsed: Boolean;
		
		public function GetCapabilitiesXMLItem(xml: XML, wmsNamespace: Namespace, version: Version)
		{
			m_itemXML = xml;
			wms = wmsNamespace;
			m_version = version;
			
			ms_name = String(xml.wms::Name);
		}
		
		public function get name(): String
		{
			return ms_name;
		}
		
		public function initialize(): void
		{
			mb_isInitialized = true;
		}
		
		public function parse(): void
		{
			mb_isParsed = true;	
		}

	}
}