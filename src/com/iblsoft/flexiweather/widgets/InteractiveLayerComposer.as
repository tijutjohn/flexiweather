package com.iblsoft.flexiweather.widgets
{
	import com.iblsoft.flexiweather.ogc.BBox;
	import com.iblsoft.flexiweather.ogc.InteractiveLayerMSBase;
	import com.iblsoft.flexiweather.ogc.InteractiveLayerWMS;
	import com.iblsoft.flexiweather.ogc.WMSLayerConfiguration;
	import com.iblsoft.flexiweather.utils.Serializable;
	import com.iblsoft.flexiweather.utils.Storage;
	import com.iblsoft.flexiweather.widgets.googlemaps.InteractiveLayerGoogleMaps;
	
	import flash.display.DisplayObject;
	import flash.events.Event;
	
	import mx.collections.ArrayCollection;
	import mx.events.CollectionEvent;
	import mx.events.CollectionEventKind;
	import mx.events.FlexEvent;
	
	public class InteractiveLayerComposer extends InteractiveDataLayer implements Serializable
	{
        protected var m_layers: ArrayCollection = new ArrayCollection();

		private var mb_orderingLayers: Boolean = false;

		public function InteractiveLayerComposer(container: InteractiveWidget)
		{
			super(container);
			m_layers.addEventListener(CollectionEvent.COLLECTION_CHANGE, onLayerCollectionChanged);
		}
		
		
		public function addLayer(l: InteractiveLayer): void
		{
			m_layers.addItemAt(l, 0);
			bindSubLayer(l);
			
			notifyLayersChanged(l);
			
			//when new layer is added to container, call onAreaChange to notify layer, that layer is already added to container, so it can render itself
			l.onAreaChanged(true);
			
		}
		

		private function notifyLayersChanged(layer: InteractiveLayer = null): void
		{
			if (layer)
			{
				m_layers.itemUpdated(layer);	
			} else {
				dispatchEvent(new Event("layersChanged"));
			}
		}
		public function orderLayers(): void
		{
			if(mb_orderingLayers)
				return;
			mb_orderingLayers = true;
			try {
//				trace("**********************************************")
//				trace("                 SORTING by ZORDER start state");
//				trace("**********************************************")
//				for(i = 0; i < numChildren; ++i) 
//				{
//					var layer: InteractiveLayer = InteractiveLayer(getChildAt(i)); 
//					trace("LAYER ["+i+"] = " + layer.name + " order: " + layer.zOrder); 
//				}
//				trace("**********************************************")
				
				// stable-sort interactive layers in ma_layers according to their zOrder property
				for(var i: int = 0; i < numChildren; ++i) {
					var ilI: InteractiveLayer = InteractiveLayer(getChildAt(i)); 
					for(var j: int = i + 1; j < numChildren; ++j) {
						var ilJ: InteractiveLayer = InteractiveLayer(getChildAt(j));
//						trace('[InteractiveLayerComposer.orderLayers] ... checking ' + ilJ.name + '['+ilJ.zOrder+'] with ' + ilI.name+'['+ilI.zOrder+']');
						if(ilJ.zOrder < ilI.zOrder) {
							// swap Ith and Jth layer, we know that J > I
//							trace('\t [InteractiveLayerComposer.orderLayers] ... swapping ' + ilJ.name + '['+ilJ.zOrder+'] with ' + ilI.name+'['+ilI.zOrder+']');
							swapChildren(ilJ, ilI); 
							ilI = InteractiveLayer(getChildAt(i)); 
							//removeChildAt(j);
							//removeChildAt(i);
							//addChildAt(ilJ, i);
							//addChildAt(ilI, j);
						}
					}
				}
				
//				trace("**********************************************")
//				trace("                 SORTING by ZORDER end state");
//				trace("**********************************************")
//				for(i = 0; i < numChildren; ++i) 
//				{
//					var layer: InteractiveLayer = InteractiveLayer(getChildAt(i)); 
//					trace("LAYER ["+i+"] = " + layer.name + " order: " + layer.zOrder); 
//				}
//				trace("**********************************************")
				
			}
			finally {
				mb_orderingLayers = false;
			}
		}

		public function removeLayer(l: InteractiveLayer): void
		{
			var i : int = m_layers.getItemIndex(l);
			if(i >= 0) {
				unbindSubLayer(l);
				m_layers.removeItemAt(i);
				notifyLayersChanged(l);
			}
		}
		
		public function removeAllLayers(): void
		{
			for each(var l: InteractiveLayer in m_layers)
				unbindSubLayer(l);
			m_layers.removeAll();
			
			notifyLayersChanged();
		}

		public function getLayerCount(): uint
		{ return m_layers.length; }


		public function getLayerByID(layerID: String):InteractiveLayer
		{
			if (m_layers && m_layers.length > 0)
			{
				for each (var layer:InteractiveLayer in m_layers)
				{
//					trace("\t InteractiveLayerCompose getLayerByID["+layerID+"] layer.id: " + layer.id + " name: " + layer.name + " label: " + layer.layerName);
					if (layer is InteractiveLayerMSBase)
					{
						var config: WMSLayerConfiguration = (layer as InteractiveLayerMSBase).configuration as WMSLayerConfiguration;
//						trace("\t InteractiveLayerCompose config: " + config.label);
					}
						
					if (layer.id && layer.id == layerID)
						return layer;
				}
			}
			return null;
		}

		
		public function getLayerAt(i_index: uint): InteractiveLayer
		{ return InteractiveLayer(m_layers.getItemAt(i_index)); }
		
		public function setLayerIndex(l: InteractiveLayer, i: int): void
		{
			var i_current: int = m_layers.getItemIndex(l);
			if(i_current == i)
				return;
			if(i_current >= 0)
				m_layers.removeItemAt(i_current);
			m_layers.addItemAt(l, i);
					
			notifyLayersChanged(l);
		}

		public function callLayersFunction(functionName: String, params: Array): void
		{
			for each(var l: InteractiveLayer in m_layers) {
            	
				if (l.hasOwnProperty(functionName))
				{
	        		var fnc: Function = l[functionName] as Function;
	            	fnc.apply(l, params);
				} else {
					trace("Layer " + l + " has not function called " + functionName);
				}
			}
		}
		
		override public function onAreaChanged(b_finalChange: Boolean): void
		{
			for each(var l: InteractiveLayer in m_layers) {
            	l.onAreaChanged(b_finalChange);
			}			
		}
		
		override public function onContainerSizeChanged(): void
		{
			for each(var l: InteractiveLayer in m_layers) {
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
			
//			trace("\n\n\tInteractiveLayerComposer negotiateBBox newBBox at startup: :" + newBBox.toLaLoString(s_crs));
			var latestBBox: BBox;
			for(var i: int = 0; i < m_layers.length; ++i) {
				
				var l: InteractiveLayer = InteractiveLayer(m_layers.getItemAt(i));
				latestBBox = l.negotiateBBox(newBBox, changeZoom);
				if (!latestBBox.equals(newBBox))
				{
//					trace("WARNING: COMPOSER bbox changed by layer " + l.layerName);
					if (l is InteractiveLayerGoogleMaps)
					{
						var viewBBox: BBox = (l as InteractiveLayerGoogleMaps).getViewBBox();
//						trace("\t current view for google maps: " + viewBBox);
					}
				}
				newBBox = latestBBox;
//				trace("\tInteractiveLayerComposer negotiateBBox newBBox ["+i+"] :" + newBBox.toLaLoString(s_crs));
			}
//			trace("\tInteractiveLayerComposer negotiateBBox newBBox at end: :" + newBBox.toLaLoString(s_crs));
			
			return newBBox;
		}

		
        // data refreshing
        override public function refresh(b_force: Boolean): void
        {
        	super.refresh(b_force);
			for each(var l: InteractiveLayer in m_layers) {
            	l.refresh(b_force);
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
					while(numChildren > 0) {
						l = getChildAt(0) as InteractiveLayer;
						removeChildAt(0);
					}
					// add layers as children in reversed order
					for each(l in m_layers) {
						if (l)
							addChildAt(l, 0);
						else {
							trace("onLayerCollectionChanged: Layer is null")
						}
					}
//					trace("onLayerCollectionChanged reverse order");
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
        
        [Bindable (event="layersChanged")]
        public function get layers(): ArrayCollection
        { return m_layers; }
        
        
        /**
		 * Clone interactiveLayer 
		 * 
		 */		
		override public function clone(): InteractiveLayer
		{
			var composer: InteractiveLayerComposer =  new InteractiveLayerComposer(container);
			
			for each (var l: InteractiveLayer in layers)
			{
				var newLayer: InteractiveLayer = l.clone();
				composer.addLayer(newLayer);
			}
			
			return composer;
		}
	}
}