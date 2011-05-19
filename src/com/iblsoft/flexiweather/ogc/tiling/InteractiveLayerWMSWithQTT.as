package com.iblsoft.flexiweather.ogc.tiling
{
	import com.iblsoft.flexiweather.ogc.InteractiveLayerQTTMS;
	import com.iblsoft.flexiweather.ogc.InteractiveLayerWMS;
	import com.iblsoft.flexiweather.ogc.WMSLayerConfiguration;
	import com.iblsoft.flexiweather.widgets.InteractiveWidget;
	
	import flash.display.BitmapData;
	import flash.display.Graphics;
	import flash.events.DataEvent;
	import flash.geom.Matrix;
	import flash.net.URLRequest;

	public class InteractiveLayerWMSWithQTT extends InteractiveLayerWMS
	{
		private var _specialCacheStrings: Array;
		private var _tiledLayer: InteractiveLayerQTTMS;
		public function get tileLayer(): InteractiveLayerQTTMS
		{
			return _tiledLayer;
		}
		
		public var avoidTiling: Boolean;
		
		public function get isTilable(): Boolean
		{
			if (avoidTiling)
				return false;
				
			var crs: String = container.getCRS();
			return m_cfg.isTilableForCRS(crs);
			
			/**
			 *  TODO: set isTilable to false, if you dont want to use tiling on WMS 
			 * (e.g. because tilling is not working with all features - e.g animation)
			 */
//			return false;
		}
		public function InteractiveLayerWMSWithQTT(container:InteractiveWidget, cfg:WMSLayerConfiguration, avoidTiling: Boolean = false)
		{
			super(container, cfg);
			
			this.avoidTiling = avoidTiling;
			
			_tiledLayer = new InteractiveLayerQTTMS(container, '', '&TileZoom=%ZOOM%&TileCol=%COL%&TileRow=%ROW%','&/png', container.getCRS(), null, 1, 12);
			addChild(_tiledLayer);
			
			changeTiledLayerVisibility(false);

		}
		
		override protected function createChildren():void
		{
			super.createChildren();
//			_tiledLayer = new InteractiveLayerQTTMS(container, '', '&TileZoom=%ZOOM%&TileCol=%COL%&TileRow=%ROW%','&/png', container.getCRS(), null, 0, 12);
		}
		override protected function childrenCreated():void
		{
			super.childrenCreated();
//			addChild(_tiledLayer);
//			
//			changeTiledLayerVisibility(false);
		}
		
		override protected function updateDisplayList(unscaledWidth:Number, unscaledHeight:Number):void
		{
			super.updateDisplayList(unscaledWidth, unscaledHeight);
			
			if (isTilable)
			{
				if (_tiledLayer.zoom == -1)
				{
					_tiledLayer.width = container.width;
					_tiledLayer.height = container.height;
					_tiledLayer.baseURL = getFullURL();
					refresh(true);
				}
			}
		}
		
		override protected function onCapabilitiesUpdated(event: DataEvent): void
		{
			super.onCapabilitiesUpdated(event);
//			trace("InteractiveLayerWMSWithQTT onCapabilitiesUpdated: " + isTilable);
			//refresh, capabilities are updated, so we can find out, if layer isTilable
			
			//FIXME check only if there is change in isTilable, if it is, make refresh, otherwise do nothin
			//refresh(true);		
		}
		
		private function changeTiledLayerVisibility(visible: Boolean): void
		{
			_tiledLayer.visible = visible;
		}
		
		override public function refresh(b_force:Boolean):void
		{
			if (isTilable)
			{
				updateTiledLayerURLBase();
				_tiledLayer.refresh(b_force);
			} else {
				super.refresh(b_force);
			}
		}
		
		override public function updateDimensionsInURLRequest(url: URLRequest): void
		{
			super.updateDimensionsInURLRequest(url);
			
			_specialCacheStrings = [];
			
			for(var s_dimName: String in md_dimensionValues) {
				var str: String = "SPECIAL_"+m_cfg.dimensionToParameterName(s_dimName) +"=" + md_dimensionValues[s_dimName];
				_specialCacheStrings.push(str);
			}
		}
		override protected function updateRequestData(request: URLRequest):void
		{
			super.updateRequestData(request);
			
			if (isTilable)
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
					_specialCacheStrings.push(str);
				}
			}
			
		}
		
		private function updateTiledLayerURLBase(): void
		{
			//update QTT Layer URL parts
			_tiledLayer.baseURL = getFullURL();
			_tiledLayer.setSpecialCacheStrings(_specialCacheStrings);
		}
		
		override public function updateData(b_forceUpdate:Boolean):void
		{
//			trace("WMSWithQTT updateData ["+name+"]");
			var gr: Graphics = graphics;
			if (isTilable)
			{
				updateTiledLayerURLBase();
				_tiledLayer.updateData(b_forceUpdate);
				changeTiledLayerVisibility(true);
			} else {
				changeTiledLayerVisibility(false);
				super.updateData(b_forceUpdate);
			}
		}
		
		override public function renderPreview(graphics: Graphics, f_width: Number, f_height: Number): void
		{
			if (isTilable)
			{
				if(tileLayer.width > 0 && tileLayer.height > 0) {
					var matrix: Matrix  = new Matrix();
					matrix.translate(-f_width / 3, -f_width / 3);
					matrix.scale(3, 3);
					matrix.translate(tileLayer.width / 3, tileLayer.height / 3);
					matrix.invert();
					var bd: BitmapData = new BitmapData(tileLayer.width, tileLayer.height, true, 0x00000000);
					bd.draw(tileLayer);
					
	  				graphics.beginBitmapFill(bd, matrix, false, true);
					graphics.drawRect(0, 0, f_width, f_height);
					graphics.endFill();
				}
				
			} else {
				super.renderPreview(graphics, f_width, f_height);	
			}
			
		}
		
		override public function draw(graphics: Graphics): void
		{
//			trace("WMSWithQTT draw ["+name+"] isTilable: " + isTilable);
			if (isTilable)
			{
//				trace("\t WMSWithQTT draw ["+name+"] zoom: " + _tiledLayer.zoom);
				updateTiledLayerURLBase();
				if (_tiledLayer.zoom < 1)
				{
					
				}
				//clear WMS graphics
				graphics.clear();
				
				_tiledLayer.draw(_tiledLayer.graphics);
				changeTiledLayerVisibility(true);
			} else {
				changeTiledLayerVisibility(false);
				super.draw(graphics);
			}
		}
		
		override public function onAreaChanged(b_finalChange: Boolean): void
		{
//			trace("WMSWithQTT onAreaChanged ["+name+"]");
			if (isTilable)
			{
				updateTiledLayerURLBase();
				_tiledLayer.onAreaChanged(b_finalChange);
				
				draw(graphics);
			} else {
				super.onAreaChanged(b_finalChange);
			}
		}
		
		override public function onContainerSizeChanged(): void
		{
			super.onContainerSizeChanged();
			_tiledLayer.width = container.width;
			_tiledLayer.height = container.height;
		}
		
		override public function synchroniseWith(s_variableId: String, value: Object): Boolean
		{
			var bool: Boolean = super.synchroniseWith(s_variableId, value);
			
//			trace(name + " synchroniseWith " + bool);
			
			return bool;
		}
		
	}
}