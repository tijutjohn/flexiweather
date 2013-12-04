package com.iblsoft.flexiweather.ogc.configuration.layers
{
	import com.iblsoft.flexiweather.ogc.IBehaviouralObject;
	import com.iblsoft.flexiweather.ogc.configuration.layers.interfaces.ILayerConfiguration;
	import com.iblsoft.flexiweather.ogc.editable.IInteractiveLayerProvider;
	import com.iblsoft.flexiweather.ogc.tiling.InteractiveLayerTiled;
	import com.iblsoft.flexiweather.ogc.tiling.TileMatrixSetLink;
	import com.iblsoft.flexiweather.ogc.tiling.TiledLayerOptions;
	import com.iblsoft.flexiweather.ogc.tiling.TiledTilingInfo;
	import com.iblsoft.flexiweather.widgets.IConfigurableLayer;
	import com.iblsoft.flexiweather.widgets.InteractiveLayer;
	import com.iblsoft.flexiweather.widgets.InteractiveWidget;
	import spark.components.Group;

	public class TiledLayerConfiguration extends LayerConfiguration implements IInteractiveLayerProvider, ILayerConfiguration, IBehaviouralObject
	{
		public var tileMatrixSetLink: TileMatrixSetLink;
		public var ma_behaviours: Array = [];

		/** Array of TiledTilingInfo instances */
		private var _tilingCRSsAndExtents: Array = [];
		
		public function get tilingCRSsAndExtents(): Array
		{
			return _tilingCRSsAndExtents;
		}
		
		public function TiledLayerConfiguration()
		{
		}

		override public function createInteractiveLayer(iw: InteractiveWidget): InteractiveLayer
		{
			var l: InteractiveLayerTiled = new InteractiveLayerTiled(iw);
			l.name = label;
			l.layerName = label;
			return l;
		}

		public function removeAllTilingInfo(): void
		{
			_tilingCRSsAndExtents = [];
		}
		
		/**
		 * Add TiledTilingInfo into array of supported tilingInfo data for this configuration
		 * @param tilingInfo
		 *
		 */
		public function addTiledTilingInfo(tilingInfo: TiledTilingInfo): void
		{
			if (!tilingCRSsAndExtents)
				_tilingCRSsAndExtents = [];
			tilingCRSsAndExtents.push(tilingInfo);
		}
		
		/**
		 * Get TiledTilingInfo for given CRS
		 *
		 * @param crs
		 * @return
		 *
		 */
		public function getTiledTilingInfoForCRS(crs: String): TiledTilingInfo
		{
			if (tilingCRSsAndExtents && tilingCRSsAndExtents.length > 0)
			{
				for each (var info: TiledTilingInfo in tilingCRSsAndExtents)
				{
					if (info.crsWithBBox && info.crsWithBBox.crs == crs)
						return info;
				}
			}
			return null;
		}

		override public function destroy(): void
		{
			super.destroy();
			//TODO implement destroy functionality
			//destroy tileMatrixSetLink
			
			if (tilingCRSsAndExtents && tilingCRSsAndExtents.length > 0)
			{
				for each (var tiledTilingInfo: TiledTilingInfo in tilingCRSsAndExtents)
				{
					tiledTilingInfo.destroy();
				}
			}
			
			ma_behaviours = null;
			super.destroy();
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

		override public function renderPreview(f_width: Number, f_height: Number, iw: InteractiveWidget = null): void
		{
			if (!iw)
				iw = new InteractiveWidget(true);
			var l: InteractiveLayerTiled = createInteractiveLayer(iw) as InteractiveLayerTiled;
			l.renderPreview(l.graphics, f_width, f_height);
		}

		override public function isCompatibleWithCRS(s_crs: String): Boolean
		{
			//TODO implement TiledLayerConfiguration isCompatibleWithCRS
//			for each(var qtTilingInfo: TiledTilingInfo in tilingCRSsAndExtents) {
//				var crsWithBBox: CRSWithBBox = qtTilingInfo.crsWithBBox;  
//				if(crsWithBBox && crsWithBBox.crs == s_crs)
//					return true;
//			}
			return false;
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

		public function hasBehaviourString(s_behaviourId: String): Boolean
		{
			return s_behaviourId in ma_behaviours;
		}

		public function get behaviours(): Array
		{
			return ma_behaviours;
		}

		public function get serviceType(): String
		{
			return "Tiled";
		}

		override public function toString(): String
		{
			if (tilingCRSsAndExtents && tilingCRSsAndExtents.length > 0)
			{
				var tilingInfo: TiledTilingInfo = tilingCRSsAndExtents[0];
				if (tilingInfo)
				{
					return 'TiledLayerConfiguration ['+id+'] urlPattern: ' + tilingInfo.urlPattern + ' CRS: ' + tilingInfo.crsWithBBox.crs + ' bbox: ' + tilingInfo.crsWithBBox.bbox.toBBOXString(); 
				}
			}
			return 'TiledLayerConfiguration ['+id+'] with NO TILING info';
		}
	}
}
