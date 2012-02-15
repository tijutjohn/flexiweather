package com.iblsoft.flexiweather.ogc
{
	import com.iblsoft.flexiweather.events.InteractiveLayerProgressEvent;
	import com.iblsoft.flexiweather.events.InteractiveLayerQTTEvent;
	import com.iblsoft.flexiweather.net.events.UniURLLoaderErrorEvent;
	import com.iblsoft.flexiweather.net.events.UniURLLoaderEvent;
	import com.iblsoft.flexiweather.net.loaders.AbstractURLLoader;
	import com.iblsoft.flexiweather.net.loaders.UniURLLoader;
	import com.iblsoft.flexiweather.ogc.cache.CacheItem;
	import com.iblsoft.flexiweather.ogc.cache.CacheItemMetadata;
	import com.iblsoft.flexiweather.ogc.cache.ICache;
	import com.iblsoft.flexiweather.ogc.cache.ICachedLayer;
	import com.iblsoft.flexiweather.ogc.cache.WMSTileCache;
	import com.iblsoft.flexiweather.ogc.tiling.ITiledLayer;
	import com.iblsoft.flexiweather.ogc.tiling.ITilesProvider;
	import com.iblsoft.flexiweather.ogc.tiling.QTTTileRequest;
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
	
	import mx.controls.Alert;
	import mx.events.DynamicEvent;
	
	import spark.primitives.Graphic;
	
	[Event(name='drawTiles', type='')]
	
	/**
	 * Generic Quad Tree (like Google Maps) tiling layer
	 **/
	public class InteractiveLayerQTTMS extends InteractiveDataLayer implements IConfigurableLayer, ICachedLayer, ITiledLayer, Serializable
	{
		public static const UPDATE_TILING_PATTERN: String = 'updateTilingPattern';
		
		public static const DRAW_TILES: String = 'drawTiles';
		
		public static var imageSmooth: Boolean = true;
		public static var drawBorders: Boolean = false;
		public static var drawDebugText: Boolean = false;
		
		private var _tileIndicesMapper: TileIndicesMapper;
		private var _viewPartsReflections: ViewPartReflectionsHelper;
		
		private var _avoidTiling: Boolean;

		private var _currentValidityTime: Date;
		private var mi_updateCycleAge: uint = 0;

		public function get tilesProvider():ITilesProvider
		{
			return _tilesProvider;
		}

		public function set tilesProvider(value:ITilesProvider):void
		{
			_tilesProvider = value;
		}

		public function set avoidTiling(value:Boolean):void
		{
			_avoidTiling = value;
		}

		protected var m_cache: WMSTileCache;
		public function get cache(): WMSTileCache
		{
			return m_cache;
		}
		
		private var ma_specialCacheStrings: Array;
		
		protected var m_timer: Timer = new Timer(10000);
		
		protected var m_cfg: QTTMSLayerConfiguration;
		public function get configuration():ILayerConfiguration
		{
			return m_cfg;
		}
		
		/** This is used only if overriding using the setter, otherwise the value from m_cfg is used. */ 
		protected var ms_explicitBaseURLPattern: String;
		
		
		private var ms_oldCRS: String;
		private var m_tilingUtils: TilingUtils;
		private var m_jobs: TileJobs;
		private var mi_zoom: int = -1;
		public var tileScaleX: Number;
		public var tileScaleY: Number;
		private var ma_currentTilesRequests: Array = [];
		private var mi_totalVisibleTiles: int;
		
		private var mi_tilesCurrentlyLoading: int;
		private var mi_tilesLoadingTotal: int;
		
		private var _tilesProvider: ITilesProvider;
		
		public function InteractiveLayerQTTMS(
				container: InteractiveWidget,
				cfg: QTTMSLayerConfiguration,
				s_baseURLPattern: String = null, s_primaryCRS: String = null, primaryCRSTilingExtent: BBox = null,
				minimumZoomLevel: uint = 0, maximumZoomLevel: uint = 10)
		{
			super(container);
			
			mi_tilesLoadingTotal = 0;
			
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
			
			/*
			for each(var crsWithBBox: CRSWithBBox in cfg.tilingCRSsAndExtents) {
				md_crsToTilingExtent[crsWithBBox.crs] = crsWithBBox.bbox;
			}
			*/
			
			_tileIndicesMapper = new TileIndicesMapper();
			_viewPartsReflections = new ViewPartReflectionsHelper(container);
			
			m_cache = new WMSTileCache();
			m_tilingUtils = new TilingUtils();
			m_tilingUtils.minimumZoom = minimumZoomLevel;
			m_tilingUtils.maximumZoom = maximumZoomLevel;
			
			m_jobs = new TileJobs();
			
			tilesProvider = new QTTTilesProvider();
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
			
			
			var i_oldZoom: int = mi_zoom;
			findZoom();
			if (mi_zoom == 0)
			{
				trace("check zoom level 0");	
			}
			if (i_oldZoom != mi_zoom)
			{
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

		private function getExpandedURL(tileIndex: TileIndex): String
		{
			return expandURLPattern(baseURLPattern, tileIndex);
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
		 * Request all tiled areas for which we need update data.
		 * If projection does not allow wrap across dateline, there will be always 1 tiled area.
		 * @return 
		 * If wrap across dateline is allowed, there can be more tiled areas returned
		 * 
		 */		
		protected function getNeededTiledAreas(): Array
		{
			var tiledAreas: Array = [];
			var _tiledArea: TiledArea;
			var s_crs: String = container.crs;
			
			var projection: Projection = Projection.getByCRS(s_crs);
			
			//FIXME instead of projection.extentBBox use tiling extent
			var partReflections: Array = container.mapBBoxToViewReflections(projection.extentBBox, true)
			for each (var partReflection: BBox in partReflections)
			{
				//find suitable visible parts for current reflection
				var reflectionVisibleParts: Array = container.mapBBoxToProjectionExtentParts(partReflection);
				
				for each (var reflectionVisiblePart: BBox in reflectionVisibleParts)
				{
					_tiledArea = m_tilingUtils.getTiledArea(reflectionVisiblePart, mi_zoom);
					if (_tiledArea)
					{
						tiledAreas.push({tiledArea: _tiledArea, viewPart: reflectionVisiblePart});
						mi_totalVisibleTiles += _tiledArea.totalVisibleTilesCount;
					}
				}
			}
			return tiledAreas;
		}
		
		protected function prepareData(tiledAreas: Array, b_forceUpdate: Boolean): Array
		{
			var loadRequests: Array = new Array();
			
			var tiledCache: WMSTileCache = m_cache as WMSTileCache;
			
			var tileIndex: TileIndex;
			var request: URLRequest;
			var s_crs: String = container.crs;
			var m_time: Date; //container.time;
			
			//initialize tile indices mapper each frame
			_tileIndicesMapper.removeAll();
			
			for each (var partObject: Object in tiledAreas)
			{
				var tiledArea: TiledArea = partObject.tiledArea as TiledArea;
				var viewPart: BBox = partObject.viewPart as BBox;
				
				for(var i_row: uint = tiledArea.topRow; i_row <= tiledArea.bottomRow; ++i_row) 
				{
					for(var i_col: uint = tiledArea.leftCol; i_col <= tiledArea.rightCol; ++i_col) 
					{
						tileIndex = new TileIndex(mi_zoom, i_row, i_col);
						//check if tileIndex is already created from other tiledArea part
						if (!_tileIndicesMapper.tileIndexInside(tileIndex))
						{
							_tileIndicesMapper.addTileIndex(tileIndex, viewPart);
							
							request = new URLRequest(getExpandedURL(tileIndex));
							// need to convert ${BASE_URL} because it's used in cachKey
							request.url = AbstractURLLoader.fromBaseURL(request.url);
							
							
							var itemMetadata: CacheItemMetadata = new CacheItemMetadata();
							itemMetadata.crs = s_crs;
							itemMetadata.tileIndex = tileIndex;
							itemMetadata.url = request;
							itemMetadata.validity = _currentValidityTime;
							itemMetadata.specialStrings = ma_specialCacheStrings;
							itemMetadata.updateCycleAge = mi_updateCycleAge;
							
//							if(!tiledCache.isTileCached(s_crs, tileIndex, request, m_time, ma_specialCacheStrings))
							if(!tiledCache.isItemCached(itemMetadata) || b_forceUpdate)
							{	
								ma_currentTilesRequests.push(request);
								loadRequests.push({
									request: request,
									requestedCRS: s_crs,
									requestedTileIndex: tileIndex,
									requestedTiledArea: tiledArea,
									requestedViewPart: viewPart
								});
							}
						}
					}
				}
			}
			
			return loadRequests;
		}
		
		protected function loadAllData(loadRequests: Array): void
		{
			if(loadRequests.length > 0)
			{
				if (tilesProvider)
				{
					dispatchEvent(new InteractiveLayerQTTEvent(InteractiveLayerQTTEvent.TILES_LOADING_STARTED, true));
					
					loadRequests.sort(sortTiles);
					
					var bkJobManager: BackgroundJobManager = BackgroundJobManager.getInstance();
					var jobName: String;
					mi_tilesCurrentlyLoading = loadRequests.length;
					mi_tilesLoadingTotal += loadRequests.length;
					
					var data: Array = [];
					for each(var requestObj: Object in loadRequests)
					{
						jobName = "Rendering tile " + requestObj.requestedTileIndex + " for layer: " + name
						// this already cancel previou job for current tile
						m_jobs.addNewTileJobRequest(requestObj.requestedTileIndex.mi_tileCol, requestObj.requestedTileIndex.mi_tileRow, dataLoader, requestObj.request);
						
						var assocData: Object = {
							requestedCRS: requestObj.requestedCRS,
							requestedTileIndex:  requestObj.requestedTileIndex,
							tiledArea: requestObj.requestedTiledArea,
							viewPart: requestObj.requestedViewPart,
							validity: _currentValidityTime,
							updateCycleAge: mi_updateCycleAge
						};
							
						var item: QTTTileRequest = new QTTTileRequest();
						item.associatedData = assocData;
						item.jobName = jobName;
						item.crs = requestObj.requestedCRS;
						item.tileIndex = requestObj.requestedTileIndex;
						item.request = requestObj.request;
						data.push(item);
						
	//					loadData(requestObj.request, assocData, jobName);
					}
					
					tilesProvider.getTiles(data, onTileLoaded, onTileLoadFailed);
				} else {
					Alert.show("Tiles Provider is not defined", "Tiles problem", Alert.OK);
				}
			} else {
				// all tiles were cached, draw them
				draw(graphics);
				
				dispatchEvent(new InteractiveLayerQTTEvent(InteractiveLayerQTTEvent.TILES_LOADED_FINISHED, true));
			}
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
			var s_crs: String = container.crs;
			
			var currentViewBBox: BBox = container.getViewBBox();
			
			var tiledAreas: Array = [];
			var _tiledArea: TiledArea;
			mi_totalVisibleTiles =  0;
			
			//update CRS and extent BBox
			m_tilingUtils.onAreaChanged(s_crs, getGTileBBoxForWholeCRS(s_crs));
			
			
			/** 
			 * request all tiled areas for which we need update data. if projection does not allow wrap across dateline, there will be always 1 tiled area
			 */
			tiledAreas = getNeededTiledAreas();
			
			
			if (tiledAreas.length == 0)
				return;
			
			mi_updateCycleAge++;
			
			var tiledCache: WMSTileCache = m_cache as WMSTileCache;
			var tileIndex: TileIndex = new TileIndex(mi_zoom);
			
			ma_currentTilesRequests = [];
			
			var loadRequests: Array;
			
			if (baseURLPattern)
			{
				loadRequests = prepareData(tiledAreas, b_forceUpdate);
				
			} else {
				trace("baseURLpattern is NULL");
			}
			
			loadAllData(loadRequests);
		}
		
		private function updateDataPart(): void
		{
			
		}
		
		private function sortTiles(reqObject1: Object, reqObject2: Object): int
		{
			var tileIndex1: TileIndex = reqObject1.requestedTileIndex;
			var tileIndex2: TileIndex = reqObject2.requestedTileIndex;
			
			var layerCenter: Point = new Point(width / 2, height / 2);//container.getViewBBox().center;
			
			var tileCenter1: Point = getTilePosition(reqObject1.requestedCRS, tileIndex1);
			var tileCenter2: Point = getTilePosition(reqObject2.requestedCRS, tileIndex2);
			
			var dist1: int = Point.distance(layerCenter, tileCenter1);
			var dist2: int = Point.distance(layerCenter, tileCenter2);
			
			if(dist1 > dist2)
			{
				return 1;
			} else {
				if(dist1 < dist2)
					return -1;
			}
			return 0;
		} 
		private function getTilePosition(crs: String, tileIndex: TileIndex): Point
		{
			var tileBBox: BBox = getGTileBBox(crs, tileIndex);
			var topLeftPoint: Point = container.coordToPoint(new Coord(crs, tileBBox.xMin, tileBBox.yMax));
			
			topLeftPoint.x = Math.floor(topLeftPoint.x);
			topLeftPoint.y = Math.floor(topLeftPoint.y);
			
			return topLeftPoint;
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
				if (item.metadata.validity.time != validity.time && item.metadata.updateCycleAge != updateCycleAge)
				{
					cache.deleteCacheItem(item, b_disposeDisplayed)
				}
			}
		}
		
		/**
		 * Removed cached tiles for specified validity time 
		 * @param validity
		 * 
		 */		
		public function removeCachedTiles(validity: Date, updateCycleAge: uint, b_disposeDisplayed: Boolean = false): void
		{
			var tiles: Array = cache.getCacheItems();
			for each (var item: CacheItem in tiles)
			{
				if (item.metadata && item.metadata.validity && item.metadata.validity.time == validity.time && item.metadata.updateCycleAge && item.metadata.updateCycleAge == updateCycleAge)
				{
					cache.deleteCacheItem(item, b_disposeDisplayed)
				}
			}
		}
		
		public function getTileFromCache(request: URLRequest, validity: Date): Object
		{
			var tiledCache: WMSTileCache = m_cache as WMSTileCache;
			
			var metadata: CacheItemMetadata = new CacheItemMetadata();
			metadata.url = request;
			metadata.validity = validity;
			metadata.specialStrings = ma_specialCacheStrings;
			
//			return tiledCache.getCacheItem(request, time, ma_specialCacheStrings); 
			return tiledCache.getCacheItem(metadata); 
		}
		
		private function findZoom(): void
		{
			var tilingExtent: BBox = getGTileBBoxForWholeCRS(container.crs);
			m_tilingUtils.onAreaChanged(container.crs, tilingExtent);
			var viewBBox: BBox = container.getViewBBox();
			
			//new Jozef tiling zoom equation
			var newZoomLevel2: Number = 1;
			if (tilingExtent)
			{
				var test: Number = (tilingExtent.width * width) / (viewBBox.width * 256);
				newZoomLevel2 = Math.log(test) * Math.LOG2E;
//				trace("New Jozef' zoom:  " + newZoomLevel2);
				//zoom level must be alway 0 or more
				newZoomLevel2 = Math.max(0, newZoomLevel2);
			}
			
			mi_zoom = Math.round(newZoomLevel2);
			//mi_zoom = m_tilingUtils.getZoom(viewBBox, new Point(width, height));
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
			customDraw(graphics);
		}
		
		private var _debugDrawInfoArray: Array;
		private function customDraw(graphics: Graphics, redrawBorder: Boolean = false): void
		{
			if(mi_zoom == -1)
			{
				trace("InteractiveLayerQTTMS.customDraw(): Isomething is wrong, tile zoom is -1");
				return;
			}

			_debugDrawInfoArray = [];
			
			var s_crs: String = container.crs;
			var currentBBox: BBox = container.getViewBBox();
			var tilingBBox: BBox = getGTileBBoxForWholeCRS(s_crs); // extent of tile z=0/r=0/c=0
			if(tilingBBox == null) {
				trace("InteractiveLayerQTTMS.customDraw(): No tiling extent for CRS " + container.crs);
				return;
			}

			var wmsTileCache: WMSTileCache = m_cache as WMSTileCache;
			
			//get cache tiles
 			var a_tiles: Array = wmsTileCache.getTiles(container.crs, mi_zoom, ma_specialCacheStrings);
			var allTiles: Array = a_tiles.reverse();
			
			graphics.clear();
			graphics.lineStyle(0,0,0);
			
			var t_tile: Object;
			var tileIndex: TileIndex;
				
			var cnt: int = 0;
			var viewPart: BBox;
			
			for each(t_tile in allTiles) {
				
				tileIndex = t_tile.tileIndex;
				viewPart = _tileIndicesMapper.getTileIndexViewPart(tileIndex);
				
				if (tileIndex)
				{
					_debugDrawInfoArray.push(tileIndex);
					
					drawTile(tileIndex, s_crs, t_tile.image.bitmapData, redrawBorder);
				}
			}
			
//			if (_console)
//			{
//				_console.print("\tCUSTOM DRAW SUMMARY: " + _debugDrawInfoArray+"\nEND", "Info", "Tilling"); 
//			}
			
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
		
		private function drawNoDataPreview(graphics: Graphics, f_width: Number, f_height: Number): void
		{
			graphics.lineStyle(2, 0xcc0000, 0.7, true);
			graphics.moveTo(0, 0);
			graphics.lineTo(f_width - 1, f_height - 1);
			graphics.moveTo(0, f_height - 1);
			graphics.lineTo(f_width - 1, 0);
			
		}
		
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
					m_cache.invalidate(newCRS, viewBBox);
				}
				invalidateData(false);
			}
			else
				invalidateDynamicPart();
		}
		
		private function checkIfAllTilesAreLoaded(): void
		{
			if(mi_tilesCurrentlyLoading == 0)
			{
				mi_tilesLoadingTotal = 0;
				dispatchEvent(new InteractiveLayerQTTEvent(InteractiveLayerQTTEvent.TILES_LOADED_FINISHED, true));
				notifyLoadingFinished();
			}
		}
		
		override protected function onDataLoaded(event: UniURLLoaderEvent): void
		{
			var result: * = event.result;
			tileLoaded(result as Bitmap, event.request, event.associatedData);
			
		}
		
		public function onTileLoaded(result: Bitmap, tileRequest: QTTTileRequest, tileIndex: TileIndex, associatedData: Object): void
		{
			tileLoaded(result, tileRequest.request, tileRequest.associatedData);
		}
		
		
		private function tileLoaded(result: Bitmap, request: URLRequest, associatedData: Object): void
		{
			tileLoadFinished();
			
			var wmsTileCache: WMSTileCache = m_cache as WMSTileCache;
			
			onJobFinished(associatedData.job);
			
			if(result is Bitmap) 
			{
				var itemMetadata: CacheItemMetadata = new CacheItemMetadata();
				itemMetadata.crs = associatedData.requestedCRS;
				itemMetadata.tileIndex = associatedData.requestedTileIndex;
				itemMetadata.tiledArea = associatedData.tiledArea;
				itemMetadata.viewPart = associatedData.viewPart;
				itemMetadata.validity = associatedData.validity;
				itemMetadata.updateCycleAge = associatedData.updateCycleAge;
				
				itemMetadata.specialStrings = ma_specialCacheStrings;
				itemMetadata.url = request;
				
				removeCachedTiles(itemMetadata.validity, itemMetadata.updateCycleAge, true);
				
				wmsTileCache.addCacheItem(Bitmap(result), itemMetadata);
				draw(graphics);
				return;

			}

			onDataLoadFailed(null);
		}
		
		private function tileLoadFinished(): void
		{
			mi_tilesCurrentlyLoading--;
			
			notifyProgress(mi_tilesLoadingTotal - mi_tilesCurrentlyLoading, mi_tilesLoadingTotal, InteractiveLayerProgressEvent.UNIT_TILES);
			
			checkIfAllTilesAreLoaded();
		}
		
		public function onTileLoadFailed(tileIndex: TileIndex, associatedData: Object): void
		{
			trace("\t onTileLoadFailed : " + tileIndex);
			tileLoadFailed();
		}
		
		private function tileLoadFailed(): void
		{
			tileLoadFinished();
		}
		
			
		override protected function onDataLoadFailed(event: UniURLLoaderErrorEvent): void
		{
			tileLoadFailed();
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
		
		protected function onJobFinished(job: BackgroundJob): void
		{
			if(job != null) {
				job.finish();
				job = null;
			}
			invalidateDynamicPart();
		}
		
		public function setSpecialCacheStrings(arr: Array): void
		{
			ma_specialCacheStrings = arr;
		}

		public function get baseURLPattern(): String
		{
			if(ms_explicitBaseURLPattern == null)
			{
				var tilingInfo: QTTilingInfo;
				//TODO get current CRS 
				var crs: String = container.getCRS();
//				var tilingInfo: QTTilingInfo = m_cfg.getQTTilingInfoForCRS(crs);
				if (m_cfg.tilingCRSsAndExtents && m_cfg.tilingCRSsAndExtents.length > 0)
					tilingInfo = m_cfg.getQTTilingInfoForCRS(crs);
				
				if (tilingInfo && tilingInfo.urlPattern)
					return tilingInfo.urlPattern;
			}
			return ms_explicitBaseURLPattern;
		}
		
		/*
		public function set baseURLPattern(s_baseURL: String): void
		{ ms_explicitBaseURLPattern = s_baseURL; }
		*/
		
		public function get zoomLevel(): int
		{ return mi_zoom; }
		
		override public function toString(): String
		{
			return "InteractiveLayerQTTMS " + name  ;
		}
		
		public function getTiles(tilesIndices:Array):void
		{
			// TODO Auto Generated method stub
			
		}
		
		public function debugCache(): String
		{
			return toString() + "\n" + m_cache.debugCache();
		}
		
		public function getCache():ICache
		{
			// TODO Auto Generated method stub
			return m_cache;
		}
		
		public function getTiledLayer():InteractiveLayerQTTMS
		{
			return this;
		}
		
		public function setValidityTime(validity: Date): void
		{
			_currentValidityTime = validity;
		}
		
		public function clearCache():void
		{
			if (m_cache)
				m_cache.clearCache();
			
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

class TileJobs
{
	private var m_jobs: Dictionary;
	
	public function TileJobs()
	{
		m_jobs = new Dictionary();	
	}
	public function addNewTileJobRequest(x: int, y: int, urlLoader: WMSImageLoader, urlRequest: URLRequest): void
	{
		var _existingJob: TileJob = m_jobs[x+"_"+y] as TileJob;
		if (_existingJob)
		{
			_existingJob.cancelRequests();
			_existingJob.urlLoader = urlLoader;
			_existingJob.urlRequest = urlRequest;
		} else {
			m_jobs[x+"_"+y] = new TileJob(x,y,urlRequest, urlLoader);
		}
		
	}
}

class TileJob
{
	private var mi_x: int;
	private var mi_y: int;
	private var m_urlRequest: URLRequest;
	private var m_urlLoader: WMSImageLoader;

	public function set urlRequest(value: URLRequest):void
	{
		m_urlRequest = value;
	}

	public function set urlLoader(value: WMSImageLoader):void
	{
		m_urlLoader = value;
	}
	
	public function TileJob(x: int, y: int, request: URLRequest, loader: WMSImageLoader)
	{
		mi_x = x;
		mi_y = y;
		m_urlRequest = request;
		m_urlLoader = loader;
	}

	public function cancelRequests(): void
	{
		m_urlLoader.cancel(m_urlRequest);
	}
}

class TileIndicesMapper
{
	private var _tileIndices: Dictionary = new Dictionary();
	
	public function TileIndicesMapper()
	{
		trace("create new tile indices mapper");
	}
	
	private function getMapperKey(tileIndex: TileIndex): String
	{
		return tileIndex.mi_tileCol + "_" + tileIndex.mi_tileRow + "_" + tileIndex.mi_tileZoom;
	}
	private function getMapperItem(tileIndex: TileIndex): Object
	{
		return _tileIndices[getMapperKey(tileIndex)];
	}
	
	public function removeAll(): void
	{
		_tileIndices = new Dictionary();
	}
	public function getTileIndexViewPart(tileIndex: TileIndex): BBox
	{
		var object: Object = getMapperItem(tileIndex);
		if (object)
			return object.viewPart;
		
		return null;
	}
	
	public function setTileIndexViewPart(tileIndex: TileIndex, viewPart: BBox): void
	{
		addTileIndex(tileIndex, viewPart);
	}
	
	public function addTileIndex(tileIndex: TileIndex, viewPart: BBox): void
	{
		_tileIndices[getMapperKey(tileIndex)] = {tileIndex: tileIndex, viewPart: viewPart};
	}
	
	public function removeTileIndex(tileIndex: TileIndex, viewPart: BBox): void
	{
		delete _tileIndices[getMapperKey(tileIndex)]
	}
	
	public function tileIndexInside(tileIndex: TileIndex): Boolean
	{
		return getMapperItem(tileIndex) != null;
		
	}
}


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