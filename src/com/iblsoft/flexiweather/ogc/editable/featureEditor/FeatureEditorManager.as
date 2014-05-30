package com.iblsoft.flexiweather.ogc.editable.featureEditor
{
	import com.iblsoft.flexiweather.events.InteractiveLayerEvent;
	import com.iblsoft.flexiweather.net.events.UniURLLoaderErrorEvent;
	import com.iblsoft.flexiweather.net.events.UniURLLoaderEvent;
	import com.iblsoft.flexiweather.ogc.InteractiveLayerWFSFeatureEditor;
	import com.iblsoft.flexiweather.ogc.editable.WFSFeatureEditable;
	import com.iblsoft.flexiweather.ogc.editable.featureEditor.data.FeatureEditorProduct;
	import com.iblsoft.flexiweather.ogc.wfs.WFSFeatureBase;
	import com.iblsoft.flexiweather.utils.ISO8601Parser;
	
	import flash.events.EventDispatcher;

	public class FeatureEditorManager extends EventDispatcher
	{
		protected var m_layer: InteractiveLayerWFSFeatureEditor;
		
		protected var mb_serviceBusy: Boolean = false;
		public function serviceBusy(): Boolean
		{
			return mb_serviceBusy;
		}
		[Bindable]
		public var transactionInProgress: Boolean;
		
		public var product: FeatureEditorProduct;
		
		
		
		public function FeatureEditorManager()
		{
		}
		
		public function issueProduct(): void
		{
			addTransactionListeners(m_layer);
			
			m_layer.issue();
			
			mb_serviceBusy = true;
		}
		
		public function importProduct(): void
		{
			m_layer.addEventListener(InteractiveLayerEvent.FEATURES_IMPORTED, onImportLoaded);
			var runDate: Date = m_layer.wfsService.getBaseTimeFunction(product.date, product.timeOffset);
			m_layer.importData(product.serviceURL, ISO8601Parser.dateToString(runDate), ISO8601Parser.dateToString(m_layer.wfsService.getValidityFunction(product.forecast, runDate)));
		}
		
		protected function onImportLoaded(event: InteractiveLayerEvent): void
		{
//			productIsLoading = false;
			
			m_layer.removeEventListener(InteractiveLayerEvent.FEATURES_IMPORTED, onImportLoaded);
			updateFeaturesTime();
			
			var newFeaturesCount: int = event.newFeaturesCount;
//			if (newFeaturesCount > 0)
//				productDirtyFlag = true;
		}
		
		
		private function updateFeaturesTime(product: FeatureEditorProduct = null): void
		{
			if (product)
			{
				var editableFeature: WFSFeatureEditable;
				
				for each(var feature: WFSFeatureBase in m_layer.features) 
				{
					editableFeature = feature as WFSFeatureEditable;
					if(editableFeature == null)
						continue;
					
//					if(editableFeature is IObjectWithBaseTimeAndValidity) 
//					{
//						IObjectWithBaseTimeAndValidity(editableFeature).baseTime = getBaseTime(product);
//						IObjectWithBaseTimeAndValidity(editableFeature).validity = getValidity(product);
//						
//						featureTimeUpdated(editableFeature);
//					}
				}	
			}
		}
		
		
		public function addTransactionListeners(userLayer: InteractiveLayerWFSFeatureEditor): void
		{
			transactionInProgress = true;
			
			userLayer.addEventListener(UniURLLoaderEvent.DATA_LOADED, onTransactionResult);
			userLayer.addEventListener(UniURLLoaderErrorEvent.DATA_LOAD_FAILED, onTransactionFailed);
			
		}
		public function removeTransactionListeners(userLayer: InteractiveLayerWFSFeatureEditor): void
		{
			transactionInProgress = false;
			userLayer.removeEventListener(UniURLLoaderEvent.DATA_LOADED, onTransactionResult);
			userLayer.removeEventListener(UniURLLoaderErrorEvent.DATA_LOAD_FAILED, onTransactionFailed);
		}
		
		protected function onTransactionFailed(event: UniURLLoaderErrorEvent): void
		{
			mb_serviceBusy = false;
			
			removeTransactionListeners(event.target as InteractiveLayerWFSFeatureEditor);
			
		}
		
		protected function onTransactionResult(event: UniURLLoaderEvent): void
		{
			
			mb_serviceBusy = false;
			
			removeTransactionListeners(event.target as InteractiveLayerWFSFeatureEditor);
			
			var xml: XML = XML(event.result); // TransactionResponse xmlns="http://www.opengis.net/wfs"
			var wfs: Namespace = new Namespace("http://www.opengis.net/wfs");
			var ogc: Namespace = new Namespace("http://www.opengis.net/ogc");
			
			
			if(xml.localName() != "TransactionResponse" && xml.localName() != "WFS_TransactionResponse") {
//				Log.getLogger("FeatureEditor").error("WFS backend transaction failure:\n" + xml.toXMLString());
//				Alert.show("WFS backend transaction failed, see log for defails.", "Feature Editor");
				return; 
			}
//			
//			productDirtyFlag = false;
//			if (freeDrawingProduct)
//			{
//				selectedProduct = freeDrawingProduct.clone();
//				freeDrawingProduct = null;
//			}
			
		}
	}
}