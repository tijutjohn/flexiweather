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
	
	import spark.primitives.Graphic;

	[Event(name = 'drawTiles', type = '')]
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

		
//		override public function getTiledArea(viewBBox: BBox, zoomLevel: String, tileSize: int): TiledArea
//		{
//			if (m_tilingUtils)
//				return m_tilingUtils.getTiledArea(viewBBox, zoomLevel, tileSize);
//			return null;
//		}
		
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
//			m_tilingUtils = new TilingUtils();
//			m_tilingUtils.minimumZoom = 0;
//			m_tilingUtils.maximumZoom = 10;
			m_currentQTTViewProperties.setConfiguration(m_cfg);
			updateCurrentWMSViewProperties();
		}
/*
		override protected function createDefaultConfiguration(): TiledLayerConfiguration
		{
			var tileSize: uint = 256;
			var baseURLPattern: String;
			var primaryCRS: String = 'CRS:84';
			var primaryCRSTilingExtent: BBox = new BBox(-180, -90, 180, 90);
			var cfg: QTTMSLayerConfiguration = new QTTMSLayerConfiguration();
			cfg.tileSize = tileSize;
			var tilingInfo: TiledTilingInfo = new TiledTilingInfo(baseURLPattern, new CRSWithBBox(primaryCRS, primaryCRSTilingExtent));
			//				cfg.urlPattern = s_baseURLPattern;
			//				if(s_primaryCRS != null && primaryCRSTilingExtent != null)
			//						cfg.tilingCRSsAndExtents.push(new CRSWithBBox(s_primaryCRS, primaryCRSTilingExtent));
			tilingInfo.minimumZoomLevel = 0;
			tilingInfo.maximumZoomLevel = 10;
			tilingInfo.tileSize = tileSize;
			cfg.addTiledTilingInfo(tilingInfo);
			return cfg;
		}
*/
	
//		override public function checkZoom(): void
//		{
//			var i_oldZoom: int = zoomLevel;
//			findZoom();
//			if (zoomLevel == 0)
//			{
//				trace("check zoom level 0");	
//			}
//			if (i_oldZoom != zoomLevel)
//			{
//				
//				notifyZoomLevelChange(zoomLevel);
//				
//				/**
//				 * check if tiling pattern has been update with all data needed 
//				 * (default pattern is just InteractiveLayerWMSWithQTT.WMS_TILING_URL_PATTERN ('&TILEZOOM=%ZOOM%&TILECOL=%COL%&TILEROW=%ROW%') without any WMS data)
//				 */ 
//				notifyTilingPatternUpdate();
//				invalidateData(false);
//			}
//		}
		
		/*

		

		protected function onPreloadingWMSDataLoadingStarted(event: InteractiveLayerEvent): void
		{
			//			var wmsViewProperties: WMSViewProperties = event.target as WMSViewProperties;
			//			wmsViewProperties.removeEventListener(InteractiveDataLayer.LOADING_STARTED, onPreloadingWMSDataLoadingStarted);
			//			trace("\t onPreloadingWMSDataLoadingStarted wmsData: " + wmsViewProperties);

		}
		protected function onPreloadingWMSDataLoadingFinished(event: InteractiveLayerEvent): void
		{
			var loader: IWMSViewPropertiesLoader = event.target as IWMSViewPropertiesLoader;
			destroyWMSViewPropertiesPreloader(loader);

			var qttViewProperties: QTTViewProperties = event.data as QTTViewProperties;
			if (qttViewProperties)
			{
				qttViewProperties.removeEventListener(InteractiveDataLayer.LOADING_FINISHED, onPreloadingWMSDataLoadingFinished);
				//			debug("onPreloadingWMSDataLoadingFinished wmsData: " + wmsViewProperties);
				//			trace("\t onPreloadingWMSDataLoadingFinished PRELOADED: " + ma_preloadedWMSViewProperties.length + " , PRELAODING: " + ma_preloadingWMSViewProperties.length);

				//remove wmsViewProperties from array of currently preloading wms view properties
				var total: int = ma_preloadingQTTViewProperties.length;
				for (var i: int = 0; i < total; i++)
				{
					var currQTTViewProperties: QTTViewProperties = ma_preloadingQTTViewProperties[i] as QTTViewProperties;
					if (currQTTViewProperties && currQTTViewProperties.equals(qttViewProperties))
					{
						ma_preloadingQTTViewProperties.splice(i, 1);
						break;
					}
				}
				//add wmsViewProperties to array of already preloaded wms view properties
				ma_preloadedQTTViewProperties.push(qttViewProperties);

				notifyProgress(ma_preloadedQTTViewProperties.length, ma_preloadingQTTViewProperties.length + ma_preloadedQTTViewProperties.length, 'frames');

				if (ma_preloadingQTTViewProperties.length == 0)
				{
					//all wms view properties are preloaded, delete preloaded wms properties, bitmaps are stored in cache
					//				total = ma_preloadedWMSViewProperties.length;
					//				for (i = 0; i < total; i++)
					//				{
					//					currWMSViewProperties = ma_preloadedWMSViewProperties[i] as WMSViewProperties
					//					delete currWMSViewProperties;
					//				}
					ma_preloadedQTTViewProperties = [];

					//dispatch preloading finished to notify all about all WMSViewProperties are preloaded
					dispatchEvent(new InteractiveLayerEvent(InteractiveDataLayer.PRELOADING_FINISHED, true));
				}
			}
		}
		*/
		/**
		 * Instead of call updateData, call invalidateData() function. It works exactly as invalidateProperties, invalidateSize or invalidateDisplayList.
		 * You can call as many times as you want invalidateData function and updateData will be called just once each frame (if neeeded)
		 * @param b_forceUpdate
		 *
		 */
