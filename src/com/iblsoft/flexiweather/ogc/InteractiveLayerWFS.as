package com.iblsoft.flexiweather.ogc
{
	import com.iblsoft.flexiweather.events.InteractiveLayerEvent;
	import com.iblsoft.flexiweather.events.WFSFeatureEditorServiceEvent;
	import com.iblsoft.flexiweather.net.events.UniURLLoaderErrorEvent;
	import com.iblsoft.flexiweather.net.events.UniURLLoaderEvent;
	import com.iblsoft.flexiweather.net.loaders.UniURLLoader;
	import com.iblsoft.flexiweather.net.loaders.WFSLoader;
	import com.iblsoft.flexiweather.ogc.editable.WFSFeatureEditable;
	import com.iblsoft.flexiweather.ogc.editable.featureEditor.data.FeatureEditorProduct;
	import com.iblsoft.flexiweather.ogc.editable.featureEditor.service.WFSFeatureEditorService;
	import com.iblsoft.flexiweather.ogc.wfs.WFSFeatureBase;
	import com.iblsoft.flexiweather.widgets.InteractiveDataLayer;
	import com.iblsoft.flexiweather.widgets.InteractiveLayer;
	import com.iblsoft.flexiweather.widgets.InteractiveWidget;

	import flash.display.Graphics;
	import flash.display.Sprite;
	import flash.net.URLRequest;
	import flash.net.URLVariables;

	import mx.collections.ArrayCollection;

	public class InteractiveLayerWFS extends InteractiveLayerFeatureBase
	{
		private var ma_queryFeatures: Array = new Array();
		private var md_queryParametersGET: Array = new Array();

//		protected var m_wfsLoader: WFSLoader;
		protected var m_wfsService: WFSFeatureEditorService;

		protected var m_product: FeatureEditorProduct;

		public function InteractiveLayerWFS(
				container: InteractiveWidget = null,
				version: Version = null)
		{
			super(container, version);

//			m_wfsLoader = new WFSLoader();
			m_wfsService = new WFSFeatureEditorService();
		}


		public function get wfsService():WFSFeatureEditorService
		{
			return m_wfsService;
		}

		public function set wfsService(value:WFSFeatureEditorService):void
		{
			m_wfsService = value;
		}

		public function setProduct(product: FeatureEditorProduct): void
		{
			m_product = product;
			m_wfsService.setProduct(product);
		}

		/**
		 * Import WFS layer data
		 *
		 * @param serviceURL
		 * @param run
		 * @param validity
		 *
		 */
		public function importData(serviceURL: String, run: String, validity: String): void
		{
			var url: URLRequest = new URLRequest(serviceURL);

			var srsName: String;
			if (!version.isLessThan(1, 1, 0))
				srsName = container.getCRS();

			m_wfsService.addEventListener(WFSFeatureEditorServiceEvent.IMPORT_DATA_RECEIVED, onImportLoaded);
			m_wfsService.importData(serviceURL, run, validity, version.toString(), ma_queryFeatures.join(","), srsName);
		}

		public function loadData(): void
		{
			var srsName: String;
			if (!version.isLessThan(1, 1, 0))
				srsName = container.getCRS();

			m_wfsService.addEventListener(WFSFeatureEditorServiceEvent.LOAD_DATA_RECEIVED, onLoadDataLoaded);
			m_wfsService.loadData(md_queryParametersGET, ma_queryFeatures.join(","), version.toString(), srsName);

		}
		public function refreshData(): void
		{
			var srsName: String;
			if (!version.isLessThan(1, 1, 0))
				srsName = container.getCRS();

			m_wfsService.addEventListener(WFSFeatureEditorServiceEvent.REFRESH_DATA_RECEIVED, onRefreshDataLoaded);
			m_wfsService.refreshData(md_queryParametersGET, ma_queryFeatures.join(","), version.toString(), srsName);

		}

		private function addFeatureAfterLoad(feature: WFSFeatureBase, a_features: ArrayCollection = null): void
		{
			if (feature != null)
			{
				feature.setMaster(this);
				feature.update(FeatureUpdateContext.fullUpdate());
				featuresContainer.addChild(feature);
				if (a_features)
					a_features.addItem(feature);
				onFeatureAdded(feature);
			}
		}

		public function removeFeatureHavingSameInternalId(feature: WFSFeatureBase): void
		{
			var s_internalId: String = feature.internalFeatureId;
			var i: int = features.getItemIndex(feature);
			if (i >= 0)
				features.removeItemAt(i);
			if (s_internalId)
			{
				var total: int = featuresContainer.numChildren;
				for (i = 0; i < total; i++)
				{
					var currFeature: WFSFeatureBase = featuresContainer.getChildAt(i) as WFSFeatureBase;
					if (currFeature.internalFeatureId == s_internalId)
					{
						featuresContainer.removeChildAt(i);
						break;
					}
				}
			}
			onFeatureRemoved(feature);
			feature.cleanup();
		}

		/**
		 * Get Feature by featureID. If feature has featureID, it means it was saved into feature database already.
		 * @param id
		 * @return
		 *
		 */
		public function getFeatureByFeatureId(id: String): WFSFeatureBase
		{
			return getFeatureByID(id, 'featureId');
		}

		public function getRemovedFeatureByFeatureId(id: String): WFSFeatureBase
		{
			return null
		}

		/**
		 * Get Feature by internalFeatureId. It used for collaboration editor. Feature has internalFeatureId even if it is not saved into feature database.
		 * @param id
		 * @return
		 *
		 */
		public function getFeatureByInternalId(id: String): WFSFeatureBase
		{
			return getFeatureByID(id, 'internalFeatureId');
		}

		private function getFeatureByID(id: String, idType: String): WFSFeatureBase
		{
			var i_count: int = featuresContainer.numChildren;
			for (var i: int = 0; i < i_count; i++)
			{
				var currFeature: WFSFeatureBase = featuresContainer.getChildAt(i) as WFSFeatureBase;
				if (currFeature && currFeature[idType] == id)
					return currFeature;
			}
			return null;
		}

		private function getFeatureFromArrayCollectionByID(id: String, idType: String, arrColl: ArrayCollection, bRemove: Boolean = false): WFSFeatureEditable
		{
			var i_count: int = arrColl.length;
			for (var i: int = 0; i < i_count; i++)
			{
				var currFeature: WFSFeatureEditable = arrColl.getItemAt(i) as WFSFeatureEditable;
				if (currFeature && currFeature[idType] == id)
				{
					if (bRemove)
						arrColl.removeItemAt(i);
					return currFeature;
				}
			}
			return null;
		}

		override public function refresh(b_force: Boolean): void
		{
			super.refresh(b_force);
			loadData();
		}

		override public function hasPreview(): Boolean
		{
			return true;
		}

		override public function renderPreview(graphics: Graphics, f_width: Number, f_height: Number): void
		{
			graphics.lineStyle(2, 0xcc00cc, 0.7, true);
			graphics.moveTo(0, 0);
			graphics.lineTo(f_width - 1, f_height - 1);
			graphics.moveTo(0, f_height - 1);
			graphics.lineTo(f_width - 1, 0);
		}

		override public function onAreaChanged(b_finalChange: Boolean): void
		{
			//FIXME this should not be called if panning or zooming is still in progress
			//TODO should be check what was change and send correct FeatureUpdateChange, for now we're sending full update
			for each (var f: WFSFeatureBase in features)
			{
				f.invalidatePoints();
				f.update(FeatureUpdateContext.fullUpdate());
			}
		}

		public function parseFeatureMember(xml: XML, wfs: Namespace, gml: Namespace): WFSFeatureBase
		{
			return null;
		}

		// event handlers
		public function onImportLoaded(event: WFSFeatureEditorServiceEvent): void
		{
			m_wfsService.removeEventListener(WFSFeatureEditorServiceEvent.IMPORT_DATA_RECEIVED, onImportLoaded);

			var xml: XML = event.xml;
			if (xml == null)
				return; // TODO: do some error handling

			var lenBefore: int = features.length
			var newFeatures: ArrayCollection = importFeaturesFromXML(xml);
			var importEvent: InteractiveLayerEvent = new InteractiveLayerEvent(InteractiveLayerEvent.FEATURES_IMPORTED);
			importEvent.newFeaturesCount = features.length - lenBefore;
			importEvent.newFeatures = newFeatures;
			dispatchEvent(importEvent);
		}

		// event handlers
		protected function onRefreshDataLoaded(event: WFSFeatureEditorServiceEvent): void
		{
			m_wfsService.removeEventListener(WFSFeatureEditorServiceEvent.REFRESH_DATA_RECEIVED, onRefreshDataLoaded);

			var xml: XML = event.xml;
			if (xml == null)
				return; // TODO: do some error handling

			var object: Object = createRefreshedFeaturesFromXML( xml );

			var refreshEvent: InteractiveLayerEvent = new InteractiveLayerEvent(InteractiveLayerEvent.FEATURES_LOADED);
			refreshEvent.refreshFeaturesObject = object;
			dispatchEvent(refreshEvent);

		}

		public function updateFeaturesOnRefresh(newFeatures: ArrayCollection): void
		{
			features.removeAll();
			features.addAll(newFeatures);
		}

		protected function onLoadDataLoaded(event: WFSFeatureEditorServiceEvent): void
		{
			m_wfsService.removeEventListener(WFSFeatureEditorServiceEvent.LOAD_DATA_RECEIVED, onLoadDataLoaded);

			var xml: XML = event.xml;
			if (xml == null)
				return; // TODO: do some error handling

			createFeaturesFromXML(xml);
			var importEvent: InteractiveLayerEvent = new InteractiveLayerEvent(InteractiveLayerEvent.FEATURES_LOADED);
			dispatchEvent(importEvent);
		}

		public function importFeaturesFromXML(xml: XML): ArrayCollection
		{
			//do same as load features, just create them
			return createFeaturesFromXML(xml, true);
		}

		/**
		 * Creates new features from XML and remove old features if bRemoveOld = true
		 * @param xml
		 * @param bRemoveOld Boolean flag if old features must be removed (Load = true, Import = false)
		 *
		 */
		override public function createFeaturesFromXML(xml: XML, bIsImport: Boolean = false): ArrayCollection
		{
			var bRemoveOld: Boolean = true;
			if (bIsImport)
				bRemoveOld = false;
			var wfs: Namespace = new Namespace("http://www.opengis.net/wfs");
			var gml: Namespace = new Namespace("http://www.opengis.net/gml");
			var a_features: ArrayCollection = new ArrayCollection();
			//for each(var featureCollection: XML in xml.wfs::FeatureCollection) {
			for each (var xmlFeatureMember: XML in xml.gml::featureMember)
			{
				try
				{
					var feature: WFSFeatureBase = parseFeatureMember(xmlFeatureMember, wfs, gml);
					addFeatureAfterLoad(feature, a_features);
					if (bIsImport)
						feature.featureId = null;
				}
				catch (e: Error)
				{
					trace(e.getStackTrace());
				}
			}
			if (bRemoveOld)
			{
//				removeAllFeatures();
				for each (var oldFeature: WFSFeatureBase in features)
				{
					featuresContainer.removeChild(oldFeature);
					oldFeature.cleanup();
					onFeatureRemoved(oldFeature);
				}
				features = a_features;
			}
			else
				features.addAll(a_features);
			invalidateDynamicPart();
			return a_features;
		}

		/**
		 * Function returns features, which was already saved to feature database (featureID is defined)
		 * @return
		 *
		 */
		protected function getFeatureDatabaseFeatures(): ArrayCollection
		{
			var arr: ArrayCollection = new ArrayCollection();
			for each (var feature: WFSFeatureBase in features)
			{
				if (feature.featureId)
					arr.addItem(feature);
			}
			return arr;
		}

		/**
		 * Function returns features, which was already saved to feature database (featureID is defined), but was removed from stage, but it's not saved to database yet.
		 * @return
		 *
		 */
		protected function getRemovedFeatureDatabaseFeatures(): ArrayCollection
		{
			return null;
		}

		/**
		 * This function is called after Refresh is called and loaded. It will create feaures which are not exist. For features, which exist, it will check if
		 * feature is modified, if not, it will be replaced. If there is at least 1 feature modified, popup will be displayed and user will be asked if he wants
		 * use current features or features from server.
		 *
		 * @param xml
		 * @param bIsImport
		 * @return
		 *
		 */
		public function createRefreshedFeaturesFromXML(xml: XML): Object
		{
			var wfs: Namespace = new Namespace("http://www.opengis.net/wfs");
			var gml: Namespace = new Namespace("http://www.opengis.net/gml");
			var returnObject: Object = {};
			var _features: ArrayCollection = new ArrayCollection();
			var _modifiedFeaturesOld: ArrayCollection = new ArrayCollection();
			var _removedFeatures: ArrayCollection = new ArrayCollection();
			var _modifiedFeaturesNew: ArrayCollection = new ArrayCollection();
			var _modifiedFeaturesCount: int = 0;
			var existingSavedFeatures: ArrayCollection = getFeatureDatabaseFeatures();
			var existingRemovedFeatures: ArrayCollection = getRemovedFeatureDatabaseFeatures();
			var serverFeatures: ArrayCollection = new ArrayCollection();
			var feature: WFSFeatureBase;
			for each (var xmlFeatureMember: XML in xml.gml::featureMember)
			{
				try
				{
					feature = parseFeatureMember(xmlFeatureMember, wfs, gml);
					serverFeatures.addItem(feature);
				}
				catch (e: Error)
				{
					trace(e.getStackTrace());
				}
			}
			var existingFeature: WFSFeatureEditable;

			var tempExistingSavedFeatures: ArrayCollection;
			var tempExistingRemovedFeatures: ArrayCollection;

			if (existingSavedFeatures && existingSavedFeatures.length > 0)
				tempExistingSavedFeatures = new ArrayCollection(existingSavedFeatures.source);
			else
				tempExistingSavedFeatures = new ArrayCollection();
			if (existingRemovedFeatures && existingRemovedFeatures.length > 0)
				tempExistingRemovedFeatures = new ArrayCollection(existingRemovedFeatures.source);
			else
				tempExistingRemovedFeatures = new ArrayCollection();


			//all feature arrays are ready
			while (serverFeatures.length > 0)
			{
				feature = serverFeatures.getItemAt(0) as WFSFeatureBase;
				serverFeatures.removeItemAt(0);
				//find if feature exists
				if (feature.featureId)
				{
					existingFeature = getFeatureFromArrayCollectionByID(feature.featureId, 'featureId', tempExistingSavedFeatures, true);
					if (!existingFeature)
					{
						//try to find feature in removed features
						existingFeature = getFeatureFromArrayCollectionByID(feature.featureId, 'featureId', tempExistingRemovedFeatures, true);
						if (existingFeature)
							existingFeature.modified = true;
					}
					if (existingFeature)
					{
						if (existingFeature.modified)
						{
							_modifiedFeaturesCount++;
							_modifiedFeaturesOld.addItem(existingFeature);
							_modifiedFeaturesNew.addItem(feature);
						}
						else
						{
							//replace new feature with old one
							//TODO remove existing feature first
							if (existingFeature.parent == featuresContainer)
							{
								featuresContainer.removeChild(existingFeature);
								onFeatureRemoved(existingFeature);
								existingFeature.cleanup();
							}
							//add new feature
							addFeatureAfterLoad(feature, _features);
						}
					}
					else
					{
						trace("dont exist, check in removed features");
						addFeatureAfterLoad(feature, _features);
					}
				}
				else
					addFeatureAfterLoad(feature, _features);
			}
			if (tempExistingSavedFeatures.length > 0)
			{
				//there are still features, which was removed from server
				while (tempExistingSavedFeatures.length > 0)
				{
					existingFeature = tempExistingSavedFeatures.getItemAt(0) as WFSFeatureEditable;
					tempExistingSavedFeatures.removeItemAt(0);
					if (existingFeature.modified)
					{
						_modifiedFeaturesCount++;
						_removedFeatures.addItem(existingFeature);
					}
					else
					{
						//just remove it, because it was removed from server
						if (existingFeature.parent == featuresContainer)
						{
							featuresContainer.removeChild(existingFeature);
							onFeatureRemoved(existingFeature);
							existingFeature.cleanup();
						}
					}
				}
			}
			returnObject.features = _features
			returnObject.modifiedFeaturesOld = _modifiedFeaturesOld;
			returnObject.modifiedFeaturesNew = _modifiedFeaturesNew;
			returnObject.modifiedFeaturesCount = _modifiedFeaturesCount;
			returnObject.removedFeatures = _removedFeatures;
//			features = _features;
			return returnObject;
		}

		public function removeDeletedFeatures(deletedFeatures: ArrayCollection): void
		{
			for each (var oldFeature: WFSFeatureBase in deletedFeatures)
			{
				if (oldFeature.parent == featuresContainer)
				{
					featuresContainer.removeChild(oldFeature);
					onFeatureRemoved(oldFeature);
					oldFeature.cleanup();
				}
			}
		}

		public function updateModifiedFeatures(oldFeatures: ArrayCollection, newFeatures: ArrayCollection): void
		{
			for each (var oldFeature: WFSFeatureBase in oldFeatures)
			{
				if (oldFeature.parent == featuresContainer)
				{
					featuresContainer.removeChild(oldFeature);
					onFeatureRemoved(oldFeature);
					oldFeature.cleanup();
				}
				else
				{
					//feature, which was removed by user, do it's not needed to remove it right now
					trace("feature, which was removed by user, do it's not needed to remove it right now");
				}
			}
			for each (var newFeature: WFSFeatureBase in newFeatures)
			{
				addFeatureAfterLoad(newFeature, features);
			}
		}

		override protected function onDataLoadFailed(event: UniURLLoaderErrorEvent): void
		{
			trace(this + " onDataLoadFailed");
		}

		public function addQueryFeature(s_featureId: String): void
		{
			ma_queryFeatures.push(s_featureId);
		}

		public function setQueryParameterGET(s_parameter: String, s_value: String): void
		{
			md_queryParametersGET[s_parameter] = s_value;
		}

		public function clearQueryParameterGET(s_parameter: String): void
		{
			delete md_queryParametersGET[s_parameter];
		}

		public function clearAllQueryParametersGET(s_parameter: String): void
		{
			md_queryParametersGET = new Array();
		}

		override public function toString(): String
		{
			return "InteractiveLayerWFS ["+id+"]: ";
		}
	}
}
