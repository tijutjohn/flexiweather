package com.iblsoft.flexiweather.ogc
{
	import com.iblsoft.flexiweather.events.InteractiveLayerEvent;
	import com.iblsoft.flexiweather.net.events.UniURLLoaderErrorEvent;
	import com.iblsoft.flexiweather.net.events.UniURLLoaderEvent;
	import com.iblsoft.flexiweather.net.loaders.UniURLLoader;
	import com.iblsoft.flexiweather.ogc.cache.ICache;
	import com.iblsoft.flexiweather.ogc.data.WMSViewProperties;
	import com.iblsoft.flexiweather.ogc.events.GetCapabilitiesEvent;
	import com.iblsoft.flexiweather.ogc.net.loaders.WMSFeatureInfoLoader;
	import com.iblsoft.flexiweather.ogc.net.loaders.WMSImageLoader;
	import com.iblsoft.flexiweather.proj.Coord;
	import com.iblsoft.flexiweather.utils.ArrayUtils;
	import com.iblsoft.flexiweather.utils.Duration;
	import com.iblsoft.flexiweather.utils.ISO8601Parser;
	import com.iblsoft.flexiweather.widgets.BackgroundJob;
	import com.iblsoft.flexiweather.widgets.GlowLabel;
	import com.iblsoft.flexiweather.widgets.IConfigurableLayer;
	import com.iblsoft.flexiweather.widgets.InteractiveDataLayer;
	import com.iblsoft.flexiweather.widgets.InteractiveLayer;
	import com.iblsoft.flexiweather.widgets.InteractiveWidget;
	
	import flash.display.Bitmap;
	import flash.display.DisplayObject;
	import flash.display.Graphics;
	import flash.events.DataEvent;
	import flash.events.Event;
	import flash.events.TimerEvent;
	import flash.geom.Matrix;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.net.URLRequest;
	import flash.net.URLVariables;
	import flash.text.engine.CFFHinting;
	import flash.utils.Dictionary;
	import flash.utils.Timer;
	
	import mx.binding.utils.BindingUtils;
	import mx.containers.Canvas;
	import mx.controls.Image;
	import mx.core.UIComponent;
	import mx.effects.Fade;
	import mx.events.DynamicEvent;
	import mx.events.EffectEvent;
	import mx.logging.Log;
	
	[Event(name="wmsStyleChanged", type="flash.events.Event")]
	
	/**
	 * Common base class for WMS type layers
	 *  
	 * @author fkormanak
	 * 
	 */	
	public class InteractiveLayerMSBase extends InteractiveDataLayer
			implements ISynchronisedObject, IConfigurableLayer
	{
		protected var m_featureInfoLoader: WMSFeatureInfoLoader = new WMSFeatureInfoLoader();

		
		protected var mb_updateAfterMakingVisible: Boolean = false;
		
		protected var m_cfg: WMSLayerConfiguration;
		protected var md_dimensionValues: Dictionary = new Dictionary(); 
		protected var md_customParameters: Dictionary = new Dictionary(); 
		protected var ma_subLayerStyleNames: Array = [];
		
		protected var m_synchronisationRole: SynchronisationRole;

		protected var m_cache: ICache;
		
		/**
		 * Currently displayed wms data 
		 */		
		protected var m_currentWMSViewProperties: WMSViewProperties;
		
		public function get currentWMSViewProperties(): WMSViewProperties
		{
			return m_currentWMSViewProperties;
		}
		
		/**
		 * wms data which are currently preloading 
		 */		
		protected var ma_preloadingWMSViewProperties: Array;
		
		/**
		 * wms data which are already preloaded 
		 */		
		protected var ma_preloadedWMSViewProperties: Array;
		
		public function InteractiveLayerMSBase(container: InteractiveWidget, cfg: WMSLayerConfiguration)
		{
			super(container);
			
			ma_preloadingWMSViewProperties = [];
			ma_preloadedWMSViewProperties = [];
			
			m_currentWMSViewProperties = new WMSViewProperties(container);
			m_currentWMSViewProperties.addEventListener(InteractiveDataLayer.LOADING_STARTED, onCurrentWMSDataLoadingStarted);
			m_currentWMSViewProperties.addEventListener(InteractiveDataLayer.LOADING_FINISHED, onCurrentWMSDataLoadingFinished);
			m_currentWMSViewProperties.addEventListener(SynchronisedVariableChangeEvent.SYNCHRONISED_VARIABLE_CHANGED, onCurrentWMSDataSynchronisedVariableChanged);
			m_currentWMSViewProperties.addEventListener("invalidateDynamicPart", onCurrentWMSDataInvalidateDynamicPart);
			
			m_featureInfoLoader.addEventListener(UniURLLoaderEvent.DATA_LOADED, onFeatureInfoLoaded);
			m_featureInfoLoader.addEventListener(UniURLLoaderErrorEvent.DATA_LOAD_FAILED, onFeatureInfoLoadFailed);
			
			m_synchronisationRole = new SynchronisationRole();
			
			setConfiguration(cfg);
			//filters = [ new GlowFilter(0xffffe0, 0.8, 2, 2, 2) ];
			createEffects();
//			setStyle('addedEffect', fadeIn);
			setStyle('showEffect', fadeIn);
//			setStyle('removedEffect', fadeOut);
			setStyle('hideEffect', fadeOut);
		}
		
		private var fadeIn: Fade;
		private var fadeOut: Fade;
		
		[Bindable]
		public var alphaBackup: Number = 1;
		
		public function changeWMSViewProperties(wmsViewProperties: WMSViewProperties): void
		{
			m_currentWMSViewProperties.removeEventListener(InteractiveDataLayer.LOADING_STARTED, onCurrentWMSDataLoadingStarted);
			m_currentWMSViewProperties.removeEventListener(InteractiveDataLayer.LOADING_FINISHED, onCurrentWMSDataLoadingFinished);
			m_currentWMSViewProperties.removeEventListener(SynchronisedVariableChangeEvent.SYNCHRONISED_VARIABLE_CHANGED, onCurrentWMSDataSynchronisedVariableChanged);
			m_currentWMSViewProperties.removeEventListener("invalidateDynamicPart", onCurrentWMSDataInvalidateDynamicPart);
			
			m_currentWMSViewProperties = wmsViewProperties;
			
			m_currentWMSViewProperties.addEventListener(InteractiveDataLayer.LOADING_STARTED, onCurrentWMSDataLoadingStarted);
			m_currentWMSViewProperties.addEventListener(InteractiveDataLayer.LOADING_FINISHED, onCurrentWMSDataLoadingFinished);
			m_currentWMSViewProperties.addEventListener(SynchronisedVariableChangeEvent.SYNCHRONISED_VARIABLE_CHANGED, onCurrentWMSDataSynchronisedVariableChanged);
			m_currentWMSViewProperties.addEventListener("invalidateDynamicPart", onCurrentWMSDataInvalidateDynamicPart);
		}
		
		/**
		 * Preload all frames from input array
		 *  
		 * @param wmsViewPropertiesArray - input array
		 * 
		 */		
		public function preloadMultiple(wmsViewPropertiesArray: Array): void
		{
			for each (var wmsViewProperties: WMSViewProperties in wmsViewPropertiesArray)
			{
				preload(wmsViewProperties);
			}
		}
		
		public function preload(wmsViewProperties: WMSViewProperties): void
		{
			wmsViewProperties.name = name;
			wmsViewProperties.setConfiguration(m_cfg);
			wmsViewProperties.cache = m_cache;
			
			ma_preloadingWMSViewProperties.push(wmsViewProperties);
			
			wmsViewProperties.addEventListener(InteractiveDataLayer.LOADING_STARTED, onPreloadingWMSDataLoadingStarted);
			wmsViewProperties.addEventListener(InteractiveDataLayer.LOADING_FINISHED, onPreloadingWMSDataLoadingFinished);
			
			wmsViewProperties.updateWMSData(true);
		}
		
		public function isPreloadedMultiple(wmsViewPropertiesArray: Array): Boolean
		{
			var isAllPreloaded: Boolean = true;
			
			for each (var wmsViewProperties: WMSViewProperties in wmsViewPropertiesArray)
			{
				isAllPreloaded = isAllPreloaded && isPreloaded(wmsViewProperties);
			}
			return isAllPreloaded;
		}
		
		private function getPreloadedWMSDimensionValue(s_variableId: String, s_value: Object): WMSViewProperties
		{
			for each (var currWmsViewProperties: WMSViewProperties in ma_preloadedWMSViewProperties)
			{
				//for now just check if preloading has started
				if (currWmsViewProperties.getWMSDimensionValue(s_variableId) == s_value)
					return currWmsViewProperties;
			}
			return null;	
		}
		
		public function isPreloadedWMSDimensionValue(s_variableId: String, s_value: Object): Boolean
		{
			for each (var currWmsViewProperties: WMSViewProperties in ma_preloadedWMSViewProperties)
			{
				//for now just check if preloading has started
				if (currWmsViewProperties.getWMSDimensionValue(s_variableId) == s_value)
					return true;
			}
			return false;	
		}
		
		public function isPreloaded(wmsViewProperties: WMSViewProperties): Boolean
		{
			for each (var currWmsViewProperties: WMSViewProperties in ma_preloadedWMSViewProperties)
			{
				//for now just check if preloading has started
				if (currWmsViewProperties.equals(wmsViewProperties))
					return true;
			}
			return false;
		}
		
		protected function onPreloadingWMSDataLoadingStarted(event: InteractiveLayerEvent): void
		{
			var wmsViewProperties: WMSViewProperties = event.target as WMSViewProperties;
			wmsViewProperties.removeEventListener(InteractiveDataLayer.LOADING_STARTED, onPreloadingWMSDataLoadingStarted);
			debug("onPreloadingWMSDataLoadingStarted wmsData: " + wmsViewProperties);
			
		}
		protected function onPreloadingWMSDataLoadingFinished(event: InteractiveLayerEvent): void
		{
			var wmsViewProperties: WMSViewProperties = event.target as WMSViewProperties;
			wmsViewProperties.removeEventListener(InteractiveDataLayer.LOADING_FINISHED, onPreloadingWMSDataLoadingFinished);
			debug("onPreloadingWMSDataLoadingFinished wmsData: " + wmsViewProperties);
			
			//remove wmsViewProperties from array of currently preloading wms view properties
			var total: int = ma_preloadingWMSViewProperties.length;
			for (var i: int = 0; i < total; i++)
			{
				var currWMSViewProperties: WMSViewProperties = ma_preloadingWMSViewProperties[i] as WMSViewProperties
				if (currWMSViewProperties && currWMSViewProperties.equals(wmsViewProperties))
				{
					ma_preloadingWMSViewProperties.splice(i, 1);
					break;
				}
			}
			//add wmsViewProperties to array of already preloaded wms view properties
			ma_preloadedWMSViewProperties.push(wmsViewProperties);
			
			notifyProgress(ma_preloadedWMSViewProperties.length, ma_preloadingWMSViewProperties.length + ma_preloadedWMSViewProperties.length, 'frames');
			
			if (ma_preloadingWMSViewProperties.length == 0)
			{
				//all wms view properties are preloaded, delete preloaded wms properties, bitmaps are stored in cache
//				total = ma_preloadedWMSViewProperties.length;
//				for (i = 0; i < total; i++)
//				{
//					currWMSViewProperties = ma_preloadedWMSViewProperties[i] as WMSViewProperties
//					delete currWMSViewProperties;
//				}
				ma_preloadedWMSViewProperties = [];
			}
		}
		
		
		protected function onCurrentWMSDataSynchronisedVariableChanged(event: SynchronisedVariableChangeEvent): void
		{
			dispatchEvent(event);
		}
		
		protected function onCurrentWMSDataInvalidateDynamicPart(event: DynamicEvent): void
		{
			invalidateDynamicPart(event['invalid']);
		}
		protected function onCurrentWMSDataLoadingStarted(event: InteractiveLayerEvent): void
		{
			
		}
		protected function onCurrentWMSDataLoadingFinished(event: InteractiveLayerEvent): void
		{
			
		}
		
		public function setConfiguration(cfg: WMSLayerConfiguration): void
		{
			if(m_cfg != null) {
				m_cfg.removeEventListener(WMSLayerConfiguration.CAPABILITIES_UPDATED, onCapabilitiesUpdated);
				m_cfg.removeEventListener(WMSLayerConfiguration.CAPABILITIES_RECEIVED, onCapabilitiesReceived);
			}
			m_cfg = cfg;

			m_cfg.addEventListener(WMSLayerConfiguration.CAPABILITIES_UPDATED, onCapabilitiesUpdated);
			m_cfg.addEventListener(WMSLayerConfiguration.CAPABILITIES_RECEIVED, onCapabilitiesReceived);
			
			if (m_currentWMSViewProperties)
			{
				m_currentWMSViewProperties.setConfiguration(cfg);
				m_currentWMSViewProperties.name = name;
			}
				
		}
		
		
		
		/**
		 * If you want to change some data in request, you can implement it in this function. 
		 * E.g if you want change request type for tile layer you can override this function and update it
		 *  
		 * 
		 */		
		protected function updateRequestData(request: URLRequest): void
		{
			
		}
		
		override public function getFullURLWithSize(width: int, height: int): String
		{
			return getGetMapFullUrl( width, height );
		}
		/**
		 * function returns full URL for getting map 
		 * @return 
		 * 
		 */		
		override public function getFullURL(): String
		{
			return getGetMapFullUrl( int(container.width), int(container.height) );
		}
		
		private function getGetMapFullUrl(width: int, height: int): String
		{
			var request: URLRequest = m_cfg.toGetMapRequest(
					container.getCRS(), container.getViewBBox().toBBOXString(),
					width, height,
					getWMSStyleListString());
			if (!request)
				return null;
			
			if (request.url.indexOf('${BASE_URL}') == -1)
			{
				debug("stop");
			}
			updateDimensionsInURLRequest(request);
			updateCustomParametersInURLRequest(request);
			updateRequestData(request);
			
			var s_url: String = request.url;
			if(request.data) {
				if(s_url.indexOf("?") >= 0)
					s_url += "&";
				else
					s_url += "?";
				s_url += request.data;
			}
			
			if (request.data.STYLE && request.data.STYLE.length > 0)
			{
				
			}
			return s_url;
		}
		
		public function debugCache(): String
		{
			return toString() + "\n" + m_cache.debugCache();
		}
		
		public function setAnimationModeEnable(value: Boolean): void
		{
			m_cache.setAnimationModeEnable(value);	
		}
		
		override protected function updateData(b_forceUpdate: Boolean): void
		{
			super.updateData(b_forceUpdate);
			
			if(!visible) {
				mb_updateAfterMakingVisible = true;
				return;
			}
		}

		public override function draw(graphics: Graphics): void
		{
			super.draw(graphics);
		}
		
		override public function onAreaChanged(b_finalChange: Boolean): void
		{
			super.onAreaChanged(b_finalChange);
		}
		
		override public function onContainerSizeChanged(): void
		{
			super.onContainerSizeChanged();
			invalidateData(false);
		}
		
        override public function refresh(b_force: Boolean): void
        {
        	super.refresh(b_force);
			invalidateData(b_force);
        	//rerender legend
        }

		private function getLegendForStyleName(styleName: String): Object
		{
			return null;
		}
		// map legend
        override public function hasLegend(): Boolean
        { 
        	if (m_currentWMSViewProperties)
				return m_currentWMSViewProperties.hasLegend();
			
        	return false;
       	}

		
		 override public function removeLegend(canvas: Canvas): void
		 {
		 	super.removeLegend(canvas);
		 	
			if (m_currentWMSViewProperties)
				return m_currentWMSViewProperties.removeLegend(canvas);
		 }
		 
		 override public function invalidateLegend():void
		 {
			if (m_currentWMSViewProperties)
				return m_currentWMSViewProperties.invalidateLegend();
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
        	super.renderLegend(canvas, callback, legendScaleX, legendScaleY, labelAlign, useCache, hintSize);
        	
			if (m_currentWMSViewProperties)
        		return m_currentWMSViewProperties.renderLegend(canvas, callback, legendScaleX, legendScaleY, labelAlign, useCache, hintSize);
					
			return null;
        }
        
        public function getLegendFromCanvas(cnv: Canvas): Image
        {
			if (m_currentWMSViewProperties)
				return m_currentWMSViewProperties.getLegendFromCanvas(cnv);
			
			return null;
        }
        
        public function isLegendCached(cnv: Canvas): Boolean
        {
			if (m_currentWMSViewProperties)
				return m_currentWMSViewProperties.isLegendCached(cnv);
			
			return false;
        }
        
        
		override public function hasFeatureInfo(): Boolean
		{
        	for each(var layer: WMSLayer in getWMSLayers()) {
        		if(layer.queryable)
        			return true;
        	}
        	return false;
		}
		
		protected var m_featureInfoCallBack: Function;
		
		override public function getFeatureInfo(coord: Coord, callback: Function): void
		{
			var a_queryableLayerNames: Array = [];
        	for each(var layer: WMSLayer in getWMSLayers()) {
        		if(layer.queryable)
        			a_queryableLayerNames.push(layer.name);
        	}
			var pt: Point = container.coordToPoint(coord);
			var url: URLRequest = m_cfg.toGetFeatureInfoRequest(
					container.getCRS(), container.getViewBBox().toBBOXString(),
					int(container.width), int(container.height),
					a_queryableLayerNames, int(Math.round(pt.x)), int(Math.round(pt.y)),
					getWMSStyleListString());
			updateDimensionsInURLRequest(url);
			updateCustomParametersInURLRequest(url);
			m_featureInfoCallBack = callback;
			m_featureInfoLoader.load(url);
		}
		
		override public function hasExtent(): Boolean
        {
        	return getExtent() != null;
        }
        
        override public function getExtent(): BBox
        {
        	if(m_cfg.service == null)
        		return null;
        	var bbox: BBox = null;
        	for each(var layer: WMSLayer in getWMSLayers()) {
        		var b: BBox = layer.getBBoxForCRS(container.getCRS());
        		if(b == null)
        			continue;
        		if(bbox == null)
        			bbox = b;
        		else
        			bbox = bbox.extendedWith(b);
        	}
			return bbox;
        }
		
		public function getWMSLayers(): Array
		{
			if (m_currentWMSViewProperties)
				return m_currentWMSViewProperties.getWMSLayers();
			
			return null;
		}
        
        public function supportWMSDimension(s_dimName: String): Boolean
		{
			if (m_currentWMSViewProperties)
				return m_currentWMSViewProperties.supportWMSDimension(s_dimName);
			
        	return false;
			
		}
		
        public function getWMSDimensionsNames(): Array
        {
			if (m_currentWMSViewProperties)
				return m_currentWMSViewProperties.getWMSDimensionsNames();
			
			return null;
        }
        
		// returns null is no such dimension exist
        public function getWMSDimensionUnitsName(s_dimName: String): String
        {
			if (m_currentWMSViewProperties)
				return m_currentWMSViewProperties.getWMSDimensionUnitsName(s_dimName);
			
			return null;
        }

		// returns null is no such dimension exist
        public function getWMSDimensionDefaultValue(s_dimName: String): String
        {
			if (m_currentWMSViewProperties)
				return m_currentWMSViewProperties.getWMSDimensionDefaultValue(s_dimName);
			
			return null;
        }
		// returns null is no such dimension exist
        public function getWMSDimensionsValues(s_dimName: String, b_intersection: Boolean = true): Array
        {
			if (m_currentWMSViewProperties)
				return m_currentWMSViewProperties.getWMSDimensionsValues(s_dimName, b_intersection);
			
			return null;
        }
        
        

		/**
		 * It returns date from RUN and FORECAST set for this layer 
		 * @return 
		 * 
		 */		
		public function getWMSCurrentDate(): Date
		{
			if (m_currentWMSViewProperties)
				return m_currentWMSViewProperties.getWMSCurrentDate();
			
			return new Date();
		}
		
		/**
		 * Change WMS Dimension value and invalidate cache (if b_invalidateCache == true)
		 *  
		 * @param s_dimName Dimension name (RUN, FORECAST, etc.)
		 * @param s_value Dimension value
		 * @param b_invalidateCache Invalidate cache
		 * 
		 */		
        public function setWMSDimensionValue(s_dimName: String, s_value: String): void
        {
			//TODO check if bitmap for dimension is value
			
			
			if (m_currentWMSViewProperties)
				m_currentWMSViewProperties.setWMSDimensionValue(s_dimName, s_value);
			
			
			
			// if "run" changed, then even time axis changes
			if(m_cfg.ms_dimensionRunName != null && s_dimName == m_cfg.ms_dimensionRunName) {
				dispatchEvent(new SynchronisedVariableChangeEvent(
					SynchronisedVariableChangeEvent.SYNCHRONISED_VARIABLE_DOMAIN_CHANGED, "frame"));
			}
			//if "forecast" changed, we need to update timeline, so we need to dispatch event
			if(m_cfg.ms_dimensionForecastName != null && s_dimName == m_cfg.ms_dimensionForecastName) {
				dispatchEvent(new SynchronisedVariableChangeEvent(
					SynchronisedVariableChangeEvent.SYNCHRONISED_VARIABLE_CHANGED, "frame"));
			}
			//if "time" changed, we need to update timeline, so we need to dispatch event
			if(m_cfg.ms_dimensionTimeName != null && s_dimName == m_cfg.ms_dimensionTimeName) {
				dispatchEvent(new SynchronisedVariableChangeEvent(
					SynchronisedVariableChangeEvent.SYNCHRONISED_VARIABLE_CHANGED, "frame"));
			}
        }

        public function getWMSDimensionValue(s_dimName: String,
        		b_returnDefault: Boolean = false): String
        {
			if (m_currentWMSViewProperties)
				return m_currentWMSViewProperties.getWMSDimensionValue(s_dimName, b_returnDefault);
			
			return null;
        }
        
        /**
        * For each WMS sub-layer, returns array of objects having .name and .label properties
        * or null if the sub-layer doesn't have any styles. This is bound together
        * into one final array having that many items as is the number of WMS sub-layers.
        **/
        public function getWMSStyles(): Array
        {
			if (m_currentWMSViewProperties)
				return m_currentWMSViewProperties.getWMSStyles();
			
			return null;
        }
        
        public function getWMSStyleName(i_subLayer: uint): String
        {
			if (m_currentWMSViewProperties)
				return m_currentWMSViewProperties.getWMSStyleName(i_subLayer);
			
			return null;
        }

        public function getWMSStyleObject(i_subLayer: uint, s_styleName: String = ''): Object
        {
			if (m_currentWMSViewProperties)
				return m_currentWMSViewProperties.getWMSStyleObject(i_subLayer, s_styleName);
			
			return null;
        }
        public function getWMSEffectiveStyleName(i_subLayer: uint): String
        {
			if (m_currentWMSViewProperties)
				return m_currentWMSViewProperties.getWMSEffectiveStyleName(i_subLayer);
			
			return null;
        }

        public function setWMSStyleName(i_subLayer: uint, s_styleName: String): void
        {
			if (m_currentWMSViewProperties)
				m_currentWMSViewProperties.setWMSStyleName(i_subLayer, s_styleName);
			
			dispatchEvent(new Event(InteractiveLayerWMS.WMS_STYLE_CHANGED));
        }
        
        public function getWMSStyleListString(): String
        {
			if (m_currentWMSViewProperties)
				return m_currentWMSViewProperties.getWMSStyleListString();
			
			return null;
        }
        
        public function setWMSCustomParameter(s_parameter: String, s_value: String): void
        {
			if (m_currentWMSViewProperties)
				m_currentWMSViewProperties.setWMSCustomParameter(s_parameter, s_value);
        }

		/**
		 * Populates URLRequest with dimension values.
		 **/
		public function updateDimensionsInURLRequest(url: URLRequest): void
		{
			if (m_currentWMSViewProperties)
				m_currentWMSViewProperties.updateDimensionsInURLRequest(url);
		}

		/**
		 * Populates URLRequest with custom parameter values.
		 **/
		public function updateCustomParametersInURLRequest(url: URLRequest): void
		{
			if (m_currentWMSViewProperties)
				m_currentWMSViewProperties.updateCustomParametersInURLRequest(url);
		 }

		// ISynchronisedObject implementation
		public function getSynchronisedVariables(): Array
		{
			if (m_currentWMSViewProperties)
				return m_currentWMSViewProperties.getSynchronisedVariables();
			
			return null;
		}

		public function canSynchronisedVariableWith(s_variable: String, s_value: Object): Boolean
		{
			if (m_currentWMSViewProperties)
				return m_currentWMSViewProperties.canSynchronisedVariableWith(s_variable, s_value);
			
			return false;
		}

		public function getSynchronisedVariableValue(s_variableId: String): Object
		{
			if (m_currentWMSViewProperties)
				return m_currentWMSViewProperties.getSynchronisedVariableValue(s_variableId);
			
			return null;
		}

		public function getSynchronisedVariableValuesList(s_variableId: String): Array
		{
			if (m_currentWMSViewProperties)
				return m_currentWMSViewProperties.getSynchronisedVariableValuesList(s_variableId);
			
			return null;
		}

		
		public function synchroniseWith(s_variableId: String, s_value: Object): Boolean
		{
			//TODO check if there is cached view properties
			if (isPreloadedWMSDimensionValue(s_variableId, s_value))
			{
				var viewProperties: WMSViewProperties = getPreloadedWMSDimensionValue(s_variableId, s_value);
				if (viewProperties)
				{
					return viewProperties.synchroniseWith(s_variableId, s_value);
				}
			}
			if (m_currentWMSViewProperties)
				return m_currentWMSViewProperties.synchroniseWith(s_variableId, s_value);
			
			return false;
		}
		

		override protected function onDataLoadFailed(event: UniURLLoaderErrorEvent): void
		{
			super.onDataLoadFailed(event);
			
			if(event != null) {
				ExceptionUtils.logError(Log.getLogger("WMS"), event,
						"Error accessing layers '" + m_cfg.ma_layerNames.join(","))
			}
		}
		
		protected function onCapabilitiesReceived(event: DataEvent): void
		{
			dispatchEvent(new GetCapabilitiesEvent(
				GetCapabilitiesEvent.CAPABILITIES_RECEIVED));
		}
		protected function onCapabilitiesUpdated(event: DataEvent): void
		{
			dispatchEvent(new SynchronisedVariableChangeEvent(
					SynchronisedVariableChangeEvent.SYNCHRONISED_VARIABLE_DOMAIN_CHANGED, "frame"));
		}

		protected function onFeatureInfoLoaded(event: UniURLLoaderEvent): void
		{
			if(m_featureInfoCallBack != null) {
				m_featureInfoCallBack.call(null, String(event.result), this);
			}
			m_featureInfoCallBack = null;
		}
		
		protected function onFeatureInfoLoadFailed(event: UniURLLoaderErrorEvent): void
		{
			m_featureInfoCallBack.call(null, String(event.result), this);
			m_featureInfoCallBack = null;
		}
		
		
		
		public function isPrimaryLayer(): Boolean
		{
			if (m_synchronisationRole)
			{
				return m_synchronisationRole.isPrimary;
			}
			return false;
		}
		
		
		/****************************************************************
		 * 
		 *  Layer show / hide effects
		 * 
		 ****************************************************************/
		private function createEffects(): void
		{
			fadeIn = new Fade(this);
			fadeIn.alphaFrom = 0;
			BindingUtils.bindProperty(fadeIn, 'alphaTo', this, "alphaBackup");
			fadeIn.duration = 300;
			
			fadeOut = new Fade(this);
			fadeOut.alphaTo = 0;
			BindingUtils.bindProperty(fadeOut, 'alphaFrom', this, "alpha");
			fadeOut.duration = 300;
			
			fadeIn.addEventListener(EffectEvent.EFFECT_END, onEffectEnd);
			fadeIn.addEventListener(EffectEvent.EFFECT_START, onEffectFadeInStart);
			fadeOut.addEventListener(EffectEvent.EFFECT_START, onEffectFadeOutStart);
			fadeOut.addEventListener(EffectEvent.EFFECT_END, onEffectEnd);
			
		}
		
		private function onEffectFadeInStart(event: EffectEvent): void
		{
			debug("onEffectFadeInStart 2 alphaBackup: " + alphaBackup + " fadeIn.alphaTo: " + fadeIn.alphaTo);
		}
		private function onEffectFadeOutStart(event: EffectEvent): void
		{
			alphaBackup = alpha;
			debug("onEffectFadeOutStart 2 alphaBackup: " + alphaBackup + " fadeIn.alphaTo: " + fadeOut.alphaFrom);
		}
		private function onEffectEnd(event: EffectEvent): void
		{
			callLater(delayedEffectEnd);
		}
		private function delayedEffectEnd(): void
		{
			var ile: InteractiveLayerEvent = new InteractiveLayerEvent(InteractiveLayerEvent.VISIBILITY_EFFECT_FINISHED);
			dispatchEvent(ile);
		}
		/****************************************************************
		 * 
		 *  End of Layer show / hide effects part
		 * 
		 ****************************************************************/
		
		override public function get name(): String
		{
			if (m_cfg)
				return m_cfg.label; 
			
			return '';
		}
		
		override public function set visible(b_visible: Boolean): void
		{
			var b_visiblePrev: Boolean = super.visible;
			super.visible = b_visible;
			
			if(!b_visiblePrev && b_visible && mb_updateAfterMakingVisible) {
				mb_updateAfterMakingVisible = false;
				invalidateData(true);
			}
		}

		override public function clone(): InteractiveLayer
		{
			var newLayer: InteractiveLayerWMS = new InteractiveLayerWMS(container, m_cfg);
			newLayer.id = id;
			newLayer.alpha = alpha;
			newLayer.zOrder = zOrder;
			newLayer.visible = visible;
					
			var styleName: String = getWMSStyleName(0)
			newLayer.setWMSStyleName(0, styleName);
			debug("\n\n CLONE InteractiveLayerWMS ["+newLayer.name+"] alpha: " + newLayer.alpha + " zOrder: " +  newLayer.zOrder);
			
			//clone all dimensions
			var dimNames: Array = getWMSDimensionsNames();
			for each (var dimName: String in dimNames)
			{
				var value : String = getWMSDimensionValue(dimName);
				newLayer.setWMSDimensionValue(dimName, value);
			}
			debug("OLD: " + name + " label: " + id);
			return newLayer;
			
		}

		protected function debug(str: String): void
		{
			trace("InteractiveLayerMSBase: " + str);
		}
		public function get configuration(): ILayerConfiguration
		{ return m_cfg; }

		public function get synchronisationRole(): SynchronisationRole
		{ return m_synchronisationRole; }
		
		override public function toString(): String
		{
			return "InteractiveLayerMSBase " + name;
		}
	}
}