package com.iblsoft.flexiweather.ogc
{
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

		public function InteractiveLayerWFS(container: InteractiveWidget)
		{
			super(container);
			m_loader.addEventListener(UniURLLoader.DATA_LOADED, onDataLoaded);
			m_loader.addEventListener(UniURLLoader.DATA_LOAD_FAILED, onDataLoadFailed);
		}

		public function updateData(): void
		{
			if(ms_serviceURL == null)
				return;
			var url: URLRequest = new URLRequest(ms_serviceURL);
			if(url.data == null)
				url.data = new URLVariables();
			url.data['SERVICE'] = 'WFS';
			url.data['VERSION'] = new Version(1, 0, 0).toString();
			url.data['REQUEST'] = 'GetFeature';
			for(var s_param: String in md_queryParametersGET) {
				var s_value: String = md_queryParametersGET[s_param];
				url.data[s_param] = s_value;
			}
			url.data['TypeName'] = ma_queryFeatures.toArray().join(",");
			m_loader.load(url);
		}
		
		public function addFeature(feature: WFSFeatureBase): void
		{
			addChild(feature);
			ma_features.addItem(feature);
			onFeatureAdded(feature);
		}

		public function removeFeature(feature: WFSFeatureBase): void
		{
			removeChild(feature);
			var i: int = ma_features.getItemIndex(feature);
			if(i >= 0)
				ma_features.removeItemAt(i);
			onFeatureRemoved(feature);
		}
		
        override public function refresh(): void
        {
        	super.refresh();
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
				f.invalidatePoints();
				f.update(this);
			}
		}

		protected function parseFeatureMember(xml: XML, wfs: Namespace, gml: Namespace): WFSFeatureBase
		{
			return null;
		}
		
		// event handlers
		public function onDataLoaded(event: UniURLLoaderEvent): void
		{
			var xml: XML = event.result as XML;
			if(xml == null)
				return; // TODO: do some error handling
			var wfs: Namespace = new Namespace("http://www.opengis.net/wfs");
			var gml: Namespace = new Namespace("http://www.opengis.net/gml");
			var a_features: ArrayCollection = new ArrayCollection(); 
			//for each(var featureCollection: XML in xml.wfs::FeatureCollection) {
			for each(var xmlFeatureMember: XML in xml.gml::featureMember) {
				try {
					var feature: WFSFeatureBase = parseFeatureMember(xmlFeatureMember, wfs, gml)
					if(feature != null) {
						feature.update(this);
						a_features.addItem(feature);
						addChild(feature);
						onFeatureAdded(feature);
					}
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
	}
}