//		override protected function updateData(b_forceUpdate: Boolean): void
//		{
//			if (!layerWasDestroyed)
//			{
//				super.updateData(b_forceUpdate);
//				
//				if (_avoidTiling)
//				{
//					//tiling for this layer is for now avoided, do not update data
//					return;
//				}
//				
//				if(zoomLevel < 0)
//				{
//					// wrong zoom, do not continue
//					return;
//				}
//				
//				if(!visible) {
//					mb_updateAfterMakingVisible = true;
//					return;
//				}
//				
//				
//				var loader: IWMSViewPropertiesLoader = getWMSViewPropertiesLoader();
//				
//				loader.addEventListener(InteractiveDataLayer.LOADING_STARTED, onCurrentWMSDataLoadingStarted);
//				loader.addEventListener(InteractiveDataLayer.PROGRESS, onCurrentWMSDataProgress);
//				loader.addEventListener(InteractiveDataLayer.LOADING_FINISHED, onCurrentWMSDataLoadingFinished);
//				loader.addEventListener("invalidateDynamicPart", onCurrentWMSDataInvalidateDynamicPart);
//				
//				loader.updateWMSData(b_forceUpdate, m_currentQTTViewProperties, forcedLayerWidth, forcedLayerHeight);
//			}
//			
//		}
//		private function updateCurrentWMSViewProperties(): void
//		{
//			if (currentQTTViewProperties && container)
//			{
//				currentQTTViewProperties.crs = container.crs;
//				currentQTTViewProperties.setViewBBox(container.getViewBBox());
//				currentQTTViewProperties.zoom = zoomLevel;
//			}
//			
//		}
		/*
		override protected function findZoom(): void
		{
			if (m_tilingUtils)
			{
				var tilingExtent: BBox = getGTileBBoxForWholeCRS(container.crs);
				m_tilingUtils.onAreaChanged(container.crs, tilingExtent);
				var viewBBox: BBox = container.getViewBBox();
				var newZoomLevel2: Number = 1;
				if (tilingExtent)
				{
					var test: Number = (tilingExtent.width * width) / (viewBBox.width * 256);
					newZoomLevel2 = Math.log(test) * Math.LOG2E;
					//zoom level must be alway 0 or more
					newZoomLevel2 = Math.max(0, newZoomLevel2);
				}
				mi_zoom = Math.round(newZoomLevel2);
				return;
			}
			mi_zoom = 0;
		}

		public override function hasPreview(): Boolean
		{ return zoomLevel != -1; }

		public override function renderPreview(graphics: Graphics, f_width: Number, f_height: Number): void
		{
			if(!width || !height)
				return;

			if (status == InteractiveDataLayer.STATE_DATA_LOADED_WITH_ERRORS || status == InteractiveDataLayer.STATE_NO_DATA_AVAILABLE)
			{
				drawNoDataPreview(graphics, f_width, f_height);
				return;
			}

			var newCRS: String = container.crs;
			var tilingInfo: TiledTilingInfo = m_cfg.getTiledTilingInfoForCRS(newCRS);
			if (!tilingInfo)
			{
				//crs is not supported
				graphics.lineStyle(2, 0xcc0000, 0.7, true);
				graphics.moveTo(0, 0);
				graphics.lineTo(f_width - 1, f_height - 1);
				graphics.moveTo(0, f_height - 1);
				graphics.lineTo(f_width - 1, 0);

				return;
			}



			var matrix: Matrix  = new Matrix();
//			matrix.translate(-f_width / 3, -f_width / 3);
//			matrix.scale(3, 3);
//			matrix.translate(width / 3, height / 3);
//			matrix.invert();


			var scaleW: Number = f_width / width;
			var scaleH: Number = f_height / height;
			var scale: Number = Math.max(scaleW, scaleH);

			scale = Math.min(scale * 2, 1);

			var nw: Number = width * scale;
			var nh: Number = height * scale;
			var xDiff: Number = (nw - f_width) / 2;
			var yDiff: Number = (nh - f_height) / 2;

			matrix.scale(scale, scale);
			matrix.translate(-xDiff, -yDiff);

			var bd: BitmapData = new BitmapData(width, height, true, 0x00000000);
			bd.draw(this);

			graphics.beginBitmapFill(bd, matrix, false, true);
			graphics.drawRect(0, 0, f_width, f_height);
			graphics.endFill();
		}


		private function drawNoDataPreview(graphics: Graphics, f_width: Number, f_height: Number): void
		{
			graphics.lineStyle(2, 0xcc0000, 0.7, true);
			graphics.moveTo(0, 0);
			graphics.lineTo(f_width - 1, f_height - 1);
			graphics.moveTo(0, f_height - 1);
			graphics.lineTo(f_width - 1, 0);

		}
		*/
