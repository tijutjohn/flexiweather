package com.iblsoft.flexiweather.ogc
{
	import com.iblsoft.flexiweather.utils.UniURLLoader;
	import com.iblsoft.flexiweather.utils.UniURLLoaderEvent;
	import com.iblsoft.flexiweather.widgets.BackgroundJob;
	import com.iblsoft.flexiweather.widgets.BackgroundJobManager;
	
	import flash.events.DataEvent;
	import flash.events.Event;
	import flash.net.URLRequest;
	import flash.net.URLVariables;
	
	import mx.collections.ArrayCollection;
	
	public class WFSServiceConfiguration extends OGCServiceConfiguration
	{
		public var id: String;
		
		internal var m_capabilitiesLoader: UniURLLoader = new UniURLLoader();
		internal var m_featureTypesLoader: UniURLLoader = new UniURLLoader();
		internal var m_capabilities: XML = null;
		internal var m_capabilitiesLoadJob: BackgroundJob = null;
		internal var m_featureTypesLoadJob: BackgroundJob = null;
		
		internal var m_featureTypes: ArrayCollection = null;
		
		internal var m_schemaParser: SchemaParser;
		
		public static const CAPABILITIES_UPDATED: String = "capabilitiesUpdated";

		[Event(name = CAPABILITIES_UPDATED, type = "flash.events.DataEvent")]
		
		public function WFSServiceConfiguration(s_url: String = null, version: Version = null)
		{
			super(s_url, "wfs", version);
			
			m_schemaParser = new SchemaParser();
			
			m_capabilitiesLoader.addEventListener(UniURLLoader.DATA_LOADED, onCapabilitiesLoaded);
			m_capabilitiesLoader.addEventListener(UniURLLoader.DATA_LOAD_FAILED, onCapabilitiesLoadFailed);
			
			m_featureTypesLoader.addEventListener(UniURLLoader.DATA_LOADED, onFeatureTypesLoaded);
			m_featureTypesLoader.addEventListener(UniURLLoader.DATA_LOAD_FAILED, onFeatureTypesLoadFailed);
		}
		
		public function getFeatureTypeByName(s_name: String): WFSFeatureType
		{
			if(m_featureTypes == null)
				return null;
				
			if (m_featureTypes.length > 0)
			{
				for each (var featureType: WFSFeatureType in m_featureTypes)
				{
					if (featureType.name == s_name)
						return featureType;
				}
			}
			return null;
		}

		public function toGetCapabilitiesRequest(): URLRequest
		{
			var r: URLRequest = toRequest("GetCapabilities");
			//r.data.FORMAT = "image/png"; 
			return r;
		}
		
		/**
		 * 
		 */
		public function toGetDescribeFeatureTypeRequest(featureTypeListVars: URLVariables): URLRequest
		{
			var r: URLRequest = new URLRequest(ms_baseURL);
			 
			if (featureTypeListVars != null){
				r.data = new URLVariables(featureTypeListVars.toString());
			}
			
			r.data.SERVICE = ms_service.toUpperCase();
			r.data.VERSION = m_version.toString();
			r.data.REQUEST = 'DescribeFeatureType';
			
			return r;
		}

		public function queryCapabilities(): void
		{
			var r: URLRequest = toGetCapabilitiesRequest();
			m_capabilitiesLoader.load(r);
			if(m_capabilitiesLoadJob != null)
				m_capabilitiesLoadJob.finish();
			m_capabilitiesLoadJob = BackgroundJobManager.getInstance().startJob(
					"Getting WFS capabilities for " + ms_baseURL);
		}
		
		/**
		 * 
		 */
		public function queryDescribeFeatureType(featureTypeListVars: URLVariables): void
		{
			var r: URLRequest = toGetDescribeFeatureTypeRequest(featureTypeListVars);
			m_featureTypesLoader.load(r);
			if(m_featureTypesLoadJob != null)
				m_featureTypesLoadJob.finish();
			m_featureTypesLoadJob = BackgroundJobManager.getInstance().startJob(
					"Getting WFS describe feature type list " + ms_baseURL);
		}
		
		override internal function update(): void
		{
			super.update();
			if(enabled)
				queryCapabilities();
		}
		
		[Bindable (event='featureTypesChanged')]
		public function get featureTypes(): ArrayCollection
		{ return m_featureTypes; }
		
		protected function onCapabilitiesLoaded(event: UniURLLoaderEvent): void
		{
			if (!m_capabilitiesLoadJob)
			{
				trace("ERROR WFS m_capabilitiesLoadJob IS null")
				return;
			}
			m_capabilitiesLoadJob.finish();
			m_capabilitiesLoadJob = null;
			if(event.result is XML) {
				var xml: XML = event.result as XML;
				
				var s_version: String = xml.@version;
				var version: Version = Version.fromString(s_version);
				//var wfs: Namespace = version.isLessThan(1, 3, 0)
				//		? new Namespace() : new Namespace("http://www.opengis.net/wfs"); 
						
				var wfs: Namespace = new Namespace("http://www.opengis.net/wfs");
				//var wfs: Namespace = new Namespace("http://www.iblsoft.com/wfs");
				
				var capability: XMLList = xml.wfs::FeatureTypeList;
				
				var nFeatureType: WFSFeatureType;
				
				if (capability != null){
					var fTypeList: XMLList = capability.wfs::FeatureType;
					var featureTypeListVars: URLVariables = new URLVariables();
					var typenameParam: Array = new Array();
					
					if (fTypeList != null){
						m_featureTypes = new ArrayCollection();
						
						for each (var fChild: XML in fTypeList){
							nFeatureType = new WFSFeatureType(fChild, wfs, version);
							
							m_featureTypes.addItem(nFeatureType);
							
							typenameParam.push(nFeatureType.title);
						}
						
						//dispatchEvent(new DataEvent(CAPABILITIES_UPDATED));
						
						//dispatchEvent(new Event('featureTypesChanged'));
					}
					
					featureTypeListVars.TYPENAME = typenameParam.join(',');
					
					// LOAD ALL FEATURE TYPES AS ONE REQUEST
					queryDescribeFeatureType(featureTypeListVars);
				}
			}
		}

		protected function onCapabilitiesLoadFailed(event: UniURLLoaderEvent): void
		{
			m_capabilitiesLoadJob.finish();
			m_capabilitiesLoadJob = null;
			// keep old m_capabilities
		}
		
		/**
		 * 
		 */
		protected function onFeatureTypesLoaded(event: UniURLLoaderEvent): void
		{
			if (!m_featureTypesLoadJob)
			{
				trace("ERROR WFS m_featureTypesLoadJob IS null")
				return;
			}
			
			m_featureTypesLoadJob.finish();
			m_featureTypesLoadJob = null;
			if(event.result is XML) {
				var xml: XML = event.result as XML;
				
				// PARSE DEFINITION
				m_schemaParser.parseSchema(xml);
				
				// GO THRUE ALL FEATURE TYPES
				for each (var tFeatureType: WFSFeatureType in m_featureTypes){
					// FIND 
					tFeatureType.setDefinition(m_schemaParser.getElementByName(tFeatureType.title));
				}
				
				dispatchEvent(new Event('featureTypesChanged'));
			}
		}
		
		/**
		 * 
		 */
		protected function onFeatureTypesLoadFailed(event: UniURLLoaderEvent): void
		{
			m_featureTypesLoadJob.finish();
			m_featureTypesLoadJob = null;
		}
	}
}