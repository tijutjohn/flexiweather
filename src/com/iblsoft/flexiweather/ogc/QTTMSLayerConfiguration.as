package com.iblsoft.flexiweather.ogc
{
	import com.iblsoft.flexiweather.ogc.editable.IInteractiveLayerProvider;
	import com.iblsoft.flexiweather.ogc.tiling.InteractiveLayerWMSWithQTT;
	import com.iblsoft.flexiweather.ogc.tiling.TileIndex;
	import com.iblsoft.flexiweather.utils.Storage;
	import com.iblsoft.flexiweather.utils.UniURLLoader;
	import com.iblsoft.flexiweather.widgets.IConfigurableLayer;
	import com.iblsoft.flexiweather.widgets.InteractiveLayer;
	import com.iblsoft.flexiweather.widgets.InteractiveWidget;
	
	import spark.components.Group;
	
	public class QTTMSLayerConfiguration extends LayerConfiguration implements IInteractiveLayerProvider, ILayerConfiguration
	{
//		public var baseURLPattern: String;
		/** Array of CRSWithBBox (items are QTTAreaData instances */
		public var tilingCRSsAndExtents: Array = [];
		
		
		public function QTTMSLayerConfiguration()
		{
		}
		
		public function removeAllTilingInfo(): void
		{
			tilingCRSsAndExtents = [];
		}
		/**
		 * Add QTTilingInfo into array of supported tilingInfo data for this configuration 
		 * @param tilingInfo
		 * 
		 */		
		public function addQTTilingInfo(tilingInfo: QTTilingInfo): void
		{
			if (!tilingCRSsAndExtents)
			{
				tilingCRSsAndExtents = [];
			}
			tilingCRSsAndExtents.push(tilingInfo);
		}
		
		/**
		 * Get QTTilingInfo for given CRS
		 *  
		 * @param crs
		 * @return 
		 * 
		 */		
		public function getQTTilingInfoForCRS(crs: String): QTTilingInfo
		{
			if (tilingCRSsAndExtents && tilingCRSsAndExtents.length > 0)
			{
				for each (var info: QTTilingInfo in tilingCRSsAndExtents)
				{
					if (info.crsWithBBox && info.crsWithBBox.crs == crs)
					{
						return info;
					}
				}
			}
			return null;
		}
		
		override public function createInteractiveLayer(iw: InteractiveWidget): InteractiveLayer
		{
			trace("create new QTT layer: " + this);
			var l: InteractiveLayerQTTMS = new InteractiveLayerQTTMS(iw, this);
			l.name = label;
			return l;
		}
		
		override public function hasCustomLayerOptions(): Boolean
		{
			return true;
		}
		
		override public function createCustomLayerOption(layer: IConfigurableLayer): Group
		{
			var options: QTTLayerOptions = new QTTLayerOptions();
			options.layer = layer as InteractiveLayerQTTMS;
			return options;	
		}
		
		override public function serialize(storage: Storage): void
		{
			super.serialize(storage);
//			baseURLPattern = storage.serializeString("url-pattern", baseURLPattern);
			storage.serializeNonpersistentArray("tiling-crs-and-extent", tilingCRSsAndExtents, QTTilingInfo);
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
			for each(var qtTilingInfo: QTTilingInfo in tilingCRSsAndExtents) {
				var crsWithBBox: CRSWithBBox = qtTilingInfo.crsWithBBox;  
				if(crsWithBBox && crsWithBBox.crs == s_crs)
					return true;
			}
			return false;
		}
/*
		override public function getPreviewURL(): String
		{
			var s_url: String = '';
			
			if(ms_previewURL == "<internal>") {
				s_url = label.replace(/\//, "_"); 
				s_url = "assets/layer-previews/" + s_url + ".png";
			}
			else if(ms_previewURL == null || ms_previewURL.length == 0) {
				
				var currQTTilingInfo: QTTilingInfo;
				
				var i_middleTile: uint = (1 << currQTTilingInfo.minimumZoomLevel) / 2;
				s_url = InteractiveLayerQTTMS.expandURLPattern(currQTTilingInfo.urlPattern,
						new TileIndex(currQTTilingInfo.minimumZoomLevel, i_middleTile, i_middleTile));
			} 
			else
				s_url = ms_previewURL;
			return s_url;
		}
	*/	
		public function get serviceType(): String
		{ return "QTT"; }
		
		override public function toString(): String
		{
			if (tilingCRSsAndExtents && tilingCRSsAndExtents.length > 0)
			{
				var tilingInfo: QTTilingInfo = tilingCRSsAndExtents[0];
				if (tilingInfo)
				{
					return 'QTTMSLayerConfiguration urlPattern: ' + tilingInfo.urlPattern + ' CRS: ' + tilingInfo.crsWithBBox.crs + ' bbox: ' + tilingInfo.crsWithBBox.bbox.toBBOXString(); 
				}
			}
			return 'QTTMSLayerConfiguration with NO TILING info';
		}
	}
}