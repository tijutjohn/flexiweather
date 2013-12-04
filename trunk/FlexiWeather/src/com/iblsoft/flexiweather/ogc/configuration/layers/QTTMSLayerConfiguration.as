package com.iblsoft.flexiweather.ogc.configuration.layers
{
	import com.iblsoft.flexiweather.net.loaders.UniURLLoader;
	import com.iblsoft.flexiweather.ogc.CRSWithBBox;
	import com.iblsoft.flexiweather.ogc.IBehaviouralObject;
	import com.iblsoft.flexiweather.ogc.InteractiveLayerQTTMS;
	import com.iblsoft.flexiweather.ogc.Version;
	import com.iblsoft.flexiweather.ogc.configuration.layers.interfaces.ILayerConfiguration;
	import com.iblsoft.flexiweather.ogc.editable.IInteractiveLayerProvider;
	import com.iblsoft.flexiweather.ogc.tiling.InteractiveLayerTiled;
	import com.iblsoft.flexiweather.ogc.tiling.InteractiveLayerWMSWithQTT;
	import com.iblsoft.flexiweather.ogc.tiling.TileIndex;
	import com.iblsoft.flexiweather.ogc.tiling.TiledLayerOptions;
	import com.iblsoft.flexiweather.ogc.tiling.TiledTilesProvider;
	import com.iblsoft.flexiweather.ogc.tiling.TiledTilingInfo;
	import com.iblsoft.flexiweather.utils.Storage;
	import com.iblsoft.flexiweather.widgets.IConfigurableLayer;
	import com.iblsoft.flexiweather.widgets.InteractiveLayer;
	import com.iblsoft.flexiweather.widgets.InteractiveWidget;
	
	import mx.utils.ArrayUtil;
	import mx.utils.ObjectUtil;
	
	import spark.components.Group;

	public class QTTMSLayerConfiguration extends TiledLayerConfiguration implements IInteractiveLayerProvider, ILayerConfiguration, IBehaviouralObject
	{
		Storage.addChangedClass('com.iblsoft.flexiweather.ogc.QTTMSLayerConfiguration', 'com.iblsoft.flexiweather.ogc.configuration.layers.QTTMSLayerConfiguration', new Version(1, 6, 0));
//		public var baseURLPattern: String;

		public function QTTMSLayerConfiguration()
		{
		}

		override public function destroy(): void
		{
			ma_behaviours = null;
			super.destroy();
		}


		override public function createInteractiveLayer(iw: InteractiveWidget): InteractiveLayer
		{
			var l: InteractiveLayerQTTMS = new InteractiveLayerQTTMS(iw, this);
//			l.tilesProvider = new QTTTilesProvider();
			l.name = label;
			l.layerName = label;
			
			if (tilingCRSsAndExtents && tilingCRSsAndExtents.length > 0)
			{
				var tilingExtents: Array = [];
				var tilingInfo: TiledTilingInfo;
				//make copy of tilingCRSsAndExtents..because next loops adds items to it
				for each (tilingInfo in tilingCRSsAndExtents)
				{
					tilingExtents.push(tilingInfo);
				}
				
				for each (tilingInfo in tilingExtents)
				{
					l.addCRSWithTilingExtent(tilingInfo.urlPattern, tilingInfo.crsWithBBox.crs, tilingInfo.crsWithBBox.bbox, tilingInfo.tileSize, tilingInfo.minimumZoomLevel, tilingInfo.maximumZoomLevel);
				}
			}
			return l;
		}

		override public function hasCustomLayerOptions(): Boolean
		{
			return false;
		}

		override public function createCustomLayerOption(layer: IConfigurableLayer): Group
		{
			var options: TiledLayerOptions = new TiledLayerOptions();
			options.layer = layer as InteractiveLayerTiled;
			return options;
		}

		override public function serialize(storage: Storage): void
		{
			super.serialize(storage);
			try
			{
				storage.serializeNonpersistentArrayMap("behaviour", ma_behaviours, String, String);
			}
			catch (error: Error)
			{
				trace("QTTMSLayerConfiguration ma_behaviours error: " + error.message);
			}
//			baseURLPattern = storage.serializeString("url-pattern", baseURLPattern);
			storage.serializeNonpersistentArray("tiling-crs-and-extent", tilingCRSsAndExtents, TiledTilingInfo);
		}

		override public function renderPreview(f_width: Number, f_height: Number, iw: InteractiveWidget = null): void
		{
			if (!iw)
				iw = new InteractiveWidget(true);
			var l: InteractiveLayerQTTMS = createInteractiveLayer(iw) as InteractiveLayerQTTMS;
			l.renderPreview(l.graphics, f_width, f_height);
		}

		override public function isCompatibleWithCRS(s_crs: String): Boolean
		{
			for each (var qtTilingInfo: TiledTilingInfo in tilingCRSsAndExtents)
			{
				var crsWithBBox: CRSWithBBox = qtTilingInfo.crsWithBBox;
				if (crsWithBBox && crsWithBBox.crs == s_crs)
					return true;
			}
			return false;
		}

		override public function get serviceType(): String
		{
			return "QTT";
		}

		override public function toString(): String
		{
			if (tilingCRSsAndExtents && tilingCRSsAndExtents.length > 0)
			{
				var tilingInfo: TiledTilingInfo = tilingCRSsAndExtents[0];
				if (tilingInfo)
					return 'QTTMSLayerConfiguration ['+id+'] tilingInfo['+tilingInfo.id+'] urlPattern: ' + tilingInfo.urlPattern + ' CRS: ' + tilingInfo.crsWithBBox.crs + ' bbox: ' + tilingInfo.crsWithBBox.bbox.toBBOXString();
			}
			return 'QTTMSLayerConfiguration ['+id+'] with NO TILING info';
		}
	}
}
