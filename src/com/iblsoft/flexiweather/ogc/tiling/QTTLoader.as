package com.iblsoft.flexiweather.ogc.tiling
{
	import com.iblsoft.flexiweather.events.InteractiveLayerEvent;
	import com.iblsoft.flexiweather.events.InteractiveLayerProgressEvent;
	import com.iblsoft.flexiweather.events.InteractiveLayerQTTEvent;
	import com.iblsoft.flexiweather.net.events.UniURLLoaderErrorEvent;
	import com.iblsoft.flexiweather.net.events.UniURLLoaderEvent;
	import com.iblsoft.flexiweather.net.loaders.AbstractURLLoader;
	import com.iblsoft.flexiweather.ogc.BBox;
	import com.iblsoft.flexiweather.ogc.InteractiveLayerQTTMS;
	import com.iblsoft.flexiweather.ogc.cache.CacheItem;
	import com.iblsoft.flexiweather.ogc.cache.WMSTileCache;
	import com.iblsoft.flexiweather.ogc.data.IViewProperties;
	import com.iblsoft.flexiweather.ogc.data.IWMSViewPropertiesLoader;
	import com.iblsoft.flexiweather.ogc.data.QTTViewProperties;
	import com.iblsoft.flexiweather.proj.Coord;
	import com.iblsoft.flexiweather.proj.Projection;
	import com.iblsoft.flexiweather.utils.ISO8601Parser;
	import com.iblsoft.flexiweather.widgets.BackgroundJob;
	import com.iblsoft.flexiweather.widgets.BackgroundJobManager;
	import com.iblsoft.flexiweather.widgets.InteractiveDataLayer;
	import com.iblsoft.flexiweather.widgets.InteractiveWidget;
	
	import flash.display.Bitmap;
	import flash.events.EventDispatcher;
	import flash.events.IEventDispatcher;
	import flash.geom.Matrix;
	import flash.geom.Point;
	import flash.net.URLRequest;
	import flash.text.TextField;
	import flash.text.TextFormat;
	
	import mx.controls.Alert;
	import mx.events.DynamicEvent;
	
	public class QTTLoader extends EventDispatcher implements IWMSViewPropertiesLoader
	{
		private var mi_zoom: int;
		private var m_layer: InteractiveLayerQTTMS;
	
		private var mi_tilesCurrentlyLoading: int;
		private var mi_tilesLoadingTotal: int;
		private var mi_totalVisibleTiles: int;
		
//		private var ma_currentTilesRequests: Array = [];
		
		private var mi_updateCycleAge: uint = 0;
		private var m_jobs: TileJobs;
		
		private var _tilesProvider: ITilesProvider;
		public function get tilesProvider():ITilesProvider
		{
			return _tilesProvider;
		}
		
		public function set tilesProvider(value:ITilesProvider):void
		{
			_tilesProvider = value;
		}

		private var _qttViewProperties: QTTViewProperties;
		
		public function QTTLoader(layer: InteractiveLayerQTTMS, zoom: int)
		{
			super(null);
			
			m_layer = layer;
			mi_zoom = zoom;
			
			mi_tilesLoadingTotal = 0;
			
			m_jobs = new TileJobs();
			
			tilesProvider = new QTTTilesProvider();
		}
		
		public function destroy():void
		{
		}
		
		public function updateWMSData(b_forceUpdate:Boolean, viewProperties: IViewProperties, forcedLayerWidth:Number, forcedLayerHeight:Number):void
		{
			var qttViewProperties: QTTViewProperties = viewProperties as QTTViewProperties;
			
			
			//store qtt view properties for later use
			_qttViewProperties = qttViewProperties;
			
			var s_crs: String = qttViewProperties.crs;
			var currentViewBBox: BBox = qttViewProperties.getViewBBox();
			
			var tiledAreas: Array = [];
			var _tiledArea: TiledArea;
			mi_totalVisibleTiles =  0;
			
			//update CRS and extent BBox
			m_layer.tilingUtils.onAreaChanged(s_crs, m_layer.getGTileBBoxForWholeCRS(s_crs));
			
			//TODO create QTTTTileViewProperties
			
			/** 
			 * request all tiled areas for which we need update data. if projection does not allow wrap across dateline, there will be always 1 tiled area
			 */
			tiledAreas = getNeededTiledAreas(qttViewProperties);
			
			
			if (tiledAreas.length == 0)
				return;
			
			qttViewProperties.tiledAreas = tiledAreas;
			
			mi_updateCycleAge++;
			
			var loadRequests: Array;
			
			var baseURLPattern: String = m_layer.baseURLPatternForCRS(s_crs);
			
			if (baseURLPattern)
			{
				loadRequests = prepareData(qttViewProperties, tiledAreas, b_forceUpdate);
			} else {
				trace("baseURLpattern is NULL");
			}
			
			loadAllData(qttViewProperties, loadRequests);
		}
		
		/**
		 * Request all tiled areas for which we need update data.
		 * If projection does not allow wrap across dateline, there will be always 1 tiled area.
		 * @return 
		 * If wrap across dateline is allowed, there can be more tiled areas returned
		 * 
		 */		
		protected function getNeededTiledAreas(qttViewProperties: QTTViewProperties): Array
		{
			var container: InteractiveWidget = m_layer.container;
			
			var tiledAreas: Array = [];
			var _tiledArea: TiledArea;
			var s_crs: String = qttViewProperties.crs;
			
			var projection: Projection = Projection.getByCRS(s_crs);
			
			//FIXME instead of projection.extentBBox use tiling extent
			var partReflections: Array = container.mapBBoxToViewReflections(projection.extentBBox, true)
			for each (var partReflection: BBox in partReflections)
			{
				//find suitable visible parts for current reflection
				var reflectionVisibleParts: Array = container.mapBBoxToProjectionExtentParts(partReflection);
				
				for each (var reflectionVisiblePart: BBox in reflectionVisibleParts)
				{
					_tiledArea = m_layer.tilingUtils.getTiledArea(reflectionVisiblePart, mi_zoom);
					if (_tiledArea)
					{
						tiledAreas.push({tiledArea: _tiledArea, viewPart: reflectionVisiblePart});
						mi_totalVisibleTiles += _tiledArea.totalVisibleTilesCount;
					}
				}
			}
			return tiledAreas;
		}
		
		protected function prepareData(qttViewProperties: QTTViewProperties, tiledAreas: Array, b_forceUpdate: Boolean): Array
		{
//			ma_currentTilesRequests = [];
			
			var loadRequests: Array = new Array();
			
			var tiledCache: WMSTileCache = m_layer.getCache() as WMSTileCache;
			
			var tileIndex: TileIndex;
			var request: URLRequest;
			var m_time: Date; //container.time;
			
			var s_crs: String = qttViewProperties.crs;
			var tileIndicesMapper: TileIndicesMapper = qttViewProperties.tileIndicesMapper;
			
			//initialize tile indices mapper each frame
			tileIndicesMapper.removeAll();
			
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
						if (!tileIndicesMapper.tileIndexInside(tileIndex))
						{
							
							var qttTile: QTTTileViewProperties = new QTTTileViewProperties(qttViewProperties);
							
							tileIndicesMapper.addTileIndex(tileIndex, viewPart);
							
							request = new URLRequest(getExpandedURL(tileIndex, s_crs));
							// need to convert ${BASE_URL} because it's used in cachKey
							request.url = AbstractURLLoader.fromBaseURL(request.url);
							
							qttTile.url = request;
							qttTile.tileIndex = tileIndex;
							qttTile.updateCycleAge = mi_updateCycleAge;
							
							
//							var itemMetadata: CacheItemMetadata = new CacheItemMetadata();
//							itemMetadata.crs = s_crs;
//							itemMetadata.tileIndex = tileIndex;
//							itemMetadata.url = request;
//							itemMetadata.validity = qttViewProperties.validity;
//							itemMetadata.specialStrings = qttViewProperties.specialCacheStrings;
//							itemMetadata.updateCycleAge = mi_updateCycleAge;
							
//							if(!tiledCache.isTileCached(s_crs, tileIndex, request, m_time, ma_specialCacheStrings))
							if(!tiledCache.isItemCached(qttTile) || b_forceUpdate)
							{	
								qttViewProperties.addTileProperties(qttTile);
//								ma_currentTilesRequests.push(request);
								loadRequests.push({
									qttTileViewProperties: qttTile,
//									request: request,
//									requestedCRS: s_crs,
//									requestedTileIndex: tileIndex,
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
		
		protected function loadAllData(qttViewProperties: QTTViewProperties, loadRequests: Array): void
		{
			if(loadRequests.length > 0)
			{
				if (tilesProvider)
				{
					notifyLoadingStart();
					dispatchEvent(new InteractiveLayerQTTEvent(InteractiveLayerQTTEvent.TILES_LOADING_STARTED, true));
					
					loadRequests.sort(sortTiles);
					
					var bkJobManager: BackgroundJobManager = BackgroundJobManager.getInstance();
					var jobName: String;
					mi_tilesCurrentlyLoading = loadRequests.length;
					mi_tilesLoadingTotal += loadRequests.length;
					
					var data: Array = [];
					for each(var requestObj: Object in loadRequests)
					{
						jobName = "Rendering tile " + requestObj.requestedTileIndex + " for layer: " + m_layer.name;
						
						// this already cancel previou job for current tile
//						m_jobs.addNewTileJobRequest(requestObj.requestedTileIndex.mi_tileCol, requestObj.requestedTileIndex.mi_tileRow, dataLoader, requestObj.request);
						
						
//						var assocData: Object = {
//							qttTileViewProperties: qttViewProperties
//							requestedCRS: requestObj.requestedCRS,
//							requestedTileIndex:  requestObj.requestedTileIndex,
//							tiledArea: requestObj.requestedTiledArea,
//							viewPart: requestObj.requestedViewPart,
//							validity: qttTileViewProperties.qttViewProperties.validity,
//							updateCycleAge: mi_updateCycleAge
//						};
						
						var qttTileViewProperties: QTTTileViewProperties = requestObj.qttTileViewProperties;
						qttTileViewProperties.updateCycleAge = mi_updateCycleAge;
						
						var item: QTTTileRequest = new QTTTileRequest(qttTileViewProperties, jobName);
						data.push(item);
						
//						item.associatedData = assocData;
//						item.jobName = jobName;
//						item.crs = qttViewProperties.crs;
//						item.tileIndex = qttTileViewProperties.tileIndex;
//						item.request = qttTileViewProperties.url;
						
					}
					
					tilesProvider.getTiles(data, onTileLoaded, onTileLoadFailed);
				} else {
					Alert.show("Tiles Provider is not defined", "Tiles problem", Alert.OK);
				}
			} else {
				// all tiles were cached, draw them
				
				//check if this is need
				invalidateDynamicPart();
				
				dispatchEvent(new InteractiveLayerQTTEvent(InteractiveLayerQTTEvent.TILES_LOADED_FINISHED, true));
			}
		}
		
		
		public function onTileLoaded(result: Bitmap, tileRequest: QTTTileRequest, tileIndex: TileIndex): void
		{
			tileLoaded(result, tileRequest);
		}
		
		
		private function tileLoaded(result: Bitmap, tileRequest: QTTTileRequest): void
		{
			tileLoadFinished();
			
			var wmsTileCache: WMSTileCache = m_layer.getCache() as WMSTileCache;
			
//			onJobFinished(tileRequest.jobName);
			
			if(result is Bitmap) 
			{
				var qttTileViewProperties: QTTTileViewProperties = tileRequest.qttTileViewProperties;
				
				//debug text;
//				var tf: TextField = new TextField();
////				tf.text = qttTileViewProperties.tileIndex.toString();
//				if (qttTileViewProperties.qttViewProperties.specialCacheStrings)
//				{
//					var arr: Array = String(qttTileViewProperties.qttViewProperties.specialCacheStrings[0]).split('='); 
//					tf.text = arr[1];
//				}
//				
//				var format: TextFormat = tf.getTextFormat();
//				format.color = 0xffffff;
//				format.size = 9;
//				tf.setTextFormat(format);
//				
//				var m: Matrix = new Matrix();
//				m.translate(10,10);
				
				qttTileViewProperties.bitmap = result as Bitmap;
//				qttTileViewProperties.bitmap.bitmapData.draw(tf, m);
				
				//FIXME why this is deleted here
//				removeCachedTiles(qttTileViewProperties, true);
				
				if (qttTileViewProperties.qttViewProperties.specialCacheStrings)
					trace("QTTLoader tileLaoded: " + qttTileViewProperties.qttViewProperties.specialCacheStrings[0] + "  tileIndex: " + qttTileViewProperties.tileIndex.toString());
				
				wmsTileCache.addCacheItem(Bitmap(result), qttTileViewProperties);
				
				invalidateDynamicPart();
				
				return;
				
			}
			
			onDataLoadFailed(null);
		}
		
		/**
		 * Removed cached tiles for specified validity time and updateCycleAge
		 * @param validity
		 * 
		 */		
		private function removeCachedTiles(qttTileViewProperties: QTTTileViewProperties, b_disposeDisplayed: Boolean = false): void
		{
			var cache: WMSTileCache = (m_layer.getCache() as WMSTileCache); 
			var tiles: Array = cache.getCacheItems();
			
			
			var validity: Date = qttTileViewProperties.qttViewProperties.validity;
			var updateCycleAge: uint = qttTileViewProperties.updateCycleAge;
			
			for each (var item: CacheItem in tiles)
			{
				var currQTTTileViewProperties: QTTTileViewProperties = item.viewProperties as QTTTileViewProperties;
				var currParentQTT: QTTViewProperties = currQTTTileViewProperties.qttViewProperties;
			
				
				if (currQTTTileViewProperties && currParentQTT)
				{
					if (currParentQTT.validity && ISO8601Parser.dateToString(currParentQTT.validity) == ISO8601Parser.dateToString(validity) && currQTTTileViewProperties.updateCycleAge && currQTTTileViewProperties.updateCycleAge == updateCycleAge)
					{
						if (currQTTTileViewProperties.tileIndex.toString() == qttTileViewProperties.tileIndex.toString())
							cache.deleteCacheItem(item, b_disposeDisplayed)
					}
				}
			}
		}
		
		protected function onJobFinished(job: BackgroundJob): void
		{
			if(job != null) {
				job.finish();
				job = null;
			}
			invalidateDynamicPart();
		}
		
		/*
		protected function onDataLoaded(event: UniURLLoaderEvent): void
		{
			var result: * = event.result;
			tileLoaded(result as Bitmap, event.request, event.associatedData);
			
		}
		*/
		
		private function tileLoadFinished(): void
		{
			mi_tilesCurrentlyLoading--;
			
			notifyProgress(mi_tilesLoadingTotal - mi_tilesCurrentlyLoading, mi_tilesLoadingTotal, InteractiveLayerProgressEvent.UNIT_TILES);
			
			checkIfAllTilesAreLoaded();
		}
		
		public function onTileLoadFailed(tileIndex: TileIndex, associatedData: Object): void
		{
			//			trace("\t onTileLoadFailed : " + tileIndex);
			tileLoadFailed();
		}
		
		private function tileLoadFailed(): void
		{
			tileLoadFinished();
		}
		
		
		protected function onDataLoadFailed(event: UniURLLoaderErrorEvent): void
		{
			tileLoadFailed();
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
		
		private function sortTiles(reqObject1: Object, reqObject2: Object): int
		{
			var qttTile1: QTTTileViewProperties = reqObject1.qttTileViewProperties;
			var qttTile2: QTTTileViewProperties = reqObject2.qttTileViewProperties;
			
			var tileIndex1: TileIndex = qttTile1.tileIndex;
			var tileIndex2: TileIndex = qttTile2.tileIndex;
			
			var layerCenter: Point = new Point(m_layer.width / 2, m_layer.height / 2);//container.getViewBBox().center;
			
			var tileCenter1: Point = getTilePosition(qttTile1.qttViewProperties.crs, tileIndex1);
			var tileCenter2: Point = getTilePosition(qttTile2.qttViewProperties.crs, tileIndex2);
			
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
			var tileBBox: BBox = m_layer.getGTileBBox(crs, tileIndex);
			var topLeftPoint: Point = m_layer.container.coordToPoint(new Coord(crs, tileBBox.xMin, tileBBox.yMax));
			
			topLeftPoint.x = Math.floor(topLeftPoint.x);
			topLeftPoint.y = Math.floor(topLeftPoint.y);
			
			return topLeftPoint;
		}
		
		
//		protected function notifyLoadingStart(associatedData: Object): void
		protected function notifyLoadingStart(): void
		{
			var e: InteractiveLayerEvent = new InteractiveLayerEvent(InteractiveDataLayer.LOADING_STARTED);
//			e.data = associatedData;
			dispatchEvent(e);
		}
		
		protected function notifyProgress(loaded: int, total: int, units: String): void
		{
			var event: InteractiveLayerProgressEvent = new InteractiveLayerProgressEvent(InteractiveDataLayer.PROGRESS, true);
			//		event.interactiveLayer = this;
			event.loaded = loaded;
			event.total = total;
			event.units = units;
			event.progress = 100 * loaded / total;
			dispatchEvent(event);
			
		}
		
		protected function notifyLoadingFinished(): void
		{
			var e: InteractiveLayerEvent = new InteractiveLayerEvent(InteractiveDataLayer.LOADING_FINISHED);
			e.data = _qttViewProperties;
			dispatchEvent(e);
		}
		
		private function invalidateDynamicPart(b_invalid: Boolean = true): void
		{
			var de: DynamicEvent = new DynamicEvent("invalidateDynamicPart");
			de["invalid"] = b_invalid;
			dispatchEvent(de);
		}
		
		private function getExpandedURL(tileIndex: TileIndex, crs: String): String
		{
			var url: String = InteractiveLayerQTTMS.expandURLPattern(m_layer.baseURLPatternForCRS(crs), tileIndex);
			if (_qttViewProperties.specialCacheStrings && _qttViewProperties.specialCacheStrings.length > 0)
			{
				var specialLen: int = String("SPECIAL_").length;
				for each (var str: String in _qttViewProperties.specialCacheStrings)
				{
					str = str.substring(specialLen, str.length);
					url += "&"+str;
				}
			}
			return url;
		}
	}
}