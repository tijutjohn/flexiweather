package com.iblsoft.flexiweather.ogc.data
{
	import com.iblsoft.flexiweather.net.events.UniURLLoaderErrorEvent;
	import com.iblsoft.flexiweather.net.events.UniURLLoaderEvent;
	import com.iblsoft.flexiweather.ogc.BBox;
	import com.iblsoft.flexiweather.ogc.ExceptionUtils;
	import com.iblsoft.flexiweather.ogc.InteractiveLayerWMS;
	import com.iblsoft.flexiweather.ogc.SynchronisationRole;
	import com.iblsoft.flexiweather.ogc.SynchronisedVariableChangeEvent;
	import com.iblsoft.flexiweather.ogc.WMSDimension;
	import com.iblsoft.flexiweather.ogc.WMSLayer;
	import com.iblsoft.flexiweather.ogc.WMSLayerConfiguration;
	import com.iblsoft.flexiweather.ogc.cache.CacheItemMetadata;
	import com.iblsoft.flexiweather.ogc.cache.ICache;
	import com.iblsoft.flexiweather.ogc.cache.WMSCache;
	import com.iblsoft.flexiweather.ogc.net.loaders.WMSImageLoader;
	import com.iblsoft.flexiweather.proj.Coord;
	import com.iblsoft.flexiweather.proj.Projection;
	import com.iblsoft.flexiweather.utils.ArrayUtils;
	import com.iblsoft.flexiweather.utils.Duration;
	import com.iblsoft.flexiweather.utils.ISO8601Parser;
	import com.iblsoft.flexiweather.utils.Serializable;
	import com.iblsoft.flexiweather.utils.Storage;
	import com.iblsoft.flexiweather.widgets.GlowLabel;
	import com.iblsoft.flexiweather.widgets.InteractiveDataLayer;
	import com.iblsoft.flexiweather.widgets.InteractiveLayer;
	import com.iblsoft.flexiweather.widgets.InteractiveWidget;
	
	import flash.display.AVM1Movie;
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.DisplayObject;
	import flash.display.Graphics;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.geom.Matrix;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.net.URLRequest;
	import flash.net.URLVariables;
	import flash.utils.Dictionary;
	import flash.utils.Timer;
	
	import mx.collections.ArrayCollection;
	import mx.containers.Canvas;
	import mx.controls.Image;
	import mx.core.UIComponent;
	import mx.events.DynamicEvent;
	import mx.logging.Log;

	public class WMSViewProperties extends InteractiveDataLayer implements Serializable
	{
		public var cache: ICache;
		
		protected var m_cfg: WMSLayerConfiguration;
		protected var md_dimensionValues: Dictionary = new Dictionary();
		protected var md_customParameters: Dictionary = new Dictionary(); 
		protected var ma_subLayerStyleNames: Array = [];
		
		/**
		 * Bitmap image holder for legend 
		 */
		protected var m_legendImage: Bitmap = null;
		
		
		protected var ma_requests: ArrayCollection = new ArrayCollection(); // of URLRequest
		protected var ma_imageParts: ArrayCollection = new ArrayCollection(); // of ImagePart
		protected var mi_updateCycleAge: uint = 0;
		
		public function imageParts(): ArrayCollection
		{
			return ma_imageParts;
		}
		
		public function WMSViewProperties(container:InteractiveWidget)
		{
			super(container);
		}
		
		public function setConfiguration(cfg: WMSLayerConfiguration): void
		{
			m_cfg = cfg;
		}
		
		
		public function serialize(storage: Storage): void
		{
			//super.serialize(storage);
			var s_dimName: String;
			
			var styleName: String;
			if (storage.isLoading())
			{
				styleName = storage.serializeString("style-name", name);
				if (styleName)
					setWMSStyleName(0, styleName);
				
				for each(s_dimName in getWMSDimensionsNames()) {
					var level: String = storage.serializeString(s_dimName, null, null);
					if (level)
						setWMSDimensionValue('ELEVATION', level );
				}
				
			} else {
				styleName = getWMSStyleName(0);
				if (styleName)
					storage.serializeString("style-name", styleName, null);
				
				for each(s_dimName in getWMSDimensionsNames()) {
					if (s_dimName.toLowerCase() == 'elevation')
						storage.serializeString('level', getWMSDimensionValue(s_dimName), null);
				}
			}
		}
		
		/**
		 * Return true is viewProperties is same 
		 *  
		 * @param viewProperties
		 * @return 
		 * 
		 */		
		public function equals(viewProperties: WMSViewProperties): Boolean
		{
			var currDimNames: Array = getWMSDimensionsNames();
			var dimNames: Array = viewProperties.getWMSDimensionsNames();
			
			if (!dimNames || !currDimNames)
				return false;
			
			if (dimNames && currDimNames && dimNames.length != currDimNames.length)
				return false;
			
			//check dimensions names
			dimNames.sort();
			currDimNames.sort();
			var total: int = dimNames.length;
			for (var i: int = 0; i < total; i++)
			{
				var dimName: String = dimNames[i] as String; 
				var currDimName: String = currDimNames[i] as String; 
				if (dimName != currDimName)
					return false;
				
				var dimValue: Object = getWMSDimensionValue(dimName);
				var currDimValue: Object = viewProperties.getWMSDimensionValue(dimName);
				
				if (dimValue != currDimValue)
					return false;
			}
			
			return true;
		}
		
		private function getDimensionForCache(): Array
		{
			var dimNames: Array = getWMSDimensionsNames();
			if (dimNames && dimNames.length > 0)
			{
				var ret: Array = [];
				for each (var dimName: String in dimNames)
				{
					var value: Object = getWMSDimensionValue(dimName);
					if (value)
						ret.push({name: dimName, value: value});
					else 
						ret.push({name: dimName, value: null});
				}
				return ret;
			}
			return null;
		}
		
		/**
		 * Check if WMS data are cached (only if b_forceUpdate is true) and load any data parts which are missing.
		 * 
		 *  
		 * @param b_forceUpdate if TRUE, data is forced to load even if they are cached
		 * 
		 */		
		public function updateWMSData(b_forceUpdate: Boolean): void
		{
			//check if data are not already cached
			
//			super.updateData(b_forceUpdate);
			++mi_updateCycleAge;
			
			if(ma_requests.length > 0) {
				for each(var request: URLRequest in ma_requests)
				m_loader.cancel(request);
				ma_requests.removeAll();
			}
			
			
			var i_width: int = int(container.width);
			var i_height: int = int(container.height);
			
			if (forcedLayerWidth > 0)
				i_width = forcedLayerWidth;
			if (forcedLayerHeight > 0)
				i_height = forcedLayerHeight;
			
			var s_currentCRS: String = container.getCRS();
			var currentViewBBox: BBox = container.getViewBBox();
			
			var f_horizontalPixelSize: Number = currentViewBBox.width / i_width;
			var f_verticalPixelSize: Number = currentViewBBox.height / i_height;
			
			var projection: Projection = Projection.getByCRS(s_currentCRS);
			var parts: Array = container.mapBBoxToProjectionExtentParts(currentViewBBox);
			//			var parts: Array = container.mapBBoxToViewParts(projection.extentBBox);
			var dimensions: Array = getDimensionForCache();
			
			for each(var partBBoxToUpdate: BBox in parts) {
				updateDataPart(
					s_currentCRS, partBBoxToUpdate,
					dimensions,
					uint(Math.round(partBBoxToUpdate.width / f_horizontalPixelSize)),
					uint(Math.round(partBBoxToUpdate.height / f_verticalPixelSize)),
					b_forceUpdate);
			}
		}
		
		/**
		 * Function similar to updateWMSData, only difference is that funciton isCached does not load any data 
		 * @return 
		 * 
		 */		
		public function isCached(): Boolean
		{
			var i_width: int = int(container.width);
			var i_height: int = int(container.height);
			
			if (forcedLayerWidth > 0)
				i_width = forcedLayerWidth;
			if (forcedLayerHeight > 0)
				i_height = forcedLayerHeight;
			
			var s_currentCRS: String = container.getCRS();
			var currentViewBBox: BBox = container.getViewBBox();
			
			var f_horizontalPixelSize: Number = currentViewBBox.width / i_width;
			var f_verticalPixelSize: Number = currentViewBBox.height / i_height;
			
			var projection: Projection = Projection.getByCRS(s_currentCRS);
			var parts: Array = container.mapBBoxToProjectionExtentParts(currentViewBBox);
			//			var parts: Array = container.mapBBoxToViewParts(projection.extentBBox);
			var dimensions: Array = getDimensionForCache();
			
			var isCached: Boolean = true;
			for each(var partBBoxToUpdate: BBox in parts) {
				var isPartCached: Boolean = isPartCached(
									s_currentCRS, partBBoxToUpdate,
									dimensions,
									uint(Math.round(partBBoxToUpdate.width / f_horizontalPixelSize)),
									uint(Math.round(partBBoxToUpdate.height / f_verticalPixelSize))
								);
				if (!isPartCached)
					return false;
			}
			
			//all parts are cached, so all WMS view properties are cached
			return true;
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
		private function isPartCached(s_currentCRS: String, currentViewBBox: BBox, dimensions: Array, i_width: uint, i_height: uint): Boolean
		{
			/**
			 * this is how you can find properties for cache metadata
			 * 
			 * var s_currentCRS: String = container.getCRS();
			 * var currentViewBBox: BBox = container.getViewBBox();
			 * var dimensions: Array = getDimensionForCache();
			 */
			
			var request: URLRequest = m_cfg.toGetMapRequest(
				s_currentCRS, currentViewBBox.toBBOXString(),
				i_width, i_height,
				getWMSStyleListString());
			
			if (!request)
				return false;
			
			updateDimensionsInURLRequest(request);
			updateCustomParametersInURLRequest(request);
			
			var wmsCache: WMSCache = cache as WMSCache;
			
//			var img: Bitmap = null;
			
			var itemMetadata: CacheItemMetadata = new CacheItemMetadata();
			itemMetadata.crs = s_currentCRS;
			itemMetadata.bbox = currentViewBBox;
			itemMetadata.url = request;
			itemMetadata.dimensions = dimensions;
			
			var isCached: Boolean = wmsCache.isItemCached(itemMetadata)
			var imgTest: DisplayObject = wmsCache.getCacheItemBitmap(itemMetadata);
			if (isCached && imgTest != null) {
				return true;
			}
			return false;
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
		private function updateDataPart(s_currentCRS: String, currentViewBBox: BBox, dimensions: Array, i_width: uint, i_height: uint, b_forceUpdate: Boolean): void
		{
			var request: URLRequest = m_cfg.toGetMapRequest(
				s_currentCRS, currentViewBBox.toBBOXString(),
				i_width, i_height,
				getWMSStyleListString());
			
			if (!request)
				return;
			
			updateDimensionsInURLRequest(request);
			updateCustomParametersInURLRequest(request);
			
			var img: DisplayObject = null;
			
			var wmsCache: WMSCache = cache as WMSCache;
			if(!b_forceUpdate)
			{
				var itemMetadata: CacheItemMetadata = new CacheItemMetadata();
				itemMetadata.crs = s_currentCRS;
				itemMetadata.bbox = currentViewBBox;
				itemMetadata.url = request;
				itemMetadata.dimensions = dimensions;
				
				var isCached: Boolean = wmsCache.isItemCached(itemMetadata)
				var imgTest: DisplayObject = wmsCache.getCacheItemBitmap(itemMetadata);
				if (isCached && imgTest != null) {
					img = imgTest;
				}
			} else {
				// invalidate property "displayed" for cached items		
				wmsCache.removeFromScreen();
			}
			
			var imagePart: ImagePart = new ImagePart();
			imagePart.mi_updateCycleAge = mi_updateCycleAge;
			imagePart.ms_imageCRS = s_currentCRS;
			imagePart.m_imageBBox = currentViewBBox;
			
			if(img == null) {
				ma_requests.addItem(request);
				if(ma_requests.length == 1) {
					
					//TODO move to InteractiveLayerWMS (listen for loading start)
//					m_autoRefreshTimer.reset();
					
					notifyLoadingStart(false);
				}
				
				m_loader.load(request,
					{ requestedImagePart: imagePart },
					"Rendering " + m_cfg.ma_layerNames.join("+"));
				
				invalidateDynamicPart();
				
				wmsCache.startImageLoading(s_currentCRS, currentViewBBox, request, dimensions);
			}
			else {
				// found in the cache
				imagePart.m_image = img;
				imagePart.mb_imageOK = true;
				for(var i: int = 0; i < ma_imageParts.length; ) {
					if(imagePart.intersectsOrHasDifferentCRS(ma_imageParts[i])) {
//						trace("InteractiveLayerWMS.updateDataPart(): removing old " + i + " part "
//							+ ImagePart(ma_imageParts[i]).ms_imageCRS + ": "
//							+ ImagePart(ma_imageParts[i]).m_imageBBox.toString()
//							+ " will remain " + (ma_imageParts.length - 1) + " part(s)");
						ma_imageParts.removeItemAt(i);
					}
					else
						++i;
				}
				ma_imageParts.addItem(imagePart);
				onFinishedRequest(null);
				invalidateDynamicPart();
			}
		}
		
		override public function invalidateDynamicPart(b_invalid: Boolean = true): void
		{
			var de: DynamicEvent = new DynamicEvent("invalidateDynamicPart");
			de["invalid"] = b_invalid
				
			dispatchEvent(de);
		}
		// Event handlers
		override protected function onDataLoaded(event: UniURLLoaderEvent): void
		{
			super.onDataLoaded(event);
			
			var imagePart: ImagePart = event.associatedData.requestedImagePart;
			//			trace("InteractiveLayerWMS.onDataLoaded(): received part "
			//					+ imagePart.ms_imageCRS + ": "
			//					+ imagePart.m_imageBBox.toString());
			
			var wmsCache: WMSCache = cache as WMSCache;
			/* FIXME:
			if (_invalidateCacheAfterImageLoad)
			{
			wmsCache.invalidate(ms_imageCRS, m_imageBBox);
			_invalidateCacheAfterImageLoad = false;
			}
			*/
			
			var result: * = event.result;
			if(result is DisplayObject) {
				imagePart.m_image = result;
				imagePart.mb_imageOK = true;
				imagePart.mi_updateCycleAge = mi_updateCycleAge;
				
				for(var i: int = 0; i < ma_imageParts.length; ) {
					if(imagePart.intersectsOrHasDifferentCRS(ma_imageParts[i])) {
						//						trace("InteractiveLayerWMS.onDataLoaded(): removing old " + i + " part "
						//							+ ImagePart(ma_imageParts[i]).ms_imageCRS + ": "
						//							+ ImagePart(ma_imageParts[i]).m_imageBBox.toString());
						ma_imageParts.removeItemAt(i);
					}
					else
						++i;
				}
				ma_imageParts.addItem(imagePart);
				var metadata: CacheItemMetadata = new CacheItemMetadata();
				metadata.crs = imagePart.ms_imageCRS;
				metadata.bbox = imagePart.m_imageBBox;
				metadata.url = event.request;
				
				wmsCache.addCacheItem( imagePart.m_image, metadata);
				
				//				wmsCache.addCacheItem(
				//						imagePart.m_image,
				//						imagePart.ms_imageCRS,
				//						imagePart.m_imageBBox,
				//						event.request);
				invalidateDynamicPart();
			}
			else {
				ExceptionUtils.logError(Log.getLogger("WMS"), result,
					"Error accessing layer(s) '" + m_cfg.ma_layerNames.join(",") + "' - unexpected response type")
			}
			
			onFinishedRequest(event.request);
		}
		
		override protected function onDataLoadFailed(event: UniURLLoaderErrorEvent): void
		{
			// event is null if this method was called internally by this class
			super.onDataLoadFailed(event);
			
			var imagePart: ImagePart = event.associatedData.requestedImagePart;
			imagePart.m_image = null;
			imagePart.mb_imageOK = false;
			invalidateDynamicPart();
			onFinishedRequest(event.request);
		}
		
		private function onFinishedRequest(request: URLRequest): void
		{
			if(request)
			{
				var id: int = ma_requests.getItemIndex(request);
				if (id > -1)
					ma_requests.removeItemAt(id);
			}
			
			if(ma_requests.length == 0) {
				for(var i: int = 0; i < ma_imageParts.length; ) {
					if(ma_imageParts[i].mi_updateCycleAge < mi_updateCycleAge) {
						ma_imageParts.removeItemAt(i);
					}
					else
						++i;
				}
				// finished loading of all requests
				
				
			}
		}
		
		public function setWMSDimensionValue(s_dimName: String, s_value: String): void
		{
			if (m_cfg.mb_legendIsDimensionDependant)
			{
				clearLegendCache();
			}
			if(s_value != null)
				md_dimensionValues[s_dimName] = s_value;
			else
				delete md_dimensionValues[s_dimName];

		}
		
		public function getWMSDimensionValue(s_dimName: String,
											 b_returnDefault: Boolean = false): String
		{
			if(s_dimName in md_dimensionValues) 
				return md_dimensionValues[s_dimName];
			else {
				if(b_returnDefault)
					return getWMSDimensionDefaultValue(s_dimName);
				return null;
			}
		}
		
		public function getWMSLayers(): Array
		{
			var a: Array = [];
			for each(var s_layerName: String in m_cfg.ma_layerNames) {
				var layer: WMSLayer = m_cfg.service.getLayerByName(s_layerName);
				if(layer != null)
					a.push(layer);
			}
			return a;
		}
		
		public function supportWMSDimension(s_dimName: String): Boolean
		{
			var a_dimNames: Array = [];
			for each(var layer: WMSLayer in getWMSLayers()) {
				for each(var dim: WMSDimension in layer.dimensions) {
					if(dim.name == s_dimName)
						return true;
				}
			}
			return false;
			
		}
		
		public function getWMSDimensionsNames(): Array
		{
			var a_dimNames: Array = [];
			for each(var layer: WMSLayer in getWMSLayers()) {
				for each(var dim: WMSDimension in layer.dimensions) {
					if(a_dimNames.indexOf(dim.name) < 0)
						a_dimNames.push(dim.name);
				}
			}
			return a_dimNames;
		}
		
		// returns null is no such dimension exist
		public function getWMSDimensionUnitsName(s_dimName: String): String
		{
			var s_units: String = null;
			var b_anyDimensionFound: Boolean = false;
			for each(var layer: WMSLayer in getWMSLayers()) {
				for each(var dim: WMSDimension in layer.dimensions) {
					if(dim.name != s_dimName)
						continue;
					if(dim.units == null)
						continue;
					b_anyDimensionFound = true;
					if(s_units == null)
						s_units = dim.units;
					else {
						if(dim.units != s_units)
							return "mixed units";
					}
				}
			}
			if(b_anyDimensionFound && s_units == null)
				return "no units";
			return s_units;
		}
		
		// returns null is no such dimension exist
		public function getWMSDimensionDefaultValue(s_dimName: String): String
		{
			var s_defaultValue: String = null;
			var b_anyDimensionFound: Boolean = false;
			for each(var layer: WMSLayer in getWMSLayers()) {
				for each(var dim: WMSDimension in layer.dimensions) {
					if(dim.name != s_dimName)
						continue;
					if(dim.units == null)
						continue;
					b_anyDimensionFound = true;
					if(s_defaultValue == null)
						s_defaultValue = dim.defaultValue;
					else {
						if(dim.defaultValue != s_defaultValue)
							return "mixed values";
					}
				}
			}
			if(b_anyDimensionFound && s_defaultValue == null)
				return "";
			return s_defaultValue;
		}
		// returns null is no such dimension exist
		public function getWMSDimensionsValues(s_dimName: String, b_intersection: Boolean = true): Array
		{
			var a_dimValues: Array;
			for each(var layer: WMSLayer in getWMSLayers()) {
				for each(var dim: WMSDimension in layer.dimensions) {
					if(dim.name != s_dimName)
						continue;
					if(a_dimValues == null)
						a_dimValues = dim.values;
					else {
						if(b_intersection)
							a_dimValues = ArrayUtils.intersectedArrays(a_dimValues, dim.values);
						else
							ArrayUtils.unionArrays(a_dimValues, dim.values);
					}
				}
			}
			
			//debug("getWMSDimensionsValues ["+s_dimName+"] = " +createDimensionsValuesString(a_dimValues));
			return a_dimValues;
		}
		
		/**
		 * It returns date from RUN and FORECAST set for this layer 
		 * @return 
		 * 
		 */		
		public function getWMSCurrentDate(): Date
		{
			var run: String = getWMSDimensionValue('RUN');
			var forecast: String = getWMSDimensionValue('FORECAST');
			
			//			debug('run: ' + run + ' forecast: ' + forecast);
			
			return new Date();
		}
		
		/**
		 * For each WMS sub-layer, returns array of objects having .name and .label properties
		 * or null if the sub-layer doesn't have any styles. This is bound together
		 * into one final array having that many items as is the number of WMS sub-layers.
		 **/
		public function getWMSStyles(): Array
		{
			var b_foundAnyStyle: Boolean = false;
			var a_styles: Array = [];
			for each(var layer: WMSLayer in getWMSLayers()) {
				var a_layerStyles: Array = [];
				for each(var style: Object in layer.styles) {
					b_foundAnyStyle = true;
					a_layerStyles.push({
						label: style.title != null ? (style.title + " (" + style.name + ")") : style.name,
						title: style.title != null  ? style.title : style.name,
						name: style.name
					});
				} 
				a_styles.push(a_layerStyles.length > 0 ? a_layerStyles : null);
			}
			return b_foundAnyStyle ? a_styles : null;
		}
		
		public function getWMSStyleName(i_subLayer: uint): String
		{
			if(i_subLayer in ma_subLayerStyleNames)
				return ma_subLayerStyleNames[i_subLayer];
			else
				return null;
		}
		
		public function getWMSStyleObject(i_subLayer: uint, s_styleName: String = ''): Object
		{
			var layer:WMSLayer = m_cfg.ma_layerConfigurations[i_subLayer] as WMSLayer;
			if (layer && layer.styles && layer.styles.length > 0) {
				if (s_styleName == '')
					return layer.styles[0];
				else {
					for each (var styleObj: Object in layer.styles)
					{
						if (styleObj.name == s_styleName)
							return styleObj;
					}
				}
			}
			return null;
		}
		public function getWMSEffectiveStyleName(i_subLayer: uint): String
		{
			var s_styleName: String = getWMSStyleName(i_subLayer);
			if(s_styleName == null) {
				var layer:WMSLayer = m_cfg.ma_layerConfigurations[i_subLayer] as WMSLayer;
				if (layer && layer.styles && layer.styles.length > 0) {
					return layer.styles[0].name;
				}
			}
			return null;
		}
		
		public function setWMSStyleName(i_subLayer: uint, s_styleName: String): void
		{
			
			clearLegendCache();
			
			if(s_styleName != null)
				ma_subLayerStyleNames[i_subLayer] = s_styleName;
			else
				delete ma_subLayerStyleNames[i_subLayer];
			
			dispatchEvent(new Event(InteractiveLayerWMS.WMS_STYLE_CHANGED));
		}
		
		public function getWMSStyleListString(): String
		{
			var s: String = "";
			for(var i_subLayer: uint = 0; i_subLayer < m_cfg.ma_layerNames.length; ++i_subLayer) {
				if(i_subLayer > 0)
					s += ",";
				if(i_subLayer in ma_subLayerStyleNames)
					s += ma_subLayerStyleNames[i_subLayer];
				else if(i_subLayer in m_cfg.ma_styleNames)
					s += m_cfg.ma_styleNames[i_subLayer];
			}
			return s;
		}
		
		public function setWMSCustomParameter(s_parameter: String, s_value: String): void
		{
			if(s_value != null)
				md_customParameters[s_parameter] = s_value;
			else
				delete md_customParameters[s_parameter];
		}
		
		/**
		 * Populates URLRequest with dimension values.
		 **/
		public function updateDimensionsInURLRequest(url: URLRequest): void
		{
			for(var s_dimName: String in md_dimensionValues) {
				if(url.data == null)
					url.data = new URLVariables();
				url.data[m_cfg.dimensionToParameterName(s_dimName)] = md_dimensionValues[s_dimName];
			}
		}
		
		/**
		 * Populates URLRequest with custom parameter values.
		 **/
		public function updateCustomParametersInURLRequest(url: URLRequest): void
		{
			for(var s_parameter: String in md_customParameters) {
				if(url.data == null)
					url.data = new URLVariables();
				url.data[s_parameter] = md_customParameters[s_parameter];
			}
		}
		
		// ISynchronisedObject implementation
		public function getSynchronisedVariables(): Array
		{
			var a: Array = [];
			
			if(m_cfg.dimensionTimeName != null
				|| (m_cfg.dimensionRunName != null && m_cfg.dimensionForecastName != null))
				a.push("frame");
			
			if(m_cfg.dimensionRunName != null)
				a.push("run");
			
			if(m_cfg.dimensionVerticalLevelName != null)
				a.push("level");
			return a;
		}
		
		public function canSynchronisedVariableWith(s_variable: String, value: Object): Boolean
		{
			return false;
		}
		
		public function getSynchronisedVariableValue(s_variableId: String): Object
		{
			if(s_variableId == "frame") {
				if(m_cfg.dimensionTimeName != null) {
					return ISO8601Parser.stringToDate(getWMSDimensionValue(m_cfg.dimensionTimeName, true));
				}
				else if(m_cfg.dimensionRunName != null && m_cfg.dimensionForecastName != null) {
					var run: Date = ISO8601Parser.stringToDate(
						getWMSDimensionValue(m_cfg.dimensionRunName, true));
					var forecast: Duration = ISO8601Parser.stringToDuration(
						getWMSDimensionValue(m_cfg.dimensionForecastName, true));
					if (run != null && forecast != null)
						return new Date(run.time + forecast.milisecondsTotal);
					
					return null;
				}
			}
			return null;
		}
		
		public function getSynchronisedVariableValuesList(s_variableId: String): Array
		{
			if(s_variableId == "frame") {
				if(m_cfg.dimensionTimeName != null) {
					var l_times: Array = getWMSDimensionsValues(m_cfg.dimensionTimeName);
					var l_resultTimes: Array = [];
					for each(var time: Object in l_times) {
						if (time.data is Date) {
							l_resultTimes.push(time.data);
						} else {
							debug("PROBLEM: InteractiveLayerMSBase getSynchronisedVariableValuesList time.data is not Date: " + time.data);
						}
					}
					
					//sort forecast by Date
					if (l_resultTimes && l_resultTimes.length > 0)
					{
						//sort Duration
						l_resultTimes.sort(sortDates);
					}
					
					return l_resultTimes;
				}
				else if(m_cfg.dimensionRunName != null && m_cfg.dimensionForecastName != null) {
					var run: Date = ISO8601Parser.stringToDate(getWMSDimensionValue(m_cfg.dimensionRunName, true));
					if(run == null)
						return [];
					var l_forecasts: Array = getWMSDimensionsValues(m_cfg.dimensionForecastName);
					var l_resultForecasts: Array = [];
					for each(var forecast: Object in l_forecasts) {
						if (forecast && (forecast.data is Duration))
						{
							l_resultForecasts.push(new Date(run.time + Duration(forecast.data).milisecondsTotal));
						} else {
							debug("PROBLEM: InteractiveLayerMSBase getSynchronisedVariableValuesList forecast.data is not Number: " + forecast.data);
						}
					}
					//sort forecast by Duration
					if (l_forecasts && l_forecasts.length > 0)
					{
						//sort Duration
						l_forecasts.sort(sortDurations);
					}
					return l_resultForecasts;
				}
				else
					return [];
			}
			else
				return null;
		}
		
		public function synchroniseWith(s_variableId: String, value: Object): Boolean
		{
			if(s_variableId == "frame") {
				if(m_cfg.dimensionTimeName != null) {
					var frame: Date = value as Date;
					// TODO: interpolation vs. find nearest value?
					setWMSDimensionValue(m_cfg.dimensionTimeName, ISO8601Parser.dateToString(frame));
					dispatchSynchronizedVariableChangeEvent(new SynchronisedVariableChangeEvent(
						SynchronisedVariableChangeEvent.SYNCHRONISED_VARIABLE_CHANGED, "frame"));
					return true;
				}
				else if(m_cfg.dimensionRunName != null && m_cfg.dimensionForecastName != null) {
					var run: Date = ISO8601Parser.stringToDate(
						getWMSDimensionValue(m_cfg.dimensionRunName, true));
					var forecast: Duration = new Duration(((value as Date).time - run.time) / 1000.0);
					var l_forecasts: Array = getWMSDimensionsValues(m_cfg.dimensionForecastName);
					// TODO: interpolation vs. find nearest value?
					var ofNearest: Object = null;
					for each(var of: Object in l_forecasts) {
						if(ofNearest == null ||
							Math.abs(Duration(of.data).secondsTotal - forecast.secondsTotal)
							< Math.abs(Duration(ofNearest.data).secondsTotal - forecast.secondsTotal)) {
							ofNearest = of;
						}
					}
					if(ofNearest != null) {
						setWMSDimensionValue(m_cfg.dimensionForecastName, ofNearest.value);
						dispatchSynchronizedVariableChangeEvent(new SynchronisedVariableChangeEvent(
							SynchronisedVariableChangeEvent.SYNCHRONISED_VARIABLE_CHANGED, "frame"));
						return true;
					}
				}
			}
			return false;
		}
		
		private function dispatchSynchronizedVariableChangeEvent(event: SynchronisedVariableChangeEvent): void
		{
			dispatchEvent(event);
		}
		
		public static function sortDates(obj1: Object, obj2: Object): int
		{
			var date1: Date = obj1 as Date; 
			var date2: Date = obj2 as Date;
			
			if (date1 && date2)
			{
				var dSec1: Number = date1.time; 
				var dSec2: Number = date2.time; 
				if (dSec1 > dSec2)
				{
					return 1;
				} else {
					if (dSec1 < dSec2)
						return -1;
				}
			}
			return 0;
		}
		public static function sortDurations(obj1: Object, obj2: Object): int
		{
			var duration1: Duration = obj1.data as Duration; 
			var duration2: Duration = obj2.data as Duration;
			
			if (duration1 && duration2)
			{
				var dSec1: Number = duration1.secondsTotal; 
				var dSec2: Number = duration2.secondsTotal; 
				if (dSec1 > dSec2)
				{
					return 1;
				} else {
					if (dSec1 < dSec2)
						return -1;
				}
			}
			return 0;
		}
		
		/******************************************************************************************
		 * 	
		 * 	Legends part
		 * 
		 ******************************************************************************************/

		private function clearLegendCache(): void
		{
			if (m_legendImage)
			{
				if (m_legendImage.width > 0 && m_legendImage.height > 0)
				{
					m_legendImage.bitmapData.dispose();
					m_legendImage = null;
				}
			}
		}
		
		private function getLegendForStyleName(styleName: String): Object
		{
			return null;
		}
		// map legend
		override public function hasLegend(): Boolean
		{ 
			//check if layer has legend	
			var styleName: String = getWMSStyleName(0);
			if (!styleName)
				styleName = '';
			var style: Object = getWMSStyleObject(0, styleName);
			
			if (style)
			{
				//				debug("MSBAse ["+name+"] hasLegend style: "  + style.legend);
				return style.legend;
			}	
			//			debug("MSBAse hasLegend NO style: ");
			return false;
		}
		
		
		override public function removeLegend(canvas: Canvas): void
		{
//			super.removeLegend(canvas);
			
			if (canvas)
			{
				while (canvas.numChildren > 0)
				{
					var disp: UIComponent = canvas.getChildAt(0) as UIComponent;
					if (disp is Image)
					{
						((disp as Image).source as Bitmap).bitmapData.dispose();
					}
					canvas.removeChildAt(0);
					disp = null;
				}	
			}
		}
		
		override public function invalidateLegend():void
		{
			debug("invalidateLegend");
		}
		/**
		 * Render legend. If legend is not cached, it needs to be loaded. 
		 * @param canvas
		 * @param callback
		 * @param labelAlign
		 * @param hintSize
		 * @return 
		 * 
		 */		
		override public function renderLegend(canvas: Canvas, callback: Function, legendScaleX: Number, legendScaleY: Number, labelAlign: String = 'left', useCache: Boolean = false, hintSize: Rectangle = null): Rectangle
		{
//			super.renderLegend(canvas, callback, legendScaleX, legendScaleY, labelAlign, useCache, hintSize);
			
			var styleName: String = getWMSStyleName(0);
			if (!styleName)
				styleName = '';
			var style: Object = getWMSStyleObject(0, styleName);
			
			var legendObject: Object = style.legend;
			
			debug("MSBAse renderLegend style: " + style.legend);
			
			var w: int = legendObject.width;
			var h: int = legendObject.height;
			if (hintSize)
			{
				w = hintSize.width;
				h = hintSize.height;
			}
			
			//			m_legendCanvas = canvas;
			//			m_legendLabelAlign = labelAlign;
			//        	m_legendCallBack = callback;
			
			debug("renderLegend url: " + legendObject.url + " scale ["+legendScaleX+","+legendScaleY+"]");
			if (!useCache || (useCache && !isLegendCachedBySize(w, h)))
			{
				var url: URLRequest = m_cfg.toGetLegendRequest(
					w, h,
					style.name);
				
				debug("LEGEND URL1: " + url.url);
				if (!(url.url.indexOf('${BASE_URL}') == 0))
				{
					
					url = new URLRequest(legendObject.url);
					debug("LEGEND URL2: " + url.url);
				} else {
					debug(" ${BASE_URL} are not using legend url from capabilities"); 
				}
				
				updateURLWithDimensions(url);
				
				if (isNaN(legendScaleX))
					legendScaleX = 1;
				if (isNaN(legendScaleY))
					legendScaleY = 1;
				
				var associatedData: Object = {canvas: canvas, labelAlign: labelAlign, callback: callback, useCache: useCache, legendScaleX: legendScaleX, legendScaleY: legendScaleY, width: w, height: h};
				
				var legendLoader: WMSImageLoader = new WMSImageLoader();
				legendLoader.addEventListener(UniURLLoaderEvent.DATA_LOADED, onLegendLoaded);
				legendLoader.addEventListener(UniURLLoaderErrorEvent.DATA_LOAD_FAILED, onLegendLoadFailed);
				
				legendLoader.load(url, associatedData);
				
			} else {
				createLegend(m_legendImage, canvas, labelAlign, callback, legendScaleX, legendScaleY, w, h);
			}
			
			var gap: int = 2;
			var labelHeight: int = 12;
			return new Rectangle(0,0, w, h + gap + labelHeight);
		}
		
		private function updateURLWithDimensions(url: URLRequest): void
		{
			var str: String = '';
			
			if (!url.data)
			{
				url.data = new URLVariables();
			}
			for each(var layer: WMSLayer in getWMSLayers()) 
			{
				for each(var dim: WMSDimension in layer.dimensions) {
					
					var value: Object = getWMSDimensionValue(dim.name);
					if (!value)
						value = dim.defaultValue;
					
					url.data[dim.name] = value.toString();
					
				}
			}
		}
		
		/**
		 * Check if legend image is cached. If last legend loaded has same width and height. 
		 * @param newWidth
		 * @param newHeight
		 * 
		 */        
		private function isLegendCachedBySize(newWidth: int, newHeight: int): Boolean
		{
			if (m_legendImage)
			{
				var oldWidth: int = (m_legendImage.width / m_legendImage.scaleX);
				var oldHeight: int = (m_legendImage.height / m_legendImage.scaleY);
				var diffWidth: int = Math.abs(oldWidth - newWidth);
				var diffHeight: int = Math.abs(oldHeight - newHeight);
				if (diffWidth < 2 && diffHeight < 2)
				{
					// legend is cached
					return true;
				}
			}
			return false;
		}
		
		public function getLegendFromCanvas(cnv: Canvas): Image
		{
			var image: Image;
			if (cnv.numChildren > 1)
			{
				var imageTest: DisplayObject = cnv.getChildAt(cnv.numChildren - 1);
				if (imageTest is Image)
				{
					image = imageTest as Image;
				}
			}
			
			return image;
		}
		
		public function isLegendCached(cnv: Canvas): Boolean
		{
			var image: Image = getLegendFromCanvas(cnv);
			return (image != null);
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
			debug("InteractiveLayerWMS onLegendLoaded ");
			var result: * = event.result;
			if(result is Bitmap) {
				
				var useCache: Boolean = event.associatedData.useCache;
				var legendScaleX: Number = event.associatedData.legendScaleX;
				var legendScaleY: Number = event.associatedData.legendScaleY;
				if (useCache)
					m_legendImage = result;
				createLegend(result, event.associatedData.canvas, event.associatedData.labelAlign, event.associatedData.callback, legendScaleX, legendScaleY, event.associatedData.width, event.associatedData.height);
			}
			removeLegendListeners(event.target as WMSImageLoader);
		}
		
		
		/**
		 * 
		 * @param image
		 * @param cnv
		 * @param labelAlign
		 * @param callback
		 * @param useCache
		 * 
		 */		
		private function createLegend(bitmap: Bitmap, cnv: Canvas, labelAlign: String, callback: Function, legendScaleX: Number, legendScaleY: Number, origWidth: int, origHeight: int): void
		{
			var gap: int = 2;
			var labelHeight: int = 12;
			
			//add legend label (name of the layer)
			var label: GlowLabel;
			if (cnv.numChildren > 0)
			{
				var labelTest: DisplayObject = cnv.getChildAt(0);
				if (labelTest is GlowLabel && labelTest.name != 'styleLabel')
				{
					label = labelTest as GlowLabel;
				}
			}
			if (!label)
			{
				label = new GlowLabel();
				cnv.addChild(label);
			}
			
			
			label.glowBlur = 5;
			label.glowColor = 0xffffff;
			label.text = name;
			label.validateNow();
			
			//FIXME FIX for legends text height
			labelHeight = label.height;
			
			label.setStyle('textAlign', labelAlign);
			
			//add legend image
			var image: Image;
			if (cnv.numChildren > 1)
			{
				var imageTest: DisplayObject = cnv.getChildAt(cnv.numChildren - 1);
				if (imageTest is Image)
				{
					image = imageTest as Image;
					image.scaleX = image.scaleY = 1;
					image.width = origWidth;
					image.height = origHeight;
				}
			}
			if (!image)
			{
				image = new Image();
				cnv.addChild(image);
			}
			
			image.source = bitmap;
			image.width = origWidth * legendScaleX;
			image.height = origHeight * legendScaleY;
			//			image.scaleX = legendScaleX;
			//			image.scaleY = legendScaleY;
			image.y = labelHeight + gap;
			
			label.width = image.width;
			
			debug("\n\t createLegend legendScaleX: " + legendScaleX + " legendScaleY: " + legendScaleY);
			debug("t createLegend image: " + image.width + " , " + image.height);
			debug("t createLegend image scale: " + image.scaleX + " , " + image.scaleY);
			cnv.width = image.width;
			cnv.height = image.height + labelHeight + gap;
			
			
			if(callback != null) {
				callback.apply(null, [cnv]);
			}
		}
		protected function onLegendLoadFailed(event: UniURLLoaderErrorEvent): void
		{
			debug("onLegendLoadFailed");
			removeLegendListeners(event.target as WMSImageLoader);
		}

		public function renderPreviewWMSData(graphics: Graphics, f_width: Number, f_height: Number): void
		{
			if (status == InteractiveDataLayer.STATE_DATA_LOADED_WITH_ERRORS)
			{
				drawNoDataPreview(graphics, f_width, f_height);
				return;
			}
			
			var imagePart: ImagePart;
			if(ma_imageParts.length > 0) {
				var matrix: Matrix = new Matrix();
				imagePart = ImagePart(ma_imageParts[0]);
				
				if (imagePart.isBitmap)
					var bitmap: Bitmap = imagePart.m_image as Bitmap;
				else {
					trace("ATTENTION: renderPreviewWMSData image is not bitmap");
					return;
				}
				
				
				matrix.translate(-f_width / 3, -f_width / 3);
				matrix.scale(3, 3);
				matrix.translate(imagePart.m_image.width / 3, imagePart.m_image.height / 3);
				matrix.invert();
				graphics.beginBitmapFill(bitmap.bitmapData, matrix, false, true);
				graphics.drawRect(0, 0, f_width, f_height);
				graphics.endFill();
			}
			var b_allImagesOK: Boolean = true;
			for each(imagePart in ma_imageParts) {
				if(!imagePart.mb_imageOK) {
					b_allImagesOK = false;
					break;
				}
			}
			if(!b_allImagesOK) {
				drawNoDataPreview(graphics, f_width, f_height);
			}
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
		
		public function drawWMSData(graphics: Graphics): void
		{
			if(container.height <= 0)
				return;
			if(container.width <= 0)
				return;
			
			var s_currentCRS: String = container.getCRS();
			//			trace("InteractiveLayerWMS.draw(): currentViewBBox=" + container.getViewBBox().toString());
			for each(var imagePart: ImagePart in ma_imageParts) {
				// Check if CRS of the image part == current CRS of the container
				if(s_currentCRS != imagePart.ms_imageCRS)
					continue; // otherwise we cannot draw it
				
				var reflectedBBoxes:Array = container.mapBBoxToViewReflections(imagePart.m_imageBBox);
				for each(var reflectedBBox: BBox in reflectedBBoxes) {
					//					trace("\t InteractiveLayerWMS.draw(): drawing reflection " + reflectedBBox.toString());
					drawImagePart(graphics, imagePart.m_image, imagePart.ms_imageCRS, reflectedBBox);
				}
			}
		}
		
		private function drawImagePart(graphics: Graphics, image: DisplayObject, s_imageCRS: String, imageBBox: BBox): void
		{
			if (image is Bitmap)
			{
				drawImagePartAsBitmap(graphics, image as Bitmap, s_imageCRS, imageBBox);
			}
			if (image is AVM1Movie)
			{
//				drawImagePartAsSWF(image as Bitmap, s_imageCRS, imageBBox);
				
				//TODO we can get bitmap from avm1movie
				var bd: BitmapData = new BitmapData(image.width, image.height, true, 0x00ff0000);
				bd.draw(image);
				
				drawImagePartAsBitmap(graphics, new Bitmap(bd), s_imageCRS, imageBBox);
			}
		}
		private function drawImagePartAsSWF(image: Bitmap, s_imageCRS: String, imageBBox: BBox): void
		{
			
		}
		
		private function drawImagePartAsBitmap(graphics: Graphics, image: Bitmap, s_imageCRS: String, imageBBox: BBox): void
		{
			var ptImageStartPoint: Point =
				container.coordToPoint(new Coord(s_imageCRS, imageBBox.xMin, imageBBox.yMax));
			var ptImageEndPoint: Point =
				container.coordToPoint(new Coord(s_imageCRS, imageBBox.xMax, imageBBox.yMin));
			ptImageEndPoint.x += 1;
			ptImageEndPoint.y += 1;
			
//			trace("InteractiveLayerWMS.draw(): image-w=" + image.width + " image-h=" + image.height);
			var ptImageSize: Point = ptImageEndPoint.subtract(ptImageStartPoint);
			ptImageSize.x = int(Math.round(ptImageSize.x));
			ptImageSize.y = int(Math.round(ptImageSize.y));
			
			var matrix: Matrix = new Matrix();
			matrix.scale(ptImageSize.x / image.width, ptImageSize.y / image.height);
//			trace("InteractiveLayerWMS.draw(): scale-x=" + matrix.a + " scale-y=" + matrix.d);
			
			matrix.translate(ptImageStartPoint.x, ptImageStartPoint.y);
			graphics.beginBitmapFill(image.bitmapData, matrix, true, true);
//			trace("InteractiveLayerWMS.draw(): x=" + ptImageStartPoint.x + " y=" + ptImageStartPoint.y + " w=" + ptImageSize.x + " h=" + ptImageSize.y);
			graphics.drawRect(ptImageStartPoint.x, ptImageStartPoint.y, ptImageSize.x, ptImageSize.y);
			graphics.endFill();
		}
		
		
		override public function clone(): InteractiveLayer
		{
			var newViewProperties: WMSViewProperties = new WMSViewProperties(container);
			newViewProperties.setConfiguration(m_cfg);
			
			newViewProperties.id = id;
			newViewProperties.alpha = alpha;
			newViewProperties.zOrder = zOrder;
			newViewProperties.visible = visible;
			
			var styleName: String = getWMSStyleName(0)
			newViewProperties.setWMSStyleName(0, styleName);
//			debug("\n\n CLONE InteractiveLayerWMS ["+newViewProperties.name+"] alpha: " + newViewProperties.alpha + " zOrder: " +  newViewProperties.zOrder);
			
			//clone all dimensions
			var dimNames: Array = getWMSDimensionsNames();
			for each (var dimName: String in dimNames)
			{
				var value : String = getWMSDimensionValue(dimName);
				newViewProperties.setWMSDimensionValue(dimName, value);
			}
//			debug("OLD: " + name + " label: " + id);
			return newViewProperties;
			
		}
		
		private function debug(str: String): void
		{
			return;
			trace(str);
		}
	}
}