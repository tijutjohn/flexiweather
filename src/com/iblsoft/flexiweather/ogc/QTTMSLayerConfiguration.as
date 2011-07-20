package com.iblsoft.flexiweather.ogc
{
	import com.iblsoft.flexiweather.ogc.editable.IInteractiveLayerProvider;
	import com.iblsoft.flexiweather.ogc.tiling.InteractiveLayerWMSWithQTT;
	import com.iblsoft.flexiweather.ogc.tiling.TileIndex;
	import com.iblsoft.flexiweather.utils.Storage;
	import com.iblsoft.flexiweather.utils.UniURLLoader;
	import com.iblsoft.flexiweather.widgets.InteractiveLayer;
	import com.iblsoft.flexiweather.widgets.InteractiveWidget;
	
	public class QTTMSLayerConfiguration extends LayerConfiguration implements IInteractiveLayerProvider, ILayerConfiguration
	{
		public var baseURLPattern: String;
		/** Array of CRSWithBBox (items are QTTAreaData instances */
		public var tilingCRSsAndExtents: Array = [];
		public var minimumZoomLevel: uint = 1;
		public var maximumZoomLevel: uint = 12;
		
		public function get crs(): String
		{
			if (tilingCRSsAndExtents && tilingCRSsAndExtents.length > 0)
			{
				var data: QTTAreaData = tilingCRSsAndExtents[0] as QTTAreaData;
				if (data && data.crsWithBBox)
					return data.crsWithBBox.crs;
			}
			return null;
		}
		public function get urlPattern(): String
		{
			if (tilingCRSsAndExtents && tilingCRSsAndExtents.length > 0)
			{
				var data: QTTAreaData = tilingCRSsAndExtents[0] as QTTAreaData;
				if (data)
					return data.urlPattern;
			}
			return null;
		}
		public function QTTMSLayerConfiguration()
		{
		}
		
		override public function createInteractiveLayer(iw: InteractiveWidget): InteractiveLayer
		{
			var l: InteractiveLayerQTTMS = new InteractiveLayerQTTMS(iw, this);
			l.name = label;
			return l;
		}
		
		override public function serialize(storage: Storage): void
		{
			super.serialize(storage);
			baseURLPattern = storage.serializeString("url-pattern", baseURLPattern);
			storage.serializeNonpersistentArray("tiling-crs-and-extent", tilingCRSsAndExtents, QTTAreaData);
			minimumZoomLevel = storage.serializeUInt("minimum-zoom-level", minimumZoomLevel, 1);
			maximumZoomLevel = storage.serializeUInt("maximum-zoom-level", maximumZoomLevel, 12);
		}
		
		override public function renderPreview(f_width: Number, f_height: Number, iw: InteractiveWidget = null): void
		{
			if (!iw)
				iw = new InteractiveWidget();
				
			var l: InteractiveLayerQTTMS = createInteractiveLayer(iw) as InteractiveLayerQTTMS;
			l.renderPreview(l.graphics, f_width, f_height);
		}
		
		override public function isCompatibleWithCRS(s_crs: String): Boolean
		{
			for each(var qttData: QTTAreaData in tilingCRSsAndExtents) {
				var crsWithBBox: CRSWithBBox = qttData.crsWithBBox;  
				if(crsWithBBox && crsWithBBox.crs == s_crs)
					return true;
			}
			return false;
		}

		override public function getPreviewURL(): String
		{
			var s_url: String = '';
			
			if(ms_previewURL == "<internal>") {
				s_url = label.replace(/\//, "_"); 
				s_url = "assets/layer-previews/" + s_url + ".png";
			}
			else if(ms_previewURL == null || ms_previewURL.length == 0) {
				var i_middleTile: uint = (1 << minimumZoomLevel) / 2;
				s_url = InteractiveLayerQTTMS.expandURLPattern(baseURLPattern,
						new TileIndex(minimumZoomLevel, i_middleTile, i_middleTile));
			} 
			else
				s_url = ms_previewURL;
			return s_url;
		}
		
		public function get serviceType(): String
		{ return "QTT"; }
	}
}