package com.iblsoft.flexiweather.ogc.tiling
{
	import com.iblsoft.flexiweather.events.InteractiveLayerEvent;
	import com.iblsoft.flexiweather.events.InteractiveLayerQTTEvent;
	import com.iblsoft.flexiweather.ogc.CRSWithBBox;
	import com.iblsoft.flexiweather.ogc.CRSWithBBoxAndTilingInfo;
	import com.iblsoft.flexiweather.ogc.InteractiveLayerQTTMS;
	import com.iblsoft.flexiweather.ogc.InteractiveLayerWMS;
	import com.iblsoft.flexiweather.ogc.QTTMSLayerConfiguration;
	import com.iblsoft.flexiweather.ogc.QTTilingInfo;
	import com.iblsoft.flexiweather.ogc.WMSLayer;
	import com.iblsoft.flexiweather.ogc.WMSLayerConfiguration;
	import com.iblsoft.flexiweather.ogc.WMSWithQTTLayerConfiguration;
	import com.iblsoft.flexiweather.ogc.cache.ICache;
	import com.iblsoft.flexiweather.ogc.cache.ICachedLayer;
	import com.iblsoft.flexiweather.widgets.InteractiveDataLayer;
	import com.iblsoft.flexiweather.widgets.InteractiveWidget;
	
	import flash.display.BitmapData;
	import flash.display.Graphics;
	import flash.events.DataEvent;
	import flash.events.Event;
	import flash.events.TimerEvent;
	import flash.geom.Matrix;
	import flash.net.URLRequest;
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
			var configAvoidTiling: Boolean = (m_cfg as WMSWithQTTLayerConfiguration).avoidTiling;
			
			if ((m_cfg as WMSWithQTTLayerConfiguration).avoidTiling || avoidTilingForAllLayers)
			{
				m_tiledLayer.avoidTiling = true;
				return false;
			}
				
			m_tiledLayer.avoidTiling = false;
			var s_crs: String = container.getCRS();
			return m_tiledLayer.getGTileBBoxForWholeCRS(s_crs) || m_cfg.isTileableForCRS(s_crs);
		}

		public function InteractiveLayerWMSWithQTT(
				container: InteractiveWidget,
				cfg: WMSWithQTTLayerConfiguration): void
		{
			super(container, cfg);
			
			var tiledLayerConfig: QTTMSLayerConfiguration = new QTTMSLayerConfiguration();
			m_tiledLayer = new InteractiveLayerQTTMS(container, tiledLayerConfig,
					'', null, null, cfg.minimumZoomLevel, cfg.maximumZoomLevel);
			
			//setup new tiles provider for InteractiveLayerQTTMS layet
			m_tiledLayer.tilesProvider = new QTTTilesProvider();
			
			m_tiledLayer.addEventListener(InteractiveLayerQTTMS.UPDATE_TILING_PATTERN, onUpdateTilingPattern);
			m_tiledLayer.addEventListener(InteractiveDataLayer.LOADING_FINISHED, onAllTilesLoaded);
			addChild(m_tiledLayer);
			
			changeTiledLayerVisibility(false);
			updateTiledLayerCRSs();
			
		}
		
		override protected function createChildren():void
		{
			super.createChildren();
		}

		override protected function childrenCreated():void
		{
			super.childrenCreated();
		}
		
		override protected function updateDisplayList(unscaledWidth:Number, unscaledHeight:Number):void
		{
			super.updateDisplayList(unscaledWidth, unscaledHeight);
			m_tiledLayer.name = name + " (tiled)";
			
			if (isTileable)
			{
				if (m_tiledLayer.zoomLevel == -1)
				{
					m_tiledLayer.width = container.width;
					m_tiledLayer.height = container.height;
					updateTiledLayerURLBase();
					refresh(true);
				}
			}
		}
		
		override protected function onCapabilitiesUpdated(event: DataEvent): void
		{
			super.onCapabilitiesUpdated(event);
			
			updateTiledLayerCRSs();
		}
		
		private function changeTiledLayerVisibility(visible: Boolean): void
		{
			m_tiledLayer.visible = visible;
		}
		
		override public function refresh(b_force:Boolean):void
		{
			if (isTileable)
			{
				updateTiledLayerURLBase();
				m_tiledLayer.refresh(b_force);
			} else {
				super.refresh(b_force);
			}
		}
		
		override public function updateDimensionsInURLRequest(url: URLRequest): void
		{
			super.updateDimensionsInURLRequest(url);
			
			ma_specialCacheStrings = [];
			
			for(var s_dimName: String in md_dimensionValues) {
				var str: String = "SPECIAL_" + m_cfg.dimensionToParameterName(s_dimName) + "="
						+ md_dimensionValues[s_dimName];
				ma_specialCacheStrings.push(str);
			}
		}
		override protected function updateRequestData(request: URLRequest):void
		{
			super.updateRequestData(request);
			
			if (isTileable)
			{
				if (request.data.hasOwnProperty('REQUEST'))
				{
					request.data.REQUEST = 'GetGTile';
				}
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
		
		private function onUpdateTilingPattern(event: Event): void
		{
			updateTiledLayerURLBase();
		}
		
		private function updateTiledLayerURLBase(): void
		{
			var crs: String = container.getCRS();
			var config:QTTMSLayerConfiguration = m_tiledLayer.configuration as QTTMSLayerConfiguration;
			
			var tilingInfo: QTTilingInfo = config.getQTTilingInfoForCRS(crs);
			if (!tilingInfo)
			{
				trace("updateTiledLayerURLBase problem with CRS"); 
			} else {
				tilingInfo.urlPattern = getFullURL() + WMS_TILING_URL_PATTERN;
			}
			/*
			//update QTT Layer URL parts
			m_tiledLayer.baseURLPattern = getFullURL() + WMS_TILING_URL_PATTERN;
			*/
			m_tiledLayer.setSpecialCacheStrings(ma_specialCacheStrings);
		}
		
		
		private function updateTiledLayerCRSs(): void
		{
			var a_layers: Array = getWMSLayers();
			
			//var config:QTTMSLayerConfiguration = m_tiledLayer.configuration as QTTMSLayerConfiguration;
			
			m_tiledLayer.clearCRSWithTilingExtents();
			if(a_layers.length == 1) {
				var l: WMSLayer = a_layers[0];
				for each(var crsWithBBox: CRSWithBBox in l.crsWithBBoxes) 
				{
					if(crsWithBBox is CRSWithBBoxAndTilingInfo) 
					{
						var ti: CRSWithBBoxAndTilingInfo = CRSWithBBoxAndTilingInfo(crsWithBBox);
						m_tiledLayer.addCRSWithTilingExtent(WMS_TILING_URL_PATTERN, ti.crs, ti.tilingExtent);
					}
				}
			}
		}
		
		override protected function updateData(b_forceUpdate:Boolean):void
		{
			super.updateData(b_forceUpdate);
			
//			trace("WMSWithQTT updateData ["+name+"]");
			var gr: Graphics = graphics;
			if (isTileable)
			{
				if(!visible) {
					m_autoRefreshTimer.reset();
					return;
				}
				
				updateTiledLayerURLBase();
				m_tiledLayer.invalidateData(b_forceUpdate);
				changeTiledLayerVisibility(true);
				
				m_autoRefreshTimer.reset();
				
			} else {
				changeTiledLayerVisibility(false);
				super.updateData(b_forceUpdate);
			}
		}
		
		
		override public function renderPreview(graphics: Graphics, f_width: Number, f_height: Number): void
		{
			if (isTileable)
			{
				tileLayer.renderPreview(graphics, f_width, f_height);
			} else {
				super.renderPreview(graphics, f_width, f_height);	
			}
			
		}
		
		override public function draw(graphics: Graphics): void
		{
			if (isTileable)
			{
				updateTiledLayerURLBase();
				//clear WMS graphics
				graphics.clear();
				
				m_tiledLayer.draw(m_tiledLayer.graphics);
				changeTiledLayerVisibility(true);
			} else {
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
			} else {
				super.onAreaChanged(b_finalChange);
			}
		}
		
		override public function onContainerSizeChanged(): void
		{
			super.onContainerSizeChanged();
			m_tiledLayer.width = container.width;
			m_tiledLayer.height = container.height;
		}
		
		override public function synchroniseWith(s_variableId: String, value: Object): Boolean
		{
			var b: Boolean = super.synchroniseWith(s_variableId, value);
			return b;
		}
		
		override public function setWMSDimensionValue(s_dimName: String, s_value: String): void
		{
			super.setWMSDimensionValue(s_dimName, s_value);
			
		}
		
		override protected function afterWMSDimensionValueIsSet(s_dimName: String, s_value: String): void
		{
			// if "run" changed, then even time axis changes
			var b_frameChanged: Boolean = false;
			if(m_cfg.ms_dimensionRunName != null && s_dimName == m_cfg.ms_dimensionRunName) {
				b_frameChanged = true;
			}
			//if "forecast" changed, we need to update timeline, so we need to dispatch event
			if(m_cfg.ms_dimensionForecastName != null && s_dimName == m_cfg.ms_dimensionForecastName) {
				b_frameChanged = true;
			}
			//if "time" changed, we need to update timeline, so we need to dispatch event
			if(m_cfg.ms_dimensionTimeName != null && s_dimName == m_cfg.ms_dimensionTimeName) {
				b_frameChanged = true;
			}
			
			if (b_frameChanged)
			{
				_currentValidityTime = getSynchronisedVariableValue("frame") as Date;
				trace("setWMSDimensionValue _currentValidityTime : " + _currentValidityTime );
				if (m_tiledLayer)
				{
					m_tiledLayer.setValidityTime(_currentValidityTime);
				}
			}
			
		}
		
		private function onAllTilesLoaded(event: InteractiveLayerEvent): void
		{
			// restartautorefresh timer
			restartAutoRefreshTimer();
		}
		
		override protected function autoRefreshTimerCompleted(event: TimerEvent): void
		{
			if (isTileable)
			{
				if (m_tiledLayer)
				{
					m_tiledLayer.invalidateData(true);
				}
			} else {
				super.autoRefreshTimerCompleted(event);
			}
			
		}
		
		override public function toString(): String
		{
			var retStr: String = "InteractiveLayerWMSWithQTT " + name + " isTileable: " + isTileable ;
			if (m_tiledLayer)
			{
				retStr += "\n\t\t" + m_tiledLayer;
			}
			return retStr;
		}
		
		override public function debugCache(): String
		{
			if (isTileable)
			{
				return toString + '\n' + m_tiledLayer.debugCache();
			}
			return toString() + "\n" + m_cache.debugCache();
		}
		
		override public function getCache():ICache
		{
			if (isTileable)
			{
				return m_tiledLayer.cache;
			}
			return m_cache;
		}
		
		public function getTiledLayer():InteractiveLayerQTTMS
		{
			if (isTileable)
			{
				return m_tiledLayer;
			}
			return null;
		}
		
		
	}
}