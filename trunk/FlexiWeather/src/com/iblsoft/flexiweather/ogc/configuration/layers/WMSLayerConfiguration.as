package com.iblsoft.flexiweather.ogc.configuration.layers
{
	import com.iblsoft.flexiweather.FlexiWeatherConfiguration;
	import com.iblsoft.flexiweather.net.loaders.AbstractURLLoader;
	import com.iblsoft.flexiweather.net.loaders.UniURLLoader;
	import com.iblsoft.flexiweather.ogc.BBox;
	import com.iblsoft.flexiweather.ogc.IBehaviouralObject;
	import com.iblsoft.flexiweather.ogc.InteractiveLayerWMS;
	import com.iblsoft.flexiweather.ogc.Version;
	import com.iblsoft.flexiweather.ogc.WMSDimension;
	import com.iblsoft.flexiweather.ogc.WMSLayer;
	import com.iblsoft.flexiweather.ogc.WMSLayerBase;
	import com.iblsoft.flexiweather.ogc.configuration.layers.interfaces.IWMSLayerConfiguration;
	import com.iblsoft.flexiweather.ogc.configuration.services.OGCServiceConfiguration;
	import com.iblsoft.flexiweather.ogc.configuration.services.WMSServiceConfiguration;
	import com.iblsoft.flexiweather.ogc.editable.IInteractiveLayerProvider;
	import com.iblsoft.flexiweather.ogc.events.ServiceCapabilitiesEvent;
	import com.iblsoft.flexiweather.utils.Storage;
	import com.iblsoft.flexiweather.widgets.InteractiveLayer;
	import com.iblsoft.flexiweather.widgets.InteractiveWidget;
	import com.iblsoft.flexiweather.widgets.data.InteractiveLayerPrintQuality;
	
	import flash.events.DataEvent;
	import flash.events.Event;
	import flash.net.URLRequest;
	
	import mx.collections.ArrayCollection;

	[Event(name = CAPABILITIES_UPDATED, type = "flash.events.DataEvent")]
	[Event(name = CAPABILITIES_RECEIVED, type = "flash.events.DataEvent")]
	public class WMSLayerConfiguration extends OGCLayerConfiguration implements IBehaviouralObject, IInteractiveLayerProvider, IWMSLayerConfiguration
	{
		Storage.addChangedClass('com.iblsoft.flexiweather.ogc.WMSLayerConfiguration', 'com.iblsoft.flexiweather.ogc.configuration.layers.WMSLayerConfiguration', new Version(1, 6, 0));

		public static const CAPABILITIES_UPDATED: String = "capabilitiesUpdated";
		public static const CAPABILITIES_RECEIVED: String = "capabilitiesReceived";

		private var ma_layerNames: Array = [];
		private var ma_styleNames: Array = [];
		private var ma_behaviours: Array = [];
		private var ma_availableImageFormats: Array = [];
		private var ms_dimensionTimeName: String = null;
		private var ms_dimensionRunName: String = null;
		private var ms_dimensionForecastName: String = null;
		private var ms_dimensionVerticalLevelName: String = null;
		private var ms_imageFormat: String = null;
		private var mb_legendIsDimensionDependant: Boolean;
		private var mi_autoRefreshPeriod: uint = 0;
		// runtime variables
		private var _layerConfigurations: Array;

		private var mb_capabilitiesReceived: Boolean;
		public function get capabilitiesReceived(): Boolean
		{
			return mb_capabilitiesReceived;
		}
		
		public function WMSLayerConfiguration(service: WMSServiceConfiguration = null, a_layerNames: Array = null)
		{
			super(service);
			
			mb_capabilitiesReceived = false;
			
			if (a_layerNames != null)
				ma_layerNames = a_layerNames;
			
			registerService();
			
//			onCapabilitiesUpdated(null);
		}

		override protected function registerService(): void
		{
			if (m_service)
			{
				m_service.addEventListener(ServiceCapabilitiesEvent.CAPABILITIES_UPDATED, onCapabilitiesUpdated)
				onCapabilitiesUpdated(null);
			}
		}
		
		override protected function unregisterService(): void
		{
			if (m_service)
				m_service.removeEventListener(ServiceCapabilitiesEvent.CAPABILITIES_UPDATED, onCapabilitiesUpdated)
		}
		
		
		public function populateLayerCapabilities(layerXML: XML): void
		{
			//if FlexiWeather loads GetCapabilitie requests, this functionality is not needed and will not be executed			
			if (FlexiWeatherConfiguration.FLEXI_WEATHER_LOADS_GET_CAPABILITIES)
				return;
			
			if (m_service)
			{ 
				(m_service as WMSServiceConfiguration).populateLayerCapabilities(layerXML);
				onCapabilitiesUpdated();
			}
		}
		
		override public function destroy(): void
		{
			unregisterService();
			
			ma_layerNames = null;
			
			if (_layerConfigurations && _layerConfigurations.length > 0)
			{
				for each (var wmsLayer: WMSLayerBase in _layerConfigurations)
				{
					wmsLayer.destroy();
					wmsLayer = null;
				}
				_layerConfigurations = null;
			}
			super.destroy();
		}

		override public function toString(): String
		{
			return "WMSLayerConfiguration " + id + " ["+m_service+"]";
		}
		
		override public function serialize(storage: Storage): void
		{
			if (storage.isLoading() && m_service != null)
				m_service.removeEventListener(ServiceCapabilitiesEvent.CAPABILITIES_UPDATED, onCapabilitiesUpdated)
			super.serialize(storage);
			
			if (storage.isLoading())
			{
				m_service.addEventListener(ServiceCapabilitiesEvent.CAPABILITIES_UPDATED, onCapabilitiesUpdated);
//				trace(this + " serialized");
			}
			
			try
			{
				storage.serializeNonpersistentArray("layer-name", ma_layerNames, String);
			}
			catch (error: Error)
			{
				trace("WMSLayeConfig ma_layerNames error: " + error.message);
			}
			try
			{
				storage.serializeNonpersistentArray("style-name", ma_styleNames, String)
			}
			catch (error: Error)
			{
				trace("WMSLayeConfig ma_styleNames error: " + error.message);
			}
			try
			{
				storage.serializeNonpersistentArrayMap("behaviour", ma_behaviours, String, String);
			}
			catch (error: Error)
			{
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
			mb_legendIsDimensionDependant = storage.serializeBool(
					"legend-dependant-on-dimension", mb_legendIsDimensionDependant, false);
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
			if (m_service.version.isLessThan(1, 3, 0))
				r.data.SRS = s_crs;
			else
				r.data.CRS = s_crs;
			r.data.TILEZOOM = i_tileZoom;
			r.data.TILEROW = i_tileRow;
			r.data.TILECOL = i_tileCol;
			if (s_style != null)
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
			if (s_style != null)
				r.data.STYLE = s_style;
			return r;
		}

		public function toGetMapRequest(
				s_crs: String, s_bbox: String,
				i_width: int, i_height: int,
				s_printQuality: String, 
				s_stylesList: String,
				s_layersOverride: String = null): URLRequest
		{
			var r: URLRequest = m_service.toRequest("GetMap");
			r.data.LAYERS = s_layersOverride == null ? ma_layerNames.join(",") : s_layersOverride;
			if (m_service.version.isLessThan(1, 3, 0))
				r.data.SRS = s_crs;
			else
				r.data.CRS = s_crs;
			r.data.BBOX = s_bbox;
			if (i_width == 0 || i_height == 0)
				return null;
			r.data.WIDTH = i_width;
			r.data.HEIGHT = i_height;
			if (s_stylesList != null)
				r.data.STYLES = s_stylesList;
			if (s_printQuality == InteractiveLayerPrintQuality.HIGH_QUALITY)
				r.data.FORMAT = getVectorImageFormat();
			else
				r.data.FORMAT = getCurrentImageFormat();
			r.data.TRANSPARENT = "TRUE";
			return r;
		}

		private function getVectorImageFormat(): String
		{
			if (service && service is WMSServiceConfiguration && (service as WMSServiceConfiguration).imageFormats)
			{
				var formats: Array = (service as WMSServiceConfiguration).imageFormats;
				for each (var currFormat: String in formats)
				{
					if (currFormat.indexOf('x-shockwave-flash') >= 0)
					{
						return currFormat;
					}
				}
			}
			return getCurrentImageFormat();
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
			if (m_service.version.isLessThan(1, 3, 0))
			{
				r.data.SRS = s_crs;
				r.data.X = i_x;
				r.data.Y = i_y;
			}
			else
			{
				r.data.CRS = s_crs;
				r.data.I = i_x;
				r.data.J = i_y;
			}
			r.data.BBOX = s_bbox;
			r.data.WIDTH = i_width;
			r.data.HEIGHT = i_height;
			if (s_stylesList != null)
				r.data.STYLES = s_stylesList;
			r.data.FORMAT = "text/html";
			r.data.TRANSPARENT = "TRUE";
			return r;
		}

		public function dimensionToParameterName(s_dim: String): String
		{
			if (s_dim.toUpperCase() == "TIME" || s_dim.toUpperCase() == "ELEVATION")
				return s_dim;
			return "DIM_" + s_dim;
		}

		protected function onCapabilitiesUpdated(event: Event = null): void
		{
			if (!m_service)
				return;
			
			var layer: WMSLayer
			var layerConf: WMSLayer
			var a_layers: ArrayCollection = new ArrayCollection();
			if (ma_layerNames)
			{
				for (var i: int = 0; i < ma_layerNames.length; ++i)
				{
					var l: WMSLayer = null;
					if (m_service != null)
						l = (service as WMSServiceConfiguration).getLayerByName(ma_layerNames[i]);
					if (l)
						a_layers.addItem(l);
				}
			}
			var b_changed: Boolean = false;
			if (_layerConfigurations == null)
				b_changed = true;
			else
			{
				for (i = 0; i < a_layers.length; ++i)
				{
					layer = a_layers[i] as WMSLayer;
					updateDimensions(layer);
					layerConf = _layerConfigurations[i] as WMSLayer
					if (layer == null)
					{
						if (layerConf == null)
							continue;
						else
						{
							b_changed = true;
							break;
						}
					}
					if (!layer.equals(layerConf))
					{
						b_changed = true;
						break;
					}
				}
			}
			if (b_changed)
			{
				for (i = 0; i < a_layers.length; ++i)
				{
					layer = a_layers[i] as WMSLayer;
					updateDimensions(layer);
				}
				_layerConfigurations = a_layers.toArray();
				if (_layerConfigurations.length > 0)
				{
					mb_capabilitiesReceived = true;
				}
				dispatchEvent(new DataEvent(CAPABILITIES_UPDATED));
			}
			if (_layerConfigurations.length > 0)
			{
				mb_capabilitiesReceived = true;
			}
			dispatchEvent(new DataEvent(CAPABILITIES_RECEIVED));
			
//			trace(this + " onCapabilitiesUpdated ");
			
		}

		private function updateDimensions(layer: WMSLayer): void
		{
			var dimensions: Array = layer.parsedDimensions;
			for each (var dimension: WMSDimension in dimensions)
			{
				switch (dimension.name)
				{
					case "RUN":
					{
						dimensionRunName = dimension.name;
						break;
					}
					case "FORECAST":
					{
						dimensionForecastName = dimension.name;
						break;
					}
					case "TIME":
					{
						dimensionTimeName = dimension.name;
						break;
					}
					case "ELEVATION":
					{
						dimensionVerticalLevelName = dimension.name;
						break;
					}
				}
			}
		}

		public function isTileableForCRS(crs: String): Boolean
		{
			if (_layerConfigurations && _layerConfigurations.length > 0)
			{
				for each (var layer: WMSLayer in _layerConfigurations)
				{
					if (layer && layer.isTileableForCRS(crs))
						return true;
				}
				return false;
			}
			return false;
		}

		override public function isCompatibleWithCRS(crs: String): Boolean
		{
			if (_layerConfigurations && _layerConfigurations.length > 0)
			{
				for each (var layer: WMSLayer in _layerConfigurations)
				{
					if (layer && layer.isCompatibleWithCRS(crs))
						return true;
				}
				return false;
			}
			return true;
		}

		override public function hasPreview(): Boolean
		{
			return true;
		}

		override public function getPreviewURL(): String
		{
			var s_url: String = '';
			if (ms_previewURL == null || ms_previewURL.length == 0)
			{
				var iw: InteractiveWidget = new InteractiveWidget(true);
				var lWMS: InteractiveLayerWMS = createInteractiveLayer(iw) as InteractiveLayerWMS;
				if (lWMS != null)
				{
					var bbox: BBox = lWMS.getExtent();
					if (bbox != null)
						iw.setExtentBBox(bbox);
					iw.addLayer(lWMS);
					lWMS.dataLoader.data = {label: label, cfg: this};
					s_url = lWMS.getFullURLWithSize(150, 100);
				}
				else
					trace("getMenuLayersXMLList interactive layer does not exist");
			}
			else
			{
				if (ms_previewURL.indexOf("<internal>") >= 0)
				{
					if (service && ma_layerNames)
					{
						s_url = getInternalIconPath(s_url);
					} else {
						trace(this + " Problem find Internal Preview URL");
					}
				}
			}
			
			if (s_url == '' && ms_previewURL && ms_previewURL.length > 0)
				return ms_previewURL;
			
			return s_url;
		}
		
		protected function getInternalIconPath(s_url: String): String
		{
			/*
			 this is code from generate-preview.py
			*/
			
			/*
			s_serviceURL = x_layer.getAttribute('service-url')
			if s_serviceURL.find('?') < 0:
				s_serviceURL += '?'
			s_id = s_serviceURL.replace('${BASE_URL}/', '').replace('http://', '').replace('https://', '')
			s_id = re.sub(r'\?.*', '', s_id)
			s_serviceURL = s_serviceURL.replace('${BASE_URL}', s_baseURL)
			s_layers = ','.join([x.firstChild.nodeValue for x in x_layer.getElementsByTagName('layer-name')])
				s_id += "_" + s_layers
			s_id = s_id.replace('/', '_').replace(',', '+')
			*/
			
			s_url = service.fullURL;
			s_url = s_url.replace(/\$\{BASE_URL\}\//, "").replace(/http:\/\//, "").replace(/https:\/\//, "");
			var paramPos: int = s_url.indexOf("?");
			if (paramPos > 0)
			{
				s_url = s_url.substr(0, paramPos);
			}
			s_url = s_url.replace(/\//gi, "_");
			s_url += "_" + ma_layerNames.join("_").replace(" ", "-").toLowerCase();
			s_url = "assets/layer-previews/" + s_url + ".png";
			
			return s_url;
			
		}

		override public function renderPreview(f_width: Number, f_height: Number, iw: InteractiveWidget = null): void
		{
			if (!iw)
				iw = new InteractiveWidget(true);
			var lWMS: InteractiveLayerWMS = createInteractiveLayer(iw) as InteractiveLayerWMS;
			lWMS.renderPreview(lWMS.graphics, f_width, f_height);
		}

		// IBehaviouralObject implementation
		public function setBehaviourString(s_behaviourId: String, s_value: String): void
		{
			ma_behaviours[s_behaviourId] = s_value;
		}

		public function getBehaviourString(s_behaviourId: String, s_default: String = null): String
		{
			return (s_behaviourId in ma_behaviours) ? ma_behaviours[s_behaviourId] : s_default;
		}

		// IInteractiveLayerProvider implementation
		override public function createInteractiveLayer(iw: InteractiveWidget): InteractiveLayer
		{
			var l: InteractiveLayerWMS = new InteractiveLayerWMS(iw, this);
			l.layerName = label;
			return l;
		}

		public function hasBehaviourString(s_behaviourId: String): Boolean
		{
			return s_behaviourId in ma_behaviours;
		}

		// getters & setters				
		public function get wmsService(): WMSServiceConfiguration
		{
			return m_service as WMSServiceConfiguration;
		}

		public function get behaviours(): Array
		{
			return ma_behaviours;
		}

		public function set legendIsDimensionDependant(b: Boolean): void
		{
			mb_legendIsDimensionDependant = b;
		}

		public function get legendIsDimensionDependant(): Boolean
		{
			return mb_legendIsDimensionDependant;
		}
		
		public function set dimensionTimeName(s: String): void
		{
			ms_dimensionTimeName = s;
		}

		public function get dimensionTimeName(): String
		{
			return ms_dimensionTimeName;
		}

		public function set dimensionRunName(s: String): void
		{
			ms_dimensionRunName = s;
		}

		public function get dimensionRunName(): String
		{
			return ms_dimensionRunName;
		}

		public function set dimensionForecastName(s: String): void
		{
			ms_dimensionForecastName = s;
		}

		public function get dimensionForecastName(): String
		{
			return ms_dimensionForecastName;
		}

		public function set dimensionVerticalLevelName(s: String): void
		{
			ms_dimensionVerticalLevelName = s;
		}

		public function get dimensionVerticalLevelName(): String
		{
			return ms_dimensionVerticalLevelName;
		}

		public function get layerType(): String
		{
			if (ma_layerNames && ma_layerNames.length > 0)
				return ma_layerNames[0] as String;
			return null;
		}

		public function get layerConfigurations(): Array
		{
			return _layerConfigurations;
		}

		public function set layerConfigurations(value: Array): void
		{
			_layerConfigurations = value;
		}

		public function get styleNames(): Array
		{
			return ma_styleNames;
		}

		public function set styleNames(value: Array): void
		{
			ma_styleNames = value;
		}

		public function get autoRefreshPeriod(): uint
		{
			return mi_autoRefreshPeriod;
		}

		public function set autoRefreshPeriod(value: uint): void
		{
			mi_autoRefreshPeriod = value;
		}

		public function get layerNames(): Array
		{
			return ma_layerNames;
		}

		public function set layerNames(value: Array): void
		{
			ma_layerNames = value;
		}

		public function get imageFormat(): String
		{
			return ms_imageFormat;
		}

		public function set imageFormat(value: String): void
		{
			ms_imageFormat = value;
		}
	}
}