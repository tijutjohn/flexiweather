package com.iblsoft.flexiweather.ogc
{
	import com.iblsoft.flexiweather.FlexiWeatherConfiguration;
	import com.iblsoft.flexiweather.events.InteractiveLayerEvent;
	import com.iblsoft.flexiweather.events.InteractiveLayerProgressEvent;
	import com.iblsoft.flexiweather.events.InteractiveLayerWMSEvent;
	import com.iblsoft.flexiweather.events.WMSViewPropertiesEvent;
	import com.iblsoft.flexiweather.net.events.UniURLLoaderErrorEvent;
	import com.iblsoft.flexiweather.net.events.UniURLLoaderEvent;
	import com.iblsoft.flexiweather.net.loaders.LoaderWithAssociatedData;
	import com.iblsoft.flexiweather.net.loaders.UniURLLoader;
	import com.iblsoft.flexiweather.ogc.cache.ICache;
	import com.iblsoft.flexiweather.ogc.cache.ICachedLayer;
	import com.iblsoft.flexiweather.ogc.cache.WMSCache;
	import com.iblsoft.flexiweather.ogc.cache.event.WMSCacheEvent;
	import com.iblsoft.flexiweather.ogc.configuration.layers.WMSLayerConfiguration;
	import com.iblsoft.flexiweather.ogc.configuration.layers.interfaces.ILayerConfiguration;
	import com.iblsoft.flexiweather.ogc.configuration.services.OGCServiceConfiguration;
	import com.iblsoft.flexiweather.ogc.configuration.services.WMSServiceConfiguration;
	import com.iblsoft.flexiweather.ogc.data.GlobalVariable;
	import com.iblsoft.flexiweather.ogc.data.GlobalVariableValue;
	import com.iblsoft.flexiweather.ogc.data.ImagePart;
	import com.iblsoft.flexiweather.ogc.data.viewProperties.IViewProperties;
	import com.iblsoft.flexiweather.ogc.data.viewProperties.IWMSViewPropertiesLoader;
	import com.iblsoft.flexiweather.ogc.data.viewProperties.WMSViewProperties;
	import com.iblsoft.flexiweather.ogc.events.GetCapabilitiesEvent;
	import com.iblsoft.flexiweather.ogc.events.MSBaseLoaderEvent;
	import com.iblsoft.flexiweather.ogc.managers.OGCServiceConfigurationManager;
	import com.iblsoft.flexiweather.ogc.multiview.synchronization.events.SynchronisationEvent;
	import com.iblsoft.flexiweather.ogc.net.loaders.MSBaseLoader;
	import com.iblsoft.flexiweather.ogc.net.loaders.WMSFeatureInfoLoader;
	import com.iblsoft.flexiweather.ogc.net.loaders.WMSImageLoader;
	import com.iblsoft.flexiweather.ogc.preload.IPreloadableLayer;
	import com.iblsoft.flexiweather.ogc.synchronisation.SynchronisationResponse;
	import com.iblsoft.flexiweather.proj.Coord;
	import com.iblsoft.flexiweather.proj.Projection;
	import com.iblsoft.flexiweather.utils.ArrayUtils;
	import com.iblsoft.flexiweather.utils.Duration;
	import com.iblsoft.flexiweather.utils.ISO8601Parser;
	import com.iblsoft.flexiweather.utils.LoggingUtils;
	import com.iblsoft.flexiweather.widgets.BackgroundJob;
	import com.iblsoft.flexiweather.widgets.GlowLabel;
	import com.iblsoft.flexiweather.widgets.IConfigurableLayer;
	import com.iblsoft.flexiweather.widgets.InteractiveDataLayer;
	import com.iblsoft.flexiweather.widgets.InteractiveLayer;
	import com.iblsoft.flexiweather.widgets.InteractiveLayerLegendGroup;
	import com.iblsoft.flexiweather.widgets.InteractiveLayerLegendImage;
	import com.iblsoft.flexiweather.widgets.InteractiveWidget;
	import com.iblsoft.flexiweather.widgets.data.InteractiveLayerPrintQuality;
	
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

	[Event(name = "wmsStyleChanged", type = "com.iblsoft.flexiweather.events.InteractiveLayerWMSEvent")]

	/**
	 * Dispatched when WMS Dimension (RUN, FORECAST, ELEVATION) is set 
	 */	
	[Event(name = "wmsDimensionValueSet", type = "com.iblsoft.flexiweather.events.WMSViewPropertiesEvent")]
	
	
	/**
	 * Common base class for WMS type layers
	 *
	 * @author fkormanak
	 *
	 */
	public class InteractiveLayerMSBase extends InteractiveDataLayer implements ISynchronisedObject, IConfigurableLayer, ICachedLayer, IPreloadableLayer
	{
		protected var m_featureInfoLoader: WMSFeatureInfoLoader = new WMSFeatureInfoLoader();
		protected var mb_updateAfterMakingVisible: Boolean = false;
		protected var m_cfg: WMSLayerConfiguration;
//		protected var md_dimensionValues: Dictionary = new Dictionary(); 
		protected var md_customParameters: Dictionary = new Dictionary();
		protected var ma_subLayerStyleNames: Array = [];
		protected var mb_synchroniseLevel: Boolean;
		protected var mb_synchroniseRun: Boolean;
		protected var m_synchronisationRole: SynchronisationRole;
		protected var m_cache: ICache;
		
		protected var _tempParameterStorage: LayerTemporaryParameterStorage = new LayerTemporaryParameterStorage();
		/**
		 * Currently displayed wms data
		 */
		protected var m_currentWMSViewProperties: WMSViewProperties;

		public function get currentViewProperties(): IViewProperties
		{
			return m_currentWMSViewProperties;
		}
		
		/**
		 * Selected style name. It is stored in currentWMSViewProperties, but on save (serialize) it's stored in layer because of loading process should set correctly
		 * stylename on layer initialization (which is asynchronous (see initializeLayerProperties() method)) 
		 */		
//		protected var styleNameValue: String;
		/**
		 * Selected level value (ELEVATION). It is stored in currentWMSViewProperties, but on save (serialize) it's stored in layer because of loading process should set correctly
		 * level on layer initialization (which is asynchronous (see initializeLayerProperties() method)) 
		 */		
//		protected var level: String;
		
		/**
		 * Selected synchronization role value. It is stored in currentWMSViewProperties, but on save (serialize) it's stored in layer because of loading process should set correctly
		 *  synchronization role on layer initialization (which is asynchronous (see initializeLayerProperties() method)) 
		 */		
		protected var synchronizationRoleValue: String;
		
		/**
		 * wms data which are already preloaded
		 */
		protected var ma_preloadedWMSViewProperties: Array;
		private var _capabilitiesReady: Boolean;

		protected function get capabilitiesReady(): Boolean
		{
			if (!FlexiWeatherConfiguration.FLEXI_WEATHER_LOADS_GET_CAPABILITIES)
			{
				//if FlexiWeather is not reading GetCapabilities requests, this getter return always TRUE
				return true;
			}
			
			if (m_cfg && m_cfg.service)
			{
				return (m_cfg.service as WMSServiceConfiguration).capabilitiesUpdated;
			}
			return _capabilitiesReady;
		}
		private var _updateDataWaiting: Boolean;

		override public function get supportsVectorData(): Boolean
		{
			if (m_cfg && m_cfg.wmsService && m_cfg.wmsService.imageFormats)
			{
				var imageFormats: Array = m_cfg.wmsService.imageFormats;
				if (imageFormats.length > 0)
				{
					for each (var format: String in imageFormats)
					{
						if (format.indexOf('x-shockwave-flash') >= 0)
							return true;
					}
				}
			}
			return false;
		}
		
		private var _vectorParent: UIComponent;
		
		public function InteractiveLayerMSBase(container: InteractiveWidget, cfg: WMSLayerConfiguration)
		{
			super(container);
			
			synchronizationRoleValue = SynchronisationRole.NONE;
			
			configuration = cfg;
			
			addEventListener(Event.ADDED_TO_STAGE, onAddedToStage);
			
		}

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
			ma_preloadingBuffer = [];
			ma_preloadedWMSViewProperties = [];
			m_currentWMSViewProperties = new WMSViewProperties();
			m_currentWMSViewProperties.parentLayer = this;
			m_currentWMSViewProperties.crs = container.crs;
			m_currentWMSViewProperties.setViewBBox(container.getViewBBox());
			m_currentWMSViewProperties.addEventListener(SynchronisedVariableChangeEvent.SYNCHRONISED_VARIABLE_CHANGED, onCurrentWMSDataSynchronisedVariableChanged);
			m_currentWMSViewProperties.addEventListener(WMSViewPropertiesEvent.WMS_DIMENSION_VALUE_SET, onWMSDimensionValueSet);
			m_featureInfoLoader.addEventListener(UniURLLoaderEvent.DATA_LOADED, onFeatureInfoLoaded);
			m_featureInfoLoader.addEventListener(UniURLLoaderErrorEvent.DATA_LOAD_FAILED, onFeatureInfoLoadFailed);
			m_synchronisationRole = new SynchronisationRole(synchronizationRoleValue);
			setConfiguration(m_cfg);
			//filters = [ new GlowFilter(0xffffe0, 0.8, 2, 2, 2) ];
			createEffects();
//			setStyle('addedEffect', fadeIn);
			setStyle('showEffect', fadeIn);
//			setStyle('removedEffect', fadeOut);
			setStyle('hideEffect', fadeOut);
			
			
			//check if layers was created from serialization
			// update current wms properties from temporary storage. That means that user set wms style, wms dimension value, custom parameter or configuration
			// before layer was added to stage
			// in _tempParameterStorage there are also store properties serialized from current WMSViewProperties
			_tempParameterStorage.updateCurrentWMSPropertiesFromStorage(m_currentWMSViewProperties);
		}
		
		private function initializeConfiguration(): void
		{
			if (m_cfg && m_cfg.service)
			{
				//update service from OGCServiceConfigurationManager
				var serviceManager: OGCServiceConfigurationManager = OGCServiceConfigurationManager.getInstance();
				var existingService: OGCServiceConfiguration = serviceManager.getServiceByName(m_cfg.service.baseURL);
				
				var wmsService: WMSServiceConfiguration = existingService as WMSServiceConfiguration; 
				
				if (wmsService && wmsService.capabilitiesUpdated)
				{
					//					trace("OGCServiceConfigurationManager found same service with capabilities already updated");
					m_cfg.service = wmsService;
				}
			}
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

		override protected function commitProperties():void
		{
			super.commitProperties();
			
			if (_configurationChanged)
			{
				initializeConfiguration();
				_configurationChanged = false;
			}
		}
		public function changeViewProperties(viewProperties: IViewProperties): void
		{
			if ((viewProperties as WMSViewProperties).crs != container.crs)
			{
				var crsError: Error = new Error("InteractiveLayerMSBase ChangeViewProperties: Layer CRS is different than InteractiveWidget.CRS");
				throw crsError;
			}
			
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

		protected function destroyWMSViewPropertiesPreloader(): void
		{
			if (_preloader)
			{
				_preloader.removeEventListener(InteractiveLayerEvent.INVALIDATE_DYNAMIC_PART, onWMSViewPropertiesDataInvalidateDynamicPart);
				_preloader.removeEventListener(InteractiveDataLayer.LOADING_FINISHED, onPreloadingWMSDataLoadingFinished);
				_preloader.destroy();
			}
		}

		
		protected function getWMSViewPropertiesLoader(): IWMSViewPropertiesLoader
		{
			var loader: MSBaseLoader = new MSBaseLoader(this); 
			return loader; 
		}

		
		private var _preloader: MSBaseLoader;
		/**
		 * Function will cancel all preloading immediately 
		 * 
		 */		
		public function cancelPreload(): void
		{
			//FIXME cancel currently preloading request 
			if (_preloader)
				_preloader.cancel();
			
			setPreloadingStatus(false);
			ma_preloadedWMSViewProperties = [];
			ma_preloadingBuffer = [];
		}
		
		public function preload(viewProperties: IViewProperties): void
		{
			var wmsViewProperties: WMSViewProperties = viewProperties as WMSViewProperties;
			if (!wmsViewProperties)
				return;
			wmsViewProperties.name = name;
			updateWMSViewPropertiesConfiguration(wmsViewProperties, m_cfg, m_cache);

			if (!wmsViewProperties.crs)
				wmsViewProperties.crs = container.getCRS();
			if (!wmsViewProperties.getViewBBox())
				wmsViewProperties.setViewBBox(container.getViewBBox());

			if (!_preloader)
			{
				_preloader = getWMSViewPropertiesLoader() as MSBaseLoader;
				_preloader.addEventListener(InteractiveLayerEvent.INVALIDATE_DYNAMIC_PART, onWMSViewPropertiesDataInvalidateDynamicPart);
				_preloader.addEventListener(InteractiveDataLayer.LOADING_STARTED, onPreloadingWMSDataLoadingStarted);
				_preloader.addEventListener(InteractiveDataLayer.LOADING_FINISHED, onPreloadingWMSDataLoadingFinished);
				_preloader.addEventListener(InteractiveDataLayer.LOADING_FINISHED_FROM_CACHE, onPreloadingWMSDataLoadingFinished);
			}
			
			if (!preloading)
			{
				setPreloadingStatus(true);
				_preloader.updateWMSData(true, wmsViewProperties, forcedLayerWidth, forcedLayerHeight, printQuality);
			} else {
				ma_preloadingBuffer.push(wmsViewProperties);
			}
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
			
			if (!currentViewBBox)
			{
				return false;
			}
			var f_horizontalPixelSize: Number = currentViewBBox.width / i_width;
			var f_verticalPixelSize: Number = currentViewBBox.height / i_height;
			var projection: Projection = Projection.getByCRS(s_currentCRS);
			var parts: Array = container.mapBBoxToProjectionExtentParts(currentViewBBox);
			//			var parts: Array = container.mapBBoxToViewParts(projection.extentBBox);
//			var dimensions: Array = getDimensionForCache(wmsViewProperties);
			var isCached: Boolean = true;
			if (parts.length > 0)
			{
				for each (var partBBoxToUpdate: BBox in parts)
				{
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
			return false;
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
			
			var bbox: String;
			if (Projection.hasCRSAxesFlippedByISO(wmsViewProperties.crs, (configuration as WMSLayerConfiguration).service.version))
			{
				bbox = String(currentViewBBox.yMin) + "," + String(currentViewBBox.xMin) + "," + String(currentViewBBox.yMax) + "," + String(currentViewBBox.xMax);	
			} else {
				bbox = currentViewBBox.toBBOXString();
			}
			
			/**
			 * this is how you can find properties for cache metadata
			 *
			 * var s_currentCRS: String = container.getCRS();
			 * var currentViewBBox: BBox = container.getViewBBox();
			 * var dimensions: Array = getDimensionForCache();
			 */
			var request: URLRequest = m_cfg.toGetMapRequest(
					wmsViewProperties.crs, bbox,
					i_width, i_height,
					printQuality,
					getWMSStyleListString());
			if (!request)
				return false;
			wmsViewProperties.updateDimensionsInURLRequest(request);
			wmsViewProperties.updateCustomParametersInURLRequest(request);
			var wmsCache: WMSCache = getCache() as WMSCache;
			wmsViewProperties.url = request;
			var isCached: Boolean = wmsCache.isItemCached(wmsViewProperties)
			var imgTest: DisplayObject = wmsCache.getCacheItemBitmap(wmsViewProperties);
			if (isCached && imgTest != null)
			{
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
		}

		protected function onPreloadingWMSDataLoadingFinished(event: InteractiveLayerEvent): void
		{
			var loader: IWMSViewPropertiesLoader = event.target as IWMSViewPropertiesLoader;
//			destroyWMSViewPropertiesPreloader(loader);
			var wmsViewProperties: WMSViewProperties = event.data.wmsViewProperties as WMSViewProperties;
			wmsViewProperties.removeEventListener(InteractiveDataLayer.LOADING_FINISHED, onPreloadingWMSDataLoadingFinished);
			wmsViewProperties.removeEventListener(InteractiveDataLayer.LOADING_FINISHED_FROM_CACHE, onPreloadingWMSDataLoadingFinished);

			//add wmsViewProperties to array of already preloaded wms view properties
			ma_preloadedWMSViewProperties.push(wmsViewProperties);
			setPreloadingStatus(false);
			
			notifyProgress(ma_preloadedWMSViewProperties.length, ma_preloadingBuffer.length + ma_preloadedWMSViewProperties.length, 'frames');
			
			
			if (ma_preloadingBuffer.length > 0)
			{
				//preload next frame
				var newWMSViewProperties: WMSViewProperties = ma_preloadingBuffer.shift() as WMSViewProperties;
				preload(newWMSViewProperties);
			} else {
				//all frames are preloaded
				ma_preloadingBuffer = [];
				var ile: InteractiveLayerEvent = new InteractiveLayerEvent(InteractiveDataLayer.PRELOADING_FINISHED, true);
				ile.data = wmsViewProperties;
				dispatchEvent(ile);
			}
		}

		protected function onCurrentWMSDataSynchronisedVariableChanged(event: SynchronisedVariableChangeEvent): void
		{
			dispatchEvent(event);
		}

		protected function onWMSViewPropertiesDataInvalidateDynamicPart(event: DynamicEvent): void
		{
		}

		protected function onCurrentWMSDataInvalidateDynamicPart(event: DynamicEvent): void
		{
			invalidateDynamicPart(event['invalid']);
		}
		protected var _currentWMSDataLoadingStarted: Boolean;

		protected function onCurrentWMSDataLoadingStarted(event: InteractiveLayerEvent): void
		{
			_currentWMSDataLoadingStarted = true;
			notifyLoadingStart(true);
		}

		protected function onCurrentWMSDataProgress(event: InteractiveLayerProgressEvent): void
		{
			notifyProgress(event.loaded, event.total, event.units);
		}

		private function destroyLoaderListeners(): void
		{
			if (_loader)
			{
				_loader.removeEventListener(InteractiveDataLayer.LOADING_STARTED, onCurrentWMSDataLoadingStarted);
				_loader.removeEventListener(InteractiveDataLayer.LOADING_FINISHED, onCurrentWMSDataLoadingFinished);
				_loader.removeEventListener(InteractiveDataLayer.LOADING_FINISHED_FROM_CACHE, onCurrentWMSDataLoadingFinishedFromCache);
				_loader.removeEventListener(InteractiveDataLayer.LOADING_FINISHED_NO_SYNCHRONIZATION_DATA, onCurrentWMSDataLoadingFinishedNoSynchronizationData);
				_loader.removeEventListener(InteractiveDataLayer.LOADING_ERROR, onCurrentWMSDataLoadingError);
				_loader.removeEventListener(InteractiveDataLayer.PROGRESS, onCurrentWMSDataProgress);
				_loader.removeEventListener(InteractiveLayerEvent.INVALIDATE_DYNAMIC_PART, onCurrentWMSDataInvalidateDynamicPart);
				_loader.destroy();
			}
		}
		protected function onCurrentWMSDataLoadingFinishedNoSynchronizationData(event: InteractiveLayerEvent): void
		{
			var loader: MSBaseLoader = event.target as MSBaseLoader;
//			removeLoaderListeners(loader);
			notifyLoadingFinishedNoSynchronizationData();
			noSynchronisationDataAvailable(graphics);
			_currentWMSDataLoadingStarted = false;
			
		}
		protected function onCurrentWMSDataLoadingError(event: InteractiveLayerEvent): void
		{
			var loader: MSBaseLoader = event.target as MSBaseLoader;
//			removeLoaderListeners(loader);
			notifyLoadingError();
			_currentWMSDataLoadingStarted = false;
		}
		protected function onCurrentWMSDataLoadingFinished(event: InteractiveLayerEvent): void
		{
			var loader: MSBaseLoader = event.target as MSBaseLoader;
//			removeLoaderListeners(loader);
			notifyLoadingFinished();
			_currentWMSDataLoadingStarted = false;
		}
		protected function onCurrentWMSDataLoadingFinishedFromCache(event: InteractiveLayerEvent): void
		{
			var loader: MSBaseLoader = event.target as MSBaseLoader;
//			removeLoaderListeners(loader);
			notifyLoadingFinishedFromCache();
			_currentWMSDataLoadingStarted = false;
		}

		public function setConfiguration(cfg: WMSLayerConfiguration): void
		{
//			debug("setConfiguration : cap received: " + cfg.capabilitiesReceived + " / " + cfg);
			if (m_cfg != null)
			{
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
			
			if (m_cfg.capabilitiesReceived)
			{
				//if capabilities was already received before layer was created, we can call onCapabilitiesUpdated right here
				callLater(onCapabilitiesUpdated);
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
			return getGetMapFullUrl(width, height);
		}

		/**
		 * function returns full URL for getting map
		 * @return
		 *
		 */
		override public function getFullURL(): String
		{
			if (container)
				return getGetMapFullUrl(int(container.width), int(container.height));
			
			return getGetMapFullUrl(0,0);
		}

		private function getGetMapFullUrl(width: int, height: int): String
		{
//			if (width != 150)
//			{
//				trace("test getGetMapFullUrl");
//			}
			var wmsLayerConfiguration: WMSLayerConfiguration = configuration as WMSLayerConfiguration;
			
			var bbox: String;
			var crs: String = container.getCRS();
			var viewBBox: BBox = container.getViewBBox();
			
			if (Projection.hasCRSAxesFlippedByISO(crs, wmsLayerConfiguration.service.version))
			{
				bbox = String(viewBBox.yMin) + "," + String(viewBBox.xMin) + "," + String(viewBBox.yMax) + "," + String(viewBBox.xMax);	
			} else {
				bbox = viewBBox.toBBOXString();
			}
			
			var request: URLRequest = m_cfg.toGetMapRequest(
					crs, bbox,
					width, height,
					printQuality,
					getWMSStyleListString());
			if (!request)
				return null;
			updateDimensionsInURLRequest(request);
			updateCustomParametersInURLRequest(request);
			updateRequestData(request);
			var s_url: String = request.url;
			if (request.data)
			{
				if (s_url.indexOf("?") >= 0)
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

		private var _loader: MSBaseLoader;
		
		override protected function updateData(b_forceUpdate: Boolean): void
		{
//			debug("updateDate["+b_forceUpdate+"] _layerInitialized: " + _layerInitialized + " capabilitiesReady: " + capabilitiesReady + " visible: " + visible);
			if (!_layerInitialized)
				return;
			//we need to postpone updateData if capabilities was not received, otherwise we do not know, if layes is tileable or not
			if (!capabilitiesReady)
			{
				waitForCapabilities();
				return;
			}
			if (!layerWasDestroyed)
			{
				if (status != STATE_NO_SYNCHRONISATION_DATA_AVAILABLE)
				{
					super.updateData(b_forceUpdate);
					if (!visible)
					{
						mb_updateAfterMakingVisible = true;
						return;
					}
					updateCurrentWMSViewProperties();
					
					if (!_loader)
					{
						_loader = getWMSViewPropertiesLoader() as MSBaseLoader;
						_loader.addEventListener(InteractiveDataLayer.LOADING_STARTED, onCurrentWMSDataLoadingStarted);
						_loader.addEventListener(InteractiveDataLayer.LOADING_FINISHED, onCurrentWMSDataLoadingFinished);
						_loader.addEventListener(InteractiveDataLayer.LOADING_FINISHED_FROM_CACHE, onCurrentWMSDataLoadingFinishedFromCache);
						_loader.addEventListener(InteractiveDataLayer.LOADING_FINISHED_NO_SYNCHRONIZATION_DATA, onCurrentWMSDataLoadingFinishedNoSynchronizationData);
						_loader.addEventListener(InteractiveDataLayer.LOADING_ERROR, onCurrentWMSDataLoadingError);
						_loader.addEventListener(InteractiveDataLayer.PROGRESS, onCurrentWMSDataProgress);
						_loader.addEventListener(InteractiveLayerEvent.INVALIDATE_DYNAMIC_PART, onCurrentWMSDataInvalidateDynamicPart);
					}
					
					//here is problem that m_currentWMSViewProperties has crs ESRI:102021 and viewBBox from CRS:84
					_loader.updateWMSData(b_forceUpdate, m_currentWMSViewProperties, forcedLayerWidth, forcedLayerHeight, printQuality);
				}
			}
		}

		private function destroyPreloading(): void
		{
			var wmsViewProperties: WMSViewProperties;
			if (ma_preloadingBuffer)
			{
				for each (wmsViewProperties in ma_preloadingBuffer)
				{
					wmsViewProperties.destroy();
				}
				ma_preloadingBuffer = null;
			}
			if (ma_preloadedWMSViewProperties)
			{
				for each (wmsViewProperties in ma_preloadedWMSViewProperties)
				{
					wmsViewProperties.destroy();
				}
				ma_preloadedWMSViewProperties = null;
			}
			destroyWMSViewPropertiesPreloader();
			
		}
		
		override public function destroy(): void
		{
			super.destroy();
			var wmsViewProperties: WMSViewProperties;
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
			destroyLoaderListeners();
			destroyPreloading();
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
				super.clear(graphics);
				graphics.clear();
//				removeVectorData();
			}
		}

		public override function draw(graphics: Graphics): void
		{
			if (!m_currentWMSViewProperties)
				return;
			if (!layerWasDestroyed)
			{
				super.draw(graphics);
				var imageParts: ArrayCollection = m_currentWMSViewProperties.imageParts;
				if (container.height <= 0)
					return;
				if (container.width <= 0)
					return;
				var s_currentCRS: String = m_currentWMSViewProperties.crs;
				for each (var imagePart: ImagePart in imageParts)
				{
					// Check if CRS of the image part == current CRS of the container
					if (s_currentCRS != imagePart.ms_imageCRS)
					{
						continue; // otherwise we cannot draw it
					}
					var reflectedBBoxes: Array = container.mapBBoxToViewReflections(imagePart.m_imageBBox);
					for each (var reflectedBBox: BBox in reflectedBBoxes)
					{
						drawImagePart(graphics, imagePart.image, imagePart.ms_imageCRS, reflectedBBox);
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
				
				/**
				 * As we agreed with Jozef, if AVM1Movie was received as data, there can be 2 different modes of rendering
				 * 
				 * 	1) printQuality == high (it's for vector printing) => will be added as avm1movie and it's not cached
				 *  2) printQuality == normal && imageFormat == x-shockwave-flash => will be added as bitmap and will be cached
				 */
				
				if (printQuality == InteractiveLayerPrintQuality.HIGH_QUALITY)
				{
					drawImagePartAsSWF(image as AVM1Movie, s_imageCRS, imageBBox);
				} else {
					
					//TODO cache bitmap
					var bd: BitmapData = new BitmapData(image.width, image.height, true, 0x00ff0000);
					bd.draw(image);
					drawImagePartAsBitmap(graphics, new Bitmap(bd), s_imageCRS, imageBBox);
				}
			}
		}

		private function removeBitmapData(): void
		{
			
		}
		
		private function clearVectorData(): void
		{
			//remove previous instances
			if (_vectorParent && _vectorParent.numChildren > 0)
			{
				var total: int = _vectorParent.numChildren;
				trace("removeVectorData movieObject: " + total + " => " + this);
				for (var i: int = 0; i < total; i++)
				{
					var dispObject: DisplayObject = _vectorParent.removeChildAt(0);
					if (dispObject is LoaderWithAssociatedData)
					{
						var loader: LoaderWithAssociatedData = dispObject as LoaderWithAssociatedData;
						var assocData: Object = loader.associatedData;
						assocData.requestedImagePart = null;
						assocData.result = null;
						assocData.wmsViewProperties = null;
						loader.unload();
						dispObject = null;
					}
					
				}
			}
		}
		private function removeVectorData(): void
		{
			//remove previous instances
			if (_vectorParent && _vectorParent.numChildren > 0)
			{
				clearVectorData();
				
				removeChild(_vectorParent);
				_vectorParent =  null;
			}
			
		}
		private function drawImagePartAsSWF(image: AVM1Movie, s_imageCRS: String, imageBBox: BBox): void
		{
			if (!_vectorParent)
			{
				_vectorParent = new UIComponent();
				addChild(_vectorParent);
			}
			
			clearVectorData();
			
			//clear bitmap data
			clear(graphics);
			
			var movieObject: DisplayObject = image.parent; 
			
			if (movieObject)
				_vectorParent.addChild(movieObject);
			else
				_vectorParent.addChild(image);
		}

		private function drawImagePartAsBitmap(graphics: Graphics, image: Bitmap, s_imageCRS: String, imageBBox: BBox): void
		{
			
			removeVectorData();
			
			var ptImageStartPoint: Point =
					container.coordToPoint(new Coord(s_imageCRS, imageBBox.xMin, imageBBox.yMax));
			var ptImageEndPoint: Point =
					container.coordToPoint(new Coord(s_imageCRS, imageBBox.xMax, imageBBox.yMin));
			ptImageEndPoint.x += 1;
			ptImageEndPoint.y += 1;
			var ptImageSize: Point = ptImageEndPoint.subtract(ptImageStartPoint);
			ptImageSize.x = int(Math.round(ptImageSize.x));
			ptImageSize.y = int(Math.round(ptImageSize.y));
			var matrix: Matrix = new Matrix();
			matrix.scale(ptImageSize.x / image.width, ptImageSize.y / image.height);
			matrix.translate(ptImageStartPoint.x, ptImageStartPoint.y);
			graphics.beginBitmapFill(image.bitmapData, matrix, true, true);
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

		public function refreshForSynchronisation(b_force: Boolean): void
		{
			setStatus(STATE_EMPTY);
			invalidateData(b_force);
			
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

		override public function removeLegend(group: InteractiveLayerLegendGroup): void
		{
			super.removeLegend(group);
			if (group)
			{
				while (group.numElements > 0)
				{
					var disp: UIComponent = group.getElementAt(0) as UIComponent;
					if (disp is InteractiveLayerLegendImage)
					{
						((disp as InteractiveLayerLegendImage).source as Bitmap).bitmapData.dispose();
					}
					group.removeElementAt(0);
					disp = null;
				}
			} else {
				trace("ILMSBase removeLegend, does not have group");
			}
		}

		private function updateURLWithDimensions(url: URLRequest): void
		{
			var str: String = '';
			if (!url.data)
			{
				url.data = new URLVariables();
			}
			for each (var layer: WMSLayer in getWMSLayers())
			{
				for each (var dim: WMSDimension in layer.dimensions)
				{
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
		override public function renderLegend(group: InteractiveLayerLegendGroup, callback: Function, legendScaleX: Number, legendScaleY: Number, labelAlign: String = 'left', useCache: Boolean = false, hintSize: Rectangle = null): Rectangle
		{
			var styleName: String = getWMSStyleName(0);
			if (!styleName)
				styleName = '';
			var style: Object = getWMSStyleObject(0, styleName);
			var legendObject: Object = style.legend;
//			debug("MSBAse renderLegend style: " + style.legend);
			var w: int = legendObject.width;
			var h: int = legendObject.height;
			if (hintSize)
			{
				w = hintSize.width;
				h = hintSize.height;
			}
//			debug("renderLegend url: " + legendObject.url + " scale [" + legendScaleX + "," + legendScaleY + "]");
			if (!useCache || (useCache && !isLegendCachedBySize(w, h)))
			{
				var url: URLRequest = m_cfg.toGetLegendRequest(
						w, h,
						style.name);
//				debug("LEGEND URL1: " + url.url);
				if (!(url.url.indexOf('${BASE_URL}') == 0))
				{
					url = new URLRequest(legendObject.url);
					debug("LEGEND URL2: " + url.url);
				}
				else
				{
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
				
				debug(" load legend for layer: " + this + " viewProperties: " + currentViewProperties);
				legendLoader.loadLegend(url, associatedData);
			}
			else
			{
				createLegend(m_currentWMSViewProperties.legendImage, group, labelAlign, callback, legendScaleX, legendScaleY, w, h);
			}
			var gap: int = 2;
			var labelHeight: int = 12;
			return new Rectangle(0, 0, w, h + gap + labelHeight);
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
		private function createLegend(bitmap: Bitmap, group: InteractiveLayerLegendGroup, labelAlign: String, callback: Function, legendScaleX: Number, legendScaleY: Number, origWidth: int, origHeight: int): void
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
			var image: InteractiveLayerLegendImage;
			if (group.numElements > 1)
			{
				var imageTest: IVisualElement = group.getElementAt(group.numElements - 1);
				if (imageTest is InteractiveLayerLegendImage)
				{
					image = imageTest as InteractiveLayerLegendImage;
					image.scaleX = image.scaleY = 1;
					image.width = origWidth;
					image.height = origHeight;
				}
			}
			if (!image)
			{
				image = new InteractiveLayerLegendImage();
				image.title = layerName;
				group.addElement(image);
			}
			
			image.source = bitmap;
			
			image.originalWidth = bitmap.bitmapData.width;
			image.originalHeight = bitmap.bitmapData.height;
			//FIX for PZAG-637
			origWidth = bitmap.bitmapData.width;
			origHeight = bitmap.bitmapData.height;
			
			//check if legend is not bigger that container, otherwsie scale needs to be adjusted
			var containerWidth: int = container.width;
			var containerHeight: int = container.height;
			
			var expectedWidth: Number = origWidth * legendScaleX;
			var expectedHeight: Number = origHeight * legendScaleY;
			if (containerWidth < expectedWidth || containerHeight < expectedHeight)
			{
				var maxLegendSizeInContainer: Number = 0.8;
				//choose correct scale
				var newScale: Number = Math.min(containerWidth * maxLegendSizeInContainer / expectedWidth, containerHeight * maxLegendSizeInContainer / expectedHeight);
				
				expectedWidth = expectedWidth * newScale;
				expectedHeight = expectedHeight * newScale;
			}
			
			image.width = expectedWidth;
			image.height = expectedHeight;
			
			//			image.scaleX = legendScaleX;
			//			image.scaleY = legendScaleY;
			image.y = labelHeight + gap;
			label.width = image.width;
//			debug("\n\t createLegend legendScaleX: " + legendScaleX + " legendScaleY: " + legendScaleY);
//			debug("t createLegend image: " + image.width + " , " + image.height);
//			debug("t createLegend image scale: " + image.scaleX + " , " + image.scaleY);
			group.width = image.width;
			group.height = image.height + labelHeight + gap;
			if (callback != null)
			{
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
			for each (var layer: WMSLayer in getWMSLayers())
			{
				if (layer.queryable)
					return true;
			}
			return false;
		}
		protected var m_featureInfoCallBack: Function;

		override public function getFeatureInfo(coord: Coord, callback: Function): void
		{
			var a_queryableLayerNames: Array = [];
			for each (var layer: WMSLayer in getWMSLayers())
			{
				if (layer.queryable)
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
			if (m_cfg.service == null)
				return null;
			var bbox: BBox = null;
			for each (var layer: WMSLayer in getWMSLayers())
			{
				var b: BBox = layer.getBBoxForCRS(container.getCRS());
				if (b == null)
					continue;
				if (bbox == null)
					bbox = b;
				else
					bbox = bbox.extendedWith(b);
			}
			return bbox;
		}

		public function getWMSLayers(): Array
		{
			var a: Array = [];
			if (m_cfg.wmsService)
			{
				for each (var s_layerName: String in m_cfg.layerNames)
				{
					var layer: WMSLayer = m_cfg.wmsService.getLayerByName(s_layerName);
					if (layer != null)
						a.push(layer);
				}
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
			if (configuration is WMSLayerConfiguration)
			{
				var wmsLayerConfiguration: WMSLayerConfiguration = configuration as WMSLayerConfiguration;
				if (wmsLayerConfiguration.legendIsDimensionDependant)
				{
					invalidateLegend();
				}
			}
			
			afterWMSDimensionValueIsSet(event.dimension, event.value);
			
			dispatchEvent(event);
			
			if (event.dimension == (configuration as WMSLayerConfiguration).dimensionVerticalLevelName && !synchroniseLevel)
			{
				var ile:  InteractiveLayerEvent = new  InteractiveLayerEvent(InteractiveLayerWMSEvent.LEVEL_CHANGED, true);
				dispatchEvent(ile);
			}
			if (event.dimension == (configuration as WMSLayerConfiguration).dimensionRunName && !synchroniseRun)
			{
				var ile2:  InteractiveLayerEvent = new  InteractiveLayerEvent(InteractiveLayerWMSEvent.RUN_CHANGED, true);
				dispatchEvent(ile2);
			}
		}

		protected function afterWMSDimensionValueIsSet(s_dimName: String, s_value: String): void
		{
			// if "run" changed, then even time axis changes
			if (m_cfg.dimensionRunName != null && s_dimName == m_cfg.dimensionRunName)
			{
				dispatchEvent(new SynchronisedVariableChangeEvent(
						SynchronisedVariableChangeEvent.SYNCHRONISED_VARIABLE_DOMAIN_CHANGED, GlobalVariable.RUN));
				dispatchEvent(new SynchronisedVariableChangeEvent(
						SynchronisedVariableChangeEvent.SYNCHRONISED_VARIABLE_DOMAIN_CHANGED, GlobalVariable.FRAME));
			}
			//if "forecast" changed, we need to update timeline, so we need to dispatch event
			if (m_cfg.dimensionForecastName != null && s_dimName == m_cfg.dimensionForecastName)
			{
				dispatchEvent(new SynchronisedVariableChangeEvent(
						SynchronisedVariableChangeEvent.SYNCHRONISED_VARIABLE_CHANGED, GlobalVariable.FRAME, true));
			}
			//if "time" changed, we need to update timeline, so we need to dispatch event
			if (m_cfg.dimensionTimeName != null && s_dimName == m_cfg.dimensionTimeName)
			{
				dispatchEvent(new SynchronisedVariableChangeEvent(
						SynchronisedVariableChangeEvent.SYNCHRONISED_VARIABLE_CHANGED, GlobalVariable.FRAME));
			}
			//if "level" changed, we need to update timeline, so we need to dispatch event
			if (m_cfg.dimensionVerticalLevelName != null && s_dimName == m_cfg.dimensionVerticalLevelName)
			{
				if (synchroniseLevel)
				{
					dispatchEvent(new SynchronisedVariableChangeEvent(
						SynchronisedVariableChangeEvent.SYNCHRONISED_VARIABLE_CHANGED, GlobalVariable.LEVEL));
				}
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
			if (m_currentWMSViewProperties) {
				m_currentWMSViewProperties.setWMSDimensionValue(s_dimName, s_value);
			} else {
				_tempParameterStorage.setWMSDimensionValue(s_dimName, s_value);
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
			{
				m_currentWMSViewProperties.setWMSStyleName(i_subLayer, s_styleName);
				dispatchEvent(new InteractiveLayerWMSEvent(InteractiveLayerWMSEvent.WMS_STYLE_CHANGED, true));
			} else {
				_tempParameterStorage.setWMSStyleName(i_subLayer, s_styleName);
			}
		}

		public function getWMSStyleListString(): String
		{
			if (m_currentWMSViewProperties)
				return m_currentWMSViewProperties.getWMSStyleListString();
			return null;
		}

		public function setWMSCustomParameter(s_parameter: String, s_value: String): void
		{
			if (m_currentWMSViewProperties) {
				m_currentWMSViewProperties.setWMSCustomParameter(s_parameter, s_value);
			} else {
				_tempParameterStorage.setWMSCustomParameter(s_parameter, s_value);
			}
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
			{
				if (s_variableId == GlobalVariable.LEVEL)
				{
					var hasLevel: Boolean = m_currentWMSViewProperties.hasSynchronisedVariable(s_variableId);
					hasLevel = hasLevel && synchroniseLevel;
					return hasLevel;
				}
				if (s_variableId == GlobalVariable.RUN)
				{
					var hasRun: Boolean = m_currentWMSViewProperties.hasSynchronisedVariable(s_variableId);
					hasRun = hasRun && synchroniseRun;
					return hasRun;
				}
					
				return m_currentWMSViewProperties.hasSynchronisedVariable(s_variableId);
			}
			return false;
		}

		public function getSynchronisedVariableClosetsValue(s_variableId: String, requiredValue: Object, direction: String = "next"): Object
		{
			if (status == InteractiveDataLayer.STATE_DATA_LOADED_WITH_ERRORS)
				return null;
			if (m_currentWMSViewProperties)
				return m_currentWMSViewProperties.getSynchronisedVariableClosetsValue(s_variableId, requiredValue, direction);
			return null;
			
		}
		public function getSynchronisedVariableValue(s_variableId: String): Object
		{
			if (status == InteractiveDataLayer.STATE_DATA_LOADED_WITH_ERRORS || status == InteractiveDataLayer.STATE_NO_SYNCHRONISATION_DATA_AVAILABLE)
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

		public function synchroniseWith(s_variableId: String, s_value: Object): String
		{
			setStatus(InteractiveDataLayer.STATE_EMPTY);
			
			var sSynchronizeWithResponse: String;
			if (isPreloadedWMSDimensionValue(s_variableId, s_value))
			{
				var viewProperties: WMSViewProperties = getPreloadedWMSDimensionValue(s_variableId, s_value);
				if (viewProperties)
				{
					sSynchronizeWithResponse = viewProperties.synchroniseWith(s_variableId, s_value);
					if (!SynchronisationResponse.wasSynchronised(sSynchronizeWithResponse))
					{
						noSynchronisationDataAvailable(graphics);
					}
					else
					{
						setStatus(InteractiveDataLayer.STATE_LOADING_DATA);
					}
					return sSynchronizeWithResponse;
				}
			}
			if (m_currentWMSViewProperties)
			{
				sSynchronizeWithResponse = m_currentWMSViewProperties.synchroniseWith(s_variableId, s_value);
				if (!SynchronisationResponse.wasSynchronised(sSynchronizeWithResponse))
				{
					noSynchronisationDataAvailable(graphics);
				}
				else
				{
//					setStatus(InteractiveDataLayer.STATE_DATA_LOADED);
				}
				debug("synchroniseWith ["+s_variableId+"]/"+s_value + " synchronized: " + sSynchronizeWithResponse);
				return sSynchronizeWithResponse;
			} else {
				_tempParameterStorage.synchroniseWith(s_variableId, s_value);
			}
			return SynchronisationResponse.SYNCHRONISATION_VALUE_NOT_FOUND;
		}

		override protected function onDataLoadFailed(event: UniURLLoaderErrorEvent): void
		{
			super.onDataLoadFailed(event);
			if (event != null)
			{
				ExceptionUtils.logError(Log.getLogger("WMS"), event,
						"Error accessing layers '" + m_cfg.layerNames.join(","))
			}
		}

		/**
		 * Update layer status and clear graphics, when layer has no data for current synchronized frame 
		 * @param gr
		 * 
		 */		
		private function noSynchronisationDataAvailable(gr: Graphics): void
		{
			setStatus(InteractiveDataLayer.STATE_NO_SYNCHRONISATION_DATA_AVAILABLE);
			clear(graphics);
		}
			
		protected function checkPostponedUpdateDataCall(): void
		{
//			debug("checkPostponedUpdateDataCall: _updateDataWaiting: " + _updateDataWaiting + " capabilitiesReady: " + capabilitiesReady);
			if (_updateDataWaiting && capabilitiesReady)
			{
				_updateDataWaiting = false;
				updateData(true);
			}
		}

		protected function onCapabilitiesReceived(event: DataEvent): void
		{
//			debug("onCapabilitiesReceived");
			_capabilitiesReady = true;
			dispatchEvent(new GetCapabilitiesEvent(
					GetCapabilitiesEvent.CAPABILITIES_RECEIVED));
			
			//dispatch also SynchronisedVariableChangeEvent events and do checkPostponedUpdateDataCall()
			onCapabilitiesUpdated();
//			checkPostponedUpdateDataCall();
		}

		protected function onCapabilitiesUpdated(event: DataEvent = null): void
		{
//			debug("MSBAse onCapabilitiesUpdated");
			_capabilitiesReady = true;
			
			/*
			dispatchEvent(new SynchronisedVariableChangeEvent(
					SynchronisedVariableChangeEvent.SYNCHRONISED_VARIABLE_DOMAIN_CHANGED, GlobalVariable.FRAME));
			if (mb_synchroniseLevel)
			{
				dispatchEvent(new SynchronisedVariableChangeEvent(
						SynchronisedVariableChangeEvent.SYNCHRONISED_VARIABLE_DOMAIN_CHANGED, GlobalVariable.LEVEL));
			}
			if (mb_synchroniseRun)
			{
				dispatchEvent(new SynchronisedVariableChangeEvent(
						SynchronisedVariableChangeEvent.SYNCHRONISED_VARIABLE_DOMAIN_CHANGED, GlobalVariable.RUN));
			}
			*/
			checkPostponedUpdateDataCall();
		}

		protected function onFeatureInfoLoaded(event: UniURLLoaderEvent): void
		{
			if (m_featureInfoCallBack != null)
			{
				m_featureInfoCallBack.call(null, String(event.result), this);
			}
			m_featureInfoCallBack = null;
		}

		protected function onFeatureInfoLoadFailed(event: UniURLLoaderErrorEvent): void
		{
			m_featureInfoCallBack.call(null, String(event.result), this);
			m_featureInfoCallBack = null;
		}

		public function get isReadyForSynchronisation(): Boolean
		{
			if (m_cfg)
			{
				return m_cfg.capabilitiesReceived;
			}
			return false;
		}
		
		public function isPrimaryLayer(): Boolean
		{
			if (m_synchronisationRole)
			{
				return m_synchronisationRole.isPrimary;
			}
			//check if synchronizationRoleValue is primary. This will take in account after serialization and before layer initialization
//			if (synchronizationRoleValue == SynchronisationRole.PRIMARY)
//				return true;
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
//			fadeIn = null;
			callLater(delayedEffectEnd);
			
//			if (!fadeOut.hasEventListener(EffectEvent.EFFECT_START))
//			{
				fadeOut.addEventListener(EffectEvent.EFFECT_START, onEffectFadeOutStart);
				fadeOut.addEventListener(EffectEvent.EFFECT_END, onFadeOutEnd);
//			}
		}

		private function onFadeOutEnd(event: EffectEvent): void
		{
			fadeOut.removeEventListener(EffectEvent.EFFECT_START, onEffectFadeOutStart);
			fadeOut.removeEventListener(EffectEvent.EFFECT_END, onFadeOutEnd);
//			fadeOut = null;
			callLater(delayedEffectEnd);
			
//			if (!fadeIn.hasEventListener(EffectEvent.EFFECT_START))
//			{
				fadeIn.addEventListener(EffectEvent.EFFECT_START, onEffectFadeInStart);
				fadeIn.addEventListener(EffectEvent.EFFECT_END, onFadeInEnd);
//			}
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
			if (!b_visiblePrev && b_visible && mb_updateAfterMakingVisible)
			{
				mb_updateAfterMakingVisible = false;
				invalidateData(true);
			}
		}

		override public function clone(): InteractiveLayer
		{
			var newLayer: InteractiveLayerMSBase = new InteractiveLayerMSBase(container, m_cfg);
			updatePropertyForCloneLayer(newLayer);
			return newLayer;
		}
		
		/**
		 * You can update all properties, which needs to be updated when clone InteractiveLayer. 
		 * Please override this function in all layers which extend InteractiveLayer  
		 * @param layer
		 * 
		 */		
		override protected function updatePropertyForCloneLayer(layer: InteractiveLayer): void
		{
			super.updatePropertyForCloneLayer(layer);
			
//			newLayer.id = id;
//			newLayer.alpha = alpha;
//			newLayer.zOrder = zOrder;
//			newLayer.visible = visible;
//			newLayer.layerName = layerName;
			if (layer is InteractiveLayerMSBase)
			{
				var newLayer: InteractiveLayerMSBase = layer as InteractiveLayerMSBase;
				newLayer.synchroniseRun = synchroniseRun;
				if (synchroniseRun)
				{
					var run: Date = getSynchronisedVariableValue(GlobalVariable.RUN) as Date;
					newLayer.synchroniseWith(GlobalVariable.RUN, run);
				}
				newLayer.synchroniseLevel = synchroniseLevel;
				if (synchroniseLevel)
				{
					newLayer.synchroniseWith(GlobalVariable.LEVEL, getSynchronisedVariableValue(GlobalVariable.LEVEL));
				}
				var styleName: String = getWMSStyleName(0)
				newLayer.setWMSStyleName(0, styleName);
				//clone all dimensions
				var dimNames: Array = getWMSDimensionsNames();
				for each (var dimName: String in dimNames)
				{
					var value: String = getWMSDimensionValue(dimName);
					newLayer.setWMSDimensionValue(dimName, value);
				}
				
			}
			
		}

		protected function debug(str: String): void
		{
//			LoggingUtils.dispatchLogEvent(this, "MSBase: " + str);
//			trace("MSBase: ["+this+"] " + str);
		}

		private var _configurationChanged: Boolean;
		public function set configuration(value: ILayerConfiguration): void
		{
			m_cfg = value as WMSLayerConfiguration;
			_configurationChanged = true;
			invalidateProperties();
		}
		
		public function get configuration(): ILayerConfiguration
		{
			return m_cfg;
		}

		public function get synchronisationRole(): SynchronisationRole
		{
			return m_synchronisationRole;
		}

		public function get synchroniseRun(): Boolean
		{
			return mb_synchroniseRun;
		}

		public function set synchroniseRun(value: Boolean): void
		{
			if (mb_synchroniseRun != value)
			{
				mb_synchroniseRun = value;
				notifySynchronizationChange(GlobalVariable.RUN, getSynchronisedVariableValue(GlobalVariable.RUN), mb_synchroniseRun);
			}
		}
		
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

		protected function onBeforeCacheItemDeleted(event: WMSCacheEvent): void
		{
			var key: String = event.item.cacheKey.key;
			var image: DisplayObject = event.item.image;
			
			var cache: WMSCache = getCache() as WMSCache;
			
			//check if this Bitmap is used in this layer
			if (m_currentWMSViewProperties)
			{
				var imageParts: ArrayCollection = m_currentWMSViewProperties.imageParts;
				for each (var imagePart: ImagePart in imageParts)
				{
					if (imagePart.isBitmap)
					{
						var currImage: DisplayObject = imagePart.image;
						if (image == currImage)
						{
							//listen when same cache item will be added
							imagePart.mb_imageOK = false;
							cache.addEventListener(WMSCacheEvent.ITEM_ADDED, onDeleteCacheItemAdded);
						}
					}
				}
			}
		}
		
		private function onDeleteCacheItemAdded(event: WMSCacheEvent): void
		{
			//update imagePart
			if (m_currentWMSViewProperties)
			{
				var imageParts: ArrayCollection = m_currentWMSViewProperties.imageParts;
				var cacheKey: String = event.item.cacheKey.key;
				for each (var imagePart: ImagePart in imageParts)
				{
					if (imagePart.isBitmap)
					{
						if (!imagePart.ms_cacheKey || imagePart.ms_cacheKey == cacheKey)
						{
							imagePart.image = event.item.image;
							imagePart.mb_imageOK = true;
							imagePart.ms_cacheKey = cacheKey;
						}
					}
				}
				invalidateDynamicPart();
			}
		}
		
		override public function toString(): String
		{
			return "InteractiveLayerMSBase " + name + " / LayerID: " + m_layerID + " IW: " + container.id;
		}

		private function destroyCache(): void
		{
			if (m_cache)
				m_cache.destroyCache();
			
			m_cache.removeEventListener(WMSCacheEvent.BEFORE_DELETE , onBeforeCacheItemDeleted);
			m_cache = null;
		}

		public function clearCache(): void
		{
			if (m_cache)
				m_cache.clearCache();
		}

		public function getCache(): ICache
		{
			return m_cache;
		}
	}
}
import com.iblsoft.flexiweather.ogc.configuration.layers.WMSLayerConfiguration;
import com.iblsoft.flexiweather.ogc.data.viewProperties.WMSViewProperties;

import flash.utils.Dictionary;

class LayerTemporaryParameterStorage {
	
	private var _styles: Dictionary = new Dictionary(true);
	private var _dimension: Dictionary = new Dictionary(true);
	private var _synchroniseVariablesDictionary: Dictionary = new Dictionary(true);
	private var _customParameter: Dictionary = new Dictionary(true);
	private var _configuration: WMSLayerConfiguration;
	
	public function LayerTemporaryParameterStorage() {
	
	}
	
	public function setConfiguration(cfg: WMSLayerConfiguration): void
	{
		_configuration = cfg;
	}
	
	public function updateCurrentWMSPropertiesFromStorage(currentWMSProperties: WMSViewProperties, bEmptyStorage: Boolean = true): void
	{
		if (currentWMSProperties)
		{
			currentWMSProperties.setConfiguration(_configuration);
			var str: Object;
			for (str in _styles)
			{
				var s_styleName: String = _styles[str] as String;
				currentWMSProperties.setWMSStyleName(str as uint, s_styleName);
			}
			for (str in _dimension)
			{
				var s_dimName: String = _dimension[str] as String;
				currentWMSProperties.setWMSDimensionValue(str as String, s_dimName);
			}
			for (str in _customParameter)
			{
				var s_parameter: String = _customParameter[str] as String;
				currentWMSProperties.setWMSCustomParameter(str as String, s_parameter);
			}
			for (str in _synchroniseVariablesDictionary)
			{
				var value: Object = _synchroniseVariablesDictionary[str] as Object;
				if (value)
					currentWMSProperties.synchroniseWith(str as String, value);
			}
		}
	}
		
	public function setWMSStyleName(i_subLayer: uint, s_styleName: String): void
	{
		_styles[i_subLayer] = s_styleName;
	}
	
	public function setWMSDimensionValue(s_dimName: String, s_value: String): void
	{
		_dimension[s_dimName] = s_value;
	}
	
	public function setWMSCustomParameter(s_parameter: String, s_value: String): void
	{
		_customParameter[s_parameter] = s_value;
	}
	
	public function synchroniseWith(s_variableId: String, s_value: Object): void
	{
		_synchroniseVariablesDictionary[s_variableId] = s_value;
	}
}