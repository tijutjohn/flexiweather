package com.iblsoft.flexiweather.ogc.net.loaders
{
	import com.iblsoft.flexiweather.events.InteractiveLayerEvent;
	import com.iblsoft.flexiweather.events.InteractiveLayerProgressEvent;
	import com.iblsoft.flexiweather.net.events.UniURLLoaderErrorEvent;
	import com.iblsoft.flexiweather.net.events.UniURLLoaderEvent;
	import com.iblsoft.flexiweather.ogc.BBox;
	import com.iblsoft.flexiweather.ogc.ExceptionUtils;
	import com.iblsoft.flexiweather.ogc.InteractiveLayerMSBase;
	import com.iblsoft.flexiweather.ogc.cache.CacheItem;
	import com.iblsoft.flexiweather.ogc.cache.WMSCache;
	import com.iblsoft.flexiweather.ogc.cache.event.WMSCacheEvent;
	import com.iblsoft.flexiweather.ogc.configuration.layers.WMSLayerConfiguration;
	import com.iblsoft.flexiweather.ogc.configuration.layers.interfaces.IWMSLayerConfiguration;
	import com.iblsoft.flexiweather.ogc.data.ImagePart;
	import com.iblsoft.flexiweather.ogc.data.viewProperties.IViewProperties;
	import com.iblsoft.flexiweather.ogc.data.viewProperties.IWMSViewPropertiesLoader;
	import com.iblsoft.flexiweather.ogc.data.viewProperties.WMSViewProperties;
	import com.iblsoft.flexiweather.ogc.events.MSBaseLoaderEvent;
	import com.iblsoft.flexiweather.proj.Projection;
	import com.iblsoft.flexiweather.widgets.InteractiveDataLayer;
	import com.iblsoft.flexiweather.widgets.InteractiveLayer;
	
	import flash.display.Bitmap;
	import flash.display.DisplayObject;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.ProgressEvent;
	import flash.net.URLRequest;
	
	import mx.collections.ArrayCollection;
	import mx.events.DynamicEvent;
	import mx.logging.Log;

	public class MSBaseLoader extends EventDispatcher implements IWMSViewPropertiesLoader
	{
		private static var uid: int = 0;
		public var id: int;
		private var ma_requests: ArrayCollection = new ArrayCollection(); // of URLRequest
		private var mi_updateCycleAge: uint = 0;
		private var m_layer: InteractiveLayerMSBase;
		protected var m_loader: WMSImageLoader;
		private var m_wmsViewProperties: WMSViewProperties;
		private var m_imagePart: ImagePart;

		private var _delayedRequestArray: Array;
		private var _delayedCachedRequestArray: Array;
		
		public function MSBaseLoader(layer: InteractiveLayerMSBase)
		{
			uid++;
			id = uid;
			m_layer = layer;
			m_loader = new WMSImageLoader();
			m_loader.addEventListener(UniURLLoaderEvent.DATA_LOADED, onDataLoaded);
			m_loader.addEventListener(ProgressEvent.PROGRESS, onDataProgress);
			m_loader.addEventListener(UniURLLoaderErrorEvent.DATA_LOAD_FAILED, onDataLoadFailed);
			
			_delayedRequestArray = [];
			_delayedCachedRequestArray = [];
		}

		override public function toString(): String
		{
			return "MSBaseLoader [" + id + "]";
		}

		public function destroy(): void
		{
			if (m_loader)
			{
				m_loader.removeEventListener(UniURLLoaderEvent.DATA_LOADED, onDataLoaded);
				m_loader.removeEventListener(ProgressEvent.PROGRESS, onDataProgress);
				m_loader.removeEventListener(UniURLLoaderErrorEvent.DATA_LOAD_FAILED, onDataLoadFailed);
				m_loader = null;
			}
		}

		public function cancel(): void
		{
			if (ma_requests.length > 0)
			{
				var wmsCache: WMSCache = m_layer.getCache() as WMSCache;
				wmsCache.cacheItemLoadingCanceled(m_wmsViewProperties);
				
				for each (var request: URLRequest in ma_requests)
				{
					m_loader.cancel(request);
				}
				ma_requests.removeAll();
			}
		}
		
		/**
		 * Check if WMS data are cached (only if b_forceUpdate is true) and load any data parts which are missing.
		 *
		 *
		 * @param b_forceUpdate if TRUE, data is forced to load even if they are cached
		 *
		 */
		public function updateWMSData(b_forceUpdate: Boolean, viewProperties: IViewProperties, forcedLayerWidth: Number, forcedLayerHeight: Number, printQuality: String): void
		{
			m_wmsViewProperties = viewProperties as WMSViewProperties;
			//check if data are not already cached
			//			super.updateData(b_forceUpdate);
			++mi_updateCycleAge;
			
			//cancel all running requests
			cancel();
			
			var i_width: int = int(m_layer.container.width);
			var i_height: int = int(m_layer.container.height);
			if (forcedLayerWidth > 0)
				i_width = forcedLayerWidth;
			if (forcedLayerHeight > 0)
				i_height = forcedLayerHeight;
			//TODO do we want support custom CRS and ViewBBox, which should be stored in WMSViewProperties or we can take it from InteractiveWidget
			var s_currentCRS: String = m_wmsViewProperties.crs;
			var currentViewBBox: BBox = m_wmsViewProperties.getViewBBox();
			var f_horizontalPixelSize: Number = currentViewBBox.width / i_width;
			var f_verticalPixelSize: Number = currentViewBBox.height / i_height;
			var projection: Projection = Projection.getByCRS(s_currentCRS);
			var parts: Array = m_layer.container.mapBBoxToProjectionExtentParts(currentViewBBox);
			//			var parts: Array = container.mapBBoxToViewParts(projection.extentBBox);
			//		var dimensions: Array = m_layer.getDimensionForCache(m_wmsViewProperties);
			for each (var partBBoxToUpdate: BBox in parts)
			{
				updateDataPart(m_wmsViewProperties,
						partBBoxToUpdate,
						uint(Math.round(partBBoxToUpdate.width / f_horizontalPixelSize)),
						uint(Math.round(partBBoxToUpdate.height / f_verticalPixelSize)),
						printQuality,
						b_forceUpdate);
			}
		}

		/**
		 * Function checks if part is cached already (if b_forceUpdate is true). If part is not cache, function will load view part.
		 * Function is similar to isPartCached, only difference is, that updateDataPart load data if part is not cached.
		 *
		 * @param s_currentCRS
		 * @param currentViewBBox
		 * @param dimensions
		 * @param i_width
		 * @param i_height
		 * @param b_forceUpdate if TRUE, data is forced to load even if they are cached
		 *
		 */
		private function updateDataPart(wmsViewProperties: WMSViewProperties, currentViewBBox: BBox, i_width: uint, i_height: uint, s_printQuality: String, b_forceUpdate: Boolean): void
		{
			var wmsLayerConfiguration: WMSLayerConfiguration = (m_layer.configuration as WMSLayerConfiguration);
			
			var bbox: String;
			if (Projection.hasCRSAxesFlippedByISO(wmsViewProperties.crs, wmsLayerConfiguration.service.version))
			{
				bbox = String(currentViewBBox.yMin) + "," + String(currentViewBBox.xMin) + "," + String(currentViewBBox.yMax) + "," + String(currentViewBBox.xMax);	
			} else {
				bbox = currentViewBBox.toBBOXString();
			}
			var request: URLRequest = wmsLayerConfiguration.toGetMapRequest(
					wmsViewProperties.crs, bbox,
					i_width, i_height,
					s_printQuality,
					m_layer.getWMSStyleListString());
			if (!request)
				return;
			
			wmsViewProperties.updateDimensionsInURLRequest(request);
			wmsViewProperties.updateCustomParametersInURLRequest(request);
			wmsViewProperties.url = request;
			
			var img: DisplayObject = null;
			var wmsCache: WMSCache = m_layer.getCache() as WMSCache;
			var cacheItem: CacheItem;
			var imagePart: ImagePart = new ImagePart();
			
			imagePart.mi_updateCycleAge = mi_updateCycleAge;
			imagePart.ms_imageCRS = wmsViewProperties.crs;
			imagePart.m_imageBBox = currentViewBBox;
			if (!b_forceUpdate)
			{
				//			var itemMetadata: CacheItemMetadata = new CacheItemMetadata();
				//			itemMetadata.crs = s_currentCRS;
				//			itemMetadata.bbox = currentViewBBox;
				//			itemMetadata.url = request;
				//			itemMetadata.dimensions = dimensions;
				var isItemLoading: Boolean = wmsCache.isItemLoading(wmsViewProperties, true);
				var isCached: Boolean = wmsCache.isItemCached(wmsViewProperties, true);
				var isNoDataCached: Boolean = wmsCache.isNoDataItemCached(wmsViewProperties);
				var imgTest: DisplayObject = wmsCache.getCacheItemBitmap(wmsViewProperties);
				if (isItemLoading && !isNoDataCached)
				{
					m_wmsViewProperties = wmsViewProperties;
					m_imagePart = imagePart;
					cacheItem = wmsCache.getCacheItem(wmsViewProperties);
					wmsCache.addEventListener(WMSCacheEvent.ITEM_ADDED, onCacheItemLoaded);
					return;
				}
				if (isCached && isNoDataCached && imgTest == null)
				{
					//is cached, but no data, do not load anything (it's data which was loaded before, but exception was returned, so we cached this info
					// invalidate property "displayed" for cached items		
					wmsCache.removeFromScreen();
					notifyLoadingFinishedNoSynchronizationData(null);
					return;
				}
				if (isCached && imgTest != null)
					img = imgTest;
			}
			else
			{
				// invalidate property "displayed" for cached items		
				wmsCache.removeFromScreen();
			}
			if (img == null)
			{
				//image is not cached
				wmsViewProperties.url = request;
				ma_requests.addItem(request);
				if (ma_requests.length == 1)
					notifyLoadingStart(false);
				
				var forecast: Object = wmsViewProperties.getWMSDimensionValue('FORECAST');
				var timeString: String = '';
				
				var jobName: String = "Rendering " + (m_layer.configuration as IWMSLayerConfiguration).layerNames.join("+");
				if (forecast)
				{
					jobName += "["+forecast+"]";
				}
				
				if (_delayedRequestArray.length > 0)
				{
					trace("there is _delayedRequestObject still, which was not executed yet");
				}
				_delayedRequestArray.push({request: request, wmsViewProperties: wmsViewProperties, wmsCache: wmsCache, imagePart: imagePart, jobName: jobName});
				m_layer.addEventListener(Event.ENTER_FRAME, startLoadingOnNextFrame);
				
			}
			else
			{
				notifyLoadingStart(false);
				
				//image is cached
				cacheItem = wmsCache.getCacheItem(wmsViewProperties);
				var key: String;
				if (cacheItem && cacheItem.cacheKey)
					key = cacheItem.cacheKey.key;
				
				addImagePart(wmsViewProperties, imagePart, img, key);
				onFinishedRequest(wmsViewProperties, null);
				invalidateDynamicPart();
				
				if (_delayedCachedRequestArray.length > 0)
				{
					trace("there is _delayedCachedRequestObject still, which was not executed yet");
				}
				_delayedCachedRequestArray.push({wmsViewProperties: wmsViewProperties});
				m_layer.addEventListener(Event.ENTER_FRAME, dispatchLoadingFinishedFromCacheOnNextFrame);
				
			}
		}
		
		private function dispatchLoadingFinishedFromCacheOnNextFrame(event: Event): void
		{
			m_layer.removeEventListener(Event.ENTER_FRAME, dispatchLoadingFinishedFromCacheOnNextFrame);
			if (_delayedCachedRequestArray)
			{
				while (_delayedCachedRequestArray.length > 0)
				{
					var cachedObject: Object = _delayedCachedRequestArray.shift();
					notifyLoadingFinishedFromCache({wmsViewProperties: cachedObject.wmsViewProperties});
				}
			}
		}
		
		private function startLoadingOnNextFrame(event: Event): void
		{
			m_layer.removeEventListener(Event.ENTER_FRAME, startLoadingOnNextFrame);
			if (_delayedRequestArray)
			{
				while (_delayedRequestArray.length > 0)
				{
					var cachedObject: Object = _delayedRequestArray.shift();
					startLoading(cachedObject.request, cachedObject.wmsViewProperties, cachedObject.wmsCache, cachedObject.imagePart, cachedObject.jobName);
				}
			}
		}

		private function startLoading(request: URLRequest, wmsViewProperties: WMSViewProperties, wmsCache: WMSCache, imagePart: ImagePart, jobName: String): void
		{
				m_loader.load(request,
						{requestedImagePart: imagePart, wmsViewProperties: wmsViewProperties},
						jobName);
				invalidateDynamicPart();
				//			wmsCache.startImageLoading(s_currentCRS, currentViewBBox, request, dimensions);
				wmsCache.startImageLoading(wmsViewProperties);
		}
		
		private function onCacheItemLoaded(event: WMSCacheEvent): void
		{
			var wmsCache: WMSCache = event.target as WMSCache;
			var item: CacheItem = event.item;
			var wmsViewProperties: WMSViewProperties = m_wmsViewProperties;
			
			wmsCache.removeEventListener(WMSCacheEvent.ITEM_ADDED, onCacheItemLoaded);
			
			var imagePart: ImagePart = m_imagePart;
			var result: * = item.image;
			imagePart.mi_updateCycleAge = mi_updateCycleAge;
			addImagePart(wmsViewProperties, imagePart, result, item.cacheKey.key);
			
			onFinishedRequest(m_wmsViewProperties, null);
			invalidateDynamicPart();
			
			notifyLoadingFinishedFromCache(event.associatedData);
		}

		protected function notifyLoadingStart(associatedData: Object): void
		{
			var e: InteractiveLayerEvent = new InteractiveLayerEvent(InteractiveDataLayer.LOADING_STARTED, true);
			e.data = associatedData;
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

		protected function notifyLoadingFinishedFromCache(associatedData: Object): void
		{
			var e: InteractiveLayerEvent = new InteractiveLayerEvent(InteractiveDataLayer.LOADING_FINISHED_FROM_CACHE, true);
			e.data = associatedData;
			dispatchEvent(e);
		}
		protected function notifyLoadingFinished(associatedData: Object): void
		{
			var e: InteractiveLayerEvent = new InteractiveLayerEvent(InteractiveDataLayer.LOADING_FINISHED, true);
			e.data = associatedData;
			dispatchEvent(e);
		}
		protected function notifyLoadingFinishedWithErrors(associatedData: Object): void
		{
			var e: InteractiveLayerEvent = new InteractiveLayerEvent(InteractiveDataLayer.LOADING_ERROR);
			e.data = associatedData;
			dispatchEvent(e);
		}
		protected function notifyLoadingFinishedNoSynchronizationData(associatedData: Object): void
		{
			var e: InteractiveLayerEvent = new InteractiveLayerEvent(InteractiveDataLayer.LOADING_FINISHED_NO_SYNCHRONIZATION_DATA);
			e.data = associatedData;
			dispatchEvent(e);
		}

		private function addImagePart(wmsViewProperties: WMSViewProperties, imagePart: ImagePart, img: DisplayObject, cacheKey: String): void
		{
			//image is cached
			var imageParts: ArrayCollection = wmsViewProperties.imageParts;
			if (imageParts)
			{
				// found in the cache
				imagePart.image = img;
				imagePart.mb_imageOK = true;
				imagePart.ms_cacheKey = cacheKey;
				
				var total: int = imageParts.length;
				if (total > 0)
				{
					for (var i: int = 0; i < total; )
					{
						var currImagePart: ImagePart = imageParts.getItemAt(i) as ImagePart;
						if (imagePart.intersectsOrHasDifferentCRS(currImagePart))
						{
							imageParts.removeItemAt(i);
							total--;
						}
						else
							++i;
					}
				}
				wmsViewProperties.addImagePart(imagePart);
			}
		}

		// Event handlers
		private function onDataProgress(event: ProgressEvent): void
		{
			if (!m_layer.layerWasDestroyed)
				notifyProgress(event.bytesLoaded, event.bytesTotal, InteractiveLayerProgressEvent.UNIT_BYTES);
		}

		private function onDataLoaded(event: UniURLLoaderEvent): void
		{
			if (!m_layer.layerWasDestroyed)
			{
				//		super.onDataLoaded(event);
				var wmsViewProperties: WMSViewProperties = event.associatedData.wmsViewProperties as WMSViewProperties;
				var imagePart: ImagePart = event.associatedData.requestedImagePart;
				var wmsCache: WMSCache = m_layer.getCache() as WMSCache;
				/* FIXME:
				if (_invalidateCacheAfterImageLoad)
				{
				wmsCache.invalidate(ms_imageCRS, m_imageBBox);
				_invalidateCacheAfterImageLoad = false;
				}
				*/
				var result: * = event.result;
				event.associatedData.result = result;
				var bError:  Boolean;
				
				if (result is DisplayObject)
				{
					var cacheItem: CacheItem = wmsCache.getCacheItem(wmsViewProperties);
					var key: String;
					if (cacheItem && cacheItem.cacheKey)
						key = cacheItem.cacheKey.key;
					
					imagePart.mi_updateCycleAge = mi_updateCycleAge;
					addImagePart(wmsViewProperties, imagePart, result, key);
					wmsViewProperties.url = event.request;
					wmsCache.addCacheItem(imagePart.image, wmsViewProperties, event.associatedData);
					invalidateDynamicPart();
					
				}
				else
				{
					notifyLoadingFinishedWithErrors(event.associatedData);
					
					ExceptionUtils.logError(Log.getLogger("WMS"), result,
							"Error accessing layer(s) '" + (m_layer.configuration as IWMSLayerConfiguration).layerNames.join(",") + "' - unexpected response type")
				}
				var bFinishedAll: Boolean = onFinishedRequest(wmsViewProperties, event.request);
				if (bFinishedAll)
				{
					//notify layer that data was loaded
					notifyLoadingFinished(event.associatedData);
				}
			}
		}

		private function onFinishedRequest(wmsViewProperties: WMSViewProperties, request: URLRequest): Boolean
		{
			if (request)
			{
				var id: int = ma_requests.getItemIndex(request);
				if (id > -1)
					ma_requests.removeItemAt(id);
			}
			if (ma_requests.length == 0)
			{
				var imageParts: ArrayCollection = wmsViewProperties.imageParts;
				for (var i: int = 0; i < imageParts.length; )
				{
					var imagePart: ImagePart = imageParts.getItemAt(i) as ImagePart;
					if (imagePart.mi_updateCycleAge < mi_updateCycleAge)
						imageParts.removeItemAt(i);
					else
						++i;
				}
				// finished loading of all requests
				return true;
			}
			return false;
		}

		private function onDataLoadFailed(event: UniURLLoaderErrorEvent): void
		{
			if (!m_layer.layerWasDestroyed)
			{
				// event is null if this method was called internally by this class
				//		super.onDataLoadFailed(event);
				var wmsViewProperties: WMSViewProperties = event.associatedData.wmsViewProperties;
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
								m_layer.getCache().addCacheNoDataItem(wmsViewProperties);
								
								ExceptionUtils.logError(Log.getLogger("WMS"), associatedData.errorResult,
									"Failed to apply value '" + (m_layer.configuration as IWMSLayerConfiguration).layerNames.join(",") + "'");
								
								notifyLoadingFinishedNoSynchronizationData(event.associatedData);
								errorStateSet = true;
							}
						}
					}
					
					if (!errorStateSet)
						notifyLoadingFinishedWithErrors(event.associatedData);
					
				}
				var imagePart: ImagePart = event.associatedData.requestedImagePart;
				imagePart.image = null;
				imagePart.mb_imageOK = false;
				imagePart.ms_cacheKey = null;
				invalidateDynamicPart();
				onFinishedRequest(wmsViewProperties, event.request);
			}
		}

		private function invalidateDynamicPart(b_invalid: Boolean = true): void
		{
			var de: DynamicEvent = new DynamicEvent(InteractiveLayerEvent.INVALIDATE_DYNAMIC_PART);
			de["invalid"] = b_invalid;
			dispatchEvent(de);
		}

		private function getDimensionForCache(wmsViewProperties: WMSViewProperties): Array
		{
			var dimNames: Array = wmsViewProperties.getWMSDimensionsNames();
			if (dimNames && dimNames.length > 0)
			{
				var ret: Array = [];
				for each (var dimName: String in dimNames)
				{
					var value: Object = wmsViewProperties.getWMSDimensionValue(dimName);
					if (value)
						ret.push({name: dimName, value: value});
					else
						ret.push({name: dimName, value: null});
				}
				return ret;
			}
			return null;
		}

		public function loadLegend(url: URLRequest, associatedData: Object): void
		{
			var legendLoader: WMSImageLoader = new WMSImageLoader();
			legendLoader.addEventListener(UniURLLoaderEvent.DATA_LOADED, onLegendLoaded);
			legendLoader.addEventListener(UniURLLoaderErrorEvent.DATA_LOAD_FAILED, onLegendLoadFailed);
			legendLoader.load(url, associatedData);
		}

		private function removeLegendListeners(legendLoader: WMSImageLoader): void
		{
			legendLoader.removeEventListener(UniURLLoaderEvent.DATA_LOADED, onLegendLoaded);
			legendLoader.removeEventListener(UniURLLoaderErrorEvent.DATA_LOAD_FAILED, onLegendLoadFailed);
		}

		/**
		 * Function which handle legend load
		 * @param event
		 *
		 */
		protected function onLegendLoaded(event: UniURLLoaderEvent): void
		{
			var result: * = event.result;
			if (result is Bitmap)
			{
				var useCache: Boolean = event.associatedData.useCache;
				var legendScaleX: Number = event.associatedData.legendScaleX;
				var legendScaleY: Number = event.associatedData.legendScaleY;
				var e: MSBaseLoaderEvent = new MSBaseLoaderEvent(MSBaseLoaderEvent.LEGEND_LOADED);
				e.data = {result: result, associatedData: event.associatedData};
				dispatchEvent(e);
					//			if (useCache)
					//				m_legendImage = result;
					//			createLegend(result, event.associatedData.group, event.associatedData.labelAlign, event.associatedData.callback, legendScaleX, legendScaleY, event.associatedData.width, event.associatedData.height);
			}
			removeLegendListeners(event.target as WMSImageLoader);
		}

		protected function onLegendLoadFailed(event: UniURLLoaderErrorEvent): void
		{
			removeLegendListeners(event.target as WMSImageLoader);
		}
	}
}
