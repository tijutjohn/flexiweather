package com.iblsoft.flexiweather.ogc
{
	import com.iblsoft.flexiweather.events.InteractiveLayerEvent;
	import com.iblsoft.flexiweather.ogc.editable.WFSFeatureEditable;
	import com.iblsoft.flexiweather.utils.UniURLLoader;
	import com.iblsoft.flexiweather.utils.UniURLLoaderEvent;
	import com.iblsoft.flexiweather.widgets.InteractiveLayer;
	import com.iblsoft.flexiweather.widgets.InteractiveWidget;
	
	import flash.display.Graphics;
	import flash.display.Sprite;
	import flash.net.URLRequest;
	import flash.net.URLVariables;
	
	import mx.collections.ArrayCollection;

	public class InteractiveLayerWFS extends InteractiveLayer
	{
		private var m_loader: UniURLLoader = new UniURLLoader();
		private var ma_features: ArrayCollection = new ArrayCollection();
		private var m_featuresContainer: Sprite = new Sprite();
		private var ma_queryFeatures: ArrayCollection = new ArrayCollection();
		private var md_queryParametersGET: Array = new Array();
		
		protected var ms_serviceURL: String = null;
		protected var m_version: Version;

		protected var mb_useMonochrome: Boolean = false;
		protected var mi_monochromeColor: uint = 0x333333;
		
		public function InteractiveLayerWFS(
				container: InteractiveWidget,
				version: Version)
		{
			super(container);
			
			m_loader.addEventListener(UniURLLoader.DATA_LOAD_FAILED, onDataLoadFailed);
			
			m_version = version;
			m_featuresContainer.mouseEnabled = false;
			m_featuresContainer.mouseChildren = false;
			addChild(m_featuresContainer);
		}

		public function importData(serviceURL: String, run: String, validity: String) : void
		{
			var url: URLRequest = new URLRequest(serviceURL);
			
			m_loader.addEventListener(UniURLLoader.DATA_LOADED, onImportLoaded);
			
			if(url.data == null)
				url.data = new URLVariables();
			url.data['SERVICE'] = 'WFS';
			url.data['VERSION'] = m_version.toString();
			url.data['REQUEST'] = 'GetFeature';
			url.data['RUN'] = run;
			url.data['VALIDITY'] = validity;
			
			if(!m_version.isLessThan(1, 1, 0)) {
				url.data['SRSNAME'] = container.getCRS();
			}
			url.data['TYPENAME'] = ma_queryFeatures.toArray().join(",");
			m_loader.load(url, null, "Importing features");
		}
		
		/**
		 * update WFS layer data (load them or refresh). 
		 * @param type - type of updating. Possible values are: load, refresh.
		 * 
		 */		
		public function updateData(type: String = 'load'): void
		{
			if(ms_serviceURL == null)
				return;
			
			switch (type)
			{
				case 'load':
					m_loader.addEventListener(UniURLLoader.DATA_LOADED, onDataLoaded);
					break;
				case 'refresh':
					m_loader.addEventListener(UniURLLoader.DATA_LOADED, onRefreshDataLoaded);
					break;
				
			}
			
			var url: URLRequest = new URLRequest(ms_serviceURL);
			if(url.data == null)
				url.data = new URLVariables();
			url.data['SERVICE'] = 'WFS';
			url.data['VERSION'] = m_version.toString();
			url.data['REQUEST'] = 'GetFeature';
			for(var s_param: String in md_queryParametersGET) {
				var s_value: String = md_queryParametersGET[s_param];
				url.data[s_param] = s_value;
			}
			if(!m_version.isLessThan(1, 1, 0)) {
				url.data['SRSNAME'] = container.getCRS();
			}
			url.data['TYPENAME'] = ma_queryFeatures.toArray().join(",");
			m_loader.load(url, null, "Loading features");
		}
		
		public function addFeature(feature: WFSFeatureBase): void
		{
			feature.setMaster(this);
			feature.update();
			m_featuresContainer.addChild(feature);
			ma_features.addItem(feature);
			onFeatureAdded(feature);
		}
		
		private function addFeatureAfterLoad(feature: WFSFeatureBase, a_features: ArrayCollection = null): void
		{
			if(feature != null) {
				feature.setMaster(this);
				feature.update();
				m_featuresContainer.addChild(feature);
				if(a_features)
					a_features.addItem(feature);
				onFeatureAdded(feature);
			}
		}

		public function removeFeatureHavingSameInternalId(feature: WFSFeatureBase): void
		{
			var s_internalId: String = feature.internalFeatureId;
			
			var i: int = ma_features.getItemIndex(feature);
			if(i >= 0)
				ma_features.removeItemAt(i);
				
			if(s_internalId)
			{
				var total: int = m_featuresContainer.numChildren;
				for(i = 0; i < total; i++)
				{
					var currFeature: WFSFeatureBase = m_featuresContainer.getChildAt(i) as WFSFeatureBase;
					if(currFeature.internalFeatureId == s_internalId)
					{
						m_featuresContainer.removeChildAt(i);
						break;
					} 
				}
			}
			
			onFeatureRemoved(feature);
			feature.cleanup();
		}
		
		public function removeAllFeatures(): void
		{
			var i_count: int = m_featuresContainer.numChildren;
			for(var i: int = i_count - 1; i >= 0; --i)
			{
				var feature: WFSFeatureBase = m_featuresContainer.getChildAt(i) as WFSFeatureBase;
				var id: int = ma_features.getItemIndex(feature);
				if (id >= 0)
				{
					ma_features.removeItemAt(id);
				}
				onFeatureRemoved(feature);
				feature.cleanup();
				m_featuresContainer.removeChildAt(i);
			}
			if (ma_features.length > 0)
			{
				trace("after removing alll features, there are still features in ma_features: " + ma_features.length + " ["+this+"]")
				ma_features.removeAll();
			}
		}

		public override function destroy(): void
		{
			removeAllFeatures();
			super.destroy();
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
			var i_count: int = m_featuresContainer.numChildren;
			for(var i:int = 0; i < i_count; i++)
			{
				var currFeature: WFSFeatureBase = m_featuresContainer.getChildAt(i) as WFSFeatureBase;
				if(currFeature && currFeature[idType] == id)
				{
					return currFeature;	
				} 
			}
			return null;
		}
		private function getFeatureFromArrayCollectionByID(id: String, idType: String, arrColl: ArrayCollection, bRemove: Boolean = false): WFSFeatureEditable
		{
			var i_count: int = arrColl.length;
			for(var i:int = 0; i < i_count; i++)
			{
				var currFeature: WFSFeatureEditable = arrColl.getItemAt(i) as WFSFeatureEditable;
				if(currFeature && currFeature[idType] == id)
				{
					if (bRemove)
						arrColl.removeItemAt(i);
						
					return currFeature;	
				} 
			}
			return null;
		}

		public function removeFeature(feature: WFSFeatureBase): void
		{
			if (feature.parent == m_featuresContainer)
			{
				m_featuresContainer.removeChild(feature);
				var i: int = ma_features.getItemIndex(feature);
				if(i >= 0)
					ma_features.removeItemAt(i);
				onFeatureRemoved(feature);
				feature.cleanup();
			}
		}
		
        override public function refresh(b_force: Boolean): void
        {
        	super.refresh(b_force);
        	updateData();
        }

		override public function hasPreview(): Boolean
		{ return true; }

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
			
			for each(var f: WFSFeatureBase in ma_features) {
				//trace("onAreaChanged ["+this+"] feature: " + f);
				f.invalidatePoints();
				f.update();
			}
		}

		public function parseFeatureMember(xml: XML, wfs: Namespace, gml: Namespace): WFSFeatureBase
		{
			return null;
		}
		
		// event handlers
		public function onImportLoaded(event: UniURLLoaderEvent): void
		{
			m_loader.removeEventListener(UniURLLoader.DATA_LOADED, onImportLoaded);
			
			var xml: XML = event.result as XML;
			if(xml == null)
				return; // TODO: do some error handling
				
			var lenBefore: int = ma_features.length
			var newFeatures: ArrayCollection = importFeaturesFromXML( xml );
			
			var importEvent: InteractiveLayerEvent = new InteractiveLayerEvent(InteractiveLayerEvent.FEATURES_IMPORTED);
			importEvent.newFeaturesCount = ma_features.length - lenBefore;
			importEvent.newFeatures = newFeatures;
			dispatchEvent(importEvent);
		}
		
		// event handlers
		public function onRefreshDataLoaded(event: UniURLLoaderEvent): void
		{
			m_loader.removeEventListener(UniURLLoader.DATA_LOADED, onRefreshDataLoaded);
			
			var xml: XML = event.result as XML;
			if(xml == null)
				return; // TODO: do some error handling
				
			var object: Object = createRefreshedFeaturesFromXML( xml );
			
			var refreshEvent: InteractiveLayerEvent = new InteractiveLayerEvent(InteractiveLayerEvent.FEATURES_LOADED);
			refreshEvent.refreshFeaturesObject = object;
			dispatchEvent(refreshEvent);
			
		}
		
		public function onDataLoaded(event: UniURLLoaderEvent): void
		{
			m_loader.removeEventListener(UniURLLoader.DATA_LOADED, onDataLoaded);
			
			var xml: XML = event.result as XML;
			if(xml == null)
				return; // TODO: do some error handling
				
			createFeaturesFromXML( xml );
			
			var importEvent: InteractiveLayerEvent = new InteractiveLayerEvent(InteractiveLayerEvent.FEATURES_LOADED);
			dispatchEvent(importEvent);
		}
		
		public function importFeaturesFromXML( xml: XML): ArrayCollection
		{
			trace("importFeaturesFromXML");
			//do same as load features, just create them
			return createFeaturesFromXML(xml, true);
		}
		
		/**
		 * Creates new features from XML and remove old features if bRemoveOld = true 
		 * @param xml
		 * @param bRemoveOld Boolean flag if old features must be removed (Load = true, Import = false)
		 * 
		 */		
		public function createFeaturesFromXML( xml: XML, bIsImport: Boolean = false): ArrayCollection
		{
			var bRemoveOld: Boolean = true;
			if (bIsImport)
				bRemoveOld = false;
			
			var wfs: Namespace = new Namespace("http://www.opengis.net/wfs");
			var gml: Namespace = new Namespace("http://www.opengis.net/gml");
			var a_features: ArrayCollection = new ArrayCollection(); 
			//for each(var featureCollection: XML in xml.wfs::FeatureCollection) {
			for each(var xmlFeatureMember: XML in xml.gml::featureMember) {
				try {
					var feature: WFSFeatureBase = parseFeatureMember(xmlFeatureMember, wfs, gml);
					addFeatureAfterLoad(feature, a_features);
					if (bIsImport)
					{
						feature.featureId = null; 
					}
				}
				catch(e: Error) {
					trace(e.getStackTrace());
				}
			}
			
			if (bRemoveOld)
			{
				for each(var oldFeature: WFSFeatureBase in ma_features) {
					m_featuresContainer.removeChild(oldFeature);
					onFeatureRemoved(oldFeature);
				}
	 			ma_features = a_features;
			} else {
				ma_features.addAll(a_features);
			}
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
			for each (var feature: WFSFeatureBase in ma_features)
			{
				if (feature.featureId)
				{
					arr.addItem(feature);
				}
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
		public function createRefreshedFeaturesFromXML( xml: XML): Object
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
			
			for each(var xmlFeatureMember: XML in xml.gml::featureMember) 
			{
				try {
					feature = parseFeatureMember(xmlFeatureMember, wfs, gml);
					serverFeatures.addItem(feature);
				}
				catch(e: Error) {
					trace(e.getStackTrace());
				}
			}
			
			trace("\nSTART saved: " + existingSavedFeatures.length + " existingRemovedFeatures: " + existingRemovedFeatures.length + " serverFeatures: " + serverFeatures.length);
			
			var existingFeature: WFSFeatureEditable;
			
			//all feature arrays are ready
			while (serverFeatures.length > 0)
			{
				feature = serverFeatures.getItemAt(0) as WFSFeatureBase;
				serverFeatures.removeItemAt(0);
				
				//find if feature exists
				if (feature.featureId)
				{
					existingFeature = getFeatureFromArrayCollectionByID(feature.featureId, 'featureId', existingSavedFeatures, true);
					if (!existingFeature)
					{
						//try to find feature in removed features
						existingFeature = getFeatureFromArrayCollectionByID(feature.featureId, 'featureId', existingRemovedFeatures, true);
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
						} else {
							//replace new feature with old one
							//TODO remove existing feature first
							if (existingFeature.parent == m_featuresContainer)
							{
								m_featuresContainer.removeChild(existingFeature);
								onFeatureRemoved(existingFeature);
							}
					
							//add new feature
							addFeatureAfterLoad(feature, _features);
						}
					} else {
						trace("dont exist, check in removed features");
						addFeatureAfterLoad(feature, _features);
					}
				} else {
					addFeatureAfterLoad(feature, _features);
				}
				
				
				trace("saved: " + existingSavedFeatures.length + " existingRemovedFeatures: " + existingRemovedFeatures.length + " serverFeatures: " + serverFeatures.length);
				
			}
			
			if (existingSavedFeatures.length > 0)
			{
				//there are still features, which was removed from server
				while (existingSavedFeatures.length > 0)
				{
					existingFeature = existingSavedFeatures.getItemAt(0) as WFSFeatureEditable;
					existingSavedFeatures.removeItemAt(0);
					
					if (existingFeature.modified)
					{
						_modifiedFeaturesCount++;
						_removedFeatures.addItem(existingFeature);
					} else {
						//just remove it, because it was removed from server
						if (existingFeature.parent == m_featuresContainer)
						{
							m_featuresContainer.removeChild(existingFeature);
							onFeatureRemoved(existingFeature);
						}
					}
				}
			}
			returnObject.features = _features
			returnObject.modifiedFeaturesOld = _modifiedFeaturesOld;
			returnObject.modifiedFeaturesNew = _modifiedFeaturesNew;
			returnObject.modifiedFeaturesCount = _modifiedFeaturesCount;
			returnObject.removedFeatures = _removedFeatures;
			
			ma_features = _features;
			
			return returnObject;
		}
		
		public function removeDeletedFeatures(deletedFeatures: ArrayCollection): void
		{
			for each(var oldFeature: WFSFeatureBase in deletedFeatures) {
				if (oldFeature.parent == m_featuresContainer)
				{
					m_featuresContainer.removeChild(oldFeature);
					onFeatureRemoved(oldFeature);
				} 
			}
		}
		public function updateModifiedFeatures(oldFeatures: ArrayCollection, newFeatures: ArrayCollection): void
		{
			for each(var oldFeature: WFSFeatureBase in oldFeatures) {
				if (oldFeature.parent == m_featuresContainer)
				{
					m_featuresContainer.removeChild(oldFeature);
					onFeatureRemoved(oldFeature);
				} else {
					//feature, which was removed by user, do it's not needed to remove it right now
					trace("feature, which was removed by user, do it's not needed to remove it right now");
				}
			}
			
			for each(var newFeature: WFSFeatureBase in newFeatures) {
				addFeatureAfterLoad(newFeature, ma_features);
			}
		}
		
		
		
		public function onDataLoadFailed(event: UniURLLoaderEvent): void
		{
		}

		protected function onFeatureAdded(feature: WFSFeatureBase): void
		{
			invalidateDynamicPart();
		}

		protected function onFeatureRemoved(feature: WFSFeatureBase): void
		{
			invalidateDynamicPart();
		}

		public function addQueryFeature(s_featureId: String): void
		{ ma_queryFeatures.addItem(s_featureId); }
		
		public function setQueryParameterGET(s_parameter: String, s_value: String): void
		{ md_queryParametersGET[s_parameter] = s_value; }

		public function clearQueryParameterGET(s_parameter: String): void
		{ delete md_queryParametersGET[s_parameter]; }

		public function clearAllQueryParametersGET(s_parameter: String): void
		{ md_queryParametersGET = new Array(); }

		// getters & setters		
		public function get features(): ArrayCollection
		{ return ma_features; }
		
		public function get serviceURL(): String
		{ return ms_serviceURL; }

		public function set serviceURL(s_serviceURL: String): void
		{ ms_serviceURL = s_serviceURL; }
		
		public function set useMonochrome(val: Boolean): void
		{
			var b_needUpdate: Boolean = false;
			if(mb_useMonochrome != val)
				b_needUpdate = true;
			
			mb_useMonochrome = val;
			
			if(b_needUpdate) {
				for(var i: int = 0; i < m_featuresContainer.numChildren; i++){
					if(m_featuresContainer.getChildAt(i) is WFSFeatureEditable){
						WFSFeatureEditable(m_featuresContainer.getChildAt(i)).update();
					}
				}
			}
		}
		
		public function get useMonochrome(): Boolean
		{ return mb_useMonochrome; }
		
		public function set monochromeColor(i_color: uint): void
		{
			var b_needUpdate: Boolean = false;
			if(mi_monochromeColor != i_color)
				b_needUpdate = true;
			
			mi_monochromeColor = i_color;
			
			if(b_needUpdate) {
				for(var i: int = 0; i < m_featuresContainer.numChildren; i++) {
					if(m_featuresContainer.getChildAt(i) is WFSFeatureEditable) {
						WFSFeatureEditable(m_featuresContainer.getChildAt(i)).update();
					}
				}
			}
		}
		
		public function get monochromeColor(): uint
		{ return mi_monochromeColor; }
		
		public function get featuresContainer(): Sprite
		{ return m_featuresContainer; }
	}
}
