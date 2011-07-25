package com.iblsoft.flexiweather.widgets.googlemaps
{
	import com.google.maps.MapType;
	import com.google.maps.interfaces.IMapType;
	import com.iblsoft.flexiweather.ogc.CRSWithBBox;
	import com.iblsoft.flexiweather.ogc.IBehaviouralObject;
	import com.iblsoft.flexiweather.ogc.ILayerConfiguration;
	import com.iblsoft.flexiweather.ogc.LayerConfiguration;
	import com.iblsoft.flexiweather.ogc.editable.IInteractiveLayerProvider;
	import com.iblsoft.flexiweather.utils.Storage;
	import com.iblsoft.flexiweather.widgets.IConfigurableLayer;
	import com.iblsoft.flexiweather.widgets.InteractiveLayer;
	import com.iblsoft.flexiweather.widgets.InteractiveWidget;
	
	import spark.components.Group;

	public class GoogleMapLayerConfiguration extends LayerConfiguration implements IInteractiveLayerProvider, ILayerConfiguration, IBehaviouralObject
	{
		public static const MAP_TYPE_NORMAL: String = 'normal';
		public static const MAP_TYPE_PHYSICAL: String = 'physical';
		public static const MAP_TYPE_SATELLITE: String = 'satellite';
		public static const MAP_TYPE_HYBRID: String = 'hybrid';
		
		/** Array of CRSWithBBox */
		public var tilingCRSsAndExtents: Array = [];
		public var minimumZoomLevel: uint = 1;
		public var maximumZoomLevel: uint = 12;

		public var ma_behaviours: Array = [];
		
		/**
		 * Possible values are all static const MAP_TYPE_ 
		 */
		public var mapType: String;
		
		public function GoogleMapLayerConfiguration()
		{
			super();
		}
		
		// IInteractiveLayerProvider implementation
		override public function createInteractiveLayer(iw: InteractiveWidget): InteractiveLayer
		{
			var l: InteractiveLayerGoogleMaps = new InteractiveLayerGoogleMaps(iw, this);
			l.layerName = label; //'Static/Google Maps';
			l.name = label; //'Static/Google Maps';
			return l;
		}
		
		override public function serialize(storage: Storage): void
		{
			
			super.serialize(storage);
			trace("GoogleMapLayerConfiguration serialize");
			
			try {
				storage.serializeNonpersistentArrayMap("behaviour", ma_behaviours, String, String);
				trace("GoogleMapLayerConfiguration ma_behaviours: ")
				for (var k: String in ma_behaviours)
				{
					trace("GoogleMapLayerConfiguration ma_behaviours["+k+"] = " + ma_behaviours[k] + "<<");
				}
			} catch (error: Error) {
				trace("GoogleMapLayerConfiguration ma_behaviours error: " + error.message);
			}
			
			storage.serializeNonpersistentArray("tiling-crs-and-extent", tilingCRSsAndExtents, CRSWithBBox);
			minimumZoomLevel = storage.serializeUInt("minimum-zoom-level", minimumZoomLevel, 1);
			maximumZoomLevel = storage.serializeUInt("maximum-zoom-level", maximumZoomLevel, 12);
			mapType = storage.serializeString("map-type", mapType);
//			label = storage.serializeString("label", label);
			
		}
		
		override public function hasPreview(): Boolean
        { return true; }
        
		override public function renderPreview(f_width: Number, f_height: Number, iw: InteractiveWidget =  null): void
		{
			if (!iw)
				iw = new InteractiveWidget();
				
			var lGoogleMaps: InteractiveLayerGoogleMaps = createInteractiveLayer(iw) as InteractiveLayerGoogleMaps;
			lGoogleMaps.renderPreview(lGoogleMaps.graphics, f_width, f_height);
		}
		
		
		
		override public function isCompatibleWithCRS(s_crs: String): Boolean
		{
			for each(var crsWithBBox: CRSWithBBox in tilingCRSsAndExtents) {
				if(crsWithBBox.crs == s_crs)
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
				var i_middleTile: uint = (1 << minimumZoomLevel) / 2;
				s_url = InteractiveLayerQTTMS.expandURLPattern(baseURLPattern,
					new TileIndex(minimumZoomLevel, i_middleTile, i_middleTile));
			} 
			else
				s_url = ms_previewURL;
			return s_url;
		}*/

		// IBehaviouralObject implementation
		public function setBehaviourString(s_behaviourId: String, s_value: String): void
		{ 
			ma_behaviours[s_behaviourId] = s_value; 
		}
		
		public function getBehaviourString(s_behaviourId: String, s_default: String = null): String
		{
			return (s_behaviourId in ma_behaviours) ? ma_behaviours[s_behaviourId] : s_default;
		}
		
		public function hasBehaviourString(s_behaviourId: String): Boolean
		{ return s_behaviourId in ma_behaviours; }
		
		override public function hasCustomLayerOptions(): Boolean
		{
			return true;
		}
		
		public function get behaviours(): Array
		{ return ma_behaviours; }

		override public function createCustomLayerOption(layer: IConfigurableLayer): Group
		{
			var options: GoogleMapsLayerOption = new GoogleMapsLayerOption();
			options.layer = layer as InteractiveLayerGoogleMaps;
			return options;	
		}
		
		public function get serviceType(): String
		{ return "Google Maps"; }
	}
}