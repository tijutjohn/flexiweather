package com.iblsoft.flexiweather.ogc.tiling
{
	import com.iblsoft.flexiweather.events.InteractiveLayerEvent;
	import com.iblsoft.flexiweather.events.InteractiveLayerProgressEvent;
	import com.iblsoft.flexiweather.events.InteractiveLayerQTTEvent;
	import com.iblsoft.flexiweather.net.events.UniURLLoaderErrorEvent;
	import com.iblsoft.flexiweather.net.events.UniURLLoaderEvent;
	import com.iblsoft.flexiweather.net.loaders.AbstractURLLoader;
	import com.iblsoft.flexiweather.ogc.BBox;
	import com.iblsoft.flexiweather.ogc.ExceptionUtils;
	import com.iblsoft.flexiweather.ogc.InteractiveLayerQTTMS;
	import com.iblsoft.flexiweather.ogc.cache.CacheItem;
	import com.iblsoft.flexiweather.ogc.cache.WMSTileCache;
	import com.iblsoft.flexiweather.ogc.configuration.layers.QTTMSLayerConfiguration;
	import com.iblsoft.flexiweather.ogc.data.viewProperties.IViewProperties;
	import com.iblsoft.flexiweather.ogc.data.viewProperties.IWMSViewPropertiesLoader;
	import com.iblsoft.flexiweather.ogc.data.viewProperties.TiledTileViewProperties;
	import com.iblsoft.flexiweather.ogc.data.viewProperties.TiledViewProperties;
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
	
	import mx.containers.Tile;
	import mx.controls.Alert;
	import mx.events.DynamicEvent;

	public class TiledLoader extends EventDispatcher implements IWMSViewPropertiesLoader
	{
		private var _zoom: String;
		private var m_layer: InteractiveLayerTiled;
		private var mi_tilesCurrentlyLoading: int;
		private var mi_tilesLoadingTotal: int;
		private var mi_totalVisibleTiles: int;
//		private var ma_currentTilesRequests: Array = [];
		private var mi_updateCycleAge: uint = 0;
		private var m_jobs: TileJobs;
		private var _tilesProvider: ITilesProvider;


		public function get zoom():String
		{
			return _zoom;
		}

		public function set zoom(value:String):void
		{
			_zoom = value;
		}

		public function get tilesProvider(): ITilesProvider
		{
			return _tilesProvider;
		}

		public function set tilesProvider(value: ITilesProvider): void
		{
			_tilesProvider = value;
		}
		private var _tiledViewProperties: TiledViewProperties;

		public function TiledLoader(layer: InteractiveLayerTiled)
		{
			super(null);
			m_layer = layer;
			mi_tilesLoadingTotal = 0;
			m_jobs = new TileJobs();
			
			var tiledCache: WMSTileCache = m_layer.getCache() as WMSTileCache;
			
			tilesProvider = new TiledTilesProvider(tiledCache);
		}

		public function destroy(): void
		{
			_tilesProvider.destroy();
		}

		public function cancel(): void
		{
			if (_tilesProvider)
				_tilesProvider.cancel();
		}
			
		public function updateWMSData(b_forceUpdate: Boolean, viewProperties: IViewProperties, forcedLayerWidth: Number, forcedLayerHeight: Number, printQuality: String): void
		{
			var tiledViewProperties: TiledViewProperties = viewProperties as TiledViewProperties;
			//store tiled view properties for later use
			_tiledViewProperties = tiledViewProperties;
			var s_crs: String = tiledViewProperties.crs;
			var currentViewBBox: BBox = tiledViewProperties.getViewBBox();
			var tiledAreas: Array = [];
			var _tiledArea: TiledArea;
			mi_totalVisibleTiles = 0;
			
			var tileMatrix: TileMatrix = m_layer.getTileMatrixForCRSAndZoom(s_crs, _zoom);
			
			//update CRS and extent BBox
			m_layer.tiledAreaChanged(s_crs, m_layer.getGTileBBoxForWholeCRS(s_crs));
			//TODO create TiledTileViewProperties
			
			//TODO do we need support for non-square tiles?
			
			var tileSize: uint = 256; 
			if (tileMatrix)
				tileSize = tileMatrix.tileWidth;  // TileSize.SIZE_256;
			
//			if (tiledViewProperties.configuration && (tiledViewProperties.configuration as Object).hasOwnProperty('tileSize'))
//				tileSize = (tiledViewProperties.configuration as Object)['tileSize'];
			/**
			 * request all tiled areas for which we need update data. if projection does not allow wrap across dateline, there will be always 1 tiled area
			*/
			tiledAreas = getNeededTiledAreas(tiledViewProperties, tileSize);
			if (tiledAreas.length == 0)
				return;
			tiledViewProperties.tiledAreas = tiledAreas;
			mi_updateCycleAge++;
			var loadRequests: Array;

			loadRequests = prepareData(tiledViewProperties, tiledAreas, b_forceUpdate);

			loadAllData(tiledViewProperties, loadRequests);
		}

		/**
		 * Request all tiled areas for which we need update data.
		 * If projection does not allow wrap across dateline, there will be always 1 tiled area.
		 * @return
		 * If wrap across dateline is allowed, there can be more tiled areas returned
		 *
		 */
		protected function getNeededTiledAreas(tiledViewProperties: TiledViewProperties, tileSize: uint): Array
		{
			var container: InteractiveWidget = m_layer.container;
			var tiledAreas: Array = [];
			var _tiledArea: TiledArea;
			var s_crs: String = tiledViewProperties.crs;
			var projection: Projection = Projection.getByCRS(s_crs);
			//FIXME instead of projection.extentBBox use tiling extent
			var partReflections: Array = container.mapBBoxToViewReflections(projection.extentBBox, true)
			for each (var partReflection: BBox in partReflections)
			{
				//find suitable visible parts for current reflection
				var reflectionVisibleParts: Array = container.mapBBoxToProjectionExtentParts(partReflection);
				for each (var reflectionVisiblePart: BBox in reflectionVisibleParts)
				{
					_tiledArea = m_layer.getTiledArea(reflectionVisiblePart, _zoom, tileSize);
					if (_tiledArea)
					{
						tiledAreas.push({tiledArea: _tiledArea, viewPart: reflectionVisiblePart});
						mi_totalVisibleTiles += _tiledArea.totalVisibleTilesCount;
					}
				}
			}
			return tiledAreas;
		}

		protected function prepareData(qttViewProperties: TiledViewProperties, tiledAreas: Array, b_forceUpdate: Boolean): Array
		{
//			ma_currentTilesRequests = [];
			var loadRequests: Array = new Array();
			var tiledCache: WMSTileCache = m_layer.getCache() as WMSTileCache;
			var tileIndex: TileIndex;
			var request: URLRequest;
			var m_time: Date; //container.time;
			var s_crs: String = qttViewProperties.crs;
			
			var fullURL: String = m_layer.getFullURL() + m_layer.baseURLPatternForCRS(s_crs);
			
			var tileIndicesMapper: TileIndicesMapper = qttViewProperties.tileIndicesMapper;
			//initialize tile indices mapper each frame
			tileIndicesMapper.removeAll();
			for each (var partObject: Object in tiledAreas)
			{
				var tiledArea: TiledArea = partObject.tiledArea as TiledArea;
				var viewPart: BBox = partObject.viewPart as BBox;
				for (var i_row: uint = tiledArea.topRow; i_row <= tiledArea.bottomRow; ++i_row)
				{
					for (var i_col: uint = tiledArea.leftCol; i_col <= tiledArea.rightCol; ++i_col)
					{
						tileIndex = new TileIndex(_zoom, i_row, i_col);
						//check if tileIndex is already created from other tiledArea part
						if (!tileIndicesMapper.tileIndexInside(tileIndex))
						{
							var qttTileViewProperties: TiledTileViewProperties = new TiledTileViewProperties(qttViewProperties);
							
							
							qttTileViewProperties.crs = qttViewProperties.crs;
							qttTileViewProperties.setValidityTime(qttViewProperties.validity);
							qttTileViewProperties.setViewBBox(qttViewProperties.getViewBBox());
							qttTileViewProperties.setSpecialCacheStrings(qttViewProperties.specialCacheStrings);
							qttTileViewProperties.tiledAreas = qttViewProperties.tiledAreas;
							
							
							tileIndicesMapper.addTileIndex(tileIndex, viewPart);
							
							var url: String = getExpandedURL(tileIndex, s_crs, fullURL);
							request = new URLRequest(url);
							
							// need to convert ${BASE_URL} because it's used in cachKey
							request.url = AbstractURLLoader.fromBaseURL(request.url);
							qttTileViewProperties.url = request;
							qttTileViewProperties.tileIndex = tileIndex;
							qttTileViewProperties.updateCycleAge = mi_updateCycleAge;
							if (!tiledCache.isItemCached(qttTileViewProperties) || b_forceUpdate)
							{
								qttViewProperties.addTileProperties(qttTileViewProperties);
								loadRequests.push({
											qttTileViewProperties: qttTileViewProperties,
											requestedTiledArea: tiledArea,
											requestedViewPart: viewPart,
											requestedTileIndex: tileIndex
										});
							}
						}
					}
				}
			}
			return loadRequests;
		}

		protected function loadAllData(qttViewProperties: TiledViewProperties, loadRequests: Array): void
		{
			if (loadRequests.length > 0)
			{
				if (tilesProvider)
				{
					notifyLoadingStart();
					dispatchEvent(new InteractiveLayerQTTEvent(InteractiveLayerQTTEvent.TILES_LOADING_STARTED, true));
					
					var tiledCache: WMSTileCache = m_layer.getCache() as WMSTileCache;
					
					loadRequests.sort(sortTiles);
					var bkJobManager: BackgroundJobManager = BackgroundJobManager.getInstance();
					var jobName: String;
					mi_tilesCurrentlyLoading = loadRequests.length;
					mi_tilesLoadingTotal += loadRequests.length;
					var data: Array = [];
					
					var validity: Date = qttViewProperties.validity;
					var validityString: String;
					if (validity)
					{
						validityString = ISO8601Parser.dateToString(validity);
					}
					for each (var requestObj: Object in loadRequests)
					{
						if (validity)
							jobName = "Rendering tile " + requestObj.requestedTileIndex + " with validity: " + validityString + " for layer: " + m_layer.name;
						else
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
						
						
						var qttTileViewProperties: TiledTileViewProperties = requestObj.qttTileViewProperties;
						qttTileViewProperties.updateCycleAge = mi_updateCycleAge;
						
						
						tiledCache.startImageLoading(qttTileViewProperties);
						
						var item: TiledTileRequest = new TiledTileRequest(qttTileViewProperties, jobName);
						data.push(item);
//						item.associatedData = assocData;
//						item.jobName = jobName;
//						item.crs = qttViewProperties.crs;
//						item.tileIndex = qttTileViewProperties.tileIndex;
//						item.request = qttTileViewProperties.url;
					}
					tilesProvider.getTiles(data, onTileLoaded, onTileLoadFailed);
				}
				else
					Alert.show("Tiles Provider is not defined", "Tiles problem", Alert.OK);
			}
			else
			{
				// all tiles were cached, draw them
				//check if this is need
				invalidateDynamicPart();
				dispatchEvent(new InteractiveLayerQTTEvent(InteractiveLayerQTTEvent.TILES_LOADED_FINISHED, true));
			}
		}

		public function onTileLoaded(result: Bitmap, tileRequest: TiledTileRequest, tileIndex: TileIndex): void
		{
			//FIXME onTileLoaded need to find out associatedData
			
			if (!m_layer.layerWasDestroyed)
				tileLoaded(result, tileRequest, null);
		}

		private function tileLoaded(result: Bitmap, tileRequest: TiledTileRequest, associatedData: Object): void
		{
			if (!m_layer.layerWasDestroyed)
			{
				tileLoadFinished();
				var wmsTileCache: WMSTileCache = m_layer.getCache() as WMSTileCache;
//				onJobFinished(tileRequest.jobName);
				if (result is Bitmap)
				{
					var qttTileViewProperties: TiledTileViewProperties = tileRequest.qttTileViewProperties;
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
					//				if (qttTileViewProperties.qttViewProperties.specialCacheStrings)
					//					trace("QTTLoader tileLaoded: " + qttTileViewProperties.qttViewProperties.specialCacheStrings[0] + "  tileIndex: " + qttTileViewProperties.tileIndex.toString());
					if (wmsTileCache)
						wmsTileCache.addCacheItem(Bitmap(result), qttTileViewProperties, associatedData);
					invalidateDynamicPart();
					return;
				}
				onDataLoadFailed(null);
			}
		}

		/**
		 * Removed cached tiles for specified validity time and updateCycleAge
		 * @param validity
		 *
		 */
		private function removeCachedTiles(qttTileViewProperties: TiledTileViewProperties, b_disposeDisplayed: Boolean = false): void
		{
			var cache: WMSTileCache = (m_layer.getCache() as WMSTileCache);
			var tiles: Array = cache.getCacheItems();
			var validity: Date = qttTileViewProperties.qttViewProperties.validity;
			var updateCycleAge: uint = qttTileViewProperties.updateCycleAge;
			for each (var item: CacheItem in tiles)
			{
				var currQTTTileViewProperties: TiledTileViewProperties = item.viewProperties as TiledTileViewProperties;
				var currParentQTT: TiledViewProperties = currQTTTileViewProperties.qttViewProperties;
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
			if (job != null)
			{
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

		public function onTileLoadFailed(tileRequest: TiledTileRequest, associatedData: Object): void
		{
			tileLoadFailed();
			//FIXME check if this is ServiceException "InvalidDimensionValue" and add information to cachec "somehow" to do not load it when looping animation
			/**
			*
			* <ServiceExceptionReport version="1.3.0">
			* 	<ServiceException code="InvalidDimensionValue">
			* 		Failed to apply value '2012-05-29T00:00:00Z' to dimension 'time'
			*	 </ServiceException>
			* </ServiceExceptionReport>
			*
			*/
			if (associatedData.errorResult)
			{
				var xml: XML = associatedData.errorResult;
				if (xml.localName() == "ServiceExceptionReport")
				{
					var serviceException: XML = xml.children()[0] as XML;
					if (serviceException.localName() == "ServiceException" && serviceException.hasOwnProperty("@code") && serviceException.@code == "InvalidDimensionValue")
					{
						var exceptionText: String = serviceException.text();
						if (exceptionText.indexOf('Failed to apply value') == 0)
						{
							var arr: Array = exceptionText.split("'");
							var timeString: String = arr[1];
							var dimension: String = arr[3];
							m_layer.getCache().addCacheNoDataItem(tileRequest.qttTileViewProperties);
						}
					}
				}
			} else {
                m_layer.getCache().cacheItemLoadingCanceled(tileRequest.qttTileViewProperties);
            }
		}

		private function tileLoadFailed(): void
		{
			tileLoadFinished();
		}

		protected function onDataLoadFailed(event: UniURLLoaderErrorEvent): void
		{
			if (!m_layer.layerWasDestroyed)
			{
				
				/**
				 *
				 * <ServiceExceptionReport version="1.3.0">
				 * 	<ServiceException code="InvalidDimensionValue">
				 * 		Failed to apply value '2012-05-29T00:00:00Z' to dimension 'time'
				 *	 </ServiceException>
				 * </ServiceExceptionReport>
				 *
				 */
				var associatedData: Object = event.associatedData;
				if (associatedData.errorResult)
				{
					var errorStateSet: Boolean;
					
					var xml: XML = associatedData.errorResult;
					if (xml.localName() == "ServiceExceptionReport")
					{
						var serviceException: XML = xml.children()[0] as XML;
						if (serviceException.localName() == "ServiceException" && serviceException.hasOwnProperty("@code") && serviceException.@code == "InvalidDimensionValue")
						{
							var exceptionText: String = serviceException.text();
							if (exceptionText.indexOf('Failed to apply value') == 0)
							{
								var arr: Array = exceptionText.split("'");
								var timeString: String = arr[1];
								var dimension: String = arr[3];
								
//								m_layer.getCache().addCacheNoDataItem(wmsViewProperties);
								
//								ExceptionUtils.logError(Log.getLogger("WMS"), associatedData.errorResult,
//									"Failed to apply value '" + (m_layer.configuration as IWMSLayerConfiguration).layerNames.join(",") + "'");
								
								notifyLoadingFinishedNoSynchronizationData()
								errorStateSet = true;
							}
						}
					}
					
					//TODO just one error needs to be dispatched whenall tiles are loaded
					if (!errorStateSet)
						notifyLoadingFinishedWithErrors();
					
				}
				
				tileLoadFailed();
			}
		}

		private function checkIfAllTilesAreLoaded(): void
		{
			if (mi_tilesCurrentlyLoading == 0)
			{
				mi_tilesLoadingTotal = 0;
				dispatchEvent(new InteractiveLayerQTTEvent(InteractiveLayerQTTEvent.TILES_LOADED_FINISHED, true));
				notifyLoadingFinished();
			}
		}

		private function sortTiles(reqObject1: Object, reqObject2: Object): int
		{
			var qttTile1: TiledTileViewProperties = reqObject1.qttTileViewProperties;
			var qttTile2: TiledTileViewProperties = reqObject2.qttTileViewProperties;
			var tileIndex1: TileIndex = qttTile1.tileIndex;
			var tileIndex2: TileIndex = qttTile2.tileIndex;
			var layerCenter: Point = new Point(m_layer.width / 2, m_layer.height / 2); //container.getViewBBox().center;
			var tileCenter1: Point = getTilePosition(qttTile1.qttViewProperties.crs, tileIndex1);
			var tileCenter2: Point = getTilePosition(qttTile2.qttViewProperties.crs, tileIndex2);
			var dist1: int = Point.distance(layerCenter, tileCenter1);
			var dist2: int = Point.distance(layerCenter, tileCenter2);
			if (dist1 > dist2)
				return 1;
			else
			{
				if (dist1 < dist2)
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

		protected function notifyLoadingFinishedWithErrors(): void
		{
			var e: InteractiveLayerEvent = new InteractiveLayerEvent(InteractiveDataLayer.LOADING_ERROR);
			e.data = _tiledViewProperties;
			dispatchEvent(e);
		}
		protected function notifyLoadingFinishedNoSynchronizationData(): void
		{
			var e: InteractiveLayerEvent = new InteractiveLayerEvent(InteractiveDataLayer.LOADING_FINISHED_NO_SYNCHRONIZATION_DATA);
			e.data = _tiledViewProperties;
			dispatchEvent(e);
		}
		
		protected function notifyLoadingFinished(): void
		{
			var e: InteractiveLayerEvent = new InteractiveLayerEvent(InteractiveDataLayer.LOADING_FINISHED);
			e.data = _tiledViewProperties;
			dispatchEvent(e);
		}

		private function invalidateDynamicPart(b_invalid: Boolean = true): void
		{
			var de: DynamicEvent = new DynamicEvent(InteractiveLayerEvent.INVALIDATE_DYNAMIC_PART);
			de["invalid"] = b_invalid;
			dispatchEvent(de);
		}

		private function getExpandedURL(tileIndex: TileIndex, crs: String, fullPath: String): String
		{
			var url: String = fullPath;// + m_layer.baseURLPatternForCRS(crs);
			
			url = InteractiveLayerTiled.expandURLPattern(url, tileIndex);
			
			if (_tiledViewProperties.specialCacheStrings && _tiledViewProperties.specialCacheStrings.length > 0)
			{
				var specialLen: int = String("SPECIAL_").length;
				for each (var str: String in _tiledViewProperties.specialCacheStrings)
				{
					str = str.substring(specialLen, str.length);
					url += "&" + str;
				}
			}
			return url;
		}
		
		override public function toString(): String
		{
			return "TiledLoader: Loading: " + mi_tilesCurrentlyLoading + " / " + mi_tilesLoadingTotal + " visible: " + mi_totalVisibleTiles;
		}
	}
}
