package com.iblsoft.flexiweather.ogc.tiling
{
	import com.iblsoft.flexiweather.ogc.CRSWithBBox;
	import com.iblsoft.flexiweather.ogc.CRSWithBBoxAndTilingInfo;
	import com.iblsoft.flexiweather.ogc.InteractiveLayerQTTMS;
	import com.iblsoft.flexiweather.ogc.InteractiveLayerWMS;
	import com.iblsoft.flexiweather.ogc.WMSLayer;
	import com.iblsoft.flexiweather.ogc.WMSLayerConfiguration;
	import com.iblsoft.flexiweather.widgets.InteractiveWidget;
	
	import flash.display.BitmapData;
	import flash.display.Graphics;
	import flash.events.DataEvent;
	import flash.geom.Matrix;
	import flash.net.URLRequest;

	/**
	 * Extension of InteractiveLayerWMS which uses IBL's GetGTile request is possible.
	 **/
	public class InteractiveLayerWMSWithQTT extends InteractiveLayerWMS
	{
		private var ma_specialCacheStrings: Array;
		private var m_tiledLayer: InteractiveLayerQTTMS;

		public function get tileLayer(): InteractiveLayerQTTMS
		{
			return m_tiledLayer;
		}
		
		/**
		 * Set this isTileable to false, if you dont want to use tiling on WMS 
		 * (e.g. because tilling is not working with all features - e.g animation)
		 */
		public var avoidTiling: Boolean;
		
		public function get isTileable(): Boolean
		{
			if (avoidTiling)
				return false;
				
			var s_crs: String = container.getCRS();
			return m_tiledLayer.getGTileBBoxForWholeCRS(s_crs) || m_cfg.isTileableForCRS(s_crs);
		}

		public function InteractiveLayerWMSWithQTT(
				container: InteractiveWidget,
				cfg: WMSLayerConfiguration,
				b_avoidTiling: Boolean = false)
		{
			super(container, cfg);
			
			this.avoidTiling = b_avoidTiling;
			
			m_tiledLayer = new InteractiveLayerQTTMS(container, '', container.getCRS(), null, 1, 12);
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
		
		private function updateTiledLayerURLBase(): void
		{
			//update QTT Layer URL parts
			m_tiledLayer.baseURL = getFullURL() + '&TILEZOOM=%ZOOM%&TILECOL=%COL%&TILEROW=%ROW%';
			m_tiledLayer.setSpecialCacheStrings(ma_specialCacheStrings);
		}
		
		private function updateTiledLayerCRSs(): void
		{
			var a_layers: Array = getWMSLayers();
			
			m_tiledLayer.clearCRSWithTilingExtents();
			if(a_layers.length == 1) {
				var l: WMSLayer = a_layers[0];
				for each(var crsWithBBox: CRSWithBBox in l.crsWithBBoxes) {
					if(crsWithBBox is CRSWithBBoxAndTilingInfo) {
						var ti: CRSWithBBoxAndTilingInfo = CRSWithBBoxAndTilingInfo(crsWithBBox);
						m_tiledLayer.addCRSWithTilingExtent(ti.crs, ti.tilingExtent);
					}
				}
			}
		}
		
		override public function updateData(b_forceUpdate:Boolean):void
		{
//			trace("WMSWithQTT updateData ["+name+"]");
			var gr: Graphics = graphics;
			if (isTileable)
			{
				updateTiledLayerURLBase();
				m_tiledLayer.updateData(b_forceUpdate);
				changeTiledLayerVisibility(true);
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
	}
}