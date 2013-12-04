package com.iblsoft.flexiweather.widgets
{
	import com.iblsoft.flexiweather.events.InteractiveLayerEvent;
	import com.iblsoft.flexiweather.events.InteractiveLayerMapEvent;
	import com.iblsoft.flexiweather.events.InteractiveLayerWMSEvent;
	import com.iblsoft.flexiweather.ogc.BBox;
	import com.iblsoft.flexiweather.ogc.InteractiveLayerMSBase;
	import com.iblsoft.flexiweather.ogc.InteractiveLayerWMS;
	import com.iblsoft.flexiweather.ogc.configuration.layers.WMSLayerConfiguration;
	import com.iblsoft.flexiweather.utils.LoggingUtils;
	import com.iblsoft.flexiweather.utils.Serializable;
	import com.iblsoft.flexiweather.utils.Storage;
	import com.iblsoft.flexiweather.widgets.googlemaps.InteractiveLayerGoogleMaps;
	
	import flash.display.DisplayObject;
	import flash.events.Event;
	
	import mx.collections.ArrayCollection;
	import mx.events.CollectionEvent;
	import mx.events.CollectionEventKind;
	import mx.events.FlexEvent;

	[Event(name = "mapLoaded", type = "com.iblsoft.flexiweather.events.InteractiveLayerMapEvent")]
	[Event(name = "mapBeforeRefresh", type = "com.iblsoft.flexiweather.events.InteractiveLayerMapEvent")]
	[Event(name = "mapRefreshed", type = "com.iblsoft.flexiweather.events.InteractiveLayerMapEvent")]
	public class InteractiveLayerComposer extends InteractiveDataLayer implements Serializable
	{
		public static const LAYERS_CHANGED: String = 'layersChanged';
		
		private static var composerID: int = 0;
		
		protected var m_layers: ArrayCollection = new ArrayCollection();
		private var mb_orderingLayers: Boolean = false;

		public function InteractiveLayerComposer(container: InteractiveWidget)
		{
			super(container);
			m_layers.addEventListener(CollectionEvent.COLLECTION_CHANGE, onLayerCollectionChanged);
			
			composerID++;
			id = composerID.toString();
		}

		override protected function commitProperties(): void
		{
			super.commitProperties();
			if (_layersOrderChanged)
			{
				orderLayers();
				_layersOrderChanged = false;
			}
		}

		private function onLayerLoadingFinished(event: InteractiveLayerEvent): void
		{
			var l: InteractiveLayer = event.interactiveLayer as InteractiveLayer;
			for each (l in m_layers)
			{
				if (l is InteractiveDataLayer)
				{
					var status: String = (l as InteractiveDataLayer).status;
					if (status != InteractiveDataLayer.STATE_DATA_LOADED)
					{
						//not all layers are loaded, stop checking
						return;
					}
				}
			}
			dispatchEvent(new InteractiveLayerMapEvent(InteractiveLayerMapEvent.MAP_LOADED, true));
		}

		public function addLayers(layers: Array): void
		{
			var l: InteractiveLayer;
			for each (l in layers)
			{
				if (l is InteractiveDataLayer)
				{
					(l as InteractiveDataLayer).addEventListener(InteractiveDataLayer.LOADING_FINISHED, onLayerLoadingFinished);
					(l as InteractiveDataLayer).addEventListener(InteractiveDataLayer.LOADING_FINISHED_FROM_CACHE, onLayerLoadingFinished);
				}
			}
			for each (l in layers)
			{
				addLayer(l);
			}
			
		}

		private function redispatchComposerChange(event: Event): void
		{
			dispatchEvent(event);
		}
		
		private function addComposerChangeEventListenersForLayer(l: InteractiveLayer): void
		{
			l.addEventListener(InteractiveLayerWMSEvent.WMS_STYLE_CHANGED, redispatchComposerChange);
			l.addEventListener(InteractiveLayerEvent.VISIBILITY_CHANGED, redispatchComposerChange);
		}
		private function removeComposerChangeEventListenersForLayer(l: InteractiveLayer): void
		{
			l.removeEventListener(InteractiveLayerWMSEvent.WMS_STYLE_CHANGED, redispatchComposerChange);
			l.removeEventListener(InteractiveLayerEvent.VISIBILITY_CHANGED, redispatchComposerChange);
		}
		public function addLayer(l: InteractiveLayer): void
		{
			addComposerChangeEventListenersForLayer(l);
			l.addEventListener(InteractiveLayerEvent.LAYER_INITIALIZED, onLayerInitialized);
			if (container)
				l.container = container;
			
			m_layers.addItemAt(l, 0);
			//wait for layer is initialized. Function "layerAdded" will be called
			debugLayers();
		}
		
		private function debugLayers(): void
		{
			return;
			
			var total: int = m_layers.length;
			var i: int;
			for (i = 0; i < total; i++)
			{
				var l: InteractiveLayer = m_layers.getItemAt(i) as InteractiveLayer;
			}
			for (i = 0; i < numChildren; ++i)
			{
				var ilI: InteractiveLayer = InteractiveLayer(getChildAt(i));
			}
		}

		protected function invalidateAreaForLayer(layer: InteractiveLayer): void
		{
			layer.onAreaChanged(true);
		}
		
		private function onLayerInitialized(event: InteractiveLayerEvent): void
		{
			var l: InteractiveLayer = event.target as InteractiveLayer;
			l.removeEventListener(InteractiveLayerEvent.LAYER_INITIALIZED, onLayerInitialized);
			layerAdded(l);
		}

		protected function layerAdded(layer: InteractiveLayer): void
		{
			bindSubLayer(layer);
			notifyLayersChanged(layer);
			
			//TODO we need to check if layer is synchronizable and call this when it will be ready for synchronization
			
			//when new layer is added to container, call onAreaChange to notify layer, that layer is already added to container, so it can render itself
//			invalidateAreaForLayer(layer);
		}

		override public function invalidateDynamicPart(b_invalid: Boolean = true): void
		{
			//do not do anything in layer composer on invalidate dynamic part, each layer will handle this on its own
		}

		private function notifyLayersChanged(layer: InteractiveLayer = null): void
		{
			if (layer)
			{
				m_layers.itemUpdated(layer);
			}
			else
			{
				dispatchEvent(new Event(LAYERS_CHANGED));
			}
			invalidateLayersOrder();
		}

		private var _layersOrderChanged: Boolean;
		public function invalidateLayersOrder(): void
		{
			if (!_layersOrderChanged)
			{
				_layersOrderChanged = true;
				invalidateProperties();
			}
		}
		
		public function orderLayers(): void
		{
			if (mb_orderingLayers)
				return;
			mb_orderingLayers = true;
			try
			{
				var layer: InteractiveLayer;
				// stable-sort interactive layers in ma_layers according to their zOrder property
				for (var i: int = 0; i < numChildren; ++i)
				{
					var ilI: InteractiveLayer = InteractiveLayer(getChildAt(i));
					for (var j: int = i + 1; j < numChildren; ++j)
					{
						var ilJ: InteractiveLayer = InteractiveLayer(getChildAt(j));
						if (ilJ.zOrder < ilI.zOrder)
						{
							// swap Ith and Jth layer, we know that J > I
							swapChildren(ilJ, ilI);
							ilI = InteractiveLayer(getChildAt(i));
						}
					}
				}
			}
			finally
			{
				mb_orderingLayers = false;
			}
		}

		public function removeLayer(l: InteractiveLayer): void
		{
			var i: int = m_layers.getItemIndex(l);
			if (i >= 0)
			{
				removeComposerChangeEventListenersForLayer(l);
				unbindSubLayer(l);
				m_layers.removeItemAt(i);
				notifyLayersChanged(l);
			}
		}

		public function removeAllLayers(): void
		{
			for each (var l: InteractiveLayer in m_layers)
			{
				removeComposerChangeEventListenersForLayer(l);
				unbindSubLayer(l);
			}
			m_layers.removeAll();
			notifyLayersChanged();
		}

		public function getLayerCount(): uint
		{
			return m_layers.length;
		}

		public function getLayerByID(layerID: String): InteractiveLayer
		{
			if (m_layers && m_layers.length > 0)
			{
				for each (var layer: InteractiveLayer in m_layers)
				{
					if (layer is InteractiveLayerMSBase)
					{
						var config: WMSLayerConfiguration = (layer as InteractiveLayerMSBase).configuration as WMSLayerConfiguration;
					}
					if (layer.id && layer.id == layerID)
						return layer;
				}
			}
			return null;
		}

		public function getLayerAt(i_index: uint): InteractiveLayer
		{
			return InteractiveLayer(m_layers.getItemAt(i_index));
		}

		public function setLayerIndex(l: InteractiveLayer, i: int): void
		{
			var i_current: int = m_layers.getItemIndex(l);
			if (i_current == i)
				return;
			if (i_current >= 0)
				m_layers.removeItemAt(i_current);
			m_layers.addItemAt(l, i);
			notifyLayersChanged(l);
		}

		public function callLayersFunction(functionName: String, params: Array): void
		{
			for each (var l: InteractiveLayer in m_layers)
			{
				if (l.hasOwnProperty(functionName))
				{
					var fnc: Function = l[functionName] as Function;
					fnc.apply(l, params);
				}
				else
				{
					trace("Layer " + l + " has not function called " + functionName);
				}
			}
		}

		override public function onAreaChanged(b_finalChange: Boolean): void
		{
			for each (var l: InteractiveLayer in m_layers)
			{
				l.onAreaChanged(b_finalChange);
			}
		}

		override public function onContainerSizeChanged(): void
		{
			for each (var l: InteractiveLayer in m_layers)
			{
				l.onContainerSizeChanged();
			}
		}

		protected function onSignalSubLayerChange(event: Event): void
		{
			invalidateDynamicPart();
			m_layers.itemUpdated(event.target);
		}

		override public function negotiateBBox(newBBox: BBox, changeZoom: Boolean = true): BBox
		{
			var s_crs: String = container.getCRS();
			var latestBBox: BBox;
			for (var i: int = 0; i < m_layers.length; ++i)
			{
				var l: InteractiveLayer = InteractiveLayer(m_layers.getItemAt(i));
				latestBBox = l.negotiateBBox(newBBox, changeZoom);
				if (!latestBBox.equals(newBBox))
				{
					if (l is InteractiveLayerGoogleMaps)
					{
						var viewBBox: BBox = (l as InteractiveLayerGoogleMaps).getViewBBox();
					}
				}
				newBBox = latestBBox;
			}
			return newBBox;
		}

		private var _refreshingLayersCount: int;
		
		// data refreshing
		override public function refresh(b_force: Boolean): void
		{
			if (_refreshingLayersCount > 0)
			{
				//there is not finished refreshing
				trace("there is not finished refreshing");
			}
			
			_refreshingLayersCount = m_layers.length;
			
			dispatchEvent(new InteractiveLayerMapEvent(InteractiveLayerMapEvent.BEFORE_REFRESH, true));
				
			super.refresh(b_force);
			
			for each (var l: InteractiveLayer in m_layers)
			{
				l.addEventListener(InteractiveDataLayer.LOADING_FINISHED, onRefreshLayerLoadingFinished);
				l.addEventListener(InteractiveDataLayer.LOADING_FINISHED_FROM_CACHE, onRefreshLayerLoadingFinished);
				l.refresh(b_force);
			}
		}
		
		private function onRefreshLayerLoadingFinished(event: InteractiveLayerEvent): void
		{
			var l: InteractiveLayer = event.target as InteractiveLayer;
			l.removeEventListener(InteractiveDataLayer.LOADING_FINISHED, onRefreshLayerLoadingFinished);
			l.removeEventListener(InteractiveDataLayer.LOADING_FINISHED_FROM_CACHE, onRefreshLayerLoadingFinished);
			
			_refreshingLayersCount--;
			
			if (_refreshingLayersCount == 0)
			{
				//refreshing is finished
				dispatchEvent(new InteractiveLayerMapEvent(InteractiveLayerMapEvent.MAP_REFRESHED, true));
			}
		}

		// helper methods        
		protected function bindSubLayer(l: InteractiveLayer): void
		{
			l.addEventListener(FlexEvent.UPDATE_COMPLETE, onSignalSubLayerChange);
			l.addEventListener(FlexEvent.SHOW, onSignalSubLayerChange);
			l.addEventListener(FlexEvent.HIDE, onSignalSubLayerChange);
		}

		protected function unbindSubLayer(l: InteractiveLayer): void
		{
			l.removeEventListener(FlexEvent.UPDATE_COMPLETE, onSignalSubLayerChange);
			l.removeEventListener(FlexEvent.SHOW, onSignalSubLayerChange);
			l.removeEventListener(FlexEvent.HIDE, onSignalSubLayerChange);
		}

		public function serialize(storage: Storage): void
		{
		}

		protected function onLayerCollectionChanged(event: CollectionEvent): void
		{
			switch (event.kind)
			{
				case CollectionEventKind.UPDATE:
					return;
					break;
				case CollectionEventKind.ADD:
				case CollectionEventKind.REMOVE:
					var l: InteractiveLayer;
					while (numChildren > 0)
					{
						l = getChildAt(0) as InteractiveLayer;
						removeChildAt(0);
					}
					// add layers as children in reversed order
					for each (l in m_layers)
					{
						if (l)
							addChildAt(l, 0);
						else
						{
							trace("onLayerCollectionChanged: Layer is null")
						}
					}
					notifyLayersChanged();
					break;
			}
		}

		public function isCompatibleWithCRS(crs: String): Boolean
		{
			if (m_layers && m_layers.length > 0)
			{
				for each (var layer: InteractiveLayer in m_layers)
				{
					if (layer is IConfigurableLayer)
					{
						var configurableLayer: IConfigurableLayer = layer as IConfigurableLayer;
						if (configurableLayer && configurableLayer.configuration && !configurableLayer.configuration.isCompatibleWithCRS(crs))
							return false;
					}
				}
			}
			return true;
		}

		[Bindable(event = "layersChanged")]
		public function get layers(): ArrayCollection
		{
			return m_layers;
		}
		[Bindable(event = "layersChanged")]
		public function get layersIDs(): String
		{
			var layersIDs: String = '';
			for each (var layer: InteractiveLayer in m_layers)
				layersIDs += layer.layerID + ", ";
				
			return layersIDs;
		}

		/**
		 * Clone interactiveLayer
		 *
		 */
		override public function clone(): InteractiveLayer
		{
			var composer: InteractiveLayerComposer = new InteractiveLayerComposer(container);
			for each (var l: InteractiveLayer in layers)
			{
				var newLayer: InteractiveLayer = l.clone();
				composer.addLayer(newLayer);
			}
			return composer;
		}

		/**
		 * Clone interactiveLayer
		 *
		 */
		public function cloneLayersForComposer(composer: InteractiveLayerComposer): void
		{
			var total: int = layers.length;
			var newLayers: Array = [];
			
			var newLayer: InteractiveLayer;
			for (var i: int = 0; i < total; i++)
			{
				var l: InteractiveLayer = layers.getItemAt(i) as InteractiveLayer;
				newLayer = l.clone();
				newLayers.unshift(newLayer);
			}
			
			composer.addLayers(newLayers);
			
			for each (newLayer in newLayers)
			{
//				composer.addLayer(newLayer);
				newLayer.refresh(true);
			}
			
			orderLayers();
		}
		
		override public function toString(): String
		{
			return "InteractiveLayerComposer ["+id+"]: ";
		}
	}
}
