package com.iblsoft.flexiweather.ogc.editable.featureEditor.service
{
	import com.iblsoft.flexiweather.events.InteractiveLayerEvent;
	import com.iblsoft.flexiweather.events.WFSFeatureEditorServiceEvent;
	import com.iblsoft.flexiweather.net.events.UniURLLoaderErrorEvent;
	import com.iblsoft.flexiweather.net.events.UniURLLoaderEvent;
	import com.iblsoft.flexiweather.net.loaders.WFSLoader;
	import com.iblsoft.flexiweather.ogc.editable.featureEditor.data.FeatureEditorProduct;
	import com.iblsoft.flexiweather.ogc.wfs.WFSFeature;
	import com.iblsoft.flexiweather.utils.ISO8601Parser;
	
	import flash.events.EventDispatcher;
	import flash.net.URLRequest;
	import flash.net.URLRequestMethod;
	import flash.net.URLVariables;
	
	import mx.collections.ArrayCollection;

	public class WFSFeatureEditorService extends EventDispatcher
	{
		private var m_product: FeatureEditorProduct
		protected var m_wfsLoader: WFSLoader;
		
		public function WFSFeatureEditorService()
		{
			m_wfsLoader = new WFSLoader();
		}
		
		public function setProduct(product: FeatureEditorProduct): void
		{
			m_product = product;
		}
		
		public function issue(xml: XML): void
		{
			var urlRequest: URLRequest = new URLRequest();
			urlRequest.contentType = "text/xml"
			urlRequest.url = m_product.serviceURL;
			urlRequest.method = URLRequestMethod.POST;
			urlRequest.data = xml;
			
			listenToTransaction();
			
			m_wfsLoader.load(urlRequest);
		}
		
		public function save(xml: XML): void
		{
			var urlRequest: URLRequest = new URLRequest();
			urlRequest.contentType = "text/xml"
			urlRequest.url = m_product.serviceURL;
			urlRequest.method = URLRequestMethod.POST;
			urlRequest.data = xml;
			
			listenToTransaction();
			
			m_wfsLoader.load(urlRequest);
		}
		
		private function stopListenToTransaction(): void
		{
			m_wfsLoader.removeEventListener(UniURLLoaderEvent.DATA_LOADED, onTransactionResult);
			m_wfsLoader.removeEventListener(UniURLLoaderErrorEvent.DATA_LOAD_FAILED, onTransactionFailed);
		}
		private function listenToTransaction(): void
		{
			m_wfsLoader.addEventListener(UniURLLoaderEvent.DATA_LOADED, onTransactionResult);
			m_wfsLoader.addEventListener(UniURLLoaderErrorEvent.DATA_LOAD_FAILED, onTransactionFailed);
		}
		
		protected function onTransactionFailed(event: UniURLLoaderErrorEvent): void
		{
			stopListenToTransaction();
			dispatchEvent(event);
		}
		
		protected function onTransactionResult(event: UniURLLoaderEvent): void
		{
			stopListenToTransaction();
			dispatchEvent(event);
		}
		/**
		 * Import WFS layer data
		 *
		 * @param serviceURL
		 * @param run
		 * @param validity
		 *
		 */
		public function importData(run: String, validity: String, versionString: String, typeName: String, srsName: String = null): void
		{
			var url: URLRequest = new URLRequest(m_product.serviceURL);
			
			m_wfsLoader.addEventListener(UniURLLoaderEvent.DATA_LOADED, onImportLoaded);
			
			if(url.data == null)
				url.data = new URLVariables();
			url.data['SERVICE'] = 'WFS';
			url.data['VERSION'] = versionString;
			url.data['REQUEST'] = 'GetFeature';
			url.data['RUN'] = run;
			url.data['VALIDITY'] = validity;
			if (srsName)
				url.data['SRSNAME'] = srsName;
			url.data['TYPENAME'] = typeName;
			m_wfsLoader.load(url, null, "Importing features");
		}
		
		private function onImportLoaded(event: UniURLLoaderEvent): void
		{
			m_wfsLoader.removeEventListener(UniURLLoaderEvent.DATA_LOADED, onImportLoaded);
			
			var xml: XML = event.result as XML;
			if (xml == null)
				return; // TODO: do some error handling
			
			var e: WFSFeatureEditorServiceEvent = new WFSFeatureEditorServiceEvent(WFSFeatureEditorServiceEvent.IMPORT_DATA_RECEIVED);
			e.xml = xml;
			dispatchEvent(e);
		}
		
		
		
		
		public function loadData(data: Array, typeName: String, versionString: String, srsName: String = null): void
		{
			m_wfsLoader.addEventListener(UniURLLoaderEvent.DATA_LOADED, onLoadDataLoaded);
			updateWFSData('load', "Load features", data, versionString, typeName, srsName);
			
		}
		
		private function onLoadDataLoaded(event: UniURLLoaderEvent): void
		{
			m_wfsLoader.removeEventListener(UniURLLoaderEvent.DATA_LOADED, onLoadDataLoaded);
			
			var xml: XML = event.result as XML;
			if (xml == null)
				return; // TODO: do some error handling
			
			var e: WFSFeatureEditorServiceEvent = new WFSFeatureEditorServiceEvent(WFSFeatureEditorServiceEvent.LOAD_DATA_RECEIVED);
			e.xml = xml;
			dispatchEvent(e);
		}
		
		
		
		public function refreshData(data: Array, typeName: String, versionString: String, srsName: String = null): void
		{
			m_wfsLoader.addEventListener(UniURLLoaderEvent.DATA_LOADED, onRefreshDataLoaded);
			updateWFSData('refresh', "Refresh features", data, versionString, typeName, srsName);
			
		}
		
		private function onRefreshDataLoaded(event: UniURLLoaderEvent): void
		{
			m_wfsLoader.removeEventListener(UniURLLoaderEvent.DATA_LOADED, onRefreshDataLoaded);
			
			var xml: XML = event.result as XML;
			if (xml == null)
				return; // TODO: do some error handling
			
			var e: WFSFeatureEditorServiceEvent = new WFSFeatureEditorServiceEvent(WFSFeatureEditorServiceEvent.REFRESH_DATA_RECEIVED);
			e.xml = xml;
			dispatchEvent(e);
		}
		
		/**
		 * update WFS layer data (load them or refresh).
		 * @param type - type of updating. Possible values are: load, refresh.
		 *
		 */
		private function updateWFSData(type: String, description: String, data: Array, versionString: String, typeName: String, srsName: String = null): void
		{
			if (m_product.serviceURL == null)
				return;
			
			var url: URLRequest = new URLRequest(m_product.serviceURL);
			if (url.data == null)
				url.data = new URLVariables();
			url.data['SERVICE'] = 'WFS';
			url.data['VERSION'] = versionString;
			url.data['REQUEST'] = 'GetFeature';
			for (var s_param: String in data)
			{
				var s_value: String = data[s_param];
				url.data[s_param] = s_value;
			}
			if (srsName)
				url.data['SRSNAME'] = srsName;
			url.data['TYPENAME'] = typeName;
			m_wfsLoader.load(url, null, description);
		}
		
		
		
		
		
		
		public function getBaseTime(product: FeatureEditorProduct): Date
		{
			var dateLocal: Date = product.date
			var timeOffset: int = product.timeOffset;
			
			if(dateLocal == null)
				return new Date(uint(new Date().time) / 3600 * 3600) 
			
			return getBaseTimeFunction(dateLocal, timeOffset);
		}
		
		private function getBaseTimeFunction(dateLocal: Date, timeOffset: int): Date
		{
			var date: Date = new Date(Date.UTC(dateLocal.fullYear, dateLocal.month, dateLocal.date));
			date.time += Number(timeOffset) * 1000.0;
			return date;
		}
		
		public function getValidity(product: FeatureEditorProduct): Date
		{
			var forecastTime: int = product.forecast;
			return getValidityFunction(forecastTime, getBaseTime(product));
		}
		
		protected function getValidityFunction(forecastTime: int, runDate: Date): Date
		{
			return new Date(runDate.time + Number(forecastTime) * 1000.0);
		}
	}
}