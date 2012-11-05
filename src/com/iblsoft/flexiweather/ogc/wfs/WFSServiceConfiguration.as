package com.iblsoft.flexiweather.ogc.wfs
{
	import com.iblsoft.flexiweather.net.events.UniURLLoaderErrorEvent;
	import com.iblsoft.flexiweather.net.events.UniURLLoaderEvent;
	import com.iblsoft.flexiweather.net.loaders.UniURLLoader;
	import com.iblsoft.flexiweather.net.loaders.XMLLoader;
	import com.iblsoft.flexiweather.utils.ArrayUtils;
	import com.iblsoft.flexiweather.widgets.BackgroundJob;
	import com.iblsoft.flexiweather.widgets.BackgroundJobManager;
	import flash.events.DataEvent;
	import flash.events.Event;
	import flash.net.URLRequest;
	import flash.net.URLVariables;
	import mx.collections.ArrayCollection;
	import com.iblsoft.flexiweather.ogc.configuration.services.OGCServiceConfiguration;
	import com.iblsoft.flexiweather.ogc.SchemaParser;
	import com.iblsoft.flexiweather.ogc.Version;

	public class WFSServiceConfiguration extends OGCServiceConfiguration
	{
		private var m_capabilitiesLoader: XMLLoader = new XMLLoader();
		private var m_featureTypesLoader: XMLLoader = new XMLLoader();
		private var m_capabilities: XML = null;
		private var m_capabilitiesLoadJob: BackgroundJob = null;
		private var m_featureTypesLoadJob: BackgroundJob = null;
		private var m_featureTypes: ArrayCollection = null;
		private var m_schemaParser: SchemaParser;
		public static const CAPABILITIES_UPDATED: String = "capabilitiesUpdated";

		[Event(name = CAPABILITIES_UPDATED, type = "flash.events.DataEvent")]
		public function WFSServiceConfiguration(s_url: String = null, version: Version = null)
		{
			super(s_url, "wfs", version);
			m_schemaParser = new SchemaParser();
			m_capabilitiesLoader.addEventListener(UniURLLoaderEvent.DATA_LOADED, onCapabilitiesLoaded);
			m_capabilitiesLoader.addEventListener(UniURLLoaderErrorEvent.DATA_LOAD_FAILED, onCapabilitiesLoadFailed);
			m_featureTypesLoader.addEventListener(UniURLLoaderEvent.DATA_LOADED, onFeatureTypesLoaded);
			m_featureTypesLoader.addEventListener(UniURLLoaderErrorEvent.DATA_LOAD_FAILED, onFeatureTypesLoadFailed);
		}

		public function getFeatureTypeByName(s_name: String): WFSFeatureType
		{
			if (m_featureTypes == null)
				return null;
			if (m_featureTypes.length > 0)
			{
				for each (var featureType: WFSFeatureType in m_featureTypes)
				{
					if ((featureType.name == s_name) || (featureType.title == s_name))
						return featureType;
				}
			}
			return null;
		}

		/**
		 * Parse output, find feature types coresponding to the output and returns ArrayCollection of WFSFeature objects
		 */
		public function getFeatures(responseXML: XML): ArrayCollection
		{
			var ret: ArrayCollection = new ArrayCollection();
			var wfs: Namespace = new Namespace('http://www.opengis.net/wfs');
			var gml: Namespace = new Namespace('http://www.opengis.net/gml');
			var fType: WFSFeatureType;
			for each (var featureMember: XML in responseXML.gml::featureMember)
			{
				var item: XML = featureMember.children()[0];
				fType = getFeatureTypeByName(item.localName());
				var sItems: ArrayCollection = fType.getScalarItems();
				ret.addItem(fType.getFeature(item));
					//ArrayUtils.unionArrays(ret.source, fType.getFeature(item));
			}
			return (ret);
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
			var r: URLRequest = new URLRequest(baseURL);
			if (featureTypeListVars != null)
				r.data = new URLVariables(featureTypeListVars.toString());
			r.data.SERVICE = serviceType;
			r.data.VERSION = version.toString();
			r.data.REQUEST = 'DescribeFeatureType';
			return r;
		}

		public function queryCapabilities(): void
		{
			var r: URLRequest = toGetCapabilitiesRequest();
			m_capabilitiesLoader.load(r);
			if (m_capabilitiesLoadJob != null)
				m_capabilitiesLoadJob.finish();
			m_capabilitiesLoadJob = BackgroundJobManager.getInstance().startJob(
					"Getting WFS capabilities for " + baseURL);
		}

		/**
		 *
		 */
		public function queryDescribeFeatureType(featureTypeListVars: URLVariables): void
		{
			var r: URLRequest = toGetDescribeFeatureTypeRequest(featureTypeListVars);
			m_featureTypesLoader.load(r);
			if (m_featureTypesLoadJob != null)
				m_featureTypesLoadJob.finish();
			m_featureTypesLoadJob = BackgroundJobManager.getInstance().startJob(
					"Getting WFS describe feature type list " + baseURL);
		}

		override public function update(): void
		{
			super.update();
			if (enabled)
				queryCapabilities();
		}

		[Bindable(event = 'featureTypesChanged')]
		public function get featureTypes(): ArrayCollection
		{
			return m_featureTypes;
		}

		protected function onCapabilitiesLoaded(event: UniURLLoaderEvent): void
		{
			if (!m_capabilitiesLoadJob)
			{
				trace("ERROR WFS m_capabilitiesLoadJob IS null")
				return;
			}
			m_capabilitiesLoadJob.finish();
			m_capabilitiesLoadJob = null;
			if (event.result is XML)
			{
				var xml: XML = event.result as XML;
				var s_version: String = xml.@version;
				var version: Version = Version.fromString(s_version);
				//var wfs: Namespace = version.isLessThan(1, 3, 0)
				//		? new Namespace() : new Namespace("http://www.opengis.net/wfs"); 
				var wfs: Namespace = new Namespace("http://www.opengis.net/wfs");
				//var wfs: Namespace = new Namespace("http://www.iblsoft.com/wfs");
				var capability: XMLList = xml.wfs::FeatureTypeList;
				var nFeatureType: WFSFeatureType;
				if (capability != null)
				{
					var fTypeList: XMLList = capability.wfs::FeatureType;
					var featureTypeListVars: URLVariables = new URLVariables();
					var typenameParam: Array = new Array();
					if (fTypeList != null)
					{
						m_featureTypes = new ArrayCollection();
						for each (var fChild: XML in fTypeList)
						{
							nFeatureType = new WFSFeatureType(fChild, wfs, version);
							m_featureTypes.addItem(nFeatureType);
							typenameParam.push(nFeatureType.title);
						}
					}
					featureTypeListVars.TYPENAME = typenameParam.join(',');
					// LOAD ALL FEATURE TYPES AS ONE REQUEST
					queryDescribeFeatureType(featureTypeListVars);
				}
			}
		}

		protected function onCapabilitiesLoadFailed(event: UniURLLoaderErrorEvent): void
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
			if (event.result is XML)
			{
				var xml: XML = event.result as XML;
				// PARSE DEFINITION
				m_schemaParser.parseSchema(xml);
				// GO THRUE ALL FEATURE TYPES
				for each (var tFeatureType: WFSFeatureType in m_featureTypes)
				{
					// FIND 
					tFeatureType.setDefinition(m_schemaParser.getElementByName(tFeatureType.title));
				}
				dispatchEvent(new Event('featureTypesChanged'));
			}
		}

		/**
		 *
		 */
		protected function onFeatureTypesLoadFailed(event: UniURLLoaderErrorEvent): void
		{
			m_featureTypesLoadJob.finish();
			m_featureTypesLoadJob = null;
		}
	}
}
