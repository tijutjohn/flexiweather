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
	import com.iblsoft.flexiweather.ogc.data.IViewProperties;
	import com.iblsoft.flexiweather.ogc.data.IWMSViewPropertiesLoader;
	import com.iblsoft.flexiweather.ogc.data.QTTViewProperties;
	import com.iblsoft.flexiweather.ogc.preload.IPreloadableLayer;
	import com.iblsoft.flexiweather.ogc.tiling.ITiledLayer;
	import com.iblsoft.flexiweather.ogc.tiling.ITilesProvider;
	import com.iblsoft.flexiweather.ogc.tiling.QTTLoader;
	import com.iblsoft.flexiweather.ogc.tiling.QTTTileRequest;
	import com.iblsoft.flexiweather.ogc.tiling.QTTTileViewProperties;
	import com.iblsoft.flexiweather.ogc.tiling.QTTTilesProvider;
	import com.iblsoft.flexiweather.ogc.tiling.TileIndex;
	import com.iblsoft.flexiweather.ogc.tiling.TiledArea;
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
	
	[Event(name='drawTiles', type='')]
	
	/**
	 * Generic Quad Tree (like Google Maps) tiling layer
	 **/
	public class InteractiveLayerQTTMS extends InteractiveDataLayer 
					implements IConfigurableLayer, ICachedLayer, ITiledLayer, IPreloadableLayer, Serializable
	{
		public static const UPDATE_TILING_PATTERN: String = 'updateTilingPattern';
		
		public static const DRAW_TILES: String = 'drawTiles';
		
		public static var imageSmooth: Boolean = true;
		public static var drawBorders: Boolean = false;
		public static var drawDebugText: Boolean = false;
		
//		private var _viewPartsReflections: ViewPartReflectionsHelper;
		
		private var _avoidTiling: Boolean;

		private var mi_updateCycleAge: uint = 0;

		public function set avoidTiling(value:Boolean):void
		{
			_avoidTiling = value;
		}

		protected var m_cache: WMSTileCache;
		public function get cache(): WMSTileCache
		{
			return m_cache;
		}
		
		private var m_tilingUtils: TilingUtils;
		
		protected var m_timer: Timer = new Timer(10000);
		
		protected var m_cfg: QTTMSLayerConfiguration;
		public function get configuration():ILayerConfiguration
		{
			return m_cfg;
		}
		
		/** This is used only if overriding using the setter, otherwise the value from m_cfg is used. */ 
		protected var ms_explicitBaseURLPattern: String;
		
		
		private var ms_oldCRS: String;
		private var mi_zoom: int = 1;
		public var tileScaleX: Number;
		public var tileScaleY: Number;
		
		/**
		 * Currently displayed wms data 
		 */		
		protected var m_currentQTTViewProperties: QTTViewProperties;
		
		public function get currentViewProperties(): IViewProperties
		{
			return currentQTTViewProperties;
		}
		
		public function get currentQTTViewProperties(): QTTViewProperties
		{
			return m_currentQTTViewProperties;
		}
		
		/**
		 * wms data which are currently preloading 
		 */		
		protected var ma_preloadingQTTViewProperties: Array;
		
		/**
		 * wms data which are already preloaded 
		 */		
		protected var ma_preloadedQTTViewProperties: Array;
		
		
		public function InteractiveLayerQTTMS(
				container: InteractiveWidget,
				cfg: QTTMSLayerConfiguration,
				s_baseURLPattern: String = null, s_primaryCRS: String = null, primaryCRSTilingExtent: BBox = null,
				minimumZoomLevel: uint = 0, maximumZoomLevel: uint = 10)
		{
			super(container);
			
			
			var tilingInfo: QTTilingInfo
			if(cfg == null) {
				cfg = new QTTMSLayerConfiguration();
				tilingInfo = new QTTilingInfo(s_baseURLPattern, new CRSWithBBox(s_primaryCRS, primaryCRSTilingExtent));
//				cfg.urlPattern = s_baseURLPattern;
//				if(s_primaryCRS != null && primaryCRSTilingExtent != null)
//						cfg.tilingCRSsAndExtents.push(new CRSWithBBox(s_primaryCRS, primaryCRSTilingExtent));
				tilingInfo.minimumZoomLevel = minimumZoomLevel;
				tilingInfo.maximumZoomLevel = maximumZoomLevel;
				cfg.addQTTilingInfo(tilingInfo);
			}
			m_cfg = cfg;
			
			m_tilingUtils = new TilingUtils();
			m_tilingUtils.minimumZoom = minimumZoomLevel;
			m_tilingUtils.maximumZoom = maximumZoomLevel;
			
			ma_preloadingQTTViewProperties = [];
			ma_preloadedQTTViewProperties = [];
			
			m_currentQTTViewProperties = new QTTViewProperties();
			updateCurrentWMSViewProperties();
			
//			m_currentWMSViewProperties.addEventListener(SynchronisedVariableChangeEvent.SYNCHRONISED_VARIABLE_CHANGED, onCurrentWMSDataSynchronisedVariableChanged);
//			m_currentWMSViewProperties.addEventListener(WMSViewPropertiesEvent.WMS_DIMENSION_VALUE_SET, onWMSDimensionValueSet);
			
			
			m_cache = new WMSTileCache();
//			_viewPartsReflections = new ViewPartReflectionsHelper(container);
		}

		public function serialize(storage: Storage): void
		{
			trace("InteractiveLayerQTTMS serialize");
			
			if (storage.isLoading())
			{
				var newAlpha: Number = storage.serializeNumber("transparency", alpha);
				if (newAlpha < 1)
				{
					alpha = newAlpha;
				}
			} else {
				if (alpha < 1) 
				{
					storage.serializeNumber("transparency", alpha);
				}
			}
		}
		
		public override function invalidateSize(): void
		{
			super.invalidateSize();
			if (container != null)
			{
				width = container.width;
				height = container.height;
			}
		}
		
		
		public override function validateSize(b_recursive: Boolean = false): void
		{
			super.validateSize(b_recursive);
			
			checkZoom();
		}
		
		public function checkZoom(): void
		{
			var i_oldZoom: int = mi_zoom;
			findZoom();
			if (mi_zoom == 0)
			{
				trace("check zoom level 0");	
			}
			if (i_oldZoom != mi_zoom)
			{
				
				notifyZoomLevelChange(mi_zoom);
				
				/**
				 * check if tiling pattern has been update with all data needed 
				 * (default pattern is just InteractiveLayerWMSWithQTT.WMS_TILING_URL_PATTERN ('&TILEZOOM=%ZOOM%&TILECOL=%COL%&TILEROW=%ROW%') without any WMS data)
				 */ 
				notifyTilingPatternUpdate();
				invalidateData(false);
			}
		}
		
		
		private function notifyTilingPatternUpdate(): void
		{
			dispatchEvent(new Event(UPDATE_TILING_PATTERN));
		}

		public static function expandURLPattern(s_url: String, tileIndex: TileIndex): String
		{
			if (s_url)
			{
				s_url = s_url.replace('%COL%', String(tileIndex.mi_tileCol));
				s_url = s_url.replace('%ROW%', String(tileIndex.mi_tileRow));
				s_url = s_url.replace('%ZOOM%', String(tileIndex.mi_tileZoom));
			} else {
				trace("expandURLPattern problem with url");
			}
			return s_url;
		}


		public function invalidateCache(): void
		{
			m_cache.invalidate(container.crs, getGTileBBoxForWholeCRS(container.crs));
		}

		
		public function clearCRSWithTilingExtents(): void
		{
			m_cfg.removeAllTilingInfo();
			//md_crsToTilingExtent = new Dictionary(); 
		}

		public function addCRSWithTilingExtent(s_urlPattern: String, s_tilingCRS: String, crsTilingExtent: BBox): void
		{
			var crsWithBBox: CRSWithBBox = new CRSWithBBox(s_tilingCRS, crsTilingExtent);
			var tilingInfo: QTTilingInfo = new QTTilingInfo(s_urlPattern, crsWithBBox);
			
			m_cfg.addQTTilingInfo(tilingInfo);
			
			//md_crsToTilingExtent[s_tilingCRS] = crsTilingExtent;
		}
		
		public function changeViewProperties(viewProperties: IViewProperties): void
		{
//			m_currentQTTViewProperties.removeEventListener(SynchronisedVariableChangeEvent.SYNCHRONISED_VARIABLE_CHANGED, onCurrentWMSDataSynchronisedVariableChanged);
			
			m_currentQTTViewProperties = viewProperties as QTTViewProperties;
			
			trace("ILQTT changeViewProperties: " + m_currentQTTViewProperties);
//			m_currentQTTViewProperties.addEventListener(SynchronisedVariableChangeEvent.SYNCHRONISED_VARIABLE_CHANGED, onCurrentWMSDataSynchronisedVariableChanged);
		}
		
		/**
		 * This function is used in preload function to set (share) configuration and cache for all preloaded wmsViewProperties items.
		 * It has to be separate function, because WMSViewProperties class supports tiled and non tiled layers and there is different configuration and cache
		 * for both types of layer. This function must be overriden for tiled layers (see InteractiveLayerWMSWithQTT.updateWMSViewPropertiesConfiguration)
		 *  
		 * @param wmsViewProperties
		 * @param configuration
		 * @param cache
		 * 
		 */		
		protected function updateWMSViewPropertiesConfiguration(qttViewProperties: QTTViewProperties, configuration: ILayerConfiguration, cache: ICache): void
		{
			qttViewProperties.setConfiguration(m_cfg);
			//			wmsViewProperties.cache = m_cache;
		}
		
		protected function destroyWMSViewPropertiesLoader(loader: IWMSViewPropertiesLoader): void
		{
			loader.removeEventListener("invalidateDynamicPart", onQTTViewPropertiesDataInvalidateDynamicPart);
			loader.removeEventListener(InteractiveDataLayer.LOADING_FINISHED, onPreloadingWMSDataLoadingFinished);
			
			loader.destroy();
		}

		protected function getWMSViewPropertiesLoader(): IWMSViewPropertiesLoader
		{
			return new QTTLoader(this, zoomLevel);
		}
		
		public function preload(viewProperties: IViewProperties): void
		{
			var qttViewProperties: QTTViewProperties = viewProperties as QTTViewProperties;
			if (!qttViewProperties)
				return;
			
			qttViewProperties.name = name;
			
			updateWMSViewPropertiesConfiguration(qttViewProperties, m_cfg, m_cache);
			
			if (ma_preloadingQTTViewProperties.length == 0)
			{
				dispatchEvent(new InteractiveLayerEvent(InteractiveDataLayer.PRELOADING_STARTED, true));
			}
			
			ma_preloadingQTTViewProperties.push(qttViewProperties);
			
			//FIXME loader needs to be destroyed, when data are loaded
			var loader: IWMSViewPropertiesLoader = getWMSViewPropertiesLoader();
			
			//			loader.addEventListener(InteractiveDataLayer.LOADING_STARTED, onPreloadingWMSDataLoadingStarted);
			//			loader.addEventListener(InteractiveDataLayer.LOADING_FINISHED, onPreloadingWMSDataLoadingFinished);
			//			loader.addEventListener(InteractiveDataLayer.LOADING_STARTED, onPreloadingWMSDataLoadingStarted);
			loader.addEventListener("invalidateDynamicPart", onQTTViewPropertiesDataInvalidateDynamicPart);
			loader.addEventListener(InteractiveDataLayer.LOADING_FINISHED, onPreloadingWMSDataLoadingFinished);
			
			loader.updateWMSData(true, qttViewProperties, forcedLayerWidth, forcedLayerHeight);
		}
		
		/**
		 * Preload all frames from input array
		 *  
		 * @param wmsViewPropertiesArray - input array
		 * 
		 */		
		public function preloadMultiple(viewPropertiesArray: Array): void
		{
			for each (var qttViewProperties: QTTViewProperties in viewPropertiesArray)
			{
				preload(qttViewProperties);
			}
		}
		
		public function isPreloadedMultiple(viewPropertiesArray: Array): Boolean
		{
			var isAllPreloaded: Boolean = true;
			
			for each (var qttViewProperties: QTTViewProperties in viewPropertiesArray)
			{
				isAllPreloaded = isAllPreloaded && isPreloaded(qttViewProperties);
			}
			return isAllPreloaded;
		}
		
		public function isPreloaded(viewProperties: IViewProperties): Boolean
		{
			var qttViewProperties: QTTViewProperties = viewProperties as QTTViewProperties;
			if (!qttViewProperties)
				return false;
			
			return qttViewProperties.isPreloaded(m_cache);
		}
		
		/**
		 * Function checks if part is cached already. Function similar to udpateDataPart.
		 * Only difference is, that isPartCached does not load data if part is not cached.
		 *  
		 * @param s_currentCRS
		 * @param currentViewBBox
		 * @param dimensions
		 * @param i_width
		 * @param i_height
		 * @return 
		 * 
		 */		
		private function isPartCached(qttViewProperties: QTTViewProperties, s_currentCRS: String, currentViewBBox: BBox, i_width: uint, i_height: uint): Boolean
		{
			/**
			 * this is how you can find properties for cache metadata
			 * 
			 * var s_currentCRS: String = container.getCRS();
			 * var currentViewBBox: BBox = container.getViewBBox();
			 * var dimensions: Array = getDimensionForCache();
			 */
			/*
			var request: URLRequest = m_cfg.toGetMapRequest(
				s_currentCRS, currentViewBBox.toBBOXString(),
				i_width, i_height,
				getWMSStyleListString());
			
			if (!request)
				return false;
			
			qttViewProperties.updateDimensionsInURLRequest(request);
			qttViewProperties.updateCustomParametersInURLRequest(request);
			
			var wmsCache: WMSTileCache = getCache() as WMSTileCache;
			
			//			var img: Bitmap = null;
			
			
			
			var isCached: Boolean = getTileFromCache(qttViewProperties, request);
			var imgTest: DisplayObject = wmsCache.getCacheItemBitmap(itemMetadata);
			if (isCached && imgTest != null) {
				return true;
			}
			*/
			return false;
		}
		
		
		protected function onQTTViewPropertiesDataInvalidateDynamicPart(event: DynamicEvent): void
		{
//			trace("onQTTViewPropertiesDataInvalidateDynamicPart");	
		}
		
		protected function onPreloadingWMSDataLoadingStarted(event: InteractiveLayerEvent): void
		{
			//			var wmsViewProperties: WMSViewProperties = event.target as WMSViewProperties;
			//			wmsViewProperties.removeEventListener(InteractiveDataLayer.LOADING_STARTED, onPreloadingWMSDataLoadingStarted);
			//			trace("\t onPreloadingWMSDataLoadingStarted wmsData: " + wmsViewProperties);
			
		}
		protected function onPreloadingWMSDataLoadingFinished(event: InteractiveLayerEvent): void
		{
			var loader: IWMSViewPropertiesLoader = event.target as IWMSViewPropertiesLoader;
			destroyWMSViewPropertiesLoader(loader);
			
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
		
		/**
		 * Function which loadData. It's good habit to call this function when you want to load your data to have one channel for loading data.
		 * It's easier to testing and it's one place for checking requests
		 *  
		 * @param urlRequest
		 * @param associatedData
		 * @param s_backgroundJobName
		 * 
		 */	
		public function loadData(
			urlRequest: URLRequest,
			associatedData: Object = null,
			s_backgroundJobName: String = null): void
		{
			var url: String = urlRequest.url;
			dataLoader.load(urlRequest, associatedData, s_backgroundJobName);
		}
		
		
		
		
		
		
		/**
		 * Instead of call updateData, call invalidateData() function. It works exactly as invalidateProperties, invalidateSize or invalidateDisplayList.
		 * You can call as many times as you want invalidateData function and updateData will be called just once each frame (if neeeded) 
		 * @param b_forceUpdate
		 * 
		 */
		override protected function updateData(b_forceUpdate: Boolean): void
		{
			super.updateData(b_forceUpdate);
			
			if (_avoidTiling)
			{
				//tiling for this layer is for now avoided, do not update data
				return;
			}
			
			if(mi_zoom < 0)
			{
				// wrong zoom, do not continue
				return;
			}
			
			
			var loader: IWMSViewPropertiesLoader = getWMSViewPropertiesLoader();
			
			loader.addEventListener(InteractiveDataLayer.LOADING_STARTED, onCurrentWMSDataLoadingStarted);
			loader.addEventListener(InteractiveDataLayer.LOADING_FINISHED, onCurrentWMSDataLoadingFinished);
			loader.addEventListener("invalidateDynamicPart", onCurrentWMSDataInvalidateDynamicPart);
			
			loader.updateWMSData(b_forceUpdate, m_currentQTTViewProperties, forcedLayerWidth, forcedLayerHeight);
			
		}
		
		
		private function updateCurrentWMSViewProperties(): void
		{
			if (currentQTTViewProperties && container)
			{
				currentQTTViewProperties.crs = container.crs;
				currentQTTViewProperties.setViewBBox(container.getViewBBox());
				currentQTTViewProperties.zoom = zoomLevel;
			}
			
		}
		
		protected var _currentQTTDataLoadingStarted: Boolean;
		
		protected function onCurrentWMSDataLoadingStarted(event: InteractiveLayerEvent): void
		{
			//			trace("\t onCurrentWMSDataLoadingStarted ["+name+"]");
			_currentQTTDataLoadingStarted = true;
			notifyLoadingStart(false);
		}
		
		protected function onCurrentWMSDataProgress(event: InteractiveLayerProgressEvent): void
		{
			notifyProgress(event.loaded, event.total, event.units);
			
		}
		
		protected function onCurrentWMSDataLoadingFinished(event: InteractiveLayerEvent): void
		{
			//			trace("\t onCurrentWMSDataLoadingFinished ["+name+"]");
			notifyLoadingFinished();	
			_currentQTTDataLoadingStarted = false;
			
			invalidateDynamicPart(true);
		}
		
		protected function onCurrentWMSDataInvalidateDynamicPart(event: DynamicEvent): void
		{
			invalidateDynamicPart(event['invalid']);
		}
		
//		private function updateDataPart(): void
//		{
//			
//		}
		
		
		/**
		 * Removed all cached tiles except tiles valid for specified time 
		 * @param validity
		 * 
		 */		
		public function removeAllCachedTilesExceptTime(validity: Date, updateCycleAge: uint, b_disposeDisplayed: Boolean = false): void
		{
			var tiles: Array = cache.getCacheItems();
			for each (var item: CacheItem in tiles)
			{
				var qttTileViewProperties: QTTTileViewProperties = item.viewProperties as QTTTileViewProperties;
				var qttViewProperties: QTTViewProperties = qttTileViewProperties as QTTViewProperties;
				
				if (qttViewProperties.validity.time != validity.time && qttTileViewProperties.updateCycleAge != updateCycleAge)
				{
					cache.deleteCacheItem(item, b_disposeDisplayed)
				}
			}
		}
		
		
		public function getTileFromCache(qttTileViewProperties: QTTTileViewProperties, request: URLRequest): Object
		{
			var tiledCache: WMSTileCache = m_cache as WMSTileCache;
		
			
			/*
			var s_crs: String = metadata.crs as String;
			var tileIndex: TileIndex = metadata.tileIndex as TileIndex;
			var time: Date = metadata.validity;
			var specialStrings: Array = metadata.specialStrings as Array;
			var url: URLRequest = metadata.url;
			*/
			
//			var metadata: CacheItemMetadata = new CacheItemMetadata();
//			metadata.crs = qttTileViewProperties.crs;
//			metadata.url = request;
//			metadata.validity = validity;
//			metadata.specialStrings = qttTileViewProperties.specialCacheStrings;
			
			return tiledCache.getCacheItem(qttTileViewProperties); 
		}
		
		private function findZoom(): void
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
		}
		
		override public function refresh(b_force: Boolean): void
		{
			findZoom();
			super.refresh(b_force);
			invalidateData(b_force);
		}
		
		override public function draw(graphics: Graphics): void
		{
			super.draw(graphics);
			
//			graphics.clear();
//			setTimeout(customDraw, 500, m_currentQTTViewProperties, graphics);
			customDraw(m_currentQTTViewProperties, graphics);
		}
		
		private var _debugDrawInfoArray: Array;
		private function customDraw(qttViewProperties: QTTViewProperties, graphics: Graphics, redrawBorder: Boolean = false): void
		{
			if(mi_zoom == -1)
			{
				trace("InteractiveLayerQTTMS.customDraw(): Isomething is wrong, tile zoom is -1");
				return;
			}

			_debugDrawInfoArray = [];
			
			var s_crs: String = qttViewProperties.crs; //container.crs;
			var currentBBox: BBox = qttViewProperties.getViewBBox();  //container.getViewBBox();
			var tilingBBox: BBox = getGTileBBoxForWholeCRS(s_crs); // extent of tile z=0/r=0/c=0
			if(tilingBBox == null) {
				trace("InteractiveLayerQTTMS.customDraw(): No tiling extent for CRS " + container.crs);
				return;
			}

			if (qttViewProperties.specialCacheStrings)
				trace("ILQTTMS customDraw " + qttViewProperties.toString() + " dim: " + qttViewProperties.specialCacheStrings[0]);
			
			var wmsTileCache: WMSTileCache = m_cache as WMSTileCache;
			
			var _specialCacheStrings: Array = qttViewProperties.specialCacheStrings;
			var _currentValidityTime: Date = qttViewProperties.validity;
			
			//get cache tiles
 			var a_tiles: Array = wmsTileCache.getTiles(s_crs, mi_zoom, _specialCacheStrings, _currentValidityTime);
			var allTiles: Array = a_tiles.reverse();
			
			graphics.clear();
			graphics.lineStyle(0,0,0);
			
			var t_tile: Object;
			var tileIndex: TileIndex;
			var cnt: int = 0;
			var viewPart: BBox;
			
			for each(t_tile in allTiles) {
				
				tileIndex = t_tile.tileIndex;
				viewPart = qttViewProperties.tileIndicesMapper.getTileIndexViewPart(tileIndex);
				
				if (tileIndex)
				{
					_debugDrawInfoArray.push(tileIndex);
					
					drawTile(tileIndex, s_crs, t_tile.image.bitmapData, redrawBorder);
				}
			}
			
			//FIXME change this, now there can be more tiledArea
//			m_cache.sortCache(m_tiledArea);
			
			dispatchEvent(new Event(DRAW_TILES));
		}
		
		private function drawTile(tileIndex: TileIndex, s_crs: String, bitmapData: BitmapData, redrawBorder: Boolean = false): void
		{
			var tileBBox: BBox = getGTileBBox(s_crs, tileIndex);
			
			var reflectedTileBBoxes: Array = container.mapBBoxToViewReflections(tileBBox);
			
//			trace("\t\t customDraw tileBBox["+tileIndex.mi_tileCol + "_" + tileIndex.mi_tileRow + "_" + tileIndex.mi_tileZoom+"]: " + tileBBox);
			if (reflectedTileBBoxes.length > 0)
			{
				for each (var reflectedTileBBox: BBox in reflectedTileBBoxes)
				{
//					trace("\t\t customDraw reflected tileBBox["+tileIndex.mi_tileCol + "_" + tileIndex.mi_tileRow + "_" + tileIndex.mi_tileZoom+"]: " + reflectedTileBBox);
					drawReflectedTile(tileIndex, reflectedTileBBox, s_crs, bitmapData, redrawBorder);
				}
			}
		}
		
		private function drawReflectedTile(tileIndex: TileIndex, tileBBox: BBox, s_crs: String, bitmapData: BitmapData, redrawBorder: Boolean = false): void
		{
			var matrix: Matrix;
			
			var topLeftCoord: Coord;
			var topRightCoord: Coord;
			var bottomLeftCoord: Coord;
			
			var topLeftPoint: Point;
			var topRightPoint: Point;
			var bottomLeftPoint: Point;
			
			var newWidth: Number;
			var newHeight: Number;
			var sx: Number;
			var sy: Number;
			var xx: Number;
			var yy: Number;
			
			topLeftPoint = container.coordToPoint(new Coord(s_crs, tileBBox.xMin, tileBBox.yMax));
			topRightPoint = container.coordToPoint(new Coord(s_crs, tileBBox.xMax, tileBBox.yMax));
			bottomLeftPoint = container.coordToPoint(new Coord(s_crs, tileBBox.xMin, tileBBox.yMin));
			
			var origNewWidth: Number = topRightPoint.x - topLeftPoint.x;
			var origNewHeight: Number = bottomLeftPoint.y - topLeftPoint.y;
			
			newWidth = origNewWidth;
			newHeight = origNewHeight;
			sx = newWidth / 256;
			sy = newHeight / 256;
			xx = topLeftPoint.x;
			yy = topLeftPoint.y;
			
			matrix = new Matrix();
			matrix.scale(sx, sy);
			matrix.translate(xx, yy);
			
			graphics.beginBitmapFill(bitmapData, matrix, false, imageSmooth);
			graphics.drawRect(xx, yy, newWidth , newHeight);
			graphics.endFill();
			
			//draw tile border 
			if(drawBorders || redrawBorder)
			{
				graphics.lineStyle(1, 0xff0000,0.3);
				graphics.drawRect(xx, yy, newWidth , newHeight);
			}
			
			if(drawDebugText)
			{
				drawText(tileIndex.mi_tileZoom + ", "
					+ tileIndex.mi_tileCol + ", "
					+ tileIndex.mi_tileRow,
					graphics, new Point(xx + 10, yy + 5));
			}
			
			tileScaleX = sx;
			tileScaleY = sy;
		}
		
		private var _console: IConsole;
		public function debugGetParameter(parameter: String): String
		{
			switch (parameter.toLowerCase())
			{
				case 'zoom':
					return mi_zoom.toString();
					break;
				case 'crs':
					return container.getCRS();
					break;
				case 'viewbbox':
					return container.getViewBBox().toBBOXString();
					break;
				case 'extentbbox':
					return container.getExtentBBox().toBBOXString();
					break;
			}
			return 'Parameter not defined';
		}
		public function debugDraw(console: IConsole, tag: String = ''): void
		{
			//FIXME temporary fix, until DebugConsole will be moved to FlexiWeather
			_console = console;
			console.print('Debug QTT Draw', 'Info', 'Tilling');
			
			draw(graphics);
			
		}
		public function debugWrapInformation(console: IConsole, tag: String = ''): void
		{
			//FIXME temporary fix, until DebugConsole will be moved to FlexiWeather
			_console = console;
			console.print('Debug Wrap Information', 'Info', 'Wrap Info');
			
			//test
//			for (var i: int = 0; i < 8; i++)
//			{
//				var maxID: int =  (1 << (i + 1) - 1) - 1;
//				console.print('zoom test i:' + i + ' zoom: ' + maxID, 'Info', 'Wrap Info');
//				
//			}
			
			var currentBBox: BBox = container.getViewBBox();
			
			var a1: Array = container.mapBBoxToViewReflections(currentBBox);
			var a2: Array = container.mapBBoxToProjectionExtentParts(currentBBox);
			var bbox: BBox
			var bbox2: BBox
			if (a1.length > 1)
			{
				for each(bbox in a1)
				{
					console.print('\t reflection: ' + bbox, 'Info', 'Wrap Info');
				}
			}
			if (a2.length > 1)
			{
				for each(bbox in a2)
				{
					console.print('\t part: ' + bbox, 'Info', 'Wrap Info');
					
					var a3: Array = container.mapBBoxToProjectionExtentParts(bbox);
					if (a3.length > 0)
					{
						for each(bbox2 in a3)
						{
							console.print('\t\t part reflection: ' + bbox2, 'Info', 'Wrap Info');
						}
					}
				}
			}
			
		}
		public override function hasPreview(): Boolean
		{ return mi_zoom != -1; }
		
		public override function renderPreview(graphics: Graphics, f_width: Number, f_height: Number): void
		{
			if(!width || !height)
				return;

			if (status == InteractiveDataLayer.STATE_DATA_LOADED_WITH_ERRORS)
			{
				drawNoDataPreview(graphics, f_width, f_height);
				return;
			}
			
			var newCRS: String = container.crs;
			var tilingInfo: QTTilingInfo = m_cfg.getQTTilingInfoForCRS(newCRS);
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
			matrix.translate(-f_width / 3, -f_width / 3);
			matrix.scale(3, 3);
			matrix.translate(width / 3, height / 3);
			matrix.invert();
			var bd: BitmapData = new BitmapData(width, height, true, 0x00000000);
			bd.draw(this);
			
			graphics.beginBitmapFill(bd, matrix, false, true);
			graphics.drawRect(0, 0, f_width, f_height);
			graphics.endFill();
		}
		
		/*
		private function drawNoDataPreview(graphics: Graphics, f_width: Number, f_height: Number): void
		{
			graphics.lineStyle(2, 0xcc0000, 0.7, true);
			graphics.moveTo(0, 0);
			graphics.lineTo(f_width - 1, f_height - 1);
			graphics.moveTo(0, f_height - 1);
			graphics.lineTo(f_width - 1, 0);
			
		}
		*/
		
		private var _tf:TextField = new TextField();
		private var _tfBD:BitmapData;
		private function drawText(txt: String, gr: Graphics, pos: Point): void
		{
			if(!_tf.filters || !_tf.filters.length) {
				_tf.filters = [new GlowFilter(0xffffffff)];
			}
			var tfWidth: int = 100;
			var tfHeight: int = 30;
			var format: TextFormat = _tf.getTextFormat();
			format.size = 18;
			_tf.setTextFormat(format);
			_tf.text = txt;

			_tfBD = new BitmapData(tfWidth, tfHeight, true, 0);
			_tfBD.draw(_tf);
			
			var m: Matrix = new Matrix();
			m.translate(pos.x, pos.y)
			gr.lineStyle(0,0,0);
			gr.beginBitmapFill(_tfBD, m, false);
			gr.drawRect(pos.x, pos.y, tfWidth, tfHeight);
			gr.endFill();
		}
		
		public function getGTileBBoxForWholeCRS(s_crs: String): BBox
		{
			var tilingInfo: QTTilingInfo = m_cfg.getQTTilingInfoForCRS(s_crs);
			if (tilingInfo)
				return tilingInfo.crsWithBBox.bbox;
			
			return null;
		}
		
		private function hideMap(): void
		{
			var gr: Graphics = graphics; 
			gr.clear();
		}
		private function isZoomCompatible(newZoom: int): Boolean
		{
			var newCRS: String = container.crs;
			var tilingInfo: QTTilingInfo = m_cfg.getQTTilingInfoForCRS(newCRS);
			if (!tilingInfo)
			{
				hideMap();
				return false;
			}
			if (newZoom < tilingInfo.minimumZoomLevel || newZoom > tilingInfo.maximumZoomLevel)
			{
				hideMap();
				return false;
			}
			
			return true;
			
		}
		private function isCRSCompatible(): Boolean
		{
			var newCRS: String = container.crs;
			var tilingInfo: QTTilingInfo = m_cfg.getQTTilingInfoForCRS(newCRS);
			if (!tilingInfo)
			{
				//crs is not supported
				hideMap();
				return false;
			}
			return true;
			
		}
		
		private function notifyZoomLevelChange(zoomLevel: int): void
		{
			var ilqe: InteractiveLayerQTTEvent = new InteractiveLayerQTTEvent(InteractiveLayerQTTEvent.ZOOM_LEVEL_CHANGED, true);
			ilqe.zoomLevel = zoomLevel;
			dispatchEvent(ilqe);			
		}
		
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
			
			if(b_finalChange || mi_zoom < 0) {
				var i_oldZoom: int = mi_zoom;
				
				findZoom();
				if (!isZoomCompatible(mi_zoom))
					return;
					
				if(mi_zoom != i_oldZoom)
				{
					notifyZoomLevelChange(mi_zoom);
					m_cache.invalidate(newCRS, viewBBox);
				}
				invalidateData(false);
			}
			else
				invalidateDynamicPart();
		}
		
		
		override protected function notifyLoadingFinished(bubbles: Boolean = true): void
		{
			super.notifyLoadingFinished(bubbles);
			
			//draw all tiles when all tiles are loaded
			draw(graphics);
		}
		
		

		public function getGTileBBox(s_crs: String, tileIndex: TileIndex): BBox
		{
			var extent: BBox = getGTileBBoxForWholeCRS(s_crs);
			if(extent == null)
				return null;

			var i_tilesInSerie: uint = 1 << tileIndex.mi_tileZoom;
			var f_tileWidth: Number = extent.width / i_tilesInSerie;
			var f_tileHeight: Number = extent.height / i_tilesInSerie;
			var f_xMin: Number = extent.xMin + tileIndex.mi_tileCol * f_tileWidth; 

			// note that tile row numbers increase in the opposite way as the Y-axis

			var f_yMin: Number = extent.yMax - (tileIndex.mi_tileRow + 1) * f_tileHeight;

			var tileBBox: BBox = new BBox(f_xMin, f_yMin, f_xMin + f_tileWidth, f_yMin + f_tileHeight);
			
			return tileBBox;
		}
		
		
		public function get tilingUtils(): TilingUtils
		{
			return m_tilingUtils;
		}
		
		override public function clone(): InteractiveLayer
		{
			var newLayer: InteractiveLayerQTTMS = new InteractiveLayerQTTMS(container, m_cfg);
			newLayer.alpha = alpha
			newLayer.zOrder = zOrder;
			newLayer.visible = visible;
			return newLayer;
		}
		
		

		public function baseURLPatternForCRS(crs: String): String
		{
			if(ms_explicitBaseURLPattern == null)
			{
				var tilingInfo: QTTilingInfo;
				if (m_cfg.tilingCRSsAndExtents && m_cfg.tilingCRSsAndExtents.length > 0)
					tilingInfo = m_cfg.getQTTilingInfoForCRS(crs);
				
				if (tilingInfo && tilingInfo.urlPattern)
					return tilingInfo.urlPattern;
			}
			return ms_explicitBaseURLPattern;
			
		}
		public function get baseURLPattern(): String
		{
			return baseURLPatternForCRS(container.getCRS());
		}
		
		public function get zoomLevel(): int
		{ return mi_zoom; }
		
		override public function toString(): String
		{
			return "InteractiveLayerQTTMS " + name  ;
		}
		
		public function getTiles(tilesIndices:Array):void
		{
			
		}
		
		public function debugCache(): String
		{
			return toString() + "\n" + m_cache.debugCache();
		}
		
		public function getCache():ICache
		{
			return m_cache;
		}
		
		public function getTiledLayer():InteractiveLayerQTTMS
		{
			return this;
		}
		
		public function clearCache():void
		{
			if (m_cache)
				m_cache.clearCache();
			
		}
		
		public function setSpecialCacheStrings(arr: Array): void
		{
			m_currentQTTViewProperties.setSpecialCacheStrings(arr);
		}
		
		public function setValidityTime(validity: Date): void
		{
			m_currentQTTViewProperties.setValidityTime(validity);
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
		{
			return _dictionary[getDictionaryKey(viewPart)];
		} else {
			return addViewPartReflections(viewPart);
		}
	}
	
	
}