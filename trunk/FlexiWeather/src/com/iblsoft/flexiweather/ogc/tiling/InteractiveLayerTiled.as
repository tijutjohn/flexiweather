package com.iblsoft.flexiweather.ogc.tiling
{
	import com.iblsoft.flexiweather.FlexiWeatherConfiguration;
	import com.iblsoft.flexiweather.events.InteractiveLayerEvent;
	import com.iblsoft.flexiweather.events.InteractiveLayerProgressEvent;
	import com.iblsoft.flexiweather.events.InteractiveLayerQTTEvent;
	import com.iblsoft.flexiweather.ogc.BBox;
	import com.iblsoft.flexiweather.ogc.InteractiveLayerQTTMS;
	import com.iblsoft.flexiweather.ogc.cache.CacheItem;
	import com.iblsoft.flexiweather.ogc.cache.ICache;
	import com.iblsoft.flexiweather.ogc.cache.ICachedLayer;
	import com.iblsoft.flexiweather.ogc.cache.WMSTileCache;
	import com.iblsoft.flexiweather.ogc.cache.event.WMSCacheEvent;
	import com.iblsoft.flexiweather.ogc.configuration.layers.TiledLayerConfiguration;
	import com.iblsoft.flexiweather.ogc.configuration.layers.interfaces.ILayerConfiguration;
	import com.iblsoft.flexiweather.ogc.data.viewProperties.IViewProperties;
	import com.iblsoft.flexiweather.ogc.data.viewProperties.IWMSViewPropertiesLoader;
	import com.iblsoft.flexiweather.ogc.data.viewProperties.TiledTileViewProperties;
	import com.iblsoft.flexiweather.ogc.data.viewProperties.TiledViewProperties;
	import com.iblsoft.flexiweather.ogc.preload.IPreloadableLayer;
	import com.iblsoft.flexiweather.plugins.IConsole;
	import com.iblsoft.flexiweather.proj.Coord;
	import com.iblsoft.flexiweather.proj.Projection;
	import com.iblsoft.flexiweather.utils.ISO8601Parser;
	import com.iblsoft.flexiweather.utils.LoggingUtils;
	import com.iblsoft.flexiweather.utils.Serializable;
	import com.iblsoft.flexiweather.utils.Storage;
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
	import flash.text.TextFieldAutoSize;
	import flash.text.TextFormat;
	import flash.utils.Dictionary;
	import flash.utils.getTimer;
	
	import mx.collections.ArrayCollection;
	import mx.controls.Alert;
	import mx.events.DynamicEvent;
	import mx.events.FlexEvent;

	public class InteractiveLayerTiled extends InteractiveDataLayer implements IConfigurableLayer, ICachedLayer, ITiledLayer, IPreloadableLayer, Serializable
	{
		public static const UPDATE_TILING_PATTERN: String = 'updateTilingPattern';
		public static const DRAW_TILES: String = 'drawTiles';
		public static var imageSmooth: Boolean = true;
		public static var drawBorders: Boolean = false;
		public static var drawDebugText: Boolean = false;
		private var ms_oldCRS: String;
		
		private var m_tilingUtils: TilingUtils;
		
//		protected var mi_zoom: int = 1;
		
		/**
		 * zoom is string, which refers to TileMatrix.id (e.g EPSG:26910:4) 
		 */		
		protected var mi_zoom: String;
		
		
		public var tileScaleX: Number;
		public var tileScaleY: Number;
		/** This is used only if overriding using the setter, otherwise the value from m_cfg is used. */
		protected var ms_explicitBaseURLPattern: String;
		private var m_cache: WMSTileCache;

		public var fullURL: String;

		public function set cache(value: WMSTileCache): void
		{
			if (m_cache)
				m_cache.removeEventListener(WMSCacheEvent.BEFORE_DELETE , onBeforeCacheItemDeleted);
			
			m_cache = value;
			
			if (m_cache)
				m_cache.addEventListener(WMSCacheEvent.BEFORE_DELETE , onBeforeCacheItemDeleted);
		}
		public function get cache(): WMSTileCache
		{
			return m_cache;
		}

		protected var m_cfg: TiledLayerConfiguration;
		private var _configurationChanged: Boolean;
		public function set configuration(value: ILayerConfiguration): void
		{
			m_cfg = value as TiledLayerConfiguration;
			_configurationChanged = true;
			invalidateProperties();
		}
		
		public function get configuration(): ILayerConfiguration
		{
			return m_cfg;
		}
		
		protected var _avoidTiling: Boolean;

		public function set avoidTiling(value: Boolean): void
		{
			_avoidTiling = value;
		}
		protected var mb_updateAfterMakingVisible: Boolean = false;

		override public function set visible(b_visible: Boolean): void
		{
			var b_visiblePrev: Boolean = super.visible;
			super.visible = b_visible;
			if (!b_visiblePrev && b_visible && mb_updateAfterMakingVisible)
			{
				mb_updateAfterMakingVisible = false;
				invalidateData(true);
			}
		}
		/**
		 * Currently displayed wms data
		 */
		protected var m_currentQTTViewProperties: TiledViewProperties;

		public function get currentViewProperties(): IViewProperties
		{
			return currentQTTViewProperties;
		}

		public function get currentQTTViewProperties(): TiledViewProperties
		{
			return m_currentQTTViewProperties;
		}
		
		/**
		 * wms data which are already preloaded
		 */
		protected var ma_preloadedQTTViewProperties: Array;

		/**
		 * If you need InteractiveLayerTiled be dependent on capabilities, which are loaded by some provider outside of this class,
		 * set onCapabilitiesDependent = true after creation of this layer and then each time capabitilities are ready set capabilitiesReady = true 
		 */		
		public var onCapabilitiesDependent: Boolean;
		
		private var _capabilitiesReady: Boolean;
		public function get capabilitiesReady():Boolean
		{
			if (!FlexiWeatherConfiguration.FLEXI_WEATHER_LOADS_GET_CAPABILITIES)
				return true;
			
			return _capabilitiesReady;
		}
		
		public function set capabilitiesReady(value:Boolean):void
		{
			_capabilitiesReady = value;
		}
		
		public function InteractiveLayerTiled(container: InteractiveWidget = null, cfg: TiledLayerConfiguration = null)
		{
			super(container);
			m_cfg = cfg;
			
			_tileMatrixSetLinks = new Array();
			
		}
		
		override protected function commitProperties():void
		{
			super.commitProperties();
			
			if (_cacheIsUpdated)
			{
				_cacheIsUpdated = false;
				invalidateDynamicPart();
			}
		}
		
		
		/**
		 * function returns full URL for getting map
		 * @return
		 *
		 */
		override public function getFullURL(): String
		{
            if (fullURL != null)
            {
                return fullURL;
            }
			return '';
		}

		/**************************************************************************************************************************************************
		 * 
		 *							Specific functionality of InteractiveLayerTiled
		 *  
		 **************************************************************************************************************************************************/
		
		private var _tileMatrixSetLinks: Array;
		
		public function getTileMatrixLimitsForCRSAndZoom(crs: String, zoom: String): TileMatrixLimits
		{
			var tileMatrixSetLink: TileMatrixSetLink = getTileMatrixSetLinkForCRS(crs);
			if (tileMatrixSetLink && tileMatrixSetLink.tileMatrixSetLimitsArray)
			{
				var tileMatrixLimits: Array = tileMatrixSetLink.tileMatrixSetLimitsArray.tileMatrixLimits;
				for each (var limit: TileMatrixLimits in tileMatrixLimits)
				{
					if (limit.tileMatrix == zoom)
					{
						return limit;
					}
				}
			}
			return null;
		}
		
		public function getTileMatrixForCRSAndZoom(crs: String, zoom: String): TileMatrix
		{
			var tileMatrixSetLink: TileMatrixSetLink = getTileMatrixSetLinkForCRS(crs);
			if (tileMatrixSetLink && tileMatrixSetLink.tileMatrixSet)
			{
				var tileMatrices: Array = tileMatrixSetLink.tileMatrixSet.tileMatrices;
				for each (var tileMatrix: TileMatrix in tileMatrices)
				{
					if (tileMatrix.id == zoom)
					{
						return tileMatrix;
					}
				}
			}
			return null;
		}
		
		protected function removeAllTileMatrixData(): void
		{
			//implement correct destroying of objects
			_tileMatrixSetLinks = [];
		}
		public function addTileMatrixSetLink(tileMatrixSetLink: TileMatrixSetLink): void
		{
			_tileMatrixSetLinks.push(tileMatrixSetLink);
		}
		
		protected function getTileMatrixSetLinkForCRS(crs: String): TileMatrixSetLink
		{
			//TODO do we support more TileMatrixSetLinks for same CRS ?
			for each (var tileMatrixSetLink: TileMatrixSetLink in _tileMatrixSetLinks)
			{
				if (tileMatrixSetLink.tileMatrixSet)
				{
					var supportedCRS: String = tileMatrixSetLink.tileMatrixSet.supportedCRS;
					if (supportedCRS == crs)
						return tileMatrixSetLink;
				}
			}
			return null;
		}
		
		/**************************************************************************************************************************************************
		 * 
		 *							End of Specific functionality of InteractiveLayerTiled
		 *  
		 **************************************************************************************************************************************************/
		
		
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
			if (m_cfg == null)
			{
				var cfg: TiledLayerConfiguration = createDefaultConfiguration();
				m_cfg = cfg;
			}
			
			m_tilingUtils = new TilingUtils(this);
			
			//preloading buffer, TiledViewProperties are stored inside
			ma_preloadingBuffer = [];
			
			//buffer for already preloaded TiledViewProperties
			ma_preloadedQTTViewProperties = [];
			
			m_currentQTTViewProperties = new TiledViewProperties();
			m_currentQTTViewProperties.setConfiguration(m_cfg);
			updateCurrentWMSViewProperties();
			//			m_currentWMSViewProperties.addEventListener(SynchronisedVariableChangeEvent.SYNCHRONISED_VARIABLE_CHANGED, onCurrentWMSDataSynchronisedVariableChanged);
			//			m_currentWMSViewProperties.addEventListener(WMSViewPropertiesEvent.WMS_DIMENSION_VALUE_SET, onWMSDimensionValueSet);
			cache = new WMSTileCache();
			
			//TODO test
//			updateData(true);
			
			addEventListener(Event.EXIT_FRAME, onExitFrame);
		}

		/**
		 * This function will be called after layer is created and configuration was not set from outside
		 *
		 */
		protected function createDefaultConfiguration(): TiledLayerConfiguration
		{
			var cfg: TiledLayerConfiguration = new TiledLayerConfiguration();
			return cfg;
		}

		public function setConfiguration(cfg: TiledLayerConfiguration): void
		{
			m_cfg = cfg;
		}

		/**************************************************************************************************************************************
		 *
		 * 		Loading data functionality
		 *
		 **************************************************************************************************************************************/
		
		protected function getWMSViewPropertiesLoader(): IWMSViewPropertiesLoader
		{
			var loader: TiledLoader = new TiledLoader(this); 
			loader.zoom = zoomLevel;
			
			return loader;
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

		protected var _loader: TiledLoader;
		
		/**
		 * Instead of call updateData, call invalidateData() function. It works exactly as invalidateProperties, invalidateSize or invalidateDisplayList.
		 * You can call as many times as you want invalidateData function and updateData will be called just once each frame (if neeeded)
		 * @param b_forceUpdate
		 *
		 */
		override protected function updateData(b_forceUpdate: Boolean): void
		{
//			debug("updateDate["+b_forceUpdate+"] _layerInitialized: " + _layerInitialized + " capabilitiesReady: " + capabilitiesReady + " visible: " + visible);
			if (!_layerInitialized)
				return;
			if (!layerWasDestroyed)
			{
				if (status != STATE_NO_SYNCHRONISATION_DATA_AVAILABLE)
				{
					super.updateData(b_forceUpdate);
					if (_avoidTiling)
					{
						//tiling for this layer is for now avoided, do not update data
						return;
					}
					if (mi_zoom == null)
					{
						// wrong zoom, do not continue
						return;
					}
					if (!visible)
					{
						mb_updateAfterMakingVisible = true;
						return;
					}
					if (!_loader)
					{
						_loader = getWMSViewPropertiesLoader() as TiledLoader;
						_loader.addEventListener(InteractiveDataLayer.LOADING_STARTED, onCurrentWMSDataLoadingStarted);
						_loader.addEventListener(InteractiveDataLayer.PROGRESS, onCurrentWMSDataProgress);
						_loader.addEventListener(InteractiveDataLayer.LOADING_FINISHED, onCurrentWMSDataLoadingFinished);
						_loader.addEventListener(InteractiveDataLayer.LOADING_FINISHED_FROM_CACHE, onCurrentWMSDataLoadingFinishedFromCache);
						_loader.addEventListener(InteractiveDataLayer.LOADING_FINISHED_NO_SYNCHRONIZATION_DATA, onCurrentWMSDataLoadingFinishedNoSynchronizationData);
						_loader.addEventListener(InteractiveDataLayer.LOADING_ERROR, onCurrentWMSDataLoadingError);
						_loader.addEventListener(InteractiveLayerEvent.INVALIDATE_DYNAMIC_PART, onCurrentWMSDataInvalidateDynamicPart);
					}
					_loader.zoom = zoomLevel; 
					_loader.updateWMSData(b_forceUpdate, m_currentQTTViewProperties, forcedLayerWidth, forcedLayerHeight, printQuality);
				}
			}
		}
		protected var _currentQTTDataLoadingStarted: Boolean;

		protected function onCurrentWMSDataLoadingStarted(event: InteractiveLayerEvent): void
		{
			_currentQTTDataLoadingStarted = true;
			notifyLoadingStart(false);
		}

		protected function onCurrentWMSDataProgress(event: InteractiveLayerProgressEvent): void
		{
			notifyProgress(event.loaded, event.total, event.units);
		}

		protected function onCurrentWMSDataLoadingError(event: InteractiveLayerEvent): void
		{
			var loader: IWMSViewPropertiesLoader = event.target as IWMSViewPropertiesLoader;
			//			destroyWMSViewPropertiesLoader(loader);
			notifyLoadingError();
			_currentQTTDataLoadingStarted = false;
			invalidateDynamicPart(true);
		}
		
		protected function onCurrentWMSDataLoadingFinishedNoSynchronizationData(event: InteractiveLayerEvent): void
		{
			var loader: IWMSViewPropertiesLoader = event.target as IWMSViewPropertiesLoader;
			//			destroyWMSViewPropertiesLoader(loader);
			notifyLoadingFinishedNoSynchronizationData();
			_currentQTTDataLoadingStarted = false;
			invalidateDynamicPart(true);
		}
		protected function onCurrentWMSDataLoadingFinished(event: InteractiveLayerEvent): void
		{
			var loader: IWMSViewPropertiesLoader = event.target as IWMSViewPropertiesLoader;
//			destroyWMSViewPropertiesLoader(loader);
			notifyLoadingFinished();
			_currentQTTDataLoadingStarted = false;
			invalidateDynamicPart(true);
		}
		
		protected function onCurrentWMSDataLoadingFinishedFromCache(event: InteractiveLayerEvent): void
		{
			var loader: IWMSViewPropertiesLoader = event.target as IWMSViewPropertiesLoader;
//			destroyWMSViewPropertiesLoader(loader);
			notifyLoadingFinishedFromCache();
			_currentQTTDataLoadingStarted = false;
			invalidateDynamicPart(true);
		}

		protected function onCurrentWMSDataInvalidateDynamicPart(event: DynamicEvent): void
		{
			invalidateDynamicPart(event['invalid']);
		}

		override protected function notifyLoadingFinished(bubbles: Boolean = true): void
		{
			super.notifyLoadingFinished(bubbles);
			//draw all tiles when all tiles are loaded
			draw(graphics);
		}

		/**************************************************************************************************************************************
		 *
		 * 		Default InteractiveLayer functionality
		 *
		 **************************************************************************************************************************************/
		public function getTiledArea(viewBBox: BBox, zoomLevel: String, tileSize: int): TiledArea
		{
			if (m_tilingUtils)
				return m_tilingUtils.getTiledArea(viewBBox, zoomLevel, tileSize);
			return null;
		}

		public function tiledAreaChanged(newCRS: String, newBBox: BBox): void
		{
			//implement this function in child classes if you need something
		}

		override public function onAreaChanged(b_finalChange: Boolean): void
		{
			if (!_layerInitialized)
				return;
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
			tiledAreaChanged(newCRS, newBBox);
			
			var zoomChanged: Boolean = false;
			if (b_finalChange || mi_zoom == null)
			{
				var i_oldZoom: String = mi_zoom;
				findZoom();
				if (!isZoomCompatible(mi_zoom))
					return;
				if (mi_zoom != i_oldZoom)
				{
					zoomChanged = true;
					//TODO how to solve  
//					notifyZoomLevelChange(mi_zoom);
					
					//quick fix 
//					callLater(invalidateCacheAfterZoomLevelChange, [newCRS, viewBBox]);
					m_cache.invalidate(newCRS, viewBBox);
					invalidateData(false);
				} else {
					invalidateData(false);
				}
			}
			else
				invalidateDynamicPart();
			
			if (zoomChanged)
			{
				notifyZoomLevelChange(mi_zoom);
			}
		}

//		private function invalidateCacheAfterZoomLevelChange(crs: String, viewBBox: BBox): void
//		{
//			if (m_cache) {
//				m_cache.invalidate(crs, viewBBox);
//				invalidateData(false);
//			} else
//				callLater(invalidateCacheAfterZoomLevelChange, [crs, viewBBox]);
//				
//		}
		/**************************************************************************************************************************************
		 *
		 * 		Drawing functionality
		 *
		 **************************************************************************************************************************************/
		override public function invalidateDisplayList():void
		{
			super.invalidateDisplayList();
		}
		override public function draw(graphics: Graphics): void
		{
//			debug("draw");
			if (!_layerInitialized)
				return;
			super.draw(graphics);
			//			graphics.clear();
			//			setTimeout(customDraw, 500, m_currentQTTViewProperties, graphics);
			customDraw(m_currentQTTViewProperties, graphics);
		}
		private var _debugDrawInfoArray: Array;

		private var customDrawCallsInFrame: int = 0;
		
		private function onExitFrame(event: Event): void
		{
			//on end of each frame reset customDrawCallsInFrame variable
			customDrawCallsInFrame = 0;
		}

		override public function clear(graphics:Graphics):void
		{
//			trace("\nTiled clear" + name);
			
			//check onExitFrame() function
			customDrawCallsInFrame++;
			if (customDrawCallsInFrame > 1)
			{
//				trace("clear will not be executed, it's called for: " + customDrawCallsInFrame + "th time this frame");
				return;
			}
			super.clear(graphics);
		}
		private function customDraw(qttViewProperties: TiledViewProperties, graphics: Graphics, redrawBorder: Boolean = false): void
		{
			if (onCapabilitiesDependent && !capabilitiesReady)
				return;
			
			if (!layerWasDestroyed)
			{
//				trace("\nTiled customdraw: " + name);
				if (mi_zoom == null)
				{
//					trace("InteractiveLayerQTTMS.customDraw(): Something is wrong, tile zoom is null");
					return;
				}
				
				if (customDrawCallsInFrame > 1)
				{
//					trace("customDraw will not be executed, it's called for: " + customDrawCallsInFrame + "th time this frame");
					return;
				}
				
				var startTime: Number = getTimer();
				
				
				_debugDrawInfoArray = [];
				var s_crs: String = qttViewProperties.crs; //container.crs;
				var currentBBox: BBox = qttViewProperties.getViewBBox(); //container.getViewBBox();
				var tilingBBox: BBox = getGTileBBoxForWholeCRS(s_crs); // extent of tile z=0/r=0/c=0
				if (tilingBBox == null)
				{
					trace("InteractiveLayerQTTMS.customDraw(): No tiling extent for CRS " + container.crs);
					return;
				}
				var wmsTileCache: WMSTileCache = m_cache as WMSTileCache;
				var _specialCacheStrings: Array = qttViewProperties.specialCacheStrings;
				var _currentValidityTime: Date = qttViewProperties.validity;
				//get cache tiles
				var t1: Number = getTimer();
				
				var a_tiles: Array = wmsTileCache.getTiles(s_crs, mi_zoom, _specialCacheStrings, _currentValidityTime);
				
				var t2: Number = getTimer();
				var getTilesTime: Number = t2 - t1;
//				trace("customDraw getTiles time: " +getTilesTime + "ms");
				
				var allTiles: Array = a_tiles.reverse();
				
				var t3: Number = getTimer();
				var getReverseTime: Number = t3 - t2;
//				trace("customDraw reverse time: " + getReverseTime + "ms");
				
				graphics.clear();
				graphics.lineStyle(0, 0, 0);
				var t_tile: Object;
				var tileIndex: TileIndex;
				var cnt: int = 0;
				var viewPart: BBox;
				for each (t_tile in allTiles)
				{
					tileIndex = t_tile.tileIndex;
					viewPart = qttViewProperties.tileIndicesMapper.getTileIndexViewPart(tileIndex);
					if (tileIndex)
					{
//						_debugDrawInfoArray.push(tileIndex);
						drawTile(tileIndex, s_crs, t_tile.image.bitmapData, redrawBorder, qttViewProperties);
					}
				}
				
				//FIXME change this, now there can be more tiledArea
				//			m_cache.sortCache(m_tiledArea);
				dispatchEvent(new Event(DRAW_TILES));
				
				
//				trace("customDraw drawTiles: " + (getTimer() - t3) + "ms");
//				
//				trace("customDraw total time: " + (getTimer() - startTime) + "ms");
				
				
			}
		}

		/**
		 * 
		 * @param tileIndex
		 * @param s_crs
		 * @param bitmapData
		 * @param redrawBorder
		 * @param qttViewProperties - just for debuggin purposes
		 * 
		 */
		private function drawTile(tileIndex: TileIndex, s_crs: String, bitmapData: BitmapData, redrawBorder: Boolean = false, qttViewProperties: TiledViewProperties = null): void
		{
			var tileBBox: BBox = getGTileBBox(s_crs, tileIndex);
			var reflectedTileBBoxes: Array = container.mapBBoxToViewReflections(tileBBox);
			if (reflectedTileBBoxes.length > 0)
			{
				for each (var reflectedTileBBox: BBox in reflectedTileBBoxes)
				{
					drawReflectedTile(tileIndex, reflectedTileBBox, s_crs, bitmapData, redrawBorder, qttViewProperties);
				}
			}
		}

		private function drawReflectedTile(tileIndex: TileIndex, tileBBox: BBox, s_crs: String, bitmapData: BitmapData, redrawBorder: Boolean = false, qttViewProperties: TiledViewProperties = null): void
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
			if (!topRightPoint || !topLeftPoint || !bottomLeftPoint)
				return;
			var origNewWidth: Number = topRightPoint.x - topLeftPoint.x;
			var origNewHeight: Number = bottomLeftPoint.y - topLeftPoint.y;
			newWidth = origNewWidth;
			newHeight = origNewHeight;
			sx = newWidth / bitmapData.width;
			sy = newHeight / bitmapData.height;
			xx = topLeftPoint.x;
			yy = topLeftPoint.y;
			matrix = new Matrix();
			matrix.scale(sx, sy);
			matrix.translate(xx, yy);
			graphics.beginBitmapFill(bitmapData, matrix, false, imageSmooth);
			graphics.drawRect(xx, yy, newWidth, newHeight);
			graphics.endFill();
			//draw tile border 
			if (drawBorders || redrawBorder)
			{
				graphics.lineStyle(1, 0xff0000, 0.3);
				graphics.drawRect(xx, yy, newWidth, newHeight);
			}
			if (drawDebugText)
			{
				var txt2: String = '';
				if (qttViewProperties && qttViewProperties.validity)
				{
					txt2 = "Validity: " + ISO8601Parser.dateToString(qttViewProperties.validity);
				}
				drawText(tileIndex.mi_tileZoom + ", "
						+ tileIndex.mi_tileCol + ", "
						+ tileIndex.mi_tileRow,
						txt2,
						graphics, new Point(xx + 10, yy + 5));
			}
			tileScaleX = sx;
			tileScaleY = sy;
		}

		private function hideMap(): void
		{
			var gr: Graphics = graphics;
			gr.clear();
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
				for each (bbox in a1)
				{
					console.print('\t reflection: ' + bbox, 'Info', 'Wrap Info');
				}
			}
			if (a2.length > 1)
			{
				for each (bbox in a2)
				{
					console.print('\t part: ' + bbox, 'Info', 'Wrap Info');
					var a3: Array = container.mapBBoxToProjectionExtentParts(bbox);
					if (a3.length > 0)
					{
						for each (bbox2 in a3)
						{
							console.print('\t\t part reflection: ' + bbox2, 'Info', 'Wrap Info');
						}
					}
				}
			}
		}
		private var _tf: TextField = new TextField();
		private var _tf2: TextField = new TextField();
		private var _tfBD: BitmapData;

		private function drawText(txt: String, txt2: String,  gr: Graphics, pos: Point): void
		{
			if (!_tf.filters || !_tf.filters.length)
			{
				_tf.filters = [new GlowFilter(0xffffffff)];
			}
			if (!_tf2.filters || !_tf2.filters.length)
			{
				_tf2.filters = [new GlowFilter(0xffffffff)];
			}
			var tfWidth: int = 200;
			var tfHeight: int = 30;
			
			var format: TextFormat = _tf.getTextFormat();
			format.size = 24;
			format.align = TextFieldAutoSize.LEFT;
			
			var format2: TextFormat = _tf2.getTextFormat();
			format2.size = 20;
			format2.align = TextFieldAutoSize.LEFT;
			
			_tf.text = txt;
			_tf.setTextFormat(format);
			
			_tf2.text = txt2;
			_tf2.setTextFormat(format2);

			_tf.width = _tf.textWidth + 20;
			_tf2.width = _tf2.textWidth + 20;
			
			tfWidth = Math.max(_tf.textWidth + 20, _tf2.textWidth + 20);
			tfHeight = _tf.textHeight + _tf2.textHeight + 5;
			
			var mTf2: Matrix = new Matrix();
			mTf2.translate(0, _tf.textHeight + 3);
			
			_tfBD = new BitmapData(tfWidth, tfHeight, true, 0x88ffffff);
			_tfBD.draw(_tf);
			_tfBD.draw(_tf2, mTf2);
			
			var m: Matrix = new Matrix();
			m.translate(pos.x, pos.y)
			gr.lineStyle(0, 0, 0);
			gr.beginBitmapFill(_tfBD, m, false);
			gr.drawRect(pos.x, pos.y, tfWidth, tfHeight);
			gr.endFill();
		}

		/**************************************************************************************************************************************
		 *
		 * 		Render preview functionality
		 *
		 **************************************************************************************************************************************/
		public override function hasPreview(): Boolean
		{
			return mi_zoom != null;
		}

		public override function renderPreview(graphics: Graphics, f_width: Number, f_height: Number): void
		{
			if (!width || !height)
				return;
			if (status == InteractiveDataLayer.STATE_DATA_LOADED_WITH_ERRORS || status == InteractiveDataLayer.STATE_NO_SYNCHRONISATION_DATA_AVAILABLE)
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
			var matrix: Matrix = new Matrix();
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
		/**************************************************************************************************************************************
		 *
		 * 		View properties functionality
		 *
		 **************************************************************************************************************************************/
		public function changeViewProperties(viewProperties: IViewProperties): void
		{
			if ((viewProperties as TiledViewProperties).crs != container.crs)
			{
				var crsError: Error = new Error("InteractiveLayerTiled ChangeViewProperties: Layer CRS is different than InteractiveWidget.CRS");
				throw crsError;
			}
			
			m_currentQTTViewProperties = viewProperties as TiledViewProperties;
		}

		protected function updateCurrentWMSViewProperties(): void
		{
			if (currentQTTViewProperties && container)
			{
				currentQTTViewProperties.crs = container.crs;
				currentQTTViewProperties.setViewBBox(container.getViewBBox());
				currentQTTViewProperties.zoom = zoomLevel;
			}
		}

		/**************************************************************************************************************************************
		 *
		 * 		Preloading View properties functionality
		 *
		 **************************************************************************************************************************************/
		private var _preloader: TiledLoader;
		
		/**
		 * Function will cancel all preloading immediately 
		 * 
		 */		
		public function cancelPreload(): void
		{
			//FIXME cancel currently preloading request
			if (_preloader)
				_preloader.cancel();
			
			//clear preloading buffer, but do not clear preloaded buffer, because just future preloads are canceled
			ma_preloadingBuffer = [];
			
			setPreloadingStatus(false);
		}
		
		public function preload(viewProperties: IViewProperties): void
		{
			var qttViewProperties: TiledViewProperties = viewProperties as TiledViewProperties;
			if (!qttViewProperties)
				return;
			qttViewProperties.name = name;
			updateWMSViewPropertiesConfiguration(qttViewProperties, m_cfg, m_cache);
			
			if (!_preloader)
			{
				_preloader = getWMSViewPropertiesLoader() as TiledLoader;
				_preloader.addEventListener(InteractiveLayerEvent.INVALIDATE_DYNAMIC_PART, onQTTViewPropertiesDataInvalidateDynamicPart);
				_preloader.addEventListener(InteractiveDataLayer.LOADING_FINISHED, onPreloadingWMSDataLoadingFinished);
				_preloader.addEventListener(InteractiveDataLayer.LOADING_FINISHED_FROM_CACHE, onPreloadingWMSDataLoadingFinishedFromCache);
			}
			trace(this + " preload preloading: " + preloading);
			if (!preloading)
			{
				setPreloadingStatus(true);
				_preloader.updateWMSData(true, qttViewProperties, forcedLayerWidth, forcedLayerHeight, printQuality);
			} else {
				ma_preloadingBuffer.push(qttViewProperties);
				trace(this + " preload add to buffer: " + ma_preloadingBuffer.length);
			}
			
		}

		/**
		 * Preload all frames from input array
		 *
		 * @param wmsViewPropertiesArray - input array
		 *
		 */
		public function preloadMultiple(viewPropertiesArray: Array): void
		{
			for each (var qttViewProperties: TiledViewProperties in viewPropertiesArray)
			{
				preload(qttViewProperties);
			}
		}

		public function isPreloadedMultiple(viewPropertiesArray: Array): Boolean
		{
			var isAllPreloaded: Boolean = true;
			for each (var qttViewProperties: TiledViewProperties in viewPropertiesArray)
			{
				isAllPreloaded = isAllPreloaded && isPreloaded(qttViewProperties);
			}
			return isAllPreloaded;
		}

		public function isPreloaded(viewProperties: IViewProperties): Boolean
		{
			var qttViewProperties: TiledViewProperties = viewProperties as TiledViewProperties;
			if (!qttViewProperties)
				return false;
			return qttViewProperties.isPreloaded(m_cache);
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
		protected function updateWMSViewPropertiesConfiguration(qttViewProperties: TiledViewProperties, configuration: ILayerConfiguration, cache: ICache): void
		{
			qttViewProperties.setConfiguration(m_cfg);
		}

		protected function onQTTViewPropertiesDataInvalidateDynamicPart(event: DynamicEvent): void
		{
		}

		protected function onPreloadingWMSDataLoadingFinishedFromCache(event: InteractiveLayerEvent): void
		{
			trace("preloading from cache");
			var loader: IWMSViewPropertiesLoader = event.target as IWMSViewPropertiesLoader;
//			destroyWMSViewPropertiesPreloader(loader);
			var qttViewProperties: TiledViewProperties = event.data as TiledViewProperties;
			if (qttViewProperties)
			{
				qttViewProperties.removeEventListener(InteractiveDataLayer.LOADING_FINISHED, onPreloadingWMSDataLoadingFinished);
				qttViewProperties.removeEventListener(InteractiveDataLayer.LOADING_FINISHED_FROM_CACHE, onPreloadingWMSDataLoadingFinishedFromCache);
			}
		}
		protected function onPreloadingWMSDataLoadingFinished(event: InteractiveLayerEvent): void
		{
			var loader: IWMSViewPropertiesLoader = event.target as IWMSViewPropertiesLoader;
//			destroyWMSViewPropertiesPreloader(loader);
			var qttViewProperties: TiledViewProperties = event.data as TiledViewProperties;
			if (qttViewProperties)
			{
				qttViewProperties.removeEventListener(InteractiveDataLayer.LOADING_FINISHED, onPreloadingWMSDataLoadingFinished);
				qttViewProperties.removeEventListener(InteractiveDataLayer.LOADING_FINISHED_FROM_CACHE, onPreloadingWMSDataLoadingFinishedFromCache);
				//remove wmsViewProperties from array of currently preloading wms view properties
				/*
				var total: int = ma_preloadingQTTViewProperties.length;
				for (var i: int = 0; i < total; i++)
				{
					var currQTTViewProperties: TiledViewProperties = ma_preloadingQTTViewProperties[i] as TiledViewProperties;
					if (currQTTViewProperties && currQTTViewProperties.equals(qttViewProperties))
					{
						ma_preloadingQTTViewProperties.splice(i, 1);
						break;
					}
				}
				*/
				//add wmsViewProperties to array of already preloaded wms view properties
				ma_preloadedQTTViewProperties.push(qttViewProperties);
				setPreloadingStatus(false);
				
				//notify progress of preloaded frames
				notifyProgress(ma_preloadedQTTViewProperties.length, ma_preloadingBuffer.length + ma_preloadedQTTViewProperties.length, 'frames');
				
				if (ma_preloadingBuffer.length > 0)
				{
					//preload next frame
					var newQttViewProperties: TiledViewProperties = ma_preloadingBuffer.shift() as TiledViewProperties;
					preload(newQttViewProperties);
				} else {
					//all frames are preloaded
					ma_preloadedQTTViewProperties = [];
					dispatchEvent(new InteractiveLayerEvent(InteractiveDataLayer.PRELOADING_FINISHED, true));
				}
				/*
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
				*/
			}
		}

		/**************************************************************************************************************************************
		 *
		 * 		Tilling pattern and CRS functionality
		 *
		 **************************************************************************************************************************************/
//		public function get tilingUtils(): TilingUtils
//		{
//			return m_tilingUtils;
//		}
		public function getGTileBBoxForWholeCRS(s_crs: String): BBox
		{
			var tilingInfo: TiledTilingInfo = m_cfg.getTiledTilingInfoForCRS(s_crs);
			if (tilingInfo)
				return tilingInfo.crsWithBBox.bbox;
			return null;
		}

		public function getGTileBBox(s_crs: String, tileIndex: TileIndex): BBox
		{
			var extent: BBox = getGTileBBoxForWholeCRS(s_crs);
			if (extent == null)
				return null;
			
			var tileMatrix: TileMatrix = getTileMatrixForCRSAndZoom(s_crs, tileIndex.mi_tileZoom);
			
			var zoomArr: Array = tileIndex.mi_tileZoom.split(':');
			var zoomLevel: int = int(zoomArr[zoomArr.length - 1]);
			
			var f_tileWidthCount: Number = extent.width / tileMatrix.matrixWidth;
			var f_tileHeightCount: Number = extent.height / tileMatrix.matrixHeight;
			
			var f_xMin: Number = extent.xMin + tileIndex.mi_tileCol * f_tileWidthCount;
			// note that tile row numbers increase in the opposite way as the Y-axis
			var f_yMin: Number = extent.yMax - (tileIndex.mi_tileRow + 1) * f_tileHeightCount;
			var tileBBox: BBox = new BBox(f_xMin, f_yMin, f_xMin + f_tileWidthCount, f_yMin + f_tileHeightCount);
			return tileBBox;
		}

		private function isCRSCompatible(): Boolean
		{
			var newCRS: String = container.crs;
			var tilingInfo: TiledTilingInfo = m_cfg.getTiledTilingInfoForCRS(newCRS);
			if (!tilingInfo)
			{
				//crs is not supported
				hideMap();
				return false;
			}
			return true;
		}

		public function baseURLPatternForCRS(crs: String): String
		{
			if(ms_explicitBaseURLPattern == null)
			{
				var tilingInfo: TiledTilingInfo;
				if (m_cfg.tilingCRSsAndExtents && m_cfg.tilingCRSsAndExtents.length > 0)
					tilingInfo = m_cfg.getTiledTilingInfoForCRS(crs);
				
				if (tilingInfo && tilingInfo.urlPattern)
					return tilingInfo.urlPattern;
			}
			return ms_explicitBaseURLPattern;
		}

		public function get baseURLPattern(): String
		{
			return baseURLPatternForCRS(container.getCRS());
		}

		public static function expandURLPattern(s_url: String, tileIndex: TileIndex): String
		{
			if (s_url)
			{
				s_url = s_url.replace('%COL%', String(tileIndex.mi_tileCol));
				s_url = s_url.replace('%ROW%', String(tileIndex.mi_tileRow));
//				s_url = s_url.replace('%ZOOM%', String(tileIndex.mi_tileZoom));
				
				//need to extract zoom from zoomString
				var zoomArr: Array = tileIndex.mi_tileZoom.split(':');
				var zoomLevel:String = zoomArr[zoomArr.length - 1];
				s_url = s_url.replace('%ZOOM%', zoomLevel);
			}
			else
			{
				trace("expandURLPattern problem with url");
			}
			return s_url;
		}

		protected function notifyTilingPatternUpdate(): void
		{
			dispatchEvent(new Event(UPDATE_TILING_PATTERN));
		}

		/**************************************************************************************************************************************
		 *
		 * 		Zoom functionality
		 *
		 **************************************************************************************************************************************/
		public function get zoomLevel(): String
		{
			return mi_zoom;
		}
		
		public function normalizedBBoxToExtent(bbox: BBox, extentBBox: BBox):  BBox
		{
			var f_crsExtentBBoxWidth: Number = extentBBox.width;
			//				var viewBBoxWest: Number = m_viewBBox.xMin;
			//				var viewBBoxEast: Number = m_viewBBox.xMax;
			var viewBBoxWest: Number = bbox.xMin;
			var viewBBoxEast: Number = bbox.xMax;
			var extentBBoxWest: Number = extentBBox.xMin;
			var extentBBoxEast: Number = extentBBox.xMax;
			
			var refCount: int = 0;
			var reflectionX: Number;
			
			var newBBox: BBox;
			if (viewBBoxWest > extentBBoxEast)
			{
				refCount = Math.ceil(viewBBoxWest / f_crsExtentBBoxWidth);
			} else if (viewBBoxEast < extentBBoxWest) {
				refCount = Math.ceil(viewBBoxWest / f_crsExtentBBoxWidth);
			}
			newBBox = new BBox(viewBBoxWest - refCount * f_crsExtentBBoxWidth, bbox.yMin, viewBBoxEast - refCount * f_crsExtentBBoxWidth, bbox.yMax);
			return newBBox;
		}
		
		protected function findZoom(): void
		{
			if (!_layerInitialized)
				return;
			
			if (onCapabilitiesDependent && !capabilitiesReady)
				return;
			
			var tileMatrixSetLink: TileMatrixSetLink = getTileMatrixSetLinkForCRS(container.crs);
			
			var projection: Projection = Projection.getByCRS(container.crs);
			var crsExtent: BBox = projection.extentBBox;
			
			//TODO how to get tiling extent from TileMatrixSetLink
			
//			var tilingExtent: BBox = getGTileBBoxForWholeCRS(container.crs);
//			m_tilingUtils.onAreaChanged(container.crs, tilingExtent);
			var viewBBox: BBox = container.getViewBBox();
//			
			viewBBox = normalizedBBoxToExtent(viewBBox, crsExtent);
			var parts: Array = container.mapBBoxToProjectionExtentParts(viewBBox);
			
			if (tileMatrixSetLink && tileMatrixSetLink.tileMatrixSet)
			{
				var tileMatrix: TileMatrix;
				var tilingExtent: BBox;
				var coverageRatio: Number;
				var tileWidth: int;
				var tileHeight: int;
				
				var tileMatrixPixelWidth: Number;
				var tileMatrixPixelHeight: Number;
				
				var dist: Number;
				
				var viewBBoxPixelWidth: Number = viewBBox.width / width;
				var viewBBoxPixelHeight: Number = viewBBox.height / height;
				
				var vBBoxPoint: Point = new Point(viewBBoxPixelWidth, viewBBoxPixelHeight);
				
				var tileMatrices: Array = tileMatrixSetLink.tileMatrixSet.tileMatrices;
				if (tileMatrices)
				{
					var bestZoomMatrix: TileMatrix;
					
					var aspectRatioDistance: Number = Number.MAX_VALUE;
					var bestSemicoveredTileSets: Array = [];
					var bestSemicoveredTileSetRatio: Number = 0;
					
					for each (tileMatrix in tileMatrices)
					{
						tilingExtent = tileMatrix.extent;
						
						var tempCoverageRation: Number = 0;
						for each (var vBBox: BBox in parts)
						{
							tempCoverageRation += tilingExtent.coverageRatio(vBBox);
						}
						coverageRatio = tempCoverageRation / parts.length;
						
						
						if (coverageRatio == 1)
						{
							tileWidth = tileMatrix.tileWidth;
							tileHeight = tileMatrix.tileHeight;

							tileMatrixPixelWidth = tilingExtent.width / tileMatrix.matrixWidth / tileMatrix.tileWidth;
							tileMatrixPixelHeight = tilingExtent.height / tileMatrix.matrixHeight / tileMatrix.tileHeight;
							
							dist = Point.distance(vBBoxPoint, new Point(tileMatrixPixelWidth, tileMatrixPixelHeight));
							if (dist < aspectRatioDistance)
							{
								aspectRatioDistance = dist;
								bestZoomMatrix = tileMatrix;
							}
						} else {
							if (coverageRatio > 0)
							{
								if (coverageRatio > bestSemicoveredTileSetRatio) {
									bestSemicoveredTileSetRatio = coverageRatio;
									bestSemicoveredTileSets = [tileMatrix];
								} else if (coverageRatio == bestSemicoveredTileSetRatio) {
									bestSemicoveredTileSets.push(tileMatrix);
								}
							}
						}
					}
				}
			}

			if (!bestZoomMatrix)
			{
				if (bestSemicoveredTileSets && bestSemicoveredTileSets.length > 0)
				{
					if (bestSemicoveredTileSets.length == 1)
					{
						bestZoomMatrix = bestSemicoveredTileSets[0] as TileMatrix;
					} else {
						
						aspectRatioDistance = Number.MAX_VALUE;
						
						for each (tileMatrix in bestSemicoveredTileSets)
						{
							tilingExtent = tileMatrix.extent;
							
							tileWidth = tileMatrix.tileWidth;
							tileHeight = tileMatrix.tileHeight;
							
							tileMatrixPixelWidth = tilingExtent.width / tileMatrix.matrixWidth / tileMatrix.tileWidth;
							tileMatrixPixelHeight = tilingExtent.height / tileMatrix.matrixHeight / tileMatrix.tileHeight;
							
							dist = Point.distance(vBBoxPoint, new Point(tileMatrixPixelWidth, tileMatrixPixelHeight));
							
							if (dist < aspectRatioDistance)
							{
								aspectRatioDistance = dist;
								bestZoomMatrix = tileMatrix;
							}
						}
					}
				} else {
					trace("Didn find any tile set which covers at least something from viewBBox");
				}
			} else {
			}
			
			if (bestZoomMatrix)
			{
				mi_zoom = bestZoomMatrix.id;
				//notify tilingUtils about area change
				m_tilingUtils.onAreaChanged(container.crs, bestZoomMatrix.extent);
			}
		}

		
		public function checkZoom(): void
		{
			if (onCapabilitiesDependent && !capabilitiesReady)
				return;
			
			if (layerInitialized)
			{
				var i_oldZoom: String = mi_zoom;
				findZoom();
	
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
		}

		private function isZoomCompatible(newZoom: String): Boolean
		{
			var newCRS: String = container.crs;
			var tilingInfo: TiledTilingInfo = m_cfg.getTiledTilingInfoForCRS(newCRS);
			if (!tilingInfo)
			{
				hideMap();
				return false;
			}
			
			//TODO fix this after InteractiveLayerTiled is implemented
//			if (newZoom < tilingInfo.minimumZoomLevel || newZoom > tilingInfo.maximumZoomLevel)
//			{
//				hideMap();
//				return false;
//			}
			
			return true;
		}

		private function notifyZoomLevelChange(zoomLevel: String): void
		{
			var ilqe: InteractiveLayerQTTEvent = new InteractiveLayerQTTEvent(InteractiveLayerQTTEvent.ZOOM_LEVEL_CHANGED, true);
			ilqe.zoomLevel = zoomLevel;
			dispatchEvent(ilqe);
		}

		/**************************************************************************************************************************************
		 *
		 * 		End of Zoom functionality
		 *
		 **************************************************************************************************************************************/
		override public function refresh(b_force: Boolean): void
		{
			if (_layerInitialized)
			{
				findZoom();
				super.refresh(b_force);
				invalidateData(b_force);
			} else {
				callLater(refresh, [b_force]);
			}
		}

		/**************************************************************************************************************************************
		 *
		 * 		Cache functionality
		 *
		 **************************************************************************************************************************************/
		public function clearCache(): void
		{
			if (m_cache)
				m_cache.clearCache();
		}

		public function getCache(): ICache
		{
			if (!m_cache)
			{
				trace("no tiled cache");
			}
			return m_cache;
		}

		private function destroyCache(): void
		{
			if (m_cache)
				m_cache.destroyCache();
		}

		public function invalidateCache(): void
		{
			m_cache.invalidate(container.crs, getGTileBBoxForWholeCRS(container.crs));
		}

		public function setSpecialCacheStrings(arr: Array): void
		{
			m_currentQTTViewProperties.setSpecialCacheStrings(arr);
		}

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
				var qttTileViewProperties: TiledTileViewProperties = item.viewProperties as TiledTileViewProperties;
				var qttViewProperties: TiledViewProperties = qttTileViewProperties as TiledViewProperties;
				if (qttViewProperties.validity.time != validity.time && qttTileViewProperties.updateCycleAge != updateCycleAge)
				{
					cache.deleteCacheItem(item, b_disposeDisplayed)
				}
			}
		}

		public function getTileFromCache(qttTileViewProperties: TiledTileViewProperties, request: URLRequest): Object
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

		/**************************************************************************************************************************************
		 *
		 * 		End of Cache functionality
		 *
		 **************************************************************************************************************************************/
		/**************************************************************************************************************************************
		 *
		 * 		Destroying layer functionality
		 *
		 **************************************************************************************************************************************/
		private function destroyPreloading(): void
		{
			var qttViewProperties: TiledViewProperties;
			if (ma_preloadedQTTViewProperties)
			{
				for each (qttViewProperties in ma_preloadedQTTViewProperties)
				{
					qttViewProperties.destroy();
				}
			}
			if (ma_preloadingBuffer)
			{
				for each (qttViewProperties in ma_preloadingBuffer)
				{
					qttViewProperties.destroy();
				}
			}
			cancelPreload();
			ma_preloadedQTTViewProperties = null;
			ma_preloadingBuffer = null;
			destroyPreloader();
			
		}
		override public function destroy(): void
		{
			super.destroy();
			
			destroyWMSViewPropertiesLoader();
			
			var qttViewProperties: TiledViewProperties;
			
			if (m_currentQTTViewProperties)
			{
				m_currentQTTViewProperties.destroy();
				m_currentQTTViewProperties = null;
			}
			
			destroyCache();
			destroyPreloading();
			
			m_cfg = null;
			cache = null;
			_tf = null;
			_tf2 = null;
			if (_debugDrawInfoArray && _debugDrawInfoArray.length > 0)
			{
				while (_debugDrawInfoArray.length > 0)
				{
					var tileIndex: TileIndex = _debugDrawInfoArray.shift();
					tileIndex = null;
				}
				_debugDrawInfoArray = null;
			}
		}

		protected function destroyWMSViewPropertiesLoader(): void
		{
			if (_loader)
			{
				_loader.removeEventListener(InteractiveDataLayer.LOADING_STARTED, onCurrentWMSDataLoadingStarted);
				_loader.removeEventListener(InteractiveDataLayer.PROGRESS, onCurrentWMSDataProgress);
				_loader.removeEventListener(InteractiveDataLayer.LOADING_FINISHED, onCurrentWMSDataLoadingFinished);
				_loader.removeEventListener(InteractiveDataLayer.LOADING_FINISHED_FROM_CACHE, onCurrentWMSDataLoadingFinishedFromCache);
				_loader.removeEventListener(InteractiveDataLayer.LOADING_FINISHED_NO_SYNCHRONIZATION_DATA, onCurrentWMSDataLoadingFinishedNoSynchronizationData);
				_loader.removeEventListener(InteractiveDataLayer.LOADING_ERROR, onCurrentWMSDataLoadingError);
				_loader.removeEventListener(InteractiveLayerEvent.INVALIDATE_DYNAMIC_PART, onCurrentWMSDataInvalidateDynamicPart);
				_loader.destroy();
			}
		}

		protected function destroyPreloader(): void
		{
			if (_preloader)
			{
				_preloader.removeEventListener(InteractiveLayerEvent.INVALIDATE_DYNAMIC_PART, onQTTViewPropertiesDataInvalidateDynamicPart);
				_preloader.removeEventListener(InteractiveDataLayer.LOADING_FINISHED, onPreloadingWMSDataLoadingFinished);
				_preloader.destroy();
			}
		}

		public function getTiledLayer(): InteractiveLayerTiled
		{
			return this;
		}

		public function setValidityTime(validity: Date): void
		{
			if (m_currentQTTViewProperties)
			{
				m_currentQTTViewProperties.setValidityTime(validity);
			}
		}

		public function serialize(storage: Storage): void
		{
			if (storage.isLoading())
			{
				var newAlpha: Number = storage.serializeNumber("transparency", alpha);
				if (newAlpha < 1)
				{
					alpha = newAlpha;
				}
			}
			else
			{
				if (alpha < 1)
				{
					storage.serializeNumber("transparency", alpha);
				}
			}
		}

		/**
		 * Overrides UIComponent.invalidateSize
		 *
		 */
		public override function invalidateSize(): void
		{
			super.invalidateSize();
			if (container != null)
			{
				width = container.width;
				height = container.height;
			}
		}

		/**
		 * Overrides UIComponent.validateSize
		 *
		 */
		public override function validateSize(b_recursive: Boolean = false): void
		{
			super.validateSize(b_recursive);
			if (_layerInitialized)
				checkZoom();
		}
		
		protected function onBeforeCacheItemDeleted(event: WMSCacheEvent): void
		{
			var key: String = event.item.cacheKey.key;
			var image: DisplayObject = event.item.image;
			
			var cache: WMSTileCache = getCache() as WMSTileCache;
			var bitmapFound: Boolean;
			
			//check if this Bitmap is used in this layer
            if (m_currentQTTViewProperties) {
                var tiles: Array = m_currentQTTViewProperties.tiles;
                for each (var tileViewProperties: TiledTileViewProperties in tiles)
                {
                    if (tileViewProperties.bitmap)
                    {
                        var currBitmap: Bitmap = tileViewProperties.bitmap;
                        if (image == currBitmap)
                        {
                            //listen when same cache item will be added
                            tileViewProperties.bitmapIsOk = false;
                            bitmapFound = true;
                        }
                    }
                }
                if (bitmapFound)
                    cache.addEventListener(WMSCacheEvent.ITEM_ADDED, onDeleteCacheItemAdded);
            }
		}
		
		private var _cacheIsUpdated: Boolean;
		private function onDeleteCacheItemAdded(event: WMSCacheEvent): void
		{
			//update imagePart
			var tiles: Array = m_currentQTTViewProperties.tiles;
			var cacheKey: String = event.item.cacheKey.key;
			for each (var tileViewProperties: TiledTileViewProperties in tiles)
			{
				if (tileViewProperties.bitmap)
				{
					if (!tileViewProperties.cacheKey || tileViewProperties.cacheKey == cacheKey)
					{
						tileViewProperties.bitmap = event.item.image as Bitmap;
						tileViewProperties.bitmapIsOk = true;
						tileViewProperties.cacheKey = cacheKey;
					}
				}
			}
			_cacheIsUpdated = true;
			invalidateProperties();
		}
		
		protected function debug(str: String): void
		{
			LoggingUtils.dispatchLogEvent(this, "Tiled: " + str);
		}

		override public function clone(): InteractiveLayer
		{
			var newLayer: InteractiveLayerTiled = new InteractiveLayerTiled(container, m_cfg);
			newLayer.alpha = alpha
			newLayer.zOrder = zOrder;
			newLayer.visible = visible;
			return newLayer;
		}

		override public function toString(): String
		{
			return "InteractiveLayerTiled " + name + " / layerID: " + m_layerID;
		}
		
		
		
	}
}