//		private var _tf:TextField = new TextField();
//		private var _tfBD:BitmapData;
//		private function drawText(txt: String, gr: Graphics, pos: Point): void
//		{
//			if(!_tf.filters || !_tf.filters.length) {
//				_tf.filters = [new GlowFilter(0xffffffff)];
//			}
//			var tfWidth: int = 100;
//			var tfHeight: int = 30;
//			var format: TextFormat = _tf.getTextFormat();
//			format.size = 18;
//			_tf.setTextFormat(format);
//			_tf.text = txt;
//
//			_tfBD = new BitmapData(tfWidth, tfHeight, true, 0);
//			_tfBD.draw(_tf);
//			
//			var m: Matrix = new Matrix();
//			m.translate(pos.x, pos.y)
//			gr.lineStyle(0,0,0);
//			gr.beginBitmapFill(_tfBD, m, false);
//			gr.drawRect(pos.x, pos.y, tfWidth, tfHeight);
//			gr.endFill();
//		}
//		public function getGTileBBoxForWholeCRS(s_crs: String): BBox
//		{
//			var tilingInfo: TiledTilingInfo = m_cfg.getTiledTilingInfoForCRS(s_crs);
//			if (tilingInfo)
//				return tilingInfo.crsWithBBox.bbox;
//			
//			return null;
//		}
//		private function hideMap(): void
//		{
//			var gr: Graphics = graphics; 
//			gr.clear();
//		}
//		private function isZoomCompatible(newZoom: int): Boolean
//		{
//			var newCRS: String = container.crs;
//			var tilingInfo: TiledTilingInfo = m_cfg.getTiledTilingInfoForCRS(newCRS);
//			if (!tilingInfo)
//			{
//				hideMap();
//				return false;
//			}
//			if (newZoom < tilingInfo.minimumZoomLevel || newZoom > tilingInfo.maximumZoomLevel)
//			{
//				hideMap();
//				return false;
//			}
//			
//			return true;
//			
//		}
//		private function isCRSCompatible(): Boolean
//		{
//			var newCRS: String = container.crs;
//			var tilingInfo: TiledTilingInfo = m_cfg.getTiledTilingInfoForCRS(newCRS);
//			if (!tilingInfo)
//			{
//				//crs is not supported
//				hideMap();
//				return false;
//			}
//			return true;
//		}
//		private function notifyZoomLevelChange(zoomLevel: int): void
//		{
//			var ilqe: InteractiveLayerQTTEvent = new InteractiveLayerQTTEvent(InteractiveLayerQTTEvent.ZOOM_LEVEL_CHANGED, true);
//			ilqe.zoomLevel = zoomLevel;
//			dispatchEvent(ilqe);			
//		}
		
		
		/*
		override public function destroy(): void
		{
			super.destroy();
			m_tilingUtils = null;
		}

		override public function baseURLPatternForCRS(crs: String): String
		{
			if (ms_explicitBaseURLPattern == null)
			{
				var tilingInfo: TiledTilingInfo;
				var qttmsConfig: QTTMSLayerConfiguration = m_cfg as QTTMSLayerConfiguration;
				if (qttmsConfig.tilingCRSsAndExtents && qttmsConfig.tilingCRSsAndExtents.length > 0)
					tilingInfo = qttmsConfig.getTiledTilingInfoForCRS(crs);
				if (tilingInfo && tilingInfo.urlPattern)
					return tilingInfo.urlPattern;
			}
			return ms_explicitBaseURLPattern;
		}

		override public function tiledAreaChanged(newCRS: String, newBBox: BBox): void
		{
			if (m_tilingUtils)
				m_tilingUtils.onAreaChanged(newCRS, newBBox);
		}
*/
		/*
		override public function onAreaChanged(b_finalChange: Boolean): void
		{
			super.onAreaChanged(b_finalChange);

			var newCRS: String = container.crs;

			//check if CRS is supported
			if (!isCRSCompatible())
			{
				return;
			}
			var newBBox: BBox = getGTileBBoxForWholeCRS(newCRS);
			var viewBBox: BBox = container.getViewBBox();

			updateCurrentWMSViewProperties();

//			trace("onAreaChanged newBBox: " + newBBox);
//			trace("onAreaChanged viewBBox: " + viewBBox);

			m_tilingUtils.onAreaChanged(newCRS, newBBox);

			if(b_finalChange || zoomLevel < 0) {
				var i_oldZoom: int = zoomLevel;

				findZoom();
				if (!isZoomCompatible(zoomLevel))
					return;

				if(zoomLevel != i_oldZoom)
				{
					notifyZoomLevelChange(zoomLevel);
					m_cache.invalidate(newCRS, viewBBox);
				}
				invalidateData(false);
			}
			else
				invalidateDynamicPart();
		}
		*/
