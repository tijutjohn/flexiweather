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

		protected var mb_useMonochrome: Boolean = false;
		protected var mi_monochromeColor: uint = 0x333333;
		
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
			m_loader.load(url, null, "Loading features");
		}
		
		public function addFeature(feature: WFSFeatureBase): void
		{
			feature.setMaster(this);
			feature.update();
			addChild(feature);
			ma_features.addItem(feature);
			onFeatureAdded(feature);
		}
		
		private function addFeatureAfterLoad(feature: WFSFeatureBase, a_features: ArrayCollection = null): void
		{
			if(feature != null) {
				feature.setMaster(this);
				feature.update();
				addChild(feature);
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
				var total: int = numChildren;
				for(i = 0; i < total; i++)
				{
					var currFeature: WFSFeatureBase = getChildAt(i) as WFSFeatureBase;
					if(currFeature.internalFeatureId == s_internalId)
					{
						removeChildAt(i);
						return;
					} 
				}
			}
			
			onFeatureRemoved(feature);
			feature.setMaster(null);
			feature.cleanup();
		}

		public function getFeatureByInternalId(id: String): WFSFeatureBase
		{
			var i_count: int = numChildren;
			for(var i:int = 0; i < i_count; i++)
			{
				var currFeature: WFSFeatureBase = getChildAt(i) as WFSFeatureBase;
				if(currFeature.internalFeatureId == id)
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
			feature.cleanup();
			feature.setMaster(null);
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
			for each(var f: WFSFeatureBase in ma_features) {
				trace("onAreaChanged ["+this+"] feature: " + f);
				f.invalidatePoints();
				f.update();
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
				for(var i: int = 0; i < numChildren; i++){
					if(getChildAt(i) is WFSFeatureEditable){
						WFSFeatureEditable(getChildAt(i)).update();
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
				for(var i: int = 0; i < numChildren; i++) {
					if(getChildAt(i) is WFSFeatureEditable) {
						WFSFeatureEditable(getChildAt(i)).update();
					}
				}
			}
		}
		
		public function get monochromeColor(): uint
		{ return mi_monochromeColor; }
	}
}
