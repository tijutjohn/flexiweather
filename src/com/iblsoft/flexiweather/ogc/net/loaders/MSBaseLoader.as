package com.iblsoft.flexiweather.ogc.net.loaders
{
	import com.iblsoft.flexiweather.events.InteractiveLayerEvent;
	import com.iblsoft.flexiweather.events.InteractiveLayerProgressEvent;
	import com.iblsoft.flexiweather.net.events.UniURLLoaderErrorEvent;
	import com.iblsoft.flexiweather.net.events.UniURLLoaderEvent;
	import com.iblsoft.flexiweather.ogc.BBox;
	import com.iblsoft.flexiweather.ogc.ExceptionUtils;
	import com.iblsoft.flexiweather.ogc.configuration.layers.interfaces.IWMSLayerConfiguration;
	import com.iblsoft.flexiweather.ogc.InteractiveLayerMSBase;
	import com.iblsoft.flexiweather.ogc.cache.CacheItem;
	import com.iblsoft.flexiweather.ogc.cache.WMSCache;
	import com.iblsoft.flexiweather.ogc.cache.event.WMSCacheEvent;
	import com.iblsoft.flexiweather.ogc.data.viewProperties.IViewProperties;
	import com.iblsoft.flexiweather.ogc.data.viewProperties.IWMSViewPropertiesLoader;
	import com.iblsoft.flexiweather.ogc.data.ImagePart;
	import com.iblsoft.flexiweather.ogc.data.viewProperties.WMSViewProperties;
	import com.iblsoft.flexiweather.ogc.events.MSBaseLoaderEvent;
	import com.iblsoft.flexiweather.proj.Projection;
	import com.iblsoft.flexiweather.widgets.InteractiveDataLayer;
	import flash.display.Bitmap;
	import flash.display.DisplayObject;
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

		public function MSBaseLoader(layer: InteractiveLayerMSBase)
		{
			uid++;
			id = uid;
			m_layer = layer;
			m_loader = new WMSImageLoader();
			m_loader.addEventListener(UniURLLoaderEvent.DATA_LOADED, onDataLoaded);
			m_loader.addEventListener(ProgressEvent.PROGRESS, onDataProgress);
			m_loader.addEventListener(UniURLLoaderErrorEvent.DATA_LOAD_FAILED, onDataLoadFailed);
		}

		override public function toString(): String
		{
			return "MSBaseLoader [" + id + "]";
		}

		public function destroy(): void
		{
			m_loader.removeEventListener(UniURLLoaderEvent.DATA_LOADED, onDataLoaded);
			m_loader.removeEventListener(ProgressEvent.PROGRESS, onDataProgress);
			m_loader.removeEventListener(UniURLLoaderErrorEvent.DATA_LOAD_FAILED, onDataLoadFailed);
			m_loader = null;
		}

		/**
		 * Check if WMS data are cached (only if b_forceUpdate is true) and load any data parts which are missing.
		 *
		 *
		 * @param b_forceUpdate if TRUE, data is forced to load even if they are cached
		 *
		 */
		public function updateWMSData(b_forceUpdate: Boolean, viewProperties: IViewProperties, forcedLayerWidth: Number, forcedLayerHeight: Number): void
		{
			m_wmsViewProperties = viewProperties as WMSViewProperties;
			//check if data are not already cached
			//			super.updateData(b_forceUpdate);
			++mi_updateCycleAge;
			if (ma_requests.length > 0)
			{
				for each (var request: URLRequest in ma_requests)
				{
					m_loader.cancel(request);
				}
				ma_requests.removeAll();
			}
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
		private function updateDataPart(wmsViewProperties: WMSViewProperties, currentViewBBox: BBox, i_width: uint, i_height: uint, b_forceUpdate: Boolean): void
		{
			var request: URLRequest = (m_layer.configuration as IWMSLayerConfiguration).toGetMapRequest(
					wmsViewProperties.crs, currentViewBBox.toBBOXString(),
					i_width, i_height,
					m_layer.getWMSStyleListString());
			if (!request)
				return;
			wmsViewProperties.updateDimensionsInURLRequest(request);
			wmsViewProperties.updateCustomParametersInURLRequest(request);
			wmsViewProperties.url = request;
			var img: DisplayObject = null;
			var wmsCache: WMSCache = m_layer.getCache() as WMSCache;
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
				var imgTest: DisplayObject = wmsCache.getCacheItemBitmap(wmsViewProperties);
				if (isItemLoading)
				{
					trace(" updateDataPart  isItemLoading = true [" + this + "/" + wmsViewProperties.parentLayer + "]");
					m_wmsViewProperties = wmsViewProperties;
					m_imagePart = imagePart;
					var cacheItem: CacheItem = wmsCache.getCacheItem(wmsViewProperties);
					wmsCache.addEventListener(WMSCacheEvent.ITEM_ADDED, onCacheItemLoaded);
					return;
				}
				if (isCached && imgTest == null)
				{
					//is cached, but no data, do not load anything (it's data which was loaded before, but exception was returned, so we cached this info
					// invalidate property "displayed" for cached items		
					wmsCache.removeFromScreen();
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
				m_loader.load(request,
						{requestedImagePart: imagePart, wmsViewProperties: wmsViewProperties},
						"Rendering " + (m_layer.configuration as IWMSLayerConfiguration).layerNames.join("+"));
				invalidateDynamicPart();
				//			wmsCache.startImageLoading(s_currentCRS, currentViewBBox, request, dimensions);
				wmsCache.startImageLoading(wmsViewProperties);
			}
			else
			{
				//image is cached
				addImagePart(wmsViewProperties, imagePart, img);
				onFinishedRequest(wmsViewProperties, null);
				invalidateDynamicPart();
				notifyLoadingFinishedFromCache(null);
			}
		}

		private function onCacheItemLoaded(event: WMSCacheEvent): void
		{
//			trace("\n\n" + this + " onCacheItemLoaded");
			var wmsCache: WMSCache = event.target as WMSCache;
			var item: CacheItem = event.item;
			wmsCache.removeEventListener(WMSCacheEvent.ITEM_ADDED, onCacheItemLoaded);
			//		super.onDataLoaded(event);
			var wmsViewProperties: WMSViewProperties = m_wmsViewProperties;
			var imagePart: ImagePart = m_imagePart;
			var result: * = item.image;
//			event.associatedData.result = result;
			imagePart.mi_updateCycleAge = mi_updateCycleAge;
			addImagePart(wmsViewProperties, imagePart, result);
//				wmsViewProperties.url = event.request;
//				wmsCache.addCacheItem( item.image, wmsViewProperties);
//				invalidateDynamicPart();
//			var bFinishedAll: Boolean = onFinishedRequest(wmsViewProperties, event.request);
//			if (bFinishedAll)
//			{
//				//notify layer that data was loaded
//				notifyLoadingFinished(event.associatedData);	
//			}
			onFinishedRequest(m_wmsViewProperties, null);
			invalidateDynamicPart();
			
			notifyLoadingFinishedFromCache(event.associatedData);
		}

		protected function notifyLoadingStart(associatedData: Object): void
		{
			var e: InteractiveLayerEvent = new InteractiveLayerEvent(InteractiveDataLayer.LOADING_STARTED);
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
			var e: InteractiveLayerEvent = new InteractiveLayerEvent(InteractiveDataLayer.LOADING_FINISHED_FROM_CACHE);
			e.data = associatedData;
			dispatchEvent(e);
		}
		protected function notifyLoadingFinished(associatedData: Object): void
		{
			var e: InteractiveLayerEvent = new InteractiveLayerEvent(InteractiveDataLayer.LOADING_FINISHED);
			e.data = associatedData;
			dispatchEvent(e);
		}

		private function addImagePart(wmsViewProperties: WMSViewProperties, imagePart: ImagePart, img: DisplayObject): void
		{
			//image is cached
			var imageParts: ArrayCollection = wmsViewProperties.imageParts;
			if (imageParts)
			{
				// found in the cache
				imagePart.m_image = img;
				imagePart.mb_imageOK = true;
				var total: int = imageParts.length;
				if (total > 0)
				{
					for (var i: int = 0; i < total; )
					{
						var currImagePart: ImagePart = imageParts.getItemAt(i) as ImagePart;
						if (imagePart.intersectsOrHasDifferentCRS(currImagePart))
						{
							//						trace("InteractiveLayerWMS.updateDataPart(): removing old " + i + " part "
							//							+ ImagePart(ma_imageParts[i]).ms_imageCRS + ": "
							//							+ ImagePart(ma_imageParts[i]).m_imageBBox.toString()
							//							+ " will remain " + (ma_imageParts.length - 1) + " part(s)");
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
				//			trace("InteractiveLayerWMS.onDataLoaded(): received part "
				//					+ imagePart.ms_imageCRS + ": "
				//					+ imagePart.m_imageBBox.toString());
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
				if (result is DisplayObject)
				{
					imagePart.mi_updateCycleAge = mi_updateCycleAge;
					addImagePart(wmsViewProperties, imagePart, result);
					wmsViewProperties.url = event.request;
					wmsCache.addCacheItem(imagePart.m_image, wmsViewProperties, event.associatedData);
					invalidateDynamicPart();
					notifyLoadingFinishedFromCache(event.associatedData);
					return;
				}
				else
				{
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
				var total: int = imageParts.length;
				for (var i: int = 0; i < total; )
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
							}
						}
					}
				}
				var imagePart: ImagePart = event.associatedData.requestedImagePart;
				imagePart.m_image = null;
				imagePart.mb_imageOK = false;
				invalidateDynamicPart();
				onFinishedRequest(wmsViewProperties, event.request);
			}
		}

		private function invalidateDynamicPart(b_invalid: Boolean = true): void
		{
//			trace("\t MSBaseLoader invalidateDynamicPart: " + id);
			var de: DynamicEvent = new DynamicEvent("invalidateDynamicPart");
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
