package com.iblsoft.flexiweather.ogc
{
	import com.iblsoft.flexiweather.ogc.tiling.InteractiveLayerWMSWithQTT;
	import com.iblsoft.flexiweather.utils.UniURLLoader;
	import com.iblsoft.flexiweather.widgets.InteractiveLayer;
	import com.iblsoft.flexiweather.widgets.InteractiveWidget;
	
	public class WMSWithQTTLayerConfiguration extends WMSLayerConfiguration
	{
		public function WMSWithQTTLayerConfiguration()
		{
		}
		
		
		override public function createInteractiveLayer(iw: InteractiveWidget): InteractiveLayer
		{
			var l: InteractiveLayerWMSWithQTT = new InteractiveLayerWMSWithQTT(iw, this);
//			l.updateData(true);
//			l.updateData(false);
			return l;
		}
		
		override public function renderPreview(f_width: Number, f_height: Number, iw: InteractiveWidget =  null): void
		{
			if (!iw)
				iw = new InteractiveWidget();
				
			var lWMSWithQTT: InteractiveLayerWMSWithQTT = createInteractiveLayer(iw) as InteractiveLayerWMSWithQTT;
			lWMSWithQTT.renderPreview(lWMSWithQTT.graphics, f_width, f_height);
		}
		
		override public function getPreviewURL(): String
		{
			var s_url: String = '';
			
			if(ms_previewURL == null || ms_previewURL.length == 0) 
			{
				var iw: InteractiveWidget = new InteractiveWidget();
				var lWMSWithQTT: InteractiveLayerWMSWithQTT = createInteractiveLayer(iw) as InteractiveLayerWMSWithQTT;
				lWMSWithQTT.avoidTiling = true;
				
				if(lWMSWithQTT != null)
				{
					var bbox: BBox = lWMSWithQTT.getExtent();
					if(bbox != null)
						iw.setExtentBBOX(bbox);
					iw.addLayer(lWMSWithQTT);
					lWMSWithQTT.dataLoader.data = { label: label, cfg: this };
					s_url = lWMSWithQTT.getFullURL();
						
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

	}
}