package com.iblsoft.flexiweather.ogc
{
	import com.iblsoft.flexiweather.events.InteractiveLayerEvent;
	import com.iblsoft.flexiweather.events.InteractiveLayerProgressEvent;
	import com.iblsoft.flexiweather.events.InteractiveLayerQTTEvent;
	import com.iblsoft.flexiweather.events.WMSViewPropertiesEvent;
	import com.iblsoft.flexiweather.net.events.UniURLLoaderErrorEvent;
	import com.iblsoft.flexiweather.net.events.UniURLLoaderEvent;
	import com.iblsoft.flexiweather.net.loaders.AbstractURLLoader;
	import com.iblsoft.flexiweather.net.loaders.UniURLLoader;
	import com.iblsoft.flexiweather.ogc.cache.CacheItem;
	import com.iblsoft.flexiweather.ogc.cache.CacheItemMetadata;
	import com.iblsoft.flexiweather.ogc.cache.ICache;
	import com.iblsoft.flexiweather.ogc.cache.ICachedLayer;
	import com.iblsoft.flexiweather.ogc.cache.WMSTileCache;
	import com.iblsoft.flexiweather.ogc.configuration.layers.QTTMSLayerConfiguration;
	import com.iblsoft.flexiweather.ogc.configuration.layers.TiledLayerConfiguration;
	import com.iblsoft.flexiweather.ogc.configuration.layers.interfaces.ILayerConfiguration;
	import com.iblsoft.flexiweather.ogc.data.viewProperties.IViewProperties;
	import com.iblsoft.flexiweather.ogc.data.viewProperties.IWMSViewPropertiesLoader;
	import com.iblsoft.flexiweather.ogc.data.viewProperties.TiledTileViewProperties;
	import com.iblsoft.flexiweather.ogc.data.viewProperties.TiledViewProperties;
	import com.iblsoft.flexiweather.ogc.preload.IPreloadableLayer;
	import com.iblsoft.flexiweather.ogc.tiling.ITiledLayer;
	import com.iblsoft.flexiweather.ogc.tiling.ITilesProvider;
	import com.iblsoft.flexiweather.ogc.tiling.InteractiveLayerTiled;
	import com.iblsoft.flexiweather.ogc.tiling.TileIndex;
	import com.iblsoft.flexiweather.ogc.tiling.TileMatrix;
	import com.iblsoft.flexiweather.ogc.tiling.TileMatrixLimits;
	import com.iblsoft.flexiweather.ogc.tiling.TileMatrixSet;
	import com.iblsoft.flexiweather.ogc.tiling.TileMatrixSetLimits;
	import com.iblsoft.flexiweather.ogc.tiling.TileMatrixSetLink;
	import com.iblsoft.flexiweather.ogc.tiling.TileSize;
	import com.iblsoft.flexiweather.ogc.tiling.TiledArea;
	import com.iblsoft.flexiweather.ogc.tiling.TiledLoader;
	import com.iblsoft.flexiweather.ogc.tiling.TiledTileRequest;
	import com.iblsoft.flexiweather.ogc.tiling.TiledTilesProvider;
	import com.iblsoft.flexiweather.ogc.tiling.TiledTilingInfo;
	import com.iblsoft.flexiweather.ogc.tiling.TilingUtils;
	import com.iblsoft.flexiweather.plugins.IConsole;
	import com.iblsoft.flexiweather.proj.Coord;
	import com.iblsoft.flexiweather.proj.Projection;
	import com.iblsoft.flexiweather.utils.Serializable;
	import com.iblsoft.flexiweather.utils.Storage;
	import com.iblsoft.flexiweather.widgets.BackgroundJob;
	import com.iblsoft.flexiweather.widgets.BackgroundJobManager;
	import com.iblsoft.flexiweather.widgets.IConfigurableLayer;
	import com.iblsoft.flexiweather.widgets.InteractiveDataLayer;
	import com.iblsoft.flexiweather.widgets.InteractiveLayer;
	import com.iblsoft.flexiweather.widgets.InteractiveWidget;
	
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.DisplayObject;
	import flash.display.Graphics;
	import flash.events.Event;
	import flash.filters.GlowFilter;
	import flash.geom.Matrix;
	import flash.geom.Point;
	import flash.net.URLRequest;
	import flash.text.TextField;
	import flash.text.TextFormat;
	import flash.utils.Dictionary;
	import flash.utils.Timer;
	import flash.utils.setTimeout;
	
	import mx.controls.Alert;
	import mx.events.DynamicEvent;
	
	/**
	 * Generic Quad Tree (like Google Maps) tiling layer
	 **/
	public class InteractiveLayerQTTMS extends InteractiveLayerTiled implements IConfigurableLayer, ICachedLayer, ITiledLayer, IPreloadableLayer, Serializable
	{
		private var mi_updateCycleAge: uint = 0;

//		protected var m_cfg: QTTMSLayerConfiguration;
//		protected var mb_updateAfterMakingVisible: Boolean = false;
//		public function InteractiveLayerQTTMS(
//				container: InteractiveWidget,
//				cfg: QTTMSLayerConfiguration,
//				s_baseURLPattern: String = null, s_primaryCRS: String = null, primaryCRSTilingExtent: BBox = null,
//				minimumZoomLevel: uint = 0, maximumZoomLevel: uint = 10, tileSize: uint = 256)
		public function InteractiveLayerQTTMS(container: InteractiveWidget = null, cfg: QTTMSLayerConfiguration = null)
		{
			super(container, cfg);
		}

		
		public function addCRSWithTilingExtent(s_urlPattern: String, s_tilingCRS: String, crsTilingExtent: BBox, tileSize: uint, minimumZoomLevel: int, maximumZoomLevel: int): void
		{
			if (tileSize == 0)
				tileSize = TileSize.SIZE_256;
			
			//new functionality need to generate correct tile matrix set
			var tileMatrixSet: TileMatrixSet = new TileMatrixSet();
			tileMatrixSet.id = s_tilingCRS;
			tileMatrixSet.supportedCRS = s_tilingCRS;
//			var denominators: Array = [5.590822639508929E8, 2.7954113197544646E8, 1.3977056598772323E8];
			for (var i: int = minimumZoomLevel; i <= maximumZoomLevel; i++)
			{
				var matrix: TileMatrix = new TileMatrix();
				matrix.id = s_tilingCRS + ':' + i;
				
				//TODO how to count scaleDenominator
				matrix.topLeftCorner = new Point(crsTilingExtent.xMin, crsTilingExtent.yMin);
				matrix.tileWidth = tileSize; 
				matrix.tileHeight = tileSize;
				matrix.matrixWidth = Math.pow(2, i);
				matrix.matrixHeight = Math.pow(2, i);

				var widthScaleDenominator: Number = crsTilingExtent.width / (matrix.tileWidth * matrix.matrixWidth); 
				var heightScaleDenominator: Number = crsTilingExtent.height / (matrix.tileHeight * matrix.matrixHeight); 
					
				matrix.scaleDenominator = widthScaleDenominator; //denominators[i];
				tileMatrixSet.addTileMatrix(matrix);
			}
			var tileMatrixSetLink: TileMatrixSetLink = new TileMatrixSetLink();
			tileMatrixSetLink.tileMatrixSet = tileMatrixSet;
			
			var tileMatrixSetLimitsArray: TileMatrixSetLimits = new TileMatrixSetLimits();
			for (var l: int = minimumZoomLevel; l <= maximumZoomLevel; l++)
			{
				var limit: TileMatrixLimits = new TileMatrixLimits();
				limit.tileMatrix = s_tilingCRS + ':' + l;
				limit.minTileRow = 0; //1;
				limit.maxTileRow = Math.pow(2, l) - 1;
				limit.minTileColumn = 0;
				limit.maxTileColumn = limit.maxTileRow;
				tileMatrixSetLimitsArray.addTileMatrixLimits(limit);
			}
			
			tileMatrixSetLink.tileMatrixSetLimitsArray = tileMatrixSetLimitsArray;
			
			addTileMatrixSetLink(tileMatrixSetLink);
			
			
			var crsWithBBox: CRSWithBBox = new CRSWithBBox(s_tilingCRS, crsTilingExtent);
			var tilingInfo: TiledTilingInfo = new TiledTilingInfo(s_urlPattern, crsWithBBox);
			(m_cfg as QTTMSLayerConfiguration).addTiledTilingInfo(tilingInfo);
			
		}
		
		public function clearCRSWithTilingExtents(): void
		{
			(m_cfg as QTTMSLayerConfiguration).removeAllTilingInfo();
			removeAllTileMatrixData();
		}

		override protected function initializeLayerAfterAddToStage(): void
		{
			super.initializeLayerAfterAddToStage();
			
			initializeLayerProperties();
		}
		
		override protected function initializeLayer(): void
		{
			super.initializeLayer();
		}
		
		private function initializeLayerProperties(): void
		{
			m_currentQTTViewProperties.setConfiguration(m_cfg);
			updateCurrentWMSViewProperties();
		}
		
		override public function clone(): InteractiveLayer
		{
			trace(this + " clone() config: " + configuration);
			
			var newLayer: InteractiveLayerQTTMS;
			if (!configuration)
				newLayer = new InteractiveLayerQTTMS(container, m_cfg as QTTMSLayerConfiguration);
			else
				newLayer = configuration.createInteractiveLayer(container) as InteractiveLayerQTTMS;
			
			updatePropertyForCloneLayer(newLayer);
			return newLayer;
		}
		
		override public function toString(): String
		{
			return "InteractiveLayerQTTMS " + name + " / " + layerID;
		}
	}
}