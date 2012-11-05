package com.iblsoft.flexiweather.ogc
{
	import com.iblsoft.flexiweather.events.InteractiveLayerEvent;
	import com.iblsoft.flexiweather.events.InteractiveLayerProgressEvent;
	import com.iblsoft.flexiweather.events.WMSViewPropertiesEvent;
	import com.iblsoft.flexiweather.net.events.UniURLLoaderErrorEvent;
	import com.iblsoft.flexiweather.net.events.UniURLLoaderEvent;
	import com.iblsoft.flexiweather.net.loaders.UniURLLoader;
	import com.iblsoft.flexiweather.ogc.cache.ICache;
	import com.iblsoft.flexiweather.ogc.cache.ICachedLayer;
	import com.iblsoft.flexiweather.ogc.cache.WMSCache;
	import com.iblsoft.flexiweather.ogc.data.GlobalVariable;
	import com.iblsoft.flexiweather.ogc.data.GlobalVariableValue;
	import com.iblsoft.flexiweather.ogc.data.viewProperties.IViewProperties;
	import com.iblsoft.flexiweather.ogc.data.viewProperties.IWMSViewPropertiesLoader;
	import com.iblsoft.flexiweather.ogc.data.ImagePart;
	import com.iblsoft.flexiweather.ogc.data.viewProperties.WMSViewProperties;
	import com.iblsoft.flexiweather.ogc.events.GetCapabilitiesEvent;
	import com.iblsoft.flexiweather.ogc.events.MSBaseLoaderEvent;
	import com.iblsoft.flexiweather.ogc.multiview.synchronization.events.SynchronisationEvent;
	import com.iblsoft.flexiweather.ogc.net.loaders.MSBaseLoader;
	import com.iblsoft.flexiweather.ogc.net.loaders.WMSFeatureInfoLoader;
	import com.iblsoft.flexiweather.ogc.net.loaders.WMSImageLoader;
	import com.iblsoft.flexiweather.ogc.preload.IPreloadableLayer;
	import com.iblsoft.flexiweather.proj.Coord;
	import com.iblsoft.flexiweather.proj.Projection;
	import com.iblsoft.flexiweather.utils.ArrayUtils;
	import com.iblsoft.flexiweather.utils.Duration;
	import com.iblsoft.flexiweather.utils.ISO8601Parser;
	import com.iblsoft.flexiweather.widgets.BackgroundJob;
	import com.iblsoft.flexiweather.widgets.GlowLabel;
	import com.iblsoft.flexiweather.widgets.IConfigurableLayer;
	import com.iblsoft.flexiweather.widgets.InteractiveDataLayer;
	import com.iblsoft.flexiweather.widgets.InteractiveLayer;
	import com.iblsoft.flexiweather.widgets.InteractiveWidget;
	
	import flash.display.AVM1Movie;
	import flash.display.Bitmap;
	import flash.display.BitmapData;
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
	import mx.collections.ArrayCollection;
	import mx.controls.Image;
	import mx.core.IVisualElement;
	import mx.core.UIComponent;
	import mx.effects.Fade;
	import mx.events.DynamicEvent;
	import mx.events.EffectEvent;
	import mx.logging.Log;
	
	import spark.components.Group;
	import com.iblsoft.flexiweather.ogc.configuration.layers.interfaces.ILayerConfiguration;
	import com.iblsoft.flexiweather.ogc.configuration.layers.WMSLayerConfiguration;
	
	[Event(name="wmsStyleChanged", type="flash.events.Event")]
	
	/**
	 * Common base class for WMS type layers
	 *  
	 * @author fkormanak
	 * 
	 */	
	public class InteractiveLayerMSBase extends InteractiveDataLayer
			implements ISynchronisedObject, IConfigurableLayer, ICachedLayer, IPreloadableLayer
	{
		protected var m_featureInfoLoader: WMSFeatureInfoLoader = new WMSFeatureInfoLoader();

		
		protected var mb_updateAfterMakingVisible: Boolean = false;
		
		protected var m_cfg: WMSLayerConfiguration;
//		protected var md_dimensionValues: Dictionary = new Dictionary(); 
		protected var md_customParameters: Dictionary = new Dictionary(); 
		protected var ma_subLayerStyleNames: Array = [];
		
		protected var mb_synchroniseLevel: Boolean;
		protected var m_synchronisationRole: SynchronisationRole;

		protected var m_cache: ICache;
		
		/**
		 * Currently displayed wms data 
		 */		
		protected var m_currentWMSViewProperties: WMSViewProperties;
		
		public function get currentViewProperties(): IViewProperties
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
		
		private var _capabilitiesReady: Boolean;
		protected function get capabilitiesReady(): Boolean
		{
			if (m_cfg && m_cfg.service)
				return m_cfg.service.capabilitiesUpdated;
			
			return _capabilitiesReady;
		}
		private var _updateDataWaiting: Boolean;
		
		public function InteractiveLayerMSBase(container: InteractiveWidget, cfg: WMSLayerConfiguration)
		{
			super(container);
			
			m_cfg = cfg;
			
			addEventListener(Event.ADDED_TO_STAGE, onAddedToStage);
		}
		
		override protected function initializeLayer():void
		{
			super.initializeLayer();
			
			ma_preloadingWMSViewProperties = [];
			ma_preloadedWMSViewProperties = [];
			
			m_currentWMSViewProperties = new WMSViewProperties();
			m_currentWMSViewProperties.parentLayer = this;
			m_currentWMSViewProperties.crs = container.crs;
			m_currentWMSViewProperties.setViewBBox(container.getViewBBox());
			m_currentWMSViewProperties.addEventListener(SynchronisedVariableChangeEvent.SYNCHRONISED_VARIABLE_CHANGED, onCurrentWMSDataSynchronisedVariableChanged);
			m_currentWMSViewProperties.addEventListener(WMSViewPropertiesEvent.WMS_DIMENSION_VALUE_SET, onWMSDimensionValueSet);
			
			m_featureInfoLoader.addEventListener(UniURLLoaderEvent.DATA_LOADED, onFeatureInfoLoaded);
			m_featureInfoLoader.addEventListener(UniURLLoaderErrorEvent.DATA_LOAD_FAILED, onFeatureInfoLoadFailed);
			
			m_synchronisationRole = new SynchronisationRole();
			
			setConfiguration(m_cfg);
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
		
		private function onAddedToStage(event: Event): void
		{
			removeEventListener(Event.ADDED_TO_STAGE, onAddedToStage);
			
			//WMS layer always synchronise FRAME variable
			notifySynchronizationChange(GlobalVariable.FRAME, null, true);
		}
		
		public function changeViewProperties(viewProperties: IViewProperties): void
		{
			m_currentWMSViewProperties.removeEventListener(SynchronisedVariableChangeEvent.SYNCHRONISED_VARIABLE_CHANGED, onCurrentWMSDataSynchronisedVariableChanged);
			m_currentWMSViewProperties.removeEventListener(WMSViewPropertiesEvent.WMS_DIMENSION_VALUE_SET, onWMSDimensionValueSet);
			
			m_currentWMSViewProperties = viewProperties as WMSViewProperties;
			
			m_currentWMSViewProperties.addEventListener(SynchronisedVariableChangeEvent.SYNCHRONISED_VARIABLE_CHANGED, onCurrentWMSDataSynchronisedVariableChanged);
			m_currentWMSViewProperties.addEventListener(WMSViewPropertiesEvent.WMS_DIMENSION_VALUE_SET, onWMSDimensionValueSet);
		}
		
		/**
		 * Preload all frames from input array
		 *  
		 * @param wmsViewPropertiesArray - input array
		 * 
		 */		
		public function preloadMultiple(viewPropertiesArray: Array): void
		{
			for each (var wmsViewProperties: WMSViewProperties in viewPropertiesArray)
			{
				preload(wmsViewProperties);
			}
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
		protected function updateWMSViewPropertiesConfiguration(wmsViewProperties: WMSViewProperties, configuration: ILayerConfiguration, cache: ICache): void
		{
			wmsViewProperties.setConfiguration(m_cfg);
//			wmsViewProperties.cache = m_cache;
		}
		
		protected function destroyWMSViewPropertiesPreloader(loader: IWMSViewPropertiesLoader): void
		{
			loader.removeEventListener("invalidateDynamicPart", onWMSViewPropertiesDataInvalidateDynamicPart);
			loader.removeEventListener(InteractiveDataLayer.LOADING_FINISHED, onPreloadingWMSDataLoadingFinished);
			
			loader.destroy();
		}
		
		protected function getWMSViewPropertiesLoader(): IWMSViewPropertiesLoader
		{
			return new MSBaseLoader(this);
		}
		
		public function preload(viewProperties: IViewProperties): void
		{
			var wmsViewProperties: WMSViewProperties = viewProperties as WMSViewProperties;
			if (!wmsViewProperties)
				return;
			
			wmsViewProperties.name = name;
			
			updateWMSViewPropertiesConfiguration(wmsViewProperties, m_cfg, m_cache);
			
			//TODO should we check if CRS abd ViewBBOx is null and set it automatically to InteractiveWidget CRS and ViewBBox
			if (!wmsViewProperties.crs)
				wmsViewProperties.crs = container.getCRS();
			if (!wmsViewProperties.getViewBBox())
				wmsViewProperties.setViewBBox(container.getViewBBox());
			
			if (ma_preloadingWMSViewProperties.length == 0)
			{
				dispatchEvent(new InteractiveLayerEvent(InteractiveDataLayer.PRELOADING_STARTED, true));
			}
			
			ma_preloadingWMSViewProperties.push(wmsViewProperties);
			
			//FIXME loader needs to be destroyed, when data are loaded
			var loader: IWMSViewPropertiesLoader = getWMSViewPropertiesLoader();
			
			loader.addEventListener("invalidateDynamicPart", onWMSViewPropertiesDataInvalidateDynamicPart);
			loader.addEventListener(InteractiveDataLayer.LOADING_STARTED, onPreloadingWMSDataLoadingStarted);
			loader.addEventListener(InteractiveDataLayer.LOADING_FINISHED, onPreloadingWMSDataLoadingFinished);
			
			loader.updateWMSData(true, wmsViewProperties, forcedLayerWidth, forcedLayerHeight);
		}
		
		public function isPreloadedMultiple(viewPropertiesArray: Array): Boolean
		{
			var isAllPreloaded: Boolean = true;
			
			for each (var wmsViewProperties: WMSViewProperties in viewPropertiesArray)
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
		
		public function isPreloaded(viewProperties: IViewProperties): Boolean
		{
			var wmsViewProperties: WMSViewProperties = viewProperties as WMSViewProperties;
			if (!wmsViewProperties)
				return false;
		
			var i_width: int = int(container.width);
			var i_height: int = int(container.height);
			
			if (forcedLayerWidth > 0)
				i_width = forcedLayerWidth;
			if (forcedLayerHeight > 0)
				i_height = forcedLayerHeight;
			
			var s_currentCRS: String = wmsViewProperties.crs;
			var currentViewBBox: BBox = wmsViewProperties.getViewBBox();
			
			var f_horizontalPixelSize: Number = currentViewBBox.width / i_width;
			var f_verticalPixelSize: Number = currentViewBBox.height / i_height;
			
			var projection: Projection = Projection.getByCRS(s_currentCRS);
			var parts: Array = container.mapBBoxToProjectionExtentParts(currentViewBBox);
			//			var parts: Array = container.mapBBoxToViewParts(projection.extentBBox);
//			var dimensions: Array = getDimensionForCache(wmsViewProperties);
			
			var isCached: Boolean = true;
			for each(var partBBoxToUpdate: BBox in parts) {
				var isPartCached: Boolean = isPartCached(
					wmsViewProperties,
					partBBoxToUpdate,
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
		private function isPartCached(wmsViewProperties: WMSViewProperties, currentViewBBox: BBox, i_width: uint, i_height: uint): Boolean
		{
			/**
			 * this is how you can find properties for cache metadata
			 * 
			 * var s_currentCRS: String = container.getCRS();
			 * var currentViewBBox: BBox = container.getViewBBox();
			 * var dimensions: Array = getDimensionForCache();
			 */
			
			var request: URLRequest = m_cfg.toGetMapRequest(
				wmsViewProperties.crs, currentViewBBox.toBBOXString(),
				i_width, i_height,
				getWMSStyleListString());
			
			if (!request)
				return false;
			
			wmsViewProperties.updateDimensionsInURLRequest(request);
			wmsViewProperties.updateCustomParametersInURLRequest(request);
			
			var wmsCache: WMSCache = getCache() as WMSCache;
			
			//			var img: Bitmap = null;
			
//			var itemMetadata: CacheItemMetadata = new CacheItemMetadata();
//			itemMetadata.crs = s_currentCRS;
//			itemMetadata.bbox = currentViewBBox;
//			itemMetadata.url = request;
//			itemMetadata.dimensions = dimensions;
			
			wmsViewProperties.url = request;
			
			var isCached: Boolean = wmsCache.isItemCached(wmsViewProperties)
			var imgTest: DisplayObject = wmsCache.getCacheItemBitmap(wmsViewProperties);
			if (isCached && imgTest != null) {
				return true;
			}
			return false;
		}
		
		public function getDimensionForCache(wmsViewProperties: WMSViewProperties): Array
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
		
		protected function onPreloadingWMSDataLoadingStarted(event: InteractiveLayerEvent): void
		{
//			var wmsViewProperties: WMSViewProperties = event.target as WMSViewProperties;
//			wmsViewProperties.removeEventListener(InteractiveDataLayer.LOADING_STARTED, onPreloadingWMSDataLoadingStarted);
//			trace("\t onPreloadingWMSDataLoadingStarted wmsData: " + wmsViewProperties);
			
		}
		protected function onPreloadingWMSDataLoadingFinished(event: InteractiveLayerEvent): void
		{
			var loader: IWMSViewPropertiesLoader = event.target as IWMSViewPropertiesLoader;
			destroyWMSViewPropertiesPreloader(loader);
			
			var wmsViewProperties: WMSViewProperties = event.data.wmsViewProperties as WMSViewProperties;
			wmsViewProperties.removeEventListener(InteractiveDataLayer.LOADING_FINISHED, onPreloadingWMSDataLoadingFinished);
//			debug("onPreloadingWMSDataLoadingFinished wmsData: " + wmsViewProperties);
//			trace("\t onPreloadingWMSDataLoadingFinished PRELOADED: " + ma_preloadedWMSViewProperties.length + " , PRELAODING: " + ma_preloadingWMSViewProperties.length);
			
			//remove wmsViewProperties from array of currently preloading wms view properties
			var total: int = ma_preloadingWMSViewProperties.length;
			for (var i: int = 0; i < total; i++)
			{
				var currWMSViewProperties: WMSViewProperties = ma_preloadingWMSViewProperties[i] as WMSViewProperties;
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
				
				//dispatch preloading finished to notify all about all WMSViewProperties are preloaded
				dispatchEvent(new InteractiveLayerEvent(InteractiveDataLayer.PRELOADING_FINISHED, true));
			}
		}
		
		
		protected function onCurrentWMSDataSynchronisedVariableChanged(event: SynchronisedVariableChangeEvent): void
		{
			dispatchEvent(event);
		}
		
		protected function onWMSViewPropertiesDataInvalidateDynamicPart(event: DynamicEvent): void
		{
			trace("onWMSViewPropertiesDataInvalidateDynamicPart");	
		}
		
		protected function onCurrentWMSDataInvalidateDynamicPart(event: DynamicEvent): void
		{
//			trace("\t onCurrentWMSDataInvalidateDynamicPart ["+this+"]");
			invalidateDynamicPart(event['invalid']);
		}
		
		protected var _currentWMSDataLoadingStarted: Boolean;
		
		protected function onCurrentWMSDataLoadingStarted(event: InteractiveLayerEvent): void
		{
//			trace("\t onCurrentWMSDataLoadingStarted ["+name+"]");
			_currentWMSDataLoadingStarted = true;
			notifyLoadingStart(false);
		}
		
		protected function onCurrentWMSDataProgress(event: InteractiveLayerProgressEvent): void
		{
//			trace("\t onCurrentWMSDataProgress ["+name+"]");
			notifyProgress(event.loaded, event.total, event.units);
			
		}
		
		protected function onCurrentWMSDataLoadingFinished(event: InteractiveLayerEvent): void
		{
//			trace("\t onCurrentWMSDataLoadingFinished ["+name+"]");
			var loader: MSBaseLoader = event.target as MSBaseLoader;
			loader.removeEventListener(InteractiveDataLayer.LOADING_STARTED, onCurrentWMSDataLoadingStarted);
			loader.removeEventListener(InteractiveDataLayer.LOADING_FINISHED, onCurrentWMSDataLoadingFinished);
			loader.removeEventListener(InteractiveDataLayer.PROGRESS, onCurrentWMSDataProgress);
			loader.removeEventListener("invalidateDynamicPart", onCurrentWMSDataInvalidateDynamicPart);
			
			notifyLoadingFinished();	
			_currentWMSDataLoadingStarted = false;
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
				if (name)
					m_currentWMSViewProperties.name = name;
			}
				
			checkPostponedUpdateDataCall();
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
		
		protected function waitForCapabilities(): void
		{
			_updateDataWaiting = true;
		}
		override protected function updateData(b_forceUpdate: Boolean): void
		{
			if (!layerInitialized)
				return;
			//we need to postpone updateData if capabilities was not received, otherwise we do not know, if layes is tileable or not
//			trace("MSBase updateData capabilitiesReady: " + capabilitiesReady + " layerWasDestroyed: " + layerWasDestroyed);
			if (!capabilitiesReady)
			{
				waitForCapabilities();
				return;
			}
			
			if (!layerWasDestroyed)
			{
			
				super.updateData(b_forceUpdate);
				
				if(!visible) {
					mb_updateAfterMakingVisible = true;
					return;
				}
				
				updateCurrentWMSViewProperties();
				
				var loader: IWMSViewPropertiesLoader = getWMSViewPropertiesLoader();
				
//				trace("\n\n ***** updateData loader: "+ (loader as MSBaseLoader).id + " ["+this+"]");
				loader.addEventListener(InteractiveDataLayer.LOADING_STARTED, onCurrentWMSDataLoadingStarted);
				loader.addEventListener(InteractiveDataLayer.LOADING_FINISHED, onCurrentWMSDataLoadingFinished);
				loader.addEventListener(InteractiveDataLayer.PROGRESS, onCurrentWMSDataProgress);
				loader.addEventListener("invalidateDynamicPart", onCurrentWMSDataInvalidateDynamicPart);
			
				loader.updateWMSData(b_forceUpdate, m_currentWMSViewProperties, forcedLayerWidth, forcedLayerHeight);
			}
			
		}

		override public function destroy():void
		{
			super.destroy();
			
			
			var wmsViewProperties: WMSViewProperties;
			if (ma_preloadingWMSViewProperties)
			{
				for each (wmsViewProperties in ma_preloadingWMSViewProperties)
				{
					wmsViewProperties.destroy();
				}
			}
			if (ma_preloadedWMSViewProperties)
			{
				for each (wmsViewProperties in ma_preloadedWMSViewProperties)
				{
					wmsViewProperties.destroy();
				}
			}
			
			ma_preloadingWMSViewProperties = null;
			ma_preloadedWMSViewProperties = null;
			
			if (md_customParameters)
			{
				md_customParameters = null;
			}
			if (ma_subLayerStyleNames)
			{
				ma_subLayerStyleNames = null;
			}
			
			if (m_currentWMSViewProperties)
			{
				m_currentWMSViewProperties.removeEventListener(SynchronisedVariableChangeEvent.SYNCHRONISED_VARIABLE_CHANGED, onCurrentWMSDataSynchronisedVariableChanged);
				m_currentWMSViewProperties.removeEventListener(WMSViewPropertiesEvent.WMS_DIMENSION_VALUE_SET, onWMSDimensionValueSet);
				m_currentWMSViewProperties.destroy();
				m_currentWMSViewProperties = null;
			}
			
			if (m_featureInfoLoader)
			{
				m_featureInfoLoader.removeEventListener(UniURLLoaderEvent.DATA_LOADED, onFeatureInfoLoaded);
				m_featureInfoLoader.removeEventListener(UniURLLoaderErrorEvent.DATA_LOAD_FAILED, onFeatureInfoLoadFailed);
				m_featureInfoLoader = null;
			}
			
			if (m_cfg)
			{
				//FIXME we neeed to check, if it's ok to destroy configuration (it should be done in LayerConfigurationManager on removeLayer action)
//				m_cfg.destroy();
				m_cfg.removeEventListener(WMSLayerConfiguration.CAPABILITIES_UPDATED, onCapabilitiesUpdated);
				m_cfg.removeEventListener(WMSLayerConfiguration.CAPABILITIES_RECEIVED, onCapabilitiesReceived);
				m_cfg = null;
			}
			
			container = null;
			fadeIn = null;
			fadeOut = null;
			m_synchronisationRole = null;
			destroyCache();
				
		}
		
		/**
		 * Call this function if you want clear layer graphics 
		 * @param graphics
		 * 
		 */		
		public override function clear(graphics: Graphics): void
		{
			if (!layerWasDestroyed)
			{
				super.draw(graphics);
				
				graphics.clear();
			}
		}
		
		public override function draw(graphics: Graphics): void
		{
			if (!m_currentWMSViewProperties)
				return;
			
			if (!layerWasDestroyed)
			{
//				trace("\n DRAW ["+ this+"]");
				super.draw(graphics);
				
				var imageParts: ArrayCollection = m_currentWMSViewProperties.imageParts;
				
				if(container.height <= 0)
					return;
				if(container.width <= 0)
					return;
				
				var s_currentCRS: String = m_currentWMSViewProperties.crs;
				
//				if (imageParts)
//					trace("\t DRAW currentViewBBox=" + container.getViewBBox().toString() + " imageParts: " + imageParts.length);
				
				for each(var imagePart: ImagePart in imageParts) {
					// Check if CRS of the image part == current CRS of the container
					if(s_currentCRS != imagePart.ms_imageCRS)
					{
						continue; // otherwise we cannot draw it
					}
					
					var reflectedBBoxes:Array = container.mapBBoxToViewReflections(imagePart.m_imageBBox);
					for each(var reflectedBBox: BBox in reflectedBBoxes) {
						drawImagePart(graphics, imagePart.m_image, imagePart.ms_imageCRS, reflectedBBox);
					}
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
			
//			trace("\t DRAWIMAGEPARTASBITMAP(): image-w=" + image.width + " image-h=" + image.height + " ["+this+"]");
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
		
		private function updateCurrentWMSViewProperties(): void
		{
			if (currentViewProperties && container)
			{
				m_currentWMSViewProperties.crs = container.crs;
				m_currentWMSViewProperties.setViewBBox(container.getViewBBox());
			}
			
		}
		override public function onAreaChanged(b_finalChange: Boolean): void
		{
			super.onAreaChanged(b_finalChange);
			updateCurrentWMSViewProperties();
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
			//check if layer has legend	
			if (!m_currentWMSViewProperties)
				return false;
			
			var styleName: String = m_currentWMSViewProperties.getWMSStyleName(0);
			if (!styleName)
				styleName = '';
			var style: Object = m_currentWMSViewProperties.getWMSStyleObject(0, styleName);
			
			if (style)
			{
				return style.legend;
			}	
			return false;
       	}

		
		 override public function removeLegend(group: Group): void
		 {
		 	super.removeLegend(group);
		 	
//			if (m_currentWMSViewProperties)
//				return m_currentWMSViewProperties.removeLegend(group);
			
			if (group)
			{
				while (group.numElements > 0)
				{
					var disp: UIComponent = group.getElementAt(0) as UIComponent;
					if (disp is Image)
					{
						((disp as Image).source as Bitmap).bitmapData.dispose();
					}
					group.removeElementAt(0);
					disp = null;
				}	
			}
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
		 * Render legend. If legend is not cached, it needs to be loaded. 
		 * @param group
		 * @param callback
		 * @param labelAlign
		 * @param hintSize
		 * @return 
		 * 
		 */		
//        override public function renderLegend(group: Group, callback: Function, legendScaleX: Number, legendScaleY: Number, labelAlign: String = 'left', useCache: Boolean = false, hintSize: Rectangle = null): Rectangle
//        {
//        	super.renderLegend(group, callback, legendScaleX, legendScaleY, labelAlign, useCache, hintSize);
//        	
//			if (m_currentWMSViewProperties)
//        		return m_currentWMSViewProperties.renderLegend(group, callback, legendScaleX, legendScaleY, labelAlign, useCache, hintSize);
//					
//			return null;
//        }
		override public function renderLegend(group: Group, callback: Function, legendScaleX: Number, legendScaleY: Number, labelAlign: String = 'left', useCache: Boolean = false, hintSize: Rectangle = null): Rectangle
		{
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

				
				var legendLoader: MSBaseLoader = new MSBaseLoader(this);
				var associatedData: Object = {wmsViewProperties: currentViewProperties, group: group, labelAlign: labelAlign, callback: callback, useCache: useCache, legendScaleX: legendScaleX, legendScaleY: legendScaleY, width: w, height: h};
				legendLoader.addEventListener(MSBaseLoaderEvent.LEGEND_LOADED, onLegendLoaded);
				legendLoader.loadLegend(url, associatedData);
				
			} else {
				createLegend(m_currentWMSViewProperties.legendImage, group, labelAlign, callback, legendScaleX, legendScaleY, w, h);
			}
			
			var gap: int = 2;
			var labelHeight: int = 12;
			return new Rectangle(0,0, w, h + gap + labelHeight);
		}
		
		private function onLegendLoaded(event: MSBaseLoaderEvent): void
		{
			var legendLoader: MSBaseLoader = event.target as MSBaseLoader;
			legendLoader.removeEventListener(MSBaseLoaderEvent.LEGEND_LOADED, onLegendLoaded);
			
			var result: * = event.data.result;
			var associatedData: Object = event.data.associatedData;
			
			(associatedData.wmsViewProperties as WMSViewProperties).legendImage = result;
			createLegend(result, associatedData.group, associatedData.labelAlign, associatedData.callback, associatedData.legendScaleX, associatedData.legendScaleY, associatedData.width, associatedData.height);
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
		private function createLegend(bitmap: Bitmap, group: Group, labelAlign: String, callback: Function, legendScaleX: Number, legendScaleY: Number, origWidth: int, origHeight: int): void
		{
			var gap: int = 2;
			var labelHeight: int = 12;
			
			//add legend label (name of the layer)
			var label: GlowLabel;
			if (group.numElements > 0)
			{
				var labelTest: DisplayObject = group.getElementAt(0) as DisplayObject;
				if (labelTest is GlowLabel && labelTest.name != 'styleLabel')
				{
					label = labelTest as GlowLabel;
				}
			}
			if (!label)
			{
				label = new GlowLabel();
				group.addElement(label);
			}
			
			
			label.glowBlur = 5;
			label.glowColor = 0xffffff;
			label.text = name;
			label.validateNow();
			
			//FIXME FIX for legends text height
			labelHeight = label.measuredHeight;
			
			label.setStyle('textAlign', labelAlign);
			
			//add legend image
			var image: Image;
			if (group.numElements > 1)
			{
				var imageTest: IVisualElement = group.getElementAt(group.numElements - 1);
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
				group.addElement(image);
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
			group.width = image.width;
			group.height = image.height + labelHeight + gap;
			
			
			if(callback != null) {
				callback.apply(null, [group]);
			}
		}
        
		private function clearLegendCache(): void
		{
			var legendImage: Bitmap = m_currentWMSViewProperties.legendImage;
			if (legendImage)
			{
				if (legendImage.width > 0 && legendImage.height > 0)
				{
					legendImage.bitmapData.dispose();
					legendImage = null;
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
			var legendImage: Bitmap = m_currentWMSViewProperties.legendImage;
			if (legendImage)
			{
				var oldWidth: int = (legendImage.width / legendImage.scaleX);
				var oldHeight: int = (legendImage.height / legendImage.scaleY);
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
		
        public function getLegendFromGroup(group: Group): Image
        {
			var image: Image;
			if (group.numElements > 1)
			{
				var imageTest: IVisualElement = group.getElementAt(group.numElements - 1);
				if (imageTest is Image)
				{
					image = imageTest as Image;
				}
			}
			
			return image;
        }
        
        public function isLegendCached(group: Group): Boolean
        {
			var image: Image = getLegendFromGroup(group);
			return (image != null);
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
			var a: Array = [];
			for each(var s_layerName: String in m_cfg.layerNames) {
				var layer: WMSLayer = m_cfg.service.getLayerByName(s_layerName);
				if(layer != null)
					a.push(layer);
			}
			return a;
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
		
		private function onWMSDimensionValueSet(event: WMSViewPropertiesEvent): void
		{
			afterWMSDimensionValueIsSet(event.dimension, event.value);
		}
		
		protected function afterWMSDimensionValueIsSet(s_dimName: String, s_value: String): void
		{
			// if "run" changed, then even time axis changes
			if(m_cfg.dimensionRunName != null && s_dimName == m_cfg.dimensionRunName) {
				dispatchEvent(new SynchronisedVariableChangeEvent(
					SynchronisedVariableChangeEvent.SYNCHRONISED_VARIABLE_DOMAIN_CHANGED, GlobalVariable.FRAME));
			}
			//if "forecast" changed, we need to update timeline, so we need to dispatch event
			if(m_cfg.dimensionForecastName != null && s_dimName == m_cfg.dimensionForecastName) {
				dispatchEvent(new SynchronisedVariableChangeEvent(
					SynchronisedVariableChangeEvent.SYNCHRONISED_VARIABLE_CHANGED, GlobalVariable.FRAME));
			}
			//if "time" changed, we need to update timeline, so we need to dispatch event
			if(m_cfg.dimensionTimeName != null && s_dimName == m_cfg.dimensionTimeName) {
				dispatchEvent(new SynchronisedVariableChangeEvent(
					SynchronisedVariableChangeEvent.SYNCHRONISED_VARIABLE_CHANGED, GlobalVariable.FRAME));
			}
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
			if (m_currentWMSViewProperties)
				m_currentWMSViewProperties.setWMSDimensionValue(s_dimName, s_value);
			
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

		public function hasSynchronisedVariable(s_variableId: String): Boolean
		{
			if (m_currentWMSViewProperties)
				return m_currentWMSViewProperties.hasSynchronisedVariable(s_variableId);
			
			return false;
		}

		public function getSynchronisedVariableValue(s_variableId: String): Object
		{
			if (status == InteractiveDataLayer.STATE_DATA_LOADED_WITH_ERRORS || status == InteractiveDataLayer.STATE_NO_DATA_AVAILABLE)
				return null;
			
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
			
			var bIsSyncronized: Boolean;
			
			if (isPreloadedWMSDimensionValue(s_variableId, s_value))
			{
				var viewProperties: WMSViewProperties = getPreloadedWMSDimensionValue(s_variableId, s_value);
				if (viewProperties)
				{
					bIsSyncronized = viewProperties.synchroniseWith(s_variableId, s_value);
					if (!bIsSyncronized)
					{
						setStatus(InteractiveDataLayer.STATE_NO_DATA_AVAILABLE);
						clear(graphics);
					} else {
						setStatus(InteractiveDataLayer.STATE_DATA_LOADED);
					}
					return bIsSyncronized;
				}
			}
			if (m_currentWMSViewProperties)
			{
				bIsSyncronized = m_currentWMSViewProperties.synchroniseWith(s_variableId, s_value);
				if (!bIsSyncronized)
				{
					setStatus(InteractiveDataLayer.STATE_NO_DATA_AVAILABLE);
					clear(graphics);
				} else {
					setStatus(InteractiveDataLayer.STATE_DATA_LOADED);
				}
				return bIsSyncronized;
			}
			
			return false;
		}
		

		override protected function onDataLoadFailed(event: UniURLLoaderErrorEvent): void
		{
			super.onDataLoadFailed(event);
			
			if(event != null) {
				ExceptionUtils.logError(Log.getLogger("WMS"), event,
						"Error accessing layers '" + m_cfg.layerNames.join(","))
			}
		}
		
		protected function checkPostponedUpdateDataCall(): void
		{
			if (_updateDataWaiting && capabilitiesReady)
			{
				_updateDataWaiting = false;
				updateData(true);
			}
		}
		
		protected function onCapabilitiesReceived(event: DataEvent): void
		{
			_capabilitiesReady = true;
			
			dispatchEvent(new GetCapabilitiesEvent(
				GetCapabilitiesEvent.CAPABILITIES_RECEIVED));
			
			checkPostponedUpdateDataCall();
		}
		
		protected function onCapabilitiesUpdated(event: DataEvent = null): void
		{
			_capabilitiesReady = true;
			
			dispatchEvent(new SynchronisedVariableChangeEvent(
					SynchronisedVariableChangeEvent.SYNCHRONISED_VARIABLE_DOMAIN_CHANGED, GlobalVariable.FRAME));
			
			if (mb_synchroniseLevel)
			{
				dispatchEvent(new SynchronisedVariableChangeEvent(
						SynchronisedVariableChangeEvent.SYNCHRONISED_VARIABLE_DOMAIN_CHANGED, GlobalVariable.LEVEL));
			}
			
			checkPostponedUpdateDataCall();
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
			
			fadeIn.addEventListener(EffectEvent.EFFECT_END, onFadeInEnd);
			fadeIn.addEventListener(EffectEvent.EFFECT_START, onEffectFadeInStart);
			fadeOut.addEventListener(EffectEvent.EFFECT_START, onEffectFadeOutStart);
			fadeOut.addEventListener(EffectEvent.EFFECT_END, onFadeOutEnd);
			
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
		private function onFadeInEnd(event: EffectEvent): void
		{
			fadeIn.removeEventListener(EffectEvent.EFFECT_END, onFadeInEnd);
			fadeIn.removeEventListener(EffectEvent.EFFECT_START, onEffectFadeInStart);
			fadeIn = null;
			callLater(delayedEffectEnd);
		}
		private function onFadeOutEnd(event: EffectEvent): void
		{
			fadeOut.removeEventListener(EffectEvent.EFFECT_START, onEffectFadeOutStart);
			fadeOut.removeEventListener(EffectEvent.EFFECT_END, onFadeOutEnd);
			fadeOut = null;
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
			//clone all dimensions
			var dimNames: Array = getWMSDimensionsNames();
			for each (var dimName: String in dimNames)
			{
				var value : String = getWMSDimensionValue(dimName);
				newLayer.setWMSDimensionValue(dimName, value);
			}
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
		
		public function get synchroniseLevel(): Boolean
		{
			return mb_synchroniseLevel;
		}
		public function set synchroniseLevel(value: Boolean): void
		{
			if (mb_synchroniseLevel != value)
			{
				mb_synchroniseLevel = value;
				notifySynchronizationChange(GlobalVariable.LEVEL, getSynchronisedVariableValue(GlobalVariable.LEVEL), mb_synchroniseLevel);
			}
		}
		
		protected function notifySynchronizationChange(globalVariable: String, globalVariableValue: Object, synchronise: Boolean): void
		{
			var eventType: String;
			
			if (synchronise)
				eventType = SynchronisationEvent.START_GLOBAL_VARIABLE_SYNCHRONIZATION;
			else
				eventType = SynchronisationEvent.STOP_GLOBAL_VARIABLE_SYNCHRONIZATION;

			var se: SynchronisationEvent = new SynchronisationEvent(eventType, true);
			se.globalVariable = globalVariable;
			se.globalVariableValue = globalVariableValue;
			dispatchEvent(se);
		}
		
		override public function toString(): String
		{
			return "InteractiveLayerMSBase " + name + " / IW: " + container.id;
		}
		
		private function destroyCache():void
		{
			if (m_cache)
				m_cache.destroyCache();
			
			m_cache = null;
			
		}
		
		public function clearCache():void
		{
			if (m_cache)
				m_cache.clearCache();
		}
		
		public function getCache():ICache
		{
			return m_cache;
		}
		
	}
}