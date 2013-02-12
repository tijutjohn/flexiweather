package com.iblsoft.flexiweather.ogc
{
	import com.iblsoft.flexiweather.events.InteractiveLayerEvent;
	import com.iblsoft.flexiweather.ogc.configuration.layers.interfaces.ILayerConfiguration;
	import com.iblsoft.flexiweather.utils.LoggingUtils;
	import com.iblsoft.flexiweather.widgets.IConfigurableLayer;
	import com.iblsoft.flexiweather.widgets.InteractiveLayer;
	import com.iblsoft.flexiweather.widgets.InteractiveLayerMap;
	
	import flash.events.Event;
	import flash.events.EventDispatcher;
	
	import mx.events.DynamicEvent;

	public class InteractiveLayerMapLayersInitializationWatcher extends EventDispatcher
	{
		public static const MAP_LAYERS_INITIALIZED: String = 'mapLayersInitialized';
		
		private static var uid: int = 0;
		public var id: int;
		private var _mapLayersInitializing: int;
		public var interactiveLayerMap: InteractiveLayerMap;
		
		public function InteractiveLayerMapLayersInitializationWatcher()
		{
			id = uid++;
		}
		
		override public function toString(): String
		{
			return "\InteractiveLayerMapLayersInitializationWatcher [" + id + "]: ";
		}
		
		public function onMapFromXMLReady(interactiveLayerMap: InteractiveLayerMap, layers: Array): void
		{
			var layer: InteractiveLayer;
			_mapLayersInitializing = 0;
			
			var cnt: int = 0;
			for each (layer in layers)
			{
				if (layer)
				{
					layer.addEventListener(InteractiveLayerEvent.LAYER_INITIALIZED, onLayerInitialized);
					_mapLayersInitializing++;
				}
			}
			for each (layer in layers)
			{
				var configuration: ILayerConfiguration;
				if (layer)
				{
					if (layer is IConfigurableLayer)
					{
						configuration = (layer as IConfigurableLayer).configuration;
					}
					interactiveLayerMap.addLayer(layer);
				}
				else
				{
				}
			}
			//			listLayers.executeBindings();
			//			player.timeAxis.executeBindings();
			for each (var l: InteractiveLayer in interactiveLayerMap.layers)
			{
				//we need to set b_force parameter to force to be able to get cached bitmaps
				l.refresh(false);
			}
		}
		
		private function onLayerInitialized(event: InteractiveLayerEvent): void
		{
			_mapLayersInitializing--;
			if (_mapLayersInitializing == 0)
			{
				dispatchEvent(new Event(MAP_LAYERS_INITIALIZED));
			}
		}
	}
}