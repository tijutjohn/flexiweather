package com.iblsoft.flexiweather.ogc
{
	import com.iblsoft.flexiweather.net.events.UniURLLoaderErrorEvent;
	import com.iblsoft.flexiweather.net.events.UniURLLoaderEvent;
	import com.iblsoft.flexiweather.net.loaders.AbstractURLLoader;
	import com.iblsoft.flexiweather.net.loaders.UniURLLoader;
	import com.iblsoft.flexiweather.ogc.Version;
	import com.iblsoft.flexiweather.ogc.editable.InteractiveLayerWFSEditable;
	import com.iblsoft.flexiweather.ogc.editable.WFSFeatureEditable;
	import com.iblsoft.flexiweather.ogc.editable.WFSFeatureEditableMode;
	import com.iblsoft.flexiweather.ogc.editable.featureEditor.events.WFSTransactionEvent;
	import com.iblsoft.flexiweather.ogc.editable.features.WFSFeatureEditableMacro;
	import com.iblsoft.flexiweather.ogc.editable.features.WFSFeatureEditablePressureCentre;
	import com.iblsoft.flexiweather.ogc.editable.features.WFSFeatureEditableRadiation;
	import com.iblsoft.flexiweather.ogc.editable.features.WFSFeatureEditableStorm;
	import com.iblsoft.flexiweather.ogc.editable.features.WFSFeatureEditableText;
	import com.iblsoft.flexiweather.ogc.editable.features.WFSFeatureEditableTropopause;
	import com.iblsoft.flexiweather.ogc.editable.features.WFSFeatureEditableVolcano;
	import com.iblsoft.flexiweather.ogc.editable.features.curves.WFSFeatureEditableFront;
	import com.iblsoft.flexiweather.ogc.editable.features.curves.WFSFeatureEditableGeometry;
	import com.iblsoft.flexiweather.ogc.editable.features.curves.WFSFeatureEditableJetStream;
	import com.iblsoft.flexiweather.ogc.editable.features.curves.withAnnotation.WFSFeatureEditableAnnotation;
	import com.iblsoft.flexiweather.ogc.editable.features.curves.withAnnotation.WFSFeatureEditableCloud;
	import com.iblsoft.flexiweather.ogc.editable.features.curves.withAnnotation.WFSFeatureEditableIcingArea;
	import com.iblsoft.flexiweather.ogc.editable.features.curves.withAnnotation.WFSFeatureEditableThunderstormArea;
	import com.iblsoft.flexiweather.ogc.editable.features.curves.withAnnotation.WFSFeatureEditableTurbulenceArea;
	import com.iblsoft.flexiweather.ogc.wfs.WFSFeatureBase;
	import com.iblsoft.flexiweather.utils.ISO8601Parser;
	import com.iblsoft.flexiweather.widgets.InteractiveWidget;
	
	import flash.display.Graphics;
	import flash.net.URLRequest;
	import flash.net.URLRequestMethod;
	
	import mx.collections.ArrayCollection;
	import mx.controls.Alert;
	import mx.rpc.events.FaultEvent;
	import mx.rpc.events.ResultEvent;
	import mx.rpc.http.HTTPService;

	public class InteractiveLayerWFSFeatureEditor extends InteractiveLayerWFSEditable
	{
		public static const TRANSACTION_SAVE: String = 'save';
		public static const TRANSACTION_ISSUE: String = 'issue';
		
		protected var ms_transactionType: String;
//		protected var m_service: HTTPService = new HTTPService();
		protected var mi_insertionHandleSeq: uint = 0; 
		protected var mm_insertionHandleToFeatureMap: Array = [];
		
		private var ml_removedFeatures: Array = [];		
		
		override public function set visible(b_visible:Boolean):void
		{
			super.visible = b_visible;
		}
		
		public function InteractiveLayerWFSFeatureEditor(container: InteractiveWidget = null)
		{
			super(container, new Version(1, 1, 0));
			invalidateDynamicPart();
			
			wfsService.addEventListener(UniURLLoaderEvent.DATA_LOADED, onTransactionResult);
			wfsService.addEventListener(UniURLLoaderErrorEvent.DATA_LOAD_FAILED, onTransactionFailed);
		}

		public function setLayerAndAnticollisionLayoutVisibility(b_visible: Boolean): void
		{
			visible = b_visible;
			if (container)
			{
				container.anticollisionObjectsVisibilityForLayer(this, b_visible);
			}
			if (b_visible)
			{
				updateAllFeatures();
			}
		}
		public function set justSelectable(value: Boolean): void
		{
			for each (var feature: WFSFeatureEditable in features)
			{
				feature.justSelectable = value;
			}
		}
		public override function draw(graphics: Graphics): void
		{
			super.draw(graphics);
		}
		
		public override function parseFeatureMember(
				xml: XML, wfs: Namespace, gml: Namespace): WFSFeatureBase
		{
			var ibl: Namespace = new Namespace("http://www.iblsoft.com/wfs");
			if (xml.localName() == 'featureMember')
			{
				//remove first member only if it's featureMember node
				xml = xml.elements()[0]; // fetch the first member
			}
			var tagName: QName = xml.name();
			var feature: WFSFeatureEditable;
			if (tagName)
			{
				if(tagName.localName == "Front") {
					feature = new WFSFeatureEditableFront("http://www.iblsoft.com/wfs", "Front", xml.@gml::id);
				}
				else if(tagName.localName == "PressureCentre") {
					feature = new WFSFeatureEditablePressureCentre("http://www.iblsoft.com/wfs", "PressureCentre", xml.@gml::id);
				}
				else if(tagName.localName == "Cloud") {
					feature = new WFSFeatureEditableCloud("http://www.iblsoft.com/wfs", "Cloud", xml.@gml::id);
				}
				else if(tagName.localName == "Geometry") 
				{
					feature = new WFSFeatureEditableGeometry("http://www.iblsoft.com/wfs", "Geometry", xml.@gml::id);
				}
				else if(tagName.localName == "JetStream") 
				{
					feature = new WFSFeatureEditableJetStream("http://www.iblsoft.com/wfs", "JetStream", xml.@gml::id);
				}
				else if(tagName.localName == "IcingArea") 
				{
					feature = new WFSFeatureEditableIcingArea("http://www.iblsoft.com/wfs", "IcingArea", xml.@gml::id);
				}
				else if(tagName.localName == "TurbulenceArea") 
				{
					feature = new WFSFeatureEditableTurbulenceArea("http://www.iblsoft.com/wfs", "TurbulenceArea", xml.@gml::id);
				}
				else if(tagName.localName == "ThunderstormArea") 
				{
					feature = new WFSFeatureEditableThunderstormArea("http://www.iblsoft.com/wfs", "ThunderstormArea", xml.@gml::id);
				}
				else if (tagName.localName == "Volcano")
				{
					feature = new WFSFeatureEditableVolcano("http://www.iblsoft.com/wfs", "Volcano", xml.@gml::id);
				}
				else if (tagName.localName == "Radiation")
				{
					feature = new WFSFeatureEditableRadiation("http://www.iblsoft.com/wfs", "Radiation", xml.@gml::id);
				}
				else if (tagName.localName == "Storm")
				{
					feature = new WFSFeatureEditableStorm("http://www.iblsoft.com/wfs", "Storm", xml.@gml::id);
				}
				else if (tagName.localName == "Tropopause")
				{
					feature = new WFSFeatureEditableTropopause("http://www.iblsoft.com/wfs", "Tropopause", xml.@gml::id);
				}
				else if (tagName.localName == "Annotation")
				{
					feature = new WFSFeatureEditableAnnotation("http://www.iblsoft.com/wfs", "Annotation", xml.@gml::id);
				}
				else if (tagName.localName == "Text")
				{
					feature = new WFSFeatureEditableText("http://www.iblsoft.com/wfs", "Text", xml.@gml::id);
				}
				else if (tagName.localName == "Macro")
				{
					feature = new WFSFeatureEditableMacro("http://www.iblsoft.com/wfs", "Macro", xml.@gml::id);
				}
				else
					return null;
				
				if (feature)
				{
					feature.setMaster(this);
					feature.fromGML(xml);
				}
				return feature;
			}
			return null;
		}
		
		public function save(): void
		{
			var xmlOperation: XML = <wfs:Transaction xmlns:wfs="http://www.opengis.net/wfs" service="WFS" version="1.1.0"/>;
			
			var l_insertedFeatures: Array = [];
			var l_insertedXMLs: Array = [];
			var xml: XML;
			var editableFeature: WFSFeatureEditable;
			var xmlInsert: XML;
			
			var insertID: int = 0;
			for each(var feature: WFSFeatureBase in features) 
			{
				editableFeature = feature as WFSFeatureEditable;
				if(editableFeature == null)
					continue;
				if(editableFeature.isInternal())
					continue;
				// FIXME: featureId should not be "" - who creates it?
				if(editableFeature.featureId == null || editableFeature.featureId == "") 
				{
					xmlInsert = <wfs:Insert xmlns:wfs="http://www.opengis.net/wfs"/>;
					var xmlFeature: XML = <root/>;
					xmlFeature.setName(editableFeature.typeName);
					xmlFeature.setNamespace(new Namespace(editableFeature.namespaceURI));
					editableFeature.toInsertGML(xmlFeature);
					
					xmlInsert.appendChild(xmlFeature);
					l_insertedFeatures[insertID] = editableFeature;
					l_insertedXMLs[insertID] = xmlInsert;
					insertID++;
				}
				else if(editableFeature.modified) {
					var xmlUpdate: XML = <wfs:Update xmlns:wfs="http://www.opengis.net/wfs"/>;
					xmlUpdate.@typeName = editableFeature.typeName;
					editableFeature.toUpdateGML(xmlUpdate);
					xmlUpdate.appendChild(
							<ogc:Filter xmlns:ogc="http://www.opengis.net/ogc" xmlns:gml="http://www.opengis.net/gml">
					            <ogc:PropertyIsEqualTo>
					                <ogc:PropertyName>@gml:id</ogc:PropertyName>
					                <ogc:Literal>{feature.featureId}</ogc:Literal>
					            </ogc:PropertyIsEqualTo>
							</ogc:Filter>);
					xmlOperation.appendChild(xmlUpdate);
				}
			}
			for each(editableFeature in ml_removedFeatures) {
				var xmlDelete: XML = <wfs:Delete xmlns:wfs="http://www.opengis.net/wfs"/>;
				xmlDelete.@typeName = editableFeature.typeName;
				xmlDelete.appendChild(
						<ogc:Filter xmlns:ogc="http://www.opengis.net/ogc" xmlns:gml="http://www.opengis.net/gml">
				            <ogc:PropertyIsEqualTo>
				                <ogc:PropertyName>@gml:id</ogc:PropertyName>
				                <ogc:Literal>{editableFeature.featureId}</ogc:Literal>
				            </ogc:PropertyIsEqualTo>
						</ogc:Filter>);
				xmlOperation.appendChild(xmlDelete);
			}
			if(l_insertedFeatures.length > 0) {
				for(var i: int = 0 ; i < insertID; i++)
				{
					xmlInsert = l_insertedXMLs[i] as XML;
					editableFeature = l_insertedFeatures[i] as WFSFeatureEditable;
					
					++mi_insertionHandleSeq;
					
					var s_iHandle: String = "insertion-" + mi_insertionHandleSeq; 
					mm_insertionHandleToFeatureMap[s_iHandle] = editableFeature; 
					xmlInsert.@handle = s_iHandle;
					xmlOperation.appendChild(xmlInsert);
				}
			} 
			//Alert.show("Sending WFS transaction request:\n" + xmlOperation.toXMLString());
			
			ms_transactionType = TRANSACTION_SAVE;
			
			wfsService.save(xmlOperation);
			
		}
		
		public function issue(): void
		{
			
			var baseTimeString: String = ISO8601Parser.dateToString(wfsService.product.getBaseTime());
			var validityString: String = ISO8601Parser.dateToString(wfsService.product.getValidity());
			
			/*
			<Transaction xsi:schemaLocation="http://www.opengis.net/wfs http://schemas.opengis.net/wfs/1.0.0/WFS-transaction.xsd http://www.iblsoft.com/wfs http://localhost:8008/test?SERVICE=WFS&REQUEST=DescribeFeatureType&VERSION=1.0.0&TYPENAME=Front%2cPressureCentre" version="1.0.0" service="WFS" xmlns="http://www.opengis.net/wfs" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
			   <LockId>my-lock-id</LockId>
			    <Native vendorId="com.iblsoft.vw" safeToIgnore="false">
			      <IssueProduct xmlns="http://www.iblsoft.com/wfs" typeName="JetStream">
			        <baseTime>2009-06-01T06:00:00</baseTime>
			        <validity>2009-06-01T12:00:00</validity>
			      </IssueProduct>
			    </Native>
			</Transaction>
			*/
			
			var xmlOperation: XML = <Transaction xsi:schemaLocation="http://www.opengis.net/wfs http://schemas.opengis.net/wfs/1.0.0/WFS-transaction.xsd http://www.iblsoft.com/wfs http://localhost:8008/test?SERVICE=WFS&REQUEST=DescribeFeatureType&VERSION=1.0.0&TYPENAME=Front%2cPressureCentre" version="1.0.0" service="WFS" xmlns="http://www.opengis.net/wfs" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"/>
			var xmlLock: XML = <LockId>my-lock-id</LockId>;
			var xmlNative: XML = <Native vendorId="com.iblsoft.vw" safeToIgnore="false"/>;
			var xmlIssueProduct: XML = <IssueProduct xmlns="http://www.iblsoft.com/wfs" typeName="JetStream"/>;
			var baseTime: XML = <baseTime>{baseTimeString}</baseTime>;
			var validity: XML = <validity>{validityString}</validity>;
			
			xmlOperation.appendChild(xmlLock);
			xmlOperation.appendChild(xmlNative);
			xmlNative.appendChild(xmlIssueProduct);
			xmlIssueProduct.appendChild(baseTime);
			xmlIssueProduct.appendChild(validity);
			
			ms_transactionType = TRANSACTION_ISSUE;
			
			wfsService.issue(xmlOperation);
			
		}
		
		protected function onTransactionFailed(event: UniURLLoaderErrorEvent): void
		{
			var wte: WFSTransactionEvent = new WFSTransactionEvent(WFSTransactionEvent.TRANSACTION_FAILED, ms_transactionType, event.result);
			dispatchEvent(wte);
			
			dispatchEvent(event);
		}
		
		protected function onTransactionResult(event: UniURLLoaderEvent): void
		{
			var xml: XML = XML(event.result); // TransactionResponse xmlns="http://www.opengis.net/wfs"
			var wfs: Namespace = new Namespace("http://www.opengis.net/wfs");
			var ogc: Namespace = new Namespace("http://www.opengis.net/ogc");
			
			if(xml.localName() != "TransactionResponse" && xml.localName() != "WFS_TransactionResponse") {
				dispatchEvent(event);
				return; 
			}

//			switch (ms_transactionType)
//			{
//				case TRANSACTION_ISSUE:
//					Alert.show('Product was issued', 'Feature Editor');
//					break;
//			}
			var editableFeature: WFSFeatureEditable;

			var i_index: uint = 0;
			for each(var ir: XML in xml.wfs::InsertResults.wfs::Feature) {
				
				editableFeature = getEditableFeatureFromInsertedResults(ir, i_index);
				if(editableFeature)
				{
					editableFeature.featureId = ir.ogc::FeatureId.@fid; 
					++i_index;
				}
			}
			for each(var feature: WFSFeatureBase in features) {
				editableFeature = feature as WFSFeatureEditable;
				if(editableFeature == null)
					continue;
				editableFeature.modified = false;
			}
			emptyRemovedFeatures();
			
			var wte: WFSTransactionEvent = new WFSTransactionEvent(WFSTransactionEvent.TRANSACTION_COMPLETE, ms_transactionType, event.result);
			dispatchEvent(wte);
			
			ms_transactionType = '';
			
			dispatchEvent(event);
		}
		
		public function getEditableFeatureFromInsertedResults(ir: XML, i_index: uint): WFSFeatureEditable
		{
			var editableFeature: WFSFeatureEditable;

			var s_handle: String = ir.@handle;
			if(!(s_handle in mm_insertionHandleToFeatureMap))
				return null;
			editableFeature = mm_insertionHandleToFeatureMap[s_handle];
			
			return editableFeature;
		}
		
		override public function removeAllFeatures(): void
		{
			super.removeAllFeatures();
			emptyRemovedFeatures();
		}
		
		public function emptyRemovedFeatures(): void
		{
			ml_removedFeatures = [];
		}
		
		override public function getRemovedFeatureByFeatureId(id: String): WFSFeatureBase
		{
			for each (var feature: WFSFeatureEditable in ml_removedFeatures)
			{
				if (feature.featureId == id)
				{
					return feature;
				}
			}
			return null;
		}
		
		/**
		 * Function returns features, which was already saved to feature database (featureID is defined), but was removed from stage, but it's not saved to database yet.
		 * @return 
		 * 
		 */		
		override protected function getRemovedFeatureDatabaseFeatures(): ArrayCollection
		{
			var arr: ArrayCollection = new ArrayCollection();
			for each (var feature: WFSFeatureEditable in ml_removedFeatures)
			{
				if (feature.featureId)
				{
					arr.addItem(feature);
				}
			}
			return arr;
		}
		
		public function onFeatureRemove(): Boolean
		{
			var feature: WFSFeatureEditable = selectedItem as WFSFeatureEditable;
			if(feature == null)
				return false;
				
			if(feature.featureId != null)
				ml_removedFeatures.push(feature);
				
			var internalFeature: Boolean = feature.internalFeatureId != null;
			
			removeFeature(feature);
			
			return internalFeature;
			
		}
	}
}
