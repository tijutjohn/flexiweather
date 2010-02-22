package com.iblsoft.flexiweather.ogc
{
	import com.iblsoft.flexiweather.ogc.editable.IInteractiveLayerProvider;
	import com.iblsoft.flexiweather.utils.Storage;
	import com.iblsoft.flexiweather.widgets.InteractiveLayer;
	import com.iblsoft.flexiweather.widgets.InteractiveWidget;
	
	import flash.events.DataEvent;
	import flash.events.Event;
	import flash.net.URLRequest;
	
	import mx.collections.ArrayCollection;
	
	public class WMSLayerConfiguration extends OGCLayerConfiguration
			implements IBehaviouralObject, IInteractiveLayerProvider
	{
		public var ma_layerNames: Array = [];
		public var ma_styleNames: Array = [];

		public var ma_behaviours: Array = [];

		public var ms_dimensionTimeName: String = null;
		public var ms_dimensionRunName: String = null;
		public var ms_dimensionForecastName: String = null;
		public var ms_dimensionVerticalLevelName: String = null;

		// runtime variables
		public var ma_layerConfigurations: Array;

		public static const CAPABILITIES_UPDATED: String = "capabilitiesUpdated";
		[Event(name = CAPABILITIES_UPDATED, type = "flash.events.DataEvent")]

		public function WMSLayerConfiguration(service: WMSServiceConfiguration = null, a_layerNames: Array = null)
		{
			super(service);
			if(a_layerNames != null)
				ma_layerNames = a_layerNames;
			if(m_service != null)
				m_service.addEventListener(WMSServiceConfiguration.CAPABILITIES_UPDATED, onCapabilitiesUpdated)
			onCapabilitiesUpdated(null);
		}
		
		override public function serialize(storage: Storage): void
		{
			if(storage.isLoading() && m_service != null)
				m_service.removeEventListener(WMSServiceConfiguration.CAPABILITIES_UPDATED, onCapabilitiesUpdated)
			super.serialize(storage);
			m_service.addEventListener(WMSServiceConfiguration.CAPABILITIES_UPDATED, onCapabilitiesUpdated)

			storage.serializeNonpersistentArray(
					"layer-name", ma_layerNames, String)
			storage.serializeNonpersistentArray(
					"style-name", ma_styleNames, String)
			storage.serializeNonpersistentArrayMap(
					"behaviour", ma_behaviours, String, String);
			ms_dimensionTimeName = storage.serializeString(
					"dimension-time-name", ms_dimensionTimeName, null);
			ms_dimensionRunName = storage.serializeString(
					"dimension-run-name", ms_dimensionRunName, null);
			ms_dimensionForecastName = storage.serializeString(
					"dimension-forecast-name", ms_dimensionForecastName, null);
			ms_dimensionVerticalLevelName = storage.serializeString(
					"dimension-level-name", ms_dimensionVerticalLevelName, null);
		}
		
		public function toGetMapRequest(
				s_crs: String, s_bbox: String,
				i_width: int, i_height: int,
				s_stylesList: String,
				s_layersOverride: String = null): URLRequest
		{
			var r: URLRequest = m_service.toRequest("GetMap");
			r.data.LAYERS = s_layersOverride == null ? ma_layerNames.join(",") : s_layersOverride;
			if(m_service.m_version.isLessThan(1, 3, 0)) 
				r.data.SRS = s_crs;
			else 
				r.data.CRS = s_crs; 
			r.data.BBOX = s_bbox; 
			r.data.WIDTH = i_width; 
			r.data.HEIGHT = i_height;
			if(s_stylesList != null)
				r.data.STYLES = s_stylesList;
			r.data.FORMAT = "image/png"; 
			r.data.TRANSPARENT = "TRUE";
			return r;
		}

		public function toGetFeatureInfoRequest(
				s_crs: String, s_bbox: String,
				i_width: int, i_height: int,
				a_queriedLayerNames: Array,
				i_x: int, i_y: int,
				s_stylesList: String): URLRequest
		{
			var r: URLRequest = m_service.toRequest("GetFeatureInfo");
			r.data.LAYERS = ma_layerNames.join(",");
			r.data.QUERY_LAYERS = a_queriedLayerNames.join(",");
			if(m_service.m_version.isLessThan(1, 3, 0)) {
				r.data.SRS = s_crs;
				r.data.X = i_x;
				r.data.Y = i_y;
			}
			else { 
				r.data.CRS = s_crs;
				r.data.I = i_x;
				r.data.J = i_y;
			} 
			r.data.BBOX = s_bbox; 
			r.data.WIDTH = i_width; 
			r.data.HEIGHT = i_height;
			if(s_stylesList != null)
				r.data.STYLES = s_stylesList;
			r.data.FORMAT = "text/html"; 
			r.data.TRANSPARENT = "TRUE";
			return r;
		}
		
		public function dimensionToParameterName(s_dim: String): String
		{
			if(s_dim == "TIME" || s_dim == "ELEVATION")
				return s_dim;
			return "DIM_" + s_dim; 
		}
		
		protected function onCapabilitiesUpdated(event: Event): void
		{
			var a_layers: ArrayCollection = new ArrayCollection();
			for(var i: int = 0; i < ma_layerNames.length; ++i) {
				var l: WMSLayer = null;
				if(m_service != null)
					l = service.getLayerByName(ma_layerNames[i]);
				a_layers.addItem(l);
			}
			var b_changed: Boolean = false;
			if(ma_layerConfigurations == null)
				b_changed = true;
			else {
				for(i = 0; i < a_layers.length; ++i) {
					if(a_layers[i] == null) {
						if(ma_layerConfigurations[i] == null)
							continue;
						else {
							b_changed = true;
							break;
						}
					}
					if(!a_layers[i].equals(ma_layerConfigurations[i])) {
						b_changed = true;
						break;
					} 
				}
			}
			if(b_changed) {
				ma_layerConfigurations = a_layers.toArray();
				dispatchEvent(new DataEvent(CAPABILITIES_UPDATED));
			}
		}

		// IBehaviouralObject implementation
		public function setBehaviourString(s_behaviourId: String, s_value: String): void
		{ ma_behaviours[s_behaviourId] = s_value; }

		public function getBehaviourString(s_behaviourId: String, s_default: String = null): String
		{
			return (s_behaviourId in ma_behaviours) ? ma_behaviours[s_behaviourId] : s_default;
		}
		
		// IInteractiveLayerProvider implementation
		public function createInteractiveLayer(iw: InteractiveWidget): InteractiveLayer
		{
			var l: InteractiveLayerWMS = new InteractiveLayerWMS(iw, this);
			l.updateData();
			return l;
		}

		public function hasBehaviourString(s_behaviourId: String): Boolean
		{ return s_behaviourId in ma_behaviours; }
				
		// getters & setters				
		public function get service(): WMSServiceConfiguration
		{ return WMSServiceConfiguration(m_service); }

		public function set service(service: WMSServiceConfiguration): void 
		{ m_service = service; }

		public function get behaviours(): Array
		{ return ma_behaviours; }

		public function set dimensionTimeName(s: String): void
		{ ms_dimensionTimeName = s; }

		public function get dimensionTimeName(): String
		{ return ms_dimensionTimeName; }

		public function set dimensionRunName(s: String): void
		{ ms_dimensionRunName = s; }

		public function get dimensionRunName(): String
		{ return ms_dimensionRunName; }

		public function set dimensionForecastName(s: String): void
		{ ms_dimensionForecastName = s; }

		public function get dimensionForecastName(): String
		{ return ms_dimensionForecastName; }

		public function set dimensionVerticalLevelName(s: String): void
		{ ms_dimensionVerticalLevelName = s; }

		public function get dimensionVerticalLevelName(): String
		{ return ms_dimensionVerticalLevelName; }
	}
}