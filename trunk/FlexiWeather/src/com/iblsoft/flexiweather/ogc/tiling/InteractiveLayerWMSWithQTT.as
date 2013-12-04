package com.iblsoft.flexiweather.ogc.tiling
{
	import com.iblsoft.flexiweather.events.InteractiveLayerEvent;
	import com.iblsoft.flexiweather.events.InteractiveLayerQTTEvent;
	import com.iblsoft.flexiweather.ogc.BBox;
	import com.iblsoft.flexiweather.ogc.CRSWithBBox;
	import com.iblsoft.flexiweather.ogc.CRSWithBBoxAndTilingInfo;
	import com.iblsoft.flexiweather.ogc.InteractiveLayerQTTMS;
	import com.iblsoft.flexiweather.ogc.InteractiveLayerWMS;
	import com.iblsoft.flexiweather.ogc.WMSLayer;
	import com.iblsoft.flexiweather.ogc.cache.ICache;
	import com.iblsoft.flexiweather.ogc.cache.ICachedLayer;
	import com.iblsoft.flexiweather.ogc.configuration.layers.QTTMSLayerConfiguration;
	import com.iblsoft.flexiweather.ogc.configuration.layers.WMSLayerConfiguration;
	import com.iblsoft.flexiweather.ogc.configuration.layers.WMSWithQTTLayerConfiguration;
	import com.iblsoft.flexiweather.ogc.configuration.layers.interfaces.ILayerConfiguration;
	import com.iblsoft.flexiweather.ogc.data.GlobalVariable;
	import com.iblsoft.flexiweather.ogc.data.viewProperties.IViewProperties;
	import com.iblsoft.flexiweather.ogc.data.viewProperties.IWMSViewPropertiesLoader;
	import com.iblsoft.flexiweather.ogc.data.viewProperties.TiledViewProperties;
	import com.iblsoft.flexiweather.ogc.data.viewProperties.WMSViewProperties;
	import com.iblsoft.flexiweather.ogc.preload.IPreloadableLayer;
	import com.iblsoft.flexiweather.utils.LoggingUtils;
	import com.iblsoft.flexiweather.widgets.InteractiveDataLayer;
	import com.iblsoft.flexiweather.widgets.InteractiveLayer;
	import com.iblsoft.flexiweather.widgets.InteractiveWidget;
	
	import flash.display.BitmapData;
	import flash.display.Graphics;
	import flash.events.DataEvent;
	import flash.events.Event;
	import flash.events.TimerEvent;
	import flash.geom.Matrix;
	import flash.net.URLRequest;
	import flash.utils.Dictionary;
	import flash.utils.Timer;

	/**
	 * Extension of InteractiveLayerWMS which uses IBL's GetGTile request is possible.
	 **/
	public class InteractiveLayerWMSWithQTT extends InteractiveLayerWMS implements ICachedLayer, ITiledLayer
	{
		public static const WMS_TILING_URL_PATTERN: String = '&TILEZOOM=%ZOOM%&TILECOL=%COL%&TILEROW=%ROW%';
		public static var avoidTilingForAllLayers: Boolean = false;
		private var _currentValidityTime: Date;
		private var ma_specialCacheStrings: Array;
		private var m_tiledLayer: InteractiveLayerQTTMS;

		public function get tileLayer(): InteractiveLayerQTTMS
		{
			return m_tiledLayer;
		}

		public function get isTileable(): Boolean
		{
			if (!m_cfg || !m_tiledLayer)
				return false;
			var configAvoidTiling: Boolean = (m_cfg as WMSWithQTTLayerConfiguration).avoidTiling;
			if ((m_cfg as WMSWithQTTLayerConfiguration).avoidTiling || avoidTilingForAllLayers)
			{
				m_tiledLayer.avoidTiling = true;
				return false;
			}
			m_tiledLayer.avoidTiling = false;
			var s_crs: String = container.getCRS();
			var gtileBBoxForWholeCRS: BBox = m_tiledLayer.getGTileBBoxForWholeCRS(s_crs);
			var isTileableForCRS: Boolean = m_cfg.isTileableForCRS(s_crs);
			return gtileBBoxForWholeCRS || isTileableForCRS;
		}

		[Bindable(event = "statusChanged")]
		[Inspectable(enumeration = "empty,loading data,no data available,data loaded with errors")]
		override public function get status(): String
		{
			if (isTileable && m_tiledLayer)
			{
				return m_tiledLayer.status;
			}
			return super.status;
		}
		
		override public function set visible(b_visible: Boolean): void
		{
			super.visible = b_visible;
			if (m_tiledLayer) {
				m_tiledLayer.visible = b_visible;
//				trace(this + " visible = " + b_visible + " / " + visible + " / " + m_tiledLayer.visible);
//			} else {
//				trace(this + " visible = " + b_visible + " / " + visible);
			}
		}

		public function InteractiveLayerWMSWithQTT(
				container: InteractiveWidget = null,
				cfg: WMSWithQTTLayerConfiguration = null): void
		{
			super(container, cfg);
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
			m_tiledLayer = createTiledLayer();
			
			if (m_tiledLayer)
			{
				m_tiledLayer.addEventListener(InteractiveLayerEvent.LAYER_INITIALIZED, onTiledLayerInitialized);
				m_tiledLayer.addEventListener(InteractiveLayerTiled.UPDATE_TILING_PATTERN, onUpdateTilingPattern);
				m_tiledLayer.addEventListener(InteractiveDataLayer.LOADING_FINISHED, onAllTilesLoaded);
				addChild(m_tiledLayer);
				changeTiledLayerVisibility(false);
				updateTiledLayerCRSs();
			}
		}
		
		protected function createTiledLayer(): InteractiveLayerQTTMS
		{
			var tiledLayerConfig: QTTMSLayerConfiguration = new QTTMSLayerConfiguration();
			var tiledLayer: InteractiveLayerQTTMS = new InteractiveLayerQTTMS(container, tiledLayerConfig);
			tiledLayer.onCapabilitiesDependent = true;
			tiledLayer.capabilitiesReady = capabilitiesReady;
			
			return tiledLayer;
		}

		override protected function createChildren(): void
		{
			super.createChildren();
		}

		override protected function childrenCreated(): void
		{
			super.childrenCreated();
		}

		override protected function updateDisplayList(unscaledWidth: Number, unscaledHeight: Number): void
		{
			if (!m_tiledLayer)
				return;
			
			if (isTileable)
			{
				draw(graphics);
			} else {
				super.updateDisplayList(unscaledWidth, unscaledHeight);
			}
			
			m_tiledLayer.name = name + " (tiled)";
			
			//TODO fix this after InteractiveLayerTiled is implemented
//			if (isTileable)
//			{
//				if (m_tiledLayer.zoomLevel == -1)
//				{
//					m_tiledLayer.width = container.width;
//					m_tiledLayer.height = container.height;
//					updateTiledLayerURLBase();
//					refresh(true);
//				}
//			}
		}

		override protected function onCapabilitiesUpdated(event: DataEvent = null): void
		{
			if (!container)
				return;
			
			updateTiledLayerCRSs();
			if (m_tiledLayer)
			{
				m_tiledLayer.capabilitiesReady = true;
				m_tiledLayer.checkZoom();
			}
			super.onCapabilitiesUpdated(event);
		}

		private function changeTiledLayerVisibility(visible: Boolean): void
		{
			if (m_tiledLayer)
				m_tiledLayer.visible = visible;
		}

		override public function refresh(b_force: Boolean): void
		{
			if (isTileable)
			{
				updateTiledLayerURLBase();
				m_tiledLayer.refresh(b_force);
			}
			else
				super.refresh(b_force);
		}

		override public function updateDimensionsInURLRequest(url: URLRequest): void
		{
			super.updateDimensionsInURLRequest(url);
			ma_specialCacheStrings = [];
			var currWMSViewProperties: WMSViewProperties = currentViewProperties as WMSViewProperties;
			var dimNames: Array = currWMSViewProperties.getWMSDimensionsNames();
			for (var s_dimName: String in dimNames)
			{
				var str: String = "SPECIAL_" + m_cfg.dimensionToParameterName(s_dimName) + "="
						+ currWMSViewProperties.getWMSDimensionValue(s_dimName);
				ma_specialCacheStrings.push(str);
			}
		}

		override protected function updateRequestData(request: URLRequest): void
		{
			super.updateRequestData(request);
			if (isTileable)
			{
				if (request.data.hasOwnProperty('REQUEST'))
					request.data.REQUEST = 'GetGTile';
				if (request.data.hasOwnProperty('LAYERS'))
				{
					request.data.LAYER = request.data.LAYERS;
					delete request.data.LAYERS;
				}
				if (request.data.hasOwnProperty('STYLES'))
				{
					request.data.STYLE = request.data.STYLES;
					delete request.data.STYLES;
				}
				if (request.data.hasOwnProperty('STYLE'))
				{
					var str: String = "SPECIAL_STYLE=" + request.data.STYLE;
					ma_specialCacheStrings.push(str);
				}
			}
		}

		override protected function updateWMSViewPropertiesConfiguration(wmsViewProperties: WMSViewProperties, configuration: ILayerConfiguration, cache: ICache): void
		{
			if (isTileable)
			{
				super.updateWMSViewPropertiesConfiguration(wmsViewProperties, m_tiledLayer.configuration, m_tiledLayer.cache);
				return;
			}
			super.updateWMSViewPropertiesConfiguration(wmsViewProperties, configuration, cache);
		}

		private function onUpdateTilingPattern(event: Event): void
		{
			updateTiledLayerURLBase();
		}

		private function updateTiledLayerURLBase(): void
		{
			var fullURL: String = getFullURL();
			m_tiledLayer.fullURL = fullURL;
			
			/*
			var crs: String = container.getCRS();
			var config: QTTMSLayerConfiguration = m_tiledLayer.configuration as QTTMSLayerConfiguration;
			
			var tilingInfo: TiledTilingInfo = config.getTiledTilingInfoForCRS(crs);
			if (!tilingInfo)
				trace("updateTiledLayerURLBase problem with CRS");
			else {
				var fullURL: String = getFullURL();
				m_tiledLayer.fullURL = fullURL;
//				tilingInfo.urlPattern = fullURL + WMS_TILING_URL_PATTERN;
			}
			//			qttViewProperties.setSpecialCacheStrings(ma_specialCacheStrings);
			*/
		}
		private function updateTiledLayerCRSs(): void
		{
			var a_layers: Array = getWMSLayers();
			m_tiledLayer.clearCRSWithTilingExtents();
			if (a_layers.length == 1)
			{
				var l: WMSLayer = a_layers[0];
				var tileSize: uint = 0;
				if (m_cfg && m_cfg.hasOwnProperty('tileSize'))
					tileSize = m_cfg['tileSize'] as uint;
				
				m_tiledLayer.clearCRSWithTilingExtents();
				for each (var crsWithBBox: CRSWithBBox in l.crsWithBBoxes)
				{
					if (crsWithBBox is CRSWithBBoxAndTilingInfo)
					{
						var ti: CRSWithBBoxAndTilingInfo = CRSWithBBoxAndTilingInfo(crsWithBBox);
						if (tileSize > 0)
							m_tiledLayer.addCRSWithTilingExtent(WMS_TILING_URL_PATTERN, ti.crs, ti.tilingExtent, tileSize, 1, 18);
						else
							m_tiledLayer.addCRSWithTilingExtent(WMS_TILING_URL_PATTERN, ti.crs, ti.tilingExtent, TileSize.SIZE_256, 1, 18);
					}
				}
				
				updateTiledLayerURLBase();
			}
		}

		override public function destroy(): void
		{
			if (m_tiledLayer)
				m_tiledLayer.destroy();
			super.destroy();
		}

		override protected function destroyWMSViewPropertiesPreloader(): void
		{
			//FIXME fix InteractiveLayerWMSWithQTT destroyWMSViewPropertiesPreloader
			
//			if (loader is TiledLoader)
//			{
//				loader.removeEventListener(InteractiveLayerEvent.INVALIDATE_DYNAMIC_PART, onWMSViewPropertiesDataInvalidateDynamicPart);
//				loader.removeEventListener(InteractiveDataLayer.LOADING_FINISHED, onPreloadingWMSDataLoadingFinished);
//				loader.destroy();
//			}
//			else
				super.destroyWMSViewPropertiesPreloader();
		}

		override protected function getWMSViewPropertiesLoader(): IWMSViewPropertiesLoader
		{
			if (isTileable)
			{
				var tiledLoader: TiledLoader = new TiledLoader(m_tiledLayer); 
				tiledLoader.zoom = m_tiledLayer.zoomLevel;
				return tiledLoader;
			} 
			return super.getWMSViewPropertiesLoader();
		}

		override protected function updateData(b_forceUpdate: Boolean): void
		{
//			debug("updateDate["+b_forceUpdate+"] isTileable: " + isTileable + " _layerInitialized: " + _layerInitialized + " capabilitiesReady: " + capabilitiesReady + " visible: " + visible);
			
			if (!_layerInitialized)
				return;
			//we need to postpone updateData if capabilities was not received, otherwise we do not know, if layes is tileable or not
			if (!capabilitiesReady)
			{
				waitForCapabilities();
				return;
			}
			if (!visible)
			{
				mb_updateAfterMakingVisible = true;
				return;
			}
			
			if (status != STATE_NO_SYNCHRONISATION_DATA_AVAILABLE)
			{
				var gr: Graphics = graphics;
				if (isTileable)
				{
					if (!visible)
					{
						m_autoRefreshTimer.reset();
						return;
					}
					updateTiledLayerURLBase();
					if (m_tiledLayer.currentQTTViewProperties)
					{
						m_tiledLayer.currentQTTViewProperties.crs = container.getCRS();
						m_tiledLayer.currentQTTViewProperties.setViewBBox(container.getViewBBox());
					}
					m_tiledLayer.invalidateData(b_forceUpdate);
					changeTiledLayerVisibility(true);
					m_autoRefreshTimer.reset();
				}
				else
				{
					changeTiledLayerVisibility(false);
					//we call super.updateData only in case of non tile
					super.updateData(b_forceUpdate);
				}
			}
		}

		override public function renderPreview(graphics: Graphics, f_width: Number, f_height: Number): void
		{
			if (isTileable)
				tileLayer.renderPreview(graphics, f_width, f_height);
			else
				super.renderPreview(graphics, f_width, f_height);
		}

		
		/**
		 * Call this function if you want clear layer graphics
		 * @param graphics
		 *
		 */
		public override function clear(graphics: Graphics): void
		{
			if (isTileable)
			{
				m_tiledLayer.clear(graphics);
			}
			else
			{
				super.clear(graphics);
			}
		}
		override public function draw(graphics: Graphics): void
		{
//			debug("draw");
			if (isTileable)
			{
				updateTiledLayerURLBase();
				//clear WMS graphics
				clear(graphics);
				m_tiledLayer.draw(m_tiledLayer.graphics);
//				changeTiledLayerVisibility(true);
				changeTiledLayerVisibility(visible);
			}
			else
			{
				changeTiledLayerVisibility(false);
				super.draw(graphics);
			}
		}

		override public function onAreaChanged(b_finalChange: Boolean): void
		{
			if (isTileable)
			{
				updateTiledLayerURLBase();
				m_tiledLayer.onAreaChanged(b_finalChange);
				invalidateDynamicPart();
			}
			else
				super.onAreaChanged(b_finalChange);
		}

		override public function onContainerSizeChanged(): void
		{
			super.onContainerSizeChanged();
			if (m_tiledLayer)
			{
				m_tiledLayer.width = container.width;
				m_tiledLayer.height = container.height;
			}
		}

		override public function synchroniseWith(s_variableId: String, value: Object): String
		{
			var s: String = super.synchroniseWith(s_variableId, value);
			return s;
		}

		override public function setWMSDimensionValue(s_dimName: String, s_value: String): void
		{
			super.setWMSDimensionValue(s_dimName, s_value);
		}

		override protected function afterWMSDimensionValueIsSet(s_dimName: String, s_value: String): void
		{
			// if "run" changed, then even time axis changes
			var b_frameChanged: Boolean = false;
			if (m_cfg.dimensionRunName != null && s_dimName == m_cfg.dimensionRunName)
				b_frameChanged = true;
			//if "forecast" changed, we need to update timeline, so we need to dispatch event
			if (m_cfg.dimensionForecastName != null && s_dimName == m_cfg.dimensionForecastName)
				b_frameChanged = true;
			//if "time" changed, we need to update timeline, so we need to dispatch event
			if (m_cfg.dimensionTimeName != null && s_dimName == m_cfg.dimensionTimeName)
				b_frameChanged = true;
			if (b_frameChanged)
			{
				_currentValidityTime = getSynchronisedVariableValue(GlobalVariable.FRAME) as Date;
				if (m_tiledLayer)
					m_tiledLayer.setValidityTime(_currentValidityTime);
			}
		}

		private function onAllTilesLoaded(event: InteractiveLayerEvent): void
		{
			if (!layerWasDestroyed)
			{
				// restartautorefresh timer
				restartAutoRefreshTimer();
			}
			else
			{
				//destroy new loaded tiles
				destroy();
			}
		}

		override protected function autoRefreshTimerCompleted(event: TimerEvent): void
		{
			if (isTileable)
			{
				if (m_tiledLayer)
					m_tiledLayer.invalidateData(true);
			}
			else
				super.autoRefreshTimerCompleted(event);
		}

		override public function toString(): String
		{
			var retStr: String = "InteractiveLayerWMSWithQTT " + name + " / layerID: " + m_layerID + " isTileable: " + isTileable + " / IW: " + container.id;
			if (m_tiledLayer)
			{
				retStr += "\n\t\t" + m_tiledLayer;
			}
			return retStr;
		}

		override public function debugCache(): String
		{
//			if (isTileable)
//			{
//				return toString + '\n' + m_tiledLayer.debugCache();
//			}
			return toString() + "\n" + m_cache.debugCache();
		}

		override public function getCache(): ICache
		{
			if (isTileable)
				return m_tiledLayer.cache;
			return m_cache;
		}

		public function getTiledLayer(): InteractiveLayerTiled
		{
			if (isTileable)
				return m_tiledLayer;
			return null;
		}

		/*********************************************************************************************
		 *
		 *					 			Preloading functions
		 *
		 *********************************************************************************************/
		private function getPreloadableInteractiveLayerBaseOnIsTileable(): IPreloadableLayer
		{
			if (isTileable && m_tiledLayer)
				return m_tiledLayer;
			return this;
		}

		private function getViewPropertiesBasedOnIsTileable(viewProperties: IViewProperties): IViewProperties
		{
			if (isTileable && m_tiledLayer)
			{
				//we need to return QTTViewProperties
				if (viewProperties is TiledViewProperties)
					return viewProperties;
				//convert it to QTTViewProperties
				return convertWMSViewPropertiesToQTTViewProperties(viewProperties as WMSViewProperties);
			}
			if (viewProperties is WMSViewProperties)
				return viewProperties;
			//TODO do we support convertin QTTViewProperties to WMSViewProperties, I don't think so
			return viewProperties;
		}

		public function convertViewPropertiesArray(viewPropertiesArray: Array): Array
		{
			var arr: Array = [];
			for each (var viewProperties: IViewProperties in viewPropertiesArray)
			{
				arr.push(getViewPropertiesBasedOnIsTileable(viewProperties));
			}
			return arr;
		}
		private var _qttViewPropertiesDictionary: Dictionary = new Dictionary

		public function convertWMSViewPropertiesToQTTViewProperties(wmsViewProperties: WMSViewProperties): TiledViewProperties
		{
			if (!_qttViewPropertiesDictionary[wmsViewProperties])
				_qttViewPropertiesDictionary[wmsViewProperties] = new TiledViewProperties();
			var qttViewProperties: TiledViewProperties = _qttViewPropertiesDictionary[wmsViewProperties];
			qttViewProperties.crs = wmsViewProperties.crs;
			qttViewProperties.setViewBBox(wmsViewProperties.getViewBBox());
			var specialStringArr: Array = [];
			var dimNames: Array = wmsViewProperties.getWMSDimensionsNames();
			for each (var s_dimName: String in dimNames)
			{
				var value: String = wmsViewProperties.getWMSDimensionValue(s_dimName);
				if (value)
				{
					var str: String = "SPECIAL_" + m_cfg.dimensionToParameterName(s_dimName) + "=" + value;
					specialStringArr.push(str);
				}
			}
			qttViewProperties.setSpecialCacheStrings(specialStringArr);
			return qttViewProperties;
		}

		public function getTiledArea(viewBBox: BBox, zoomLevel: String, tileSize: int): TiledArea
		{
			return tileLayer.getTiledArea(viewBBox, zoomLevel, tileSize);
		}

		override public function get currentViewProperties(): IViewProperties
		{
			return super.currentViewProperties;
		}

		override public function changeViewProperties(viewProperties: IViewProperties): void
		{
			var layer: IPreloadableLayer = getPreloadableInteractiveLayerBaseOnIsTileable();
			if (layer == this)
				return super.changeViewProperties(getViewPropertiesBasedOnIsTileable(viewProperties));
					
			return layer.changeViewProperties(getViewPropertiesBasedOnIsTileable(viewProperties));
		}

		override public function cancelPreload():void
		{
			var layer: IPreloadableLayer = getPreloadableInteractiveLayerBaseOnIsTileable();
			if (layer == this)
				return super.cancelPreload();
			
			return layer.cancelPreload();
		}
		override public function preload(viewProperties: IViewProperties): void
		{
			var layer: IPreloadableLayer = getPreloadableInteractiveLayerBaseOnIsTileable();
			if (layer == this)
				return super.preload(getViewPropertiesBasedOnIsTileable(viewProperties));

			return layer.preload(getViewPropertiesBasedOnIsTileable(viewProperties));
		}

		override public function preloadMultiple(viewPropertiesArray: Array): void
		{
			var layer: IPreloadableLayer = getPreloadableInteractiveLayerBaseOnIsTileable();
			if (layer == this)
				return super.preloadMultiple(convertViewPropertiesArray(viewPropertiesArray));

			return layer.preloadMultiple(convertViewPropertiesArray(viewPropertiesArray));
		}

		override public function isPreloaded(viewProperties: IViewProperties): Boolean
		{
 			var layer: IPreloadableLayer = getPreloadableInteractiveLayerBaseOnIsTileable();
			if (layer == this)
				return super.isPreloaded(getViewPropertiesBasedOnIsTileable(viewProperties));

			return layer.isPreloaded(getViewPropertiesBasedOnIsTileable(viewProperties));
		}

		override public function isPreloadedMultiple(viewPropertiesArray: Array): Boolean
		{
			var layer: IPreloadableLayer = getPreloadableInteractiveLayerBaseOnIsTileable();
			if (layer == this)
				return super.isPreloadedMultiple(convertViewPropertiesArray(viewPropertiesArray));

			return layer.isPreloadedMultiple(convertViewPropertiesArray(viewPropertiesArray));
		}

		override public function clearCache(): void
		{
			var layer: IPreloadableLayer = getPreloadableInteractiveLayerBaseOnIsTileable();
			if (layer is ICachedLayer)
			{
				var cachedLayer: ICachedLayer = layer as ICachedLayer;
				var cache: ICache = cachedLayer.getCache();
				if (cache)
					cache.clearCache();
			}
		}
		
		private function onTiledLayerInitialized(event: InteractiveLayerEvent): void
		{
			event.stopImmediatePropagation();
			event.stopPropagation();
			
			m_tiledLayer.removeEventListener(InteractiveLayerEvent.LAYER_INITIALIZED, onTiledLayerInitialized);
			notifyLayerInitializedIfBothLayersAreInitialized();
		}
		override protected function delayedInitializeLayerAfterAddToStage():void
		{
			if (!_layerInitialized)
			{
				_layerInitialized = true;
				notifyLayerInitializedIfBothLayersAreInitialized();
			} else {
				trace(this + " delayedInitializeLayerAfterAddToStage ALREADY INITIALIZED");
				
			}
		}
		
		private function notifyLayerInitializedIfBothLayersAreInitialized(): void
		{
			if (layerInitialized)
			{
				if (m_tiledLayer)
				{
					if (m_tiledLayer.layerInitialized)
						notifyLayerInitialized();
				} else {
					notifyLayerInitialized();
				}
			}
		}
		
		override protected function debug(str: String): void
		{
//			trace(this + " WMSWithQTT: " + str);
//			LoggingUtils.dispatchLogEvent(this, "WMSWithQTT: " + str);
		}
		
		override public function clone(): InteractiveLayer
		{
			var newLayer: InteractiveLayerWMSWithQTT = new InteractiveLayerWMSWithQTT(container, m_cfg as WMSWithQTTLayerConfiguration);
			updatePropertyForCloneLayer(newLayer);
//			newLayer.tileLayer.clone();
			//TODO how to clone tiled layer
			return newLayer;
		}
	}
}
