package com.iblsoft.flexiweather.ogc.configuration.layers
{
	import com.iblsoft.flexiweather.net.loaders.AbstractURLLoader;
	import com.iblsoft.flexiweather.net.loaders.UniURLLoader;
	import com.iblsoft.flexiweather.ogc.BBox;
	import com.iblsoft.flexiweather.ogc.IBehaviouralObject;
	import com.iblsoft.flexiweather.ogc.Version;
	import com.iblsoft.flexiweather.ogc.tiling.InteractiveLayerWMSWithQTT;
	import com.iblsoft.flexiweather.utils.Storage;
	import com.iblsoft.flexiweather.widgets.InteractiveLayer;
	import com.iblsoft.flexiweather.widgets.InteractiveWidget;
	import com.iblsoft.flexiweather.ogc.configuration.services.WMSServiceConfiguration;

	public class WMSWithQTTLayerConfiguration extends WMSLayerConfiguration implements IBehaviouralObject
	{
		Storage.addChangedClass('com.iblsoft.flexiweather.ogc.WMSWithQTTLayerConfiguration', 'com.iblsoft.flexiweather.ogc.configuration.layers.WMSWithQTTLayerConfiguration', new Version(1, 6, 0));
		
		private var _avoidTiling: Boolean;
		public var minimumZoomLevel: uint = 1;
		public var maximumZoomLevel: uint = 12;
		public var tileSize: uint = 256;

		public function WMSWithQTTLayerConfiguration(service: WMSServiceConfiguration = null, a_layerNames: Array = null, tileSize: uint = 256)
		{
			super(service, a_layerNames);
			this.tileSize = tileSize;
		}

		public function get avoidTiling(): Boolean
		{
			return _avoidTiling;
		}

		public function set avoidTiling(value: Boolean): void
		{
			_avoidTiling = value;
		}

		override public function createInteractiveLayer(iw: InteractiveWidget): InteractiveLayer
		{
			var l: InteractiveLayerWMSWithQTT = new InteractiveLayerWMSWithQTT(iw, this);
			l.layerName = label;
			return l;
		}

		override public function serialize(storage: Storage): void
		{
			super.serialize(storage);
			avoidTiling = storage.serializeBool("avoid-tiling", avoidTiling, false);
			minimumZoomLevel = storage.serializeUInt("minimum-zoom-level", minimumZoomLevel, 1);
			maximumZoomLevel = storage.serializeUInt("maximum-zoom-level", maximumZoomLevel, 12);
			tileSize = storage.serializeUInt("tile-size", tileSize, 256);
		}

		override public function renderPreview(f_width: Number, f_height: Number, iw: InteractiveWidget = null): void
		{
			if (!iw)
				iw = new InteractiveWidget(true);
			var lWMSWithQTT: InteractiveLayerWMSWithQTT = createInteractiveLayer(iw) as InteractiveLayerWMSWithQTT;
			lWMSWithQTT.renderPreview(lWMSWithQTT.graphics, f_width, f_height);
		}

		override public function getPreviewURL(): String
		{
			var s_url: String = '';
			if (ms_previewURL == null || ms_previewURL.length == 0)
			{
				var iw: InteractiveWidget = new InteractiveWidget(true);
				var lWMSWithQTT: InteractiveLayerWMSWithQTT = createInteractiveLayer(iw) as InteractiveLayerWMSWithQTT;
				var lCfg: WMSWithQTTLayerConfiguration = new WMSWithQTTLayerConfiguration();
				lCfg.avoidTiling = true;
				if (lWMSWithQTT != null)
				{
					var bbox: BBox = lWMSWithQTT.getExtent();
					if (bbox != null)
						iw.setExtentBBox(bbox);
					iw.addLayer(lWMSWithQTT);
					lWMSWithQTT.dataLoader.data = {label: label, cfg: this};
					s_url = lWMSWithQTT.getFullURL();
				}
				else
					trace("getMenuLayersXMLList interactive layer does not exist");
			}
			else
			{
				if (ms_previewURL.indexOf("<internal>") >= 0)
				{
					if (service && layerNames)
					{
						s_url = getInternalIconPath(s_url);
//						s_url = service.fullURL;
						//check if there is ${BASE_URL} in fullURL and convert it
//						s_url = AbstractURLLoader.fromBaseURL(s_url);
//						s_url = s_url.replace(/.*\//, "").replace(/\?.*/, "");
//						s_url = s_url.replace("/", "-");
//						s_url += "-" + layerNames.join("_").replace(" ", "-").toLowerCase();
//						s_url = "assets/layer-previews/" + s_url + ".png";
						
					} else {
						trace(this + " Problem find Internal Preview URL");
					}
				}
			}
			
			if (s_url == '' && ms_previewURL && ms_previewURL.length > 0)
				return ms_previewURL;
			
			return s_url;
		}
		
		override public function toString(): String
		{
			return "WMSWithQTTLayerConfiguration " + id + " ["+m_service+"] ";
		}
	}
}
