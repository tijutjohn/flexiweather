package com.iblsoft.flexiweather.ogc
{
	import com.iblsoft.flexiweather.ogc.editable.IInteractiveLayerProvider;
	import com.iblsoft.flexiweather.utils.Storage;
	import com.iblsoft.flexiweather.utils.UniURLLoader;
	import com.iblsoft.flexiweather.widgets.InteractiveLayer;
	import com.iblsoft.flexiweather.widgets.InteractiveWidget;
	
	import flash.events.DataEvent;
	import flash.events.Event;
	import flash.net.URLRequest;
	
	import mx.collections.ArrayCollection;
	
	public class WMSLayerConfiguration extends OGCLayerConfiguration
			implements IBehaviouralObject, IInteractiveLayerProvider, ILayerConfiguration
	{
		public var ma_layerNames: Array = [];
		public var ma_styleNames: Array = [];

		public var ma_behaviours: Array = [];
		public var ma_availableImageFormats: Array = [];
		

		public var ms_dimensionTimeName: String = null;
		public var ms_dimensionRunName: String = null;
		public var ms_dimensionForecastName: String = null;
		public var ms_dimensionVerticalLevelName: String = null;
		public var ms_imageFormat: String = null;
		public var mb_legendIsDimensionDependant: Boolean;
		public var mi_autoRefreshPeriod: uint = 0;
		
		public var ms_layerType: String = null;
		
		
		// runtime variables
		public var ma_layerConfigurations: Array;

		public static const CAPABILITIES_UPDATED: String = "capabilitiesUpdated";
		public static const CAPABILITIES_RECEIVED: String = "capabilitiesReceived";
		
		[Event(name = CAPABILITIES_UPDATED, type = "flash.events.DataEvent")]
		[Event(name = CAPABILITIES_RECEIVED, type = "flash.events.DataEvent")]

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

			try {
				storage.serializeNonpersistentArray("layer-name", ma_layerNames, String);
			} catch (error: Error) {
				trace("WMSLayeConfig ma_layerNames error: " + error.message);
			}
			try {
				storage.serializeNonpersistentArray("style-name", ma_styleNames, String)
			} catch (error: Error) {
				trace("WMSLayeConfig ma_styleNames error: " + error.message);
			}
			try {
				storage.serializeNonpersistentArrayMap("behaviour", ma_behaviours, String, String);
				trace("ma_behaviours: ")
				for (var k: String in ma_behaviours)
				{
					trace("ma_behaviours["+k+"] = " + ma_behaviours[k] + "<<");
				}
			} catch (error: Error) {
				trace("WMSLayeConfig ma_behaviours error: " + error.message);
			}
			
			ms_dimensionTimeName = storage.serializeString(
					"dimension-time-name", ms_dimensionTimeName, null);
			ms_dimensionRunName = storage.serializeString(
					"dimension-run-name", ms_dimensionRunName, null);
			ms_dimensionForecastName = storage.serializeString(
					"dimension-forecast-name", ms_dimensionForecastName, null);
			ms_dimensionVerticalLevelName = storage.serializeString(
					"dimension-level-name", ms_dimensionVerticalLevelName, null);

			ms_previewURL = storage.serializeString("preview-url", ms_previewURL, "<internal>");
			
			mi_autoRefreshPeriod = storage.serializeInt(
					"auto-refresh-period", mi_autoRefreshPeriod, 0);
			ms_imageFormat = storage.serializeString(
					"image-format", ms_imageFormat, "image/png");
					
		}
		
		public function toGetGTileRequest(
            s_crs: String, i_tileZoom: uint,
            i_tileRow: uint, i_tileCol: uint,
            s_style: String): URLRequest
        {
            var r: URLRequest = m_service.toRequest("GetGTile");
            r.data.LAYER = ma_layerNames.length > 0 ? ma_layerNames[0] : '';
            if(m_service.version.isLessThan(1, 3, 0)) 
                r.data.SRS = s_crs;
            else 
                r.data.CRS = s_crs; 
            r.data.TILEZOOM = i_tileZoom; 
            r.data.TILEROW = i_tileRow; 
            r.data.TILECOL = i_tileCol; 
            if(s_style != null)
                r.data.STYLE = s_style;
                
            
            r.data.FORMAT = getCurrentImageFormat(); 
            r.data.TRANSPARENT = "TRUE";
            return r;
        }
        
		public function toGetLegendRequest(
				i_width: int, i_height: int,
				s_style: String = null): URLRequest
		{
			var r: URLRequest = m_service.toRequest("GetLegendGraphic");
			r.data.LAYER = ma_layerNames[0];
			if(s_style != null)
				r.data.STYLE = s_style;
			return r;
		}
		
		public function toGetMapRequest(
				s_crs: String, s_bbox: String,
				i_width: int, i_height: int,
				s_stylesList: String,
				s_layersOverride: String = null): URLRequest
		{
			var r: URLRequest = m_service.toRequest("GetMap");
			r.data.LAYERS = s_layersOverride == null ? ma_layerNames.join(",") : s_layersOverride;
			if(m_service.version.isLessThan(1, 3, 0)) 
				r.data.SRS = s_crs;
			else 
				r.data.CRS = s_crs; 
			r.data.BBOX = s_bbox; 
			if (i_width == 0 || i_height == 0)
			{
				trace("Stop, GetMap size = 0");
				return null;
			}
			
			r.data.WIDTH = i_width; 
			r.data.HEIGHT = i_height;
			if(s_stylesList != null)
				r.data.STYLES = s_stylesList;
				
			r.data.FORMAT = getCurrentImageFormat(); 
			r.data.TRANSPARENT = "TRUE";
			
//			trace("toGetMapRequest layers: " + r.data.LAYERS + " format: " + r.data.FORMAT);
			return r;
		}

		private function getCurrentImageFormat(): String
		{
			var format: String = ms_imageFormat;
			if (format == null)
				format = 'image/png';
				
			return format;
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
			if(m_service.version.isLessThan(1, 3, 0)) {
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
			if(s_dim.toUpperCase() == "TIME" || s_dim.toUpperCase() == "ELEVATION")
				return s_dim;
			return "DIM_" + s_dim; 
		}
		
		protected function onCapabilitiesUpdated(event: Event): void
		{
			var layer: WMSLayer
			var layerConf: WMSLayer
			
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
				for(i = 0; i < a_layers.length; ++i) 
				{
					layer = a_layers[i] as WMSLayer;
					layerConf = ma_layerConfigurations[i] as WMSLayer
					if(layer == null) 
					{
						if(layerConf == null)
							continue;
						else {
							b_changed = true;
							break;
						}
					}
					if(!layer.equals(layerConf)) 
					{
						b_changed = true;
						break;
					} 
				}
			}
			if(b_changed) {
				ma_layerConfigurations = a_layers.toArray();
				for each (layer  in ma_layerConfigurations)
				{
					trace(layer);
				}
				dispatchEvent(new DataEvent(CAPABILITIES_UPDATED));
			} else {
				trace("WMSLayerConfiguration onCapabilitiesUpdated -> there is no change");
			}
			dispatchEvent(new DataEvent(CAPABILITIES_RECEIVED));
		}

		public function isTileableForCRS(crs: String): Boolean
		{
			if (ma_layerConfigurations && ma_layerConfigurations.length > 0)
			{
				for each (var layer: WMSLayer in ma_layerConfigurations)
				{
					if (!layer)
						trace("WMSLayerConfiguration.isTileableForCRS(): layer is NULL")
					if (layer && layer.isTileableForCRS(crs))
						return true;
				}
				return false;
			}
			
			return false;
		}

		override public function isCompatibleWithCRS(crs: String): Boolean
		{
			if (ma_layerConfigurations && ma_layerConfigurations.length > 0)
			{
				for each (var layer: WMSLayer in ma_layerConfigurations)
				{
					if (layer.isCompatibleWithCRS(crs))
						return true;
				}
				return false;
			}
			
			return true;
		}
		
		override public function hasPreview(): Boolean
        { return true; }
        
		override public function getPreviewURL(): String
		{
			var s_url: String = '';
			
			if(ms_previewURL == null || ms_previewURL.length == 0) 
			{
				var iw: InteractiveWidget = new InteractiveWidget();
				var lWMS: InteractiveLayerWMS = createInteractiveLayer(iw) as InteractiveLayerWMS;
				if(lWMS != null)
				{
					var bbox: BBox = lWMS.getExtent();
					if(bbox != null)
						iw.setExtentBBOX(bbox);
					iw.addLayer(lWMS);
					lWMS.dataLoader.data = { label: label, cfg: this };
					s_url = lWMS.getFullURL();
						
				} else {
					trace("getMenuLayersXMLList interactive layer does not exist");
				}
			} else {
			
				if(ms_previewURL == "<internal>") {
					s_url = service.fullURL;
					//check if there is ${BASE_URL} in fullURL and convert it
					s_url = UniURLLoader.fromBaseURL(s_url);
					s_url = s_url.replace(/.*\//, "").replace(/\?.*/, "");
					s_url = s_url.replace("/", "-");
					s_url += "-" + ma_layerNames.join("_").replace(" ", "-").toLowerCase();
					s_url = "assets/layer-previews/" + s_url + ".png";
				}
			}	
			
			return s_url;
		}
		
		override public function renderPreview(f_width: Number, f_height: Number, iw: InteractiveWidget =  null): void
		{
			if (!iw)
				iw = new InteractiveWidget();
				
			var lWMS: InteractiveLayerWMS = createInteractiveLayer(iw) as InteractiveLayerWMS;
			lWMS.renderPreview(lWMS.graphics, f_width, f_height);
		}
		
		// IBehaviouralObject implementation
		public function setBehaviourString(s_behaviourId: String, s_value: String): void
		{ ma_behaviours[s_behaviourId] = s_value; }

		public function getBehaviourString(s_behaviourId: String, s_default: String = null): String
		{
			return (s_behaviourId in ma_behaviours) ? ma_behaviours[s_behaviourId] : s_default;
		}
		
		// IInteractiveLayerProvider implementation
		override public function createInteractiveLayer(iw: InteractiveWidget): InteractiveLayer
		{
			var l: InteractiveLayerWMS = new InteractiveLayerWMS(iw, this);
			//l.updateData(false);
//			l.updateData(true);
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
		
		public function set layerType(s: String): void
		{ ms_layerType = s; }

		public function get layerType(): String
		{ return ms_layerType; }
		
	}
}