package com.iblsoft.flexiweather.ogc
{
	import com.iblsoft.flexiweather.ogc.editable.WFSFeatureEditable;
	import com.iblsoft.flexiweather.utils.UniURLLoader;
	import com.iblsoft.flexiweather.utils.UniURLLoaderEvent;
	import com.iblsoft.flexiweather.widgets.InteractiveLayer;
	import com.iblsoft.flexiweather.widgets.InteractiveWidget;
	
	import flash.display.Graphics;
	import flash.net.URLRequest;
	import flash.net.URLVariables;
	
	import mx.collections.ArrayCollection;

	public class InteractiveLayerWFS extends InteractiveLayer
	{
		private var m_loader: UniURLLoader = new UniURLLoader();
		private var ma_features: ArrayCollection = new ArrayCollection();
		private var ma_queryFeatures: ArrayCollection = new ArrayCollection();
		private var md_queryParametersGET: Array = new Array();
		
		protected var ms_serviceURL: String = null;
		protected var m_version: Version;

		protected var m_use_monochrome: Boolean = false;
		protected var m_monochrome_color: uint = 0x333333;

		public function InteractiveLayerWFS(
				container: InteractiveWidget,
				version: Version)
		{
			super(container);
			m_loader.addEventListener(UniURLLoader.DATA_LOADED, onDataLoaded);
			m_loader.addEventListener(UniURLLoader.DATA_LOAD_FAILED, onDataLoadFailed);
			m_version = version;
		}

		public function updateData(): void
		{
			if(ms_serviceURL == null)
				return;
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
			m_loader.load(url);
		}
		
		/**
		 * 
		 */
		public function addFeature(feature: WFSFeatureBase): void
		{
			addChild(feature);
			ma_features.addItem(feature);
			onFeatureAdded(feature);
		}
		
		public function addFeatureAfterLoad(feature: WFSFeatureBase, a_features: ArrayCollection = null): void
		{
			if(feature != null) {
				feature.update(this);
				if (a_features)
					a_features.addItem(feature);
				addChild(feature);
				onFeatureAdded(feature);
			}
		}

		public function removeFeatureByID(feature: WFSFeatureBase): void
		{
			var internalID: String = feature.internalFeatureId;
			
			var i: int = ma_features.getItemIndex(feature);
			if(i >= 0)
				ma_features.removeItemAt(i);
				
			if (internalID)
			{
				var total: int = numChildren;
				for (i = 0; i < total; i++)
				{
					var currFeature: WFSFeatureBase = getChildAt(i) as WFSFeatureBase;
					if (currFeature.internalFeatureId == internalID)
					{
						removeChildAt(i);
						return;
					} 
				}
			}
			
			onFeatureRemoved(feature);
		}
		public function getFeatureByInternalID(id: String): WFSFeatureBase
		{
			var total: int = numChildren;
			for (var i:int = 0; i < total; i++)
			{
				var currFeature: WFSFeatureBase = getChildAt(i) as WFSFeatureBase;
				trace("InteractiveLayerWFS currFeature: " + currFeature.internalFeatureId + " ID: " + id);
				if (currFeature.internalFeatureId == id)
				{
					return currFeature;
				} 
			}
			return null;
		}
		public function removeFeature(feature: WFSFeatureBase): void
		{
			removeChild(feature);
			var i: int = ma_features.getItemIndex(feature);
			if(i >= 0)
				ma_features.removeItemAt(i);
			onFeatureRemoved(feature);
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
			{
				graphics.lineStyle(2, 0xcc00cc, 0.7, true);
				graphics.moveTo(0, 0);
				graphics.lineTo(f_width - 1, f_height - 1);
				graphics.moveTo(0, f_height - 1);
				graphics.lineTo(f_width - 1, 0);
			}
		}
		
		override public function onAreaChanged(b_finalChange: Boolean): void
		{
			for each(var f: WFSFeatureBase in ma_features) {
				trace("onAreaChanged ["+this+"] feature: " + f);
				f.invalidatePoints();
				f.update(this);
			}
		}

		public function parseFeatureMember(xml: XML, wfs: Namespace, gml: Namespace): WFSFeatureBase
		{
			return null;
		}
		
		// event handlers
		public function onDataLoaded(event: UniURLLoaderEvent): void
		{
			var xml: XML = event.result as XML;
			if(xml == null)
				return; // TODO: do some error handling
				
			createFeaturesFromXML( xml );
		}
		
		public function createFeaturesFromXML( xml: XML): void
		{
			var wfs: Namespace = new Namespace("http://www.opengis.net/wfs");
			var gml: Namespace = new Namespace("http://www.opengis.net/gml");
			var a_features: ArrayCollection = new ArrayCollection(); 
			//for each(var featureCollection: XML in xml.wfs::FeatureCollection) {
			for each(var xmlFeatureMember: XML in xml.gml::featureMember) {
				try {
					var feature: WFSFeatureBase = parseFeatureMember(xmlFeatureMember, wfs, gml)
					addFeatureAfterLoad(feature, a_features);
				}
				catch(e: Error) {
					trace(e.getStackTrace());
				}
			}
			
			for each(var oldFeature: WFSFeatureBase in ma_features) {
				removeChild(oldFeature);
				onFeatureRemoved(oldFeature);
			}
			ma_features = a_features;
			invalidateDynamicPart();
		}
		
		
		
		public function onDataLoadFailed(event: UniURLLoaderEvent): void
		{
		}

		protected function onFeatureAdded(feature: WFSFeatureBase): void
		{}

		protected function onFeatureRemoved(feature: WFSFeatureBase): void
		{}

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
		
		public function set use_monochrome(val: Boolean): void
		{
			var needUpdate: Boolean = false;
			if (m_use_monochrome != val){
				needUpdate = true;
			}
			
			m_use_monochrome = val;
			
			if (needUpdate){
				for (var i: int = 0; i < numChildren; i++){
					if (getChildAt(i) is WFSFeatureEditable){
						WFSFeatureEditable(getChildAt(i)).update(this);
					}
				}
			}
		}
		
		public function get use_monochrome(): Boolean
		{ return m_use_monochrome; }
		
		public function set monochrome_color(val: uint): void
		{
			var needUpdate: Boolean = false;
			if (m_monochrome_color != val){
				needUpdate = true;
			}
			
			m_monochrome_color = val;
			
			if (needUpdate){
				for (var i: int = 0; i < numChildren; i++){
					if (getChildAt(i) is WFSFeatureEditable){
						WFSFeatureEditable(getChildAt(i)).update(this);
					}
				}
			}
		}
		
		public function get monochrome_color(): uint
		{ return m_monochrome_color; }
	}
}