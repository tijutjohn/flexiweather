package com.iblsoft.flexiweather.ogc.tiling
{
	import com.iblsoft.flexiweather.ogc.InteractiveLayerQTTMS;
	import com.iblsoft.flexiweather.ogc.InteractiveLayerWMS;
	import com.iblsoft.flexiweather.ogc.WMSLayerConfiguration;
	import com.iblsoft.flexiweather.widgets.InteractiveWidget;
	
	import flash.display.Graphics;
	import flash.events.DataEvent;
	import flash.net.URLRequest;

	public class InteractiveLayerWMSWithQTT extends InteractiveLayerWMS
	{
		private var _tiledLayer: InteractiveLayerQTTMS;
		public function get tileLayer(): InteractiveLayerQTTMS
		{
			return _tiledLayer;
		}
		
		public function get isTilable(): Boolean
		{
			var crs: String = container.getCRS();
			//return m_cfg.isTilableForCRS(crs);
			
			/**
			 *  TODO: set isTilable to false, if you dont want to use tiling on WMS 
			 * (e.g. because tilling is not working with all features - e.g animation)
			 */
			return false;
		}
		public function InteractiveLayerWMSWithQTT(container:InteractiveWidget, cfg:WMSLayerConfiguration)
		{
			super(container, cfg);
			
			_tiledLayer = new InteractiveLayerQTTMS(container, '', '&TileZoom=%ZOOM%&TileCol=%COL%&TileRow=%ROW%','&/png', container.getCRS(), null, 0, 12);
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
			refresh(true);		
			updateData(true);
		}
		
		private function changeTiledLayerVisibility(visible: Boolean): void
		{
			_tiledLayer.visible = visible;
		}
		
		override public function refresh(b_force:Boolean):void
		{
			if (isTilable)
			{
				_tiledLayer.refresh(b_force);
			} else {
				super.refresh(b_force);
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
			}
			
		}
		override public function updateData(b_forceUpdate:Boolean):void
		{
//			trace("WMSWithQTT updateData ["+name+"]");
			var gr: Graphics = graphics;
			if (isTilable)
			{
				//update QTT Layer URL parts
				_tiledLayer.baseURL = getFullURL();
				_tiledLayer.updateData(b_forceUpdate);
				changeTiledLayerVisibility(true);
			} else {
				changeTiledLayerVisibility(false);
				super.updateData(b_forceUpdate);
			}
		}
		
		override public function draw(graphics: Graphics): void
		{
//			trace("WMSWithQTT draw ["+name+"] isTilable: " + isTilable);
			if (isTilable)
			{
//				trace("\t WMSWithQTT draw ["+name+"] zoom: " + _tiledLayer.zoom);
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
				_tiledLayer.baseURL = getFullURL();
				_tiledLayer.onAreaChanged(b_finalChange);
				
				draw(graphics);
			} else {
				super.onAreaChanged(b_finalChange);
			}
		}
		
		override public function onContainerSizeChanged(): void
		{
			super.onContainerSizeChanged();
//			_tiledLayer.x = container.x;
//			_tiledLayer.y = container.y;
			_tiledLayer.width = container.width;
			_tiledLayer.height = container.height;
		}
		
	}
}