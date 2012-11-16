package com.iblsoft.flexiweather.ogc.tiling
{
	import com.iblsoft.flexiweather.events.InteractiveLayerEvent;
	import com.iblsoft.flexiweather.events.InteractiveLayerProgressEvent;
	import com.iblsoft.flexiweather.events.InteractiveLayerQTTEvent;
	import com.iblsoft.flexiweather.ogc.BBox;
	import com.iblsoft.flexiweather.ogc.InteractiveLayerQTTMS;
	import com.iblsoft.flexiweather.ogc.cache.CacheItem;
	import com.iblsoft.flexiweather.ogc.cache.ICache;
	import com.iblsoft.flexiweather.ogc.cache.ICachedLayer;
	import com.iblsoft.flexiweather.ogc.cache.WMSTileCache;
	import com.iblsoft.flexiweather.ogc.configuration.layers.TiledLayerConfiguration;
	import com.iblsoft.flexiweather.ogc.configuration.layers.interfaces.ILayerConfiguration;
	import com.iblsoft.flexiweather.ogc.data.viewProperties.IViewProperties;
	import com.iblsoft.flexiweather.ogc.data.viewProperties.IWMSViewPropertiesLoader;
	import com.iblsoft.flexiweather.ogc.data.viewProperties.TiledTileViewProperties;
	import com.iblsoft.flexiweather.ogc.data.viewProperties.TiledViewProperties;
	import com.iblsoft.flexiweather.ogc.preload.IPreloadableLayer;
	import com.iblsoft.flexiweather.plugins.IConsole;
	import com.iblsoft.flexiweather.proj.Coord;
	import com.iblsoft.flexiweather.utils.Serializable;
	import com.iblsoft.flexiweather.utils.Storage;
	import com.iblsoft.flexiweather.widgets.IConfigurableLayer;
	import com.iblsoft.flexiweather.widgets.InteractiveDataLayer;
	import com.iblsoft.flexiweather.widgets.InteractiveLayer;
	import com.iblsoft.flexiweather.widgets.InteractiveWidget;
	import flash.display.BitmapData;
	import flash.display.Graphics;
	import flash.events.Event;
	import flash.filters.GlowFilter;
	import flash.geom.Matrix;
	import flash.geom.Point;
	import flash.net.URLRequest;
	import flash.text.TextField;
	import flash.text.TextFormat;
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
		protected var mi_zoom: int = 1;
		public var tileScaleX: Number;
		public var tileScaleY: Number;
		/** This is used only if overriding using the setter, otherwise the value from m_cfg is used. */
		protected var ms_explicitBaseURLPattern: String;
		protected var m_cache: WMSTileCache;

		public function get cache(): WMSTileCache
		{
			return m_cache;
		}
		protected var m_cfg: TiledLayerConfiguration;

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
		 * wms data which are currently preloading
		 */
		protected var ma_preloadingQTTViewProperties: Array;
		/**
		 * wms data which are already preloaded
		 */
		protected var ma_preloadedQTTViewProperties: Array;

		public function InteractiveLayerTiled(container: InteractiveWidget = null, cfg: TiledLayerConfiguration = null)
		{
			super(container);
			m_cfg = cfg;
		}

		override protected function initializeLayer(): void
		{
			super.initializeLayer();
			if (m_cfg == null)
			{
				var cfg: TiledLayerConfiguration = createDefaultConfiguration();
				m_cfg = cfg;
			}
			ma_preloadingQTTViewProperties = [];
			ma_preloadedQTTViewProperties = [];
			m_currentQTTViewProperties = new TiledViewProperties();
			m_currentQTTViewProperties.setConfiguration(m_cfg);
			updateCurrentWMSViewProperties();
			//			m_currentWMSViewProperties.addEventListener(SynchronisedVariableChangeEvent.SYNCHRONISED_VARIABLE_CHANGED, onCurrentWMSDataSynchronisedVariableChanged);
			//			m_currentWMSViewProperties.addEventListener(WMSViewPropertiesEvent.WMS_DIMENSION_VALUE_SET, onWMSDimensionValueSet);
			m_cache = new WMSTileCache();
			//			_viewPartsReflections = new ViewPartReflectionsHelper(container);
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
			return new TiledLoader(this, zoomLevel);
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
			if (!layerInitialized)
				return;
			if (!layerWasDestroyed)
			{
				super.updateData(b_forceUpdate);
				if (_avoidTiling)
				{
					//tiling for this layer is for now avoided, do not update data
					return;
				}
				if (mi_zoom < 0)
				{
					// wrong zoom, do not continue
					return;
				}
				if (!visible)
				{
					mb_updateAfterMakingVisible = true;
					return;
				}
				var loader: IWMSViewPropertiesLoader = getWMSViewPropertiesLoader();
				loader.addEventListener(InteractiveDataLayer.LOADING_STARTED, onCurrentWMSDataLoadingStarted);
				loader.addEventListener(InteractiveDataLayer.PROGRESS, onCurrentWMSDataProgress);
				loader.addEventListener(InteractiveDataLayer.LOADING_FINISHED, onCurrentWMSDataLoadingFinished);
				loader.addEventListener(InteractiveDataLayer.LOADING_FINISHED_FROM_CACHE, onCurrentWMSDataLoadingFinishedFromCache);
				loader.addEventListener("invalidateDynamicPart", onCurrentWMSDataInvalidateDynamicPart);
				loader.updateWMSData(b_forceUpdate, m_currentQTTViewProperties, forcedLayerWidth, forcedLayerHeight);
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
			var loader: IWMSViewPropertiesLoader = event.target as IWMSViewPropertiesLoader;
			destroyWMSViewPropertiesLoader(loader);
			notifyLoadingFinished();
			_currentQTTDataLoadingStarted = false;
			invalidateDynamicPart(true);
		}
		
		protected function onCurrentWMSDataLoadingFinishedFromCache(event: InteractiveLayerEvent): void
		{
			var loader: IWMSViewPropertiesLoader = event.target as IWMSViewPropertiesLoader;
			destroyWMSViewPropertiesLoader(loader);
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
		public function getTiledArea(viewBBox: BBox, zoomLevel: int, tileSize: int): TiledArea
		{
			return null;
		}

		public function tiledAreaChanged(newCRS: String, newBBox: BBox): void
		{
			//implement this function in child classes if you need something
		}

		override public function onAreaChanged(b_finalChange: Boolean): void
		{
			if (!layerInitialized)
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
			if (b_finalChange || mi_zoom < 0)
			{
				var i_oldZoom: int = mi_zoom;
				findZoom();
				if (!isZoomCompatible(mi_zoom))
					return;
				if (mi_zoom != i_oldZoom)
				{
					notifyZoomLevelChange(mi_zoom);
					m_cache.invalidate(newCRS, viewBBox);
				}
				invalidateData(false);
			}
			else
				invalidateDynamicPart();
		}

		/**************************************************************************************************************************************
		 *
		 * 		Drawing functionality
		 *
		 **************************************************************************************************************************************/
		override public function draw(graphics: Graphics): void
		{
			if (!layerInitialized)
				return;
			super.draw(graphics);
			//			graphics.clear();
			//			setTimeout(customDraw, 500, m_currentQTTViewProperties, graphics);
			customDraw(m_currentQTTViewProperties, graphics);
		}
		private var _debugDrawInfoArray: Array;

		private function customDraw(qttViewProperties: TiledViewProperties, graphics: Graphics, redrawBorder: Boolean = false): void
		{
			if (!layerWasDestroyed)
			{
				if (mi_zoom == -1)
				{
					trace("InteractiveLayerQTTMS.customDraw(): Isomething is wrong, tile zoom is -1");
					return;
				}
				_debugDrawInfoArray = [];
				var s_crs: String = qttViewProperties.crs; //container.crs;
				var currentBBox: BBox = qttViewProperties.getViewBBox(); //container.getViewBBox();
				var tilingBBox: BBox = getGTileBBoxForWholeCRS(s_crs); // extent of tile z=0/r=0/c=0
				if (tilingBBox == null)
				{
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
						_debugDrawInfoArray.push(tileIndex);
						drawTile(tileIndex, s_crs, t_tile.image.bitmapData, redrawBorder);
					}
				}
				//FIXME change this, now there can be more tiledArea
				//			m_cache.sortCache(m_tiledArea);
				dispatchEvent(new Event(DRAW_TILES));
			}
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
			if (!topRightPoint || !topLeftPoint)
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
				drawText(tileIndex.mi_tileZoom + ", "
						+ tileIndex.mi_tileCol + ", "
						+ tileIndex.mi_tileRow,
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
		private var _tfBD: BitmapData;

		private function drawText(txt: String, gr: Graphics, pos: Point): void
		{
			if (!_tf.filters || !_tf.filters.length)
			{
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
			return mi_zoom != -1;
		}

		public override function renderPreview(graphics: Graphics, f_width: Number, f_height: Number): void
		{
			if (!width || !height)
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
//			m_currentQTTViewProperties.removeEventListener(SynchronisedVariableChangeEvent.SYNCHRONISED_VARIABLE_CHANGED, onCurrentWMSDataSynchronisedVariableChanged);
			m_currentQTTViewProperties = viewProperties as TiledViewProperties;
			trace("ILQTT changeViewProperties: " + m_currentQTTViewProperties);
//			m_currentQTTViewProperties.addEventListener(SynchronisedVariableChangeEvent.SYNCHRONISED_VARIABLE_CHANGED, onCurrentWMSDataSynchronisedVariableChanged);
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
		public function preload(viewProperties: IViewProperties): void
		{
			var qttViewProperties: TiledViewProperties = viewProperties as TiledViewProperties;
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

		protected function onPreloadingWMSDataLoadingFinished(event: InteractiveLayerEvent): void
		{
			var loader: IWMSViewPropertiesLoader = event.target as IWMSViewPropertiesLoader;
			destroyWMSViewPropertiesPreloader(loader);
			var qttViewProperties: TiledViewProperties = event.data as TiledViewProperties;
			if (qttViewProperties)
			{
				qttViewProperties.removeEventListener(InteractiveDataLayer.LOADING_FINISHED, onPreloadingWMSDataLoadingFinished);
				//			debug("onPreloadingWMSDataLoadingFinished wmsData: " + wmsViewProperties);
				//			trace("\t onPreloadingWMSDataLoadingFinished PRELOADED: " + ma_preloadedWMSViewProperties.length + " , PRELAODING: " + ma_preloadingWMSViewProperties.length);
				//remove wmsViewProperties from array of currently preloading wms view properties
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
			var i_tilesInSerie: uint = 1 << tileIndex.mi_tileZoom;
			var f_tileWidth: Number = extent.width / i_tilesInSerie;
			var f_tileHeight: Number = extent.height / i_tilesInSerie;
			var f_xMin: Number = extent.xMin + tileIndex.mi_tileCol * f_tileWidth;
			// note that tile row numbers increase in the opposite way as the Y-axis
			var f_yMin: Number = extent.yMax - (tileIndex.mi_tileRow + 1) * f_tileHeight;
			var tileBBox: BBox = new BBox(f_xMin, f_yMin, f_xMin + f_tileWidth, f_yMin + f_tileHeight);
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
//			if(ms_explicitBaseURLPattern == null)
//			{
//				var tilingInfo: TiledTilingInfo;
//				if (m_cfg.tilingCRSsAndExtents && m_cfg.tilingCRSsAndExtents.length > 0)
//					tilingInfo = m_cfg.getTiledTilingInfoForCRS(crs);
//				
//				if (tilingInfo && tilingInfo.urlPattern)
//					return tilingInfo.urlPattern;
//			}
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
				s_url = s_url.replace('%ZOOM%', String(tileIndex.mi_tileZoom));
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
		public function get zoomLevel(): int
		{
			return mi_zoom;
		}

		protected function findZoom(): void
		{
//			var tilingExtent: BBox = getGTileBBoxForWholeCRS(container.crs);
//			m_tilingUtils.onAreaChanged(container.crs, tilingExtent);
//			var viewBBox: BBox = container.getViewBBox();
//			
//			var newZoomLevel2: Number = 1;
//			if (tilingExtent)
//			{
//				var test: Number = (tilingExtent.width * width) / (viewBBox.width * 256);
//				newZoomLevel2 = Math.log(test) * Math.LOG2E;
//				//zoom level must be alway 0 or more
//				newZoomLevel2 = Math.max(0, newZoomLevel2);
//			}
//			
//			mi_zoom = Math.round(newZoomLevel2);
		}

		public function checkZoom(): void
		{
			var i_oldZoom: int = mi_zoom;
			findZoom();
//			if (mi_zoom == 0)
//			{
//				trace("check zoom level 0");	
//			}
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

		private function isZoomCompatible(newZoom: int): Boolean
		{
			var newCRS: String = container.crs;
			var tilingInfo: TiledTilingInfo = m_cfg.getTiledTilingInfoForCRS(newCRS);
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

		private function notifyZoomLevelChange(zoomLevel: int): void
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
			findZoom();
			super.refresh(b_force);
			invalidateData(b_force);
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
		private function isPartCached(qttViewProperties: TiledViewProperties, s_currentCRS: String, currentViewBBox: BBox, i_width: uint, i_height: uint): Boolean
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
		override public function destroy(): void
		{
			super.destroy();
			var qttViewProperties: TiledViewProperties;
			if (ma_preloadingQTTViewProperties)
			{
				for each (qttViewProperties in ma_preloadingQTTViewProperties)
				{
					qttViewProperties.destroy();
				}
			}
			if (ma_preloadedQTTViewProperties)
			{
				for each (qttViewProperties in ma_preloadedQTTViewProperties)
				{
					qttViewProperties.destroy();
				}
			}
			ma_preloadingQTTViewProperties = null;
			ma_preloadedQTTViewProperties = null;
			if (m_currentQTTViewProperties)
			{
				m_currentQTTViewProperties.destroy();
				m_currentQTTViewProperties = null;
			}
			destroyCache();
			m_cfg = null;
			m_cache = null;
			_tf = null;
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

		protected function destroyWMSViewPropertiesLoader(loader: IWMSViewPropertiesLoader): void
		{
			loader.removeEventListener(InteractiveDataLayer.LOADING_STARTED, onCurrentWMSDataLoadingStarted);
			loader.removeEventListener(InteractiveDataLayer.PROGRESS, onCurrentWMSDataProgress);
			loader.removeEventListener(InteractiveDataLayer.LOADING_FINISHED, onCurrentWMSDataLoadingFinished);
			loader.removeEventListener(InteractiveDataLayer.LOADING_FINISHED_FROM_CACHE, onCurrentWMSDataLoadingFinishedFromCache);
			loader.removeEventListener("invalidateDynamicPart", onCurrentWMSDataInvalidateDynamicPart);
			loader.destroy();
		}

		protected function destroyWMSViewPropertiesPreloader(loader: IWMSViewPropertiesLoader): void
		{
			loader.removeEventListener("invalidateDynamicPart", onQTTViewPropertiesDataInvalidateDynamicPart);
			loader.removeEventListener(InteractiveDataLayer.LOADING_FINISHED, onPreloadingWMSDataLoadingFinished);
			loader.destroy();
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
			trace("InteractiveLayerTiled serialize");
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
			checkZoom();
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
			return "InteractiveLayerTiled " + name;
		}
	}
}