//
//		public function getGTileBBox(s_crs: String, tileIndex: TileIndex): BBox
//		{
//			var extent: BBox = getGTileBBoxForWholeCRS(s_crs);
//			if(extent == null)
//				return null;
//
//			var i_tilesInSerie: uint = 1 << tileIndex.mi_tileZoom;
//			var f_tileWidth: Number = extent.width / i_tilesInSerie;
//			var f_tileHeight: Number = extent.height / i_tilesInSerie;
//			var f_xMin: Number = extent.xMin + tileIndex.mi_tileCol * f_tileWidth; 
//
//			// note that tile row numbers increase in the opposite way as the Y-axis
//
//			var f_yMin: Number = extent.yMax - (tileIndex.mi_tileRow + 1) * f_tileHeight;
//
//			var tileBBox: BBox = new BBox(f_xMin, f_yMin, f_xMin + f_tileWidth, f_yMin + f_tileHeight);
//			
//			return tileBBox;
//		}
/*		
		public function get tilingUtils(): TilingUtils
		{
			return m_tilingUtils;
		}
*/


//		public function baseURLPatternForCRS(crs: String): String
//		{
//			if(ms_explicitBaseURLPattern == null)
//			{
//				var tilingInfo: TiledTilingInfo;
//				if (m_cfg.tilingCRSsAndExtents && m_cfg.tilingCRSsAndExtents.length > 0)
//					tilingInfo = m_cfg.getTiledTilingInfoForCRS(crs);
//				
//				if (tilingInfo && tilingInfo.urlPattern)
//					return tilingInfo.urlPattern;
//			}
//			return ms_explicitBaseURLPattern;
//			
//		}
//		public function get baseURLPattern(): String
//		{
//			return baseURLPatternForCRS(container.getCRS());
//		}
		
		override public function clone(): InteractiveLayer
		{
			var newLayer: InteractiveLayerQTTMS = new InteractiveLayerQTTMS(container, m_cfg as QTTMSLayerConfiguration);
			updatePropertyForCloneLayer(newLayer);
			return newLayer;
		}
		
		override public function toString(): String
		{
			return "InteractiveLayerQTTMS " + name;
		}
	}
}
import com.iblsoft.flexiweather.net.loaders.UniURLLoader;
import com.iblsoft.flexiweather.ogc.BBox;
import com.iblsoft.flexiweather.ogc.net.loaders.WMSImageLoader;
import com.iblsoft.flexiweather.ogc.tiling.TileIndex;
import com.iblsoft.flexiweather.widgets.BackgroundJob;
import com.iblsoft.flexiweather.widgets.InteractiveWidget;
import flash.net.URLRequest;
import flash.utils.Dictionary;
import mx.messaging.AbstractConsumer;

class ViewPartReflectionsHelper
{
	private var _dictionary: Dictionary = new Dictionary();
	private var _container: InteractiveWidget;

	function ViewPartReflectionsHelper(iw: InteractiveWidget)
	{
		_container = iw;
	}

	private function getDictionaryKey(viewPart: BBox): String
	{
		return viewPart.toBBOXString();
	}

	public function addViewPartReflections(viewPart: BBox): Array
	{
		var arr: Array = _container.mapBBoxToViewReflections(viewPart);
		_dictionary[getDictionaryKey(viewPart)] = arr;
		return arr;
	}

	public function getViewPartReflections(viewPart: BBox): Array
	{
		if (_dictionary[getDictionaryKey(viewPart)])
			return _dictionary[getDictionaryKey(viewPart)];
		else
			return addViewPartReflections(viewPart);
	}
}
