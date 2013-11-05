package com.iblsoft.flexiweather.ogc
{
	import com.iblsoft.flexiweather.ogc.configuration.services.WMSServiceParsingManager;

	public class GetCapabilitiesXMLItem
	{
		protected var ms_name: String;
		
		protected var wms: Namespace;
		protected var m_version: Version;
		
		protected var m_itemXML: XML;
		
		protected var mb_isInitialized: Boolean;
		protected var mb_isParsed: Boolean;
		
		public function get itemXML(): XML
		{
			return m_itemXML;
		}
		
		public function GetCapabilitiesXMLItem(xml: XML, wmsNamespace: Namespace, version: Version)
		{
			m_itemXML = xml;
			wms = wmsNamespace;
			m_version = version;
			
			ms_name = String(xml.wms::Name);
		}
		
		protected function addAllArrayItems(arrTo: Array, arrFrom: Array): Array
		{
//			trace("addAllArrayItems 1  " +  arrTo.length + "from: "+ arrFrom.length);
			arrTo = arrTo.concat(arrFrom);
//			trace("addAllArrayItems 2  " +  arrTo.length + "from: "+ arrFrom.length);
			return arrTo;
		}
		
		protected function removeAllArrayItems(arr: Array): void
		{
			arr.splice(0);
		}
		
		public function get name(): String
		{
			return ms_name;
		}
		
		public function initialize(parsingManager: WMSServiceParsingManager = null): void
		{
			mb_isInitialized = true;
		}
		
		public function parse(parsingManager: WMSServiceParsingManager = null): void
		{
			mb_isParsed = true;	
		}

	}
}