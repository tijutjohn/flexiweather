package com.iblsoft.flexiweather.widgets
{
	import com.iblsoft.flexiweather.events.InteractiveLayerEvent;
	import com.iblsoft.flexiweather.ogc.ISynchronisedObject;
	import com.iblsoft.flexiweather.ogc.InteractiveLayerWMS;
	import com.iblsoft.flexiweather.ogc.SynchronisedVariableChangeEvent;
	import com.iblsoft.flexiweather.proj.Coord;
	import com.iblsoft.flexiweather.utils.ArrayUtils;
	import com.iblsoft.flexiweather.utils.DateUtils;
	
	import flash.events.DataEvent;
	import flash.events.Event;
	
	import mx.collections.ArrayCollection;
	import mx.events.CollectionEvent;
	import mx.events.CollectionEventKind;
	import mx.events.FlexEvent;
	
	public class InteractiveLayerComposer extends InteractiveLayer
	{
        internal var m_layers: ArrayCollection = new ArrayCollection();

		public static const TIME_AXIS_UPDATED: String = "timeAxisUpdated";
		[Event(name = TIME_AXIS_UPDATED, type = "flash.events.DataEvent")]
		
		public static const PRIMARY_LAYER_CHANGED: String = "primaryLayerChanged";
		[Event(name = PRIMARY_LAYER_CHANGED, type = "flash.events.DataEvent")]

		public static const TIME_VARIABLE_CHANGED: String = "timeVariableChanged";
		[Event(name = TIME_VARIABLE_CHANGED, type = "mx.events.DynamicEvent")]
		
		public static const SYNCHRONISE_WITH: String = "synchroniseWith";
		[Event(name = SYNCHRONISE_WITH, type = "mx.events.DynamicEvent")]

		private var mb_orderingLayers: Boolean = false;

		public function InteractiveLayerComposer(container: InteractiveWidget)
		{
			super(container);
			m_layers.addEventListener(CollectionEvent.COLLECTION_CHANGE, onLayerCollectionChanged);
		}
		
		private var _dateFormat: String;
		public function get dateFormat(): String
		{
			return _dateFormat;
		}
		public function set dateFormat(value: String): void
		{
			_dateFormat = value;
			dispatchEvent(new Event('frameChanged'));
		}
		
		[Bindable (event="frameChanged")]
		public function get frame(): Date
		{
			var frameDate: Date = getSynchronizedFrameValue();
			return frameDate;
		}
		[Bindable (event="frameChanged")]
		public function get frameString(): String
		{
			var frameDate: Date = getSynchronizedFrameValue();
			if (dateFormat && dateFormat.length > 0)
				return DateUtils.strftime(frameDate, dateFormat);
				
			return '';
		}
		
		public function addLayer(l: InteractiveLayer): void
		{
			m_layers.addItemAt(l, 0);
			bindSubLayer(l);
			
			notifyLayersChanged(l);
			
			//orderLayers();
		}

		private function notifyLayersChanged(layer: InteractiveLayer = null): void
		{
			if (layer)
			{
//				trace("COMPOSER notifyLayersChanged: " + layer);
				m_layers.itemUpdated(layer);	
			} else {
//				trace("COMPOSER notifyLayersChanged ");
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
//			notifyLayersChanged();
		}

		protected function onSynchronisedVariableChanged(event: SynchronisedVariableChangeEvent): void
		{
			dispatchEvent(new DataEvent(TIME_AXIS_UPDATED));
			dispatchEvent(new Event('frameChanged'));
		}

		protected function onSynchronisedVariableDomainChanged(event: SynchronisedVariableChangeEvent): void
		{
			dispatchEvent(new DataEvent(TIME_AXIS_UPDATED));
			dispatchEvent(new Event('frameChanged'));
		}
		
		
		private function getSynchronizedFrameValue(): Date
		{
			var l_syncLayers: Array = [];
			var l_timeAxis: Array = enumTimeAxis(l_syncLayers);
          	if(l_timeAxis == null) // no time axis
          		return null;
          		
			var so: ISynchronisedObject;
			
          	for each(so in l_syncLayers) 
          	{
          		var frame: Date = so.getSynchronisedVariableValue("frame") as Date;
//          		trace("getSynchronizedFrameValue frame: " + frame);
          	}

			return frame;
		}
		/**
		 * Layer composer need to dispatch event when new layer becomes primary 
		 * 
		 */		
		public function primaryLayerHasChanged(): void
		{
			dispatchEvent(new DataEvent(PRIMARY_LAYER_CHANGED));
		}
		
		// data global variables synchronisation
		public function enumTimeAxis(l_syncLayers: Array = null): Array
		{
			if(l_syncLayers == null)
				l_syncLayers = [];
			var l_timeAxis: Array = null;
			for each(var l: InteractiveLayer in m_layers) {
				var so: ISynchronisedObject = l as ISynchronisedObject;
				var test: * = so.getSynchronisedVariables();
				//trace("enumTimeAxis so: " + (so as Object).name + " synchro vars: " + test.toString());
            	if(so == null)
            		continue;
            	if(so.getSynchronisedVariables().indexOf("frame") < 0)
            		continue;
            		
            	if (!so.isPrimaryLayer())
            		continue;
            		
            	var l_frames: Array = so.getSynchronisedVariableValuesList("frame");
            	if(l_frames == null)
            		continue;

            	l_syncLayers.push(so);
            	if(l_timeAxis == null)
            		l_timeAxis = l_frames;
            	else
            		ArrayUtils.unionArrays(l_timeAxis, l_frames);
			}
			return l_timeAxis; 			
		}
		
		public function getDimensionDefaultValue(dimName: String): Object
		{
			var l_syncLayers: Array = [];
			var l_timeAxis: Array = enumTimeAxis(l_syncLayers);
//          	if(l_timeAxis == null) // no time axis
//          		return null;
          		
          	var i: int;
			var so: ISynchronisedObject;
			
          	for each(so in l_syncLayers) 
          	{
				var value: Object = (so as InteractiveLayerWMS).getWMSDimensionDefaultValue(dimName );
          	}

			return value;
		}
		public function getDimensionValues(dimName: String, b_intersection: Boolean = true): Array
		{
			
			var l_syncLayers: Array = [];
			var l_timeAxis: Array = enumTimeAxis(l_syncLayers);
         	if(l_timeAxis == null) // no time axis
         		return null;
          		
          	var i: int;
			var so: ISynchronisedObject;
			
			var a_dimValues: Array;
          	for each(so in l_syncLayers) 
          	{
          		//trace("\n Composer getDimensionValues ["+dimName+"] get values for layer: " + (so as Object).name);
				var values: Array = (so as InteractiveLayerWMS).getWMSDimensionsValues(dimName, true);
          		
          		if(a_dimValues == null)
    				a_dimValues = values;
    			else {
    				if(b_intersection)
    					a_dimValues = ArrayUtils.intersectedArrays(a_dimValues, values);
    				else
    					ArrayUtils.unionArrays(a_dimValues, values);
    			}	
          	}

			return a_dimValues;
				
		}
		
		public function areFramesInsideTimePeriod(startDate: Date, endDate: Date): Boolean
		{
			var l_syncLayers: Array = [];
			var l_timeAxis: Array = enumTimeAxis(l_syncLayers);
          	if(l_timeAxis == null) // no time axis
          		return false;
          		
          	var i: int;
			var so: ISynchronisedObject;
			
          	for each(so in l_syncLayers) {
          		var frame: Date = so.getSynchronisedVariableValue("frame") as Date;
          		if(frame == null)
          			continue;
          			
          		for(i = 0; i < l_timeAxis.length; ++i) 
          		{
          			var currDate: Date = l_timeAxis[i] as Date;
          			if (startDate.time <= currDate.time && currDate.time <= endDate.time) 
          			{
          				return true;
          			}
          		}
          	}
          	
          	return false;
		}

		/**
		 * return first available frame 
		 * @return 
		 * 
		 */		
		public function getFirstFrame(): Date
		{
			var l_syncLayers: Array = [];
			var l_timeAxis: Array = enumTimeAxis(l_syncLayers);
          	if(l_timeAxis == null) // no time axis
          		return null;
          	
          	return 	l_timeAxis[0] as Date;
		}
		
		public function getLastFrame(): Date
		{
			var l_syncLayers: Array = [];
			var l_timeAxis: Array = enumTimeAxis(l_syncLayers);
          	if(l_timeAxis == null) // no time axis
          		return null;
          	
          	return 	l_timeAxis[l_timeAxis.length - 1] as Date;
		}
		public function getNowFrame(): Date
		{
			var l_syncLayers: Array = [];
			var l_timeAxis: Array = enumTimeAxis(l_syncLayers);
          	if(l_timeAxis == null) // no time axis
          		return null;
          		
          	var i: int;
			var so: ISynchronisedObject;
			
			var now: Date = DateUtils.convertToUTCDate(new Date());
			var nowDistance: Number = Number.MAX_VALUE;
			var nowFrame: Date;
			
          	for each(so in l_syncLayers) {
          		var frame: Date = so.getSynchronisedVariableValue("frame") as Date;
          		if(frame == null)
          			continue;
          			
          		for(i = 0; i < l_timeAxis.length; ++i) 
          		{
          			var currDate: Date = l_timeAxis[i] as Date;
          			if (Math.abs(currDate.time - now.time) < nowDistance) 
          			{
          				nowDistance = Math.abs(currDate.time - now.time);
          				nowFrame = currDate;
          			}
          		}
          	}
          	
          	return nowFrame;
		}
		
		public function moveFrame(i_offset: int): Boolean
		{
			var l_syncLayers: Array = [];
			var l_timeAxis: Array = enumTimeAxis(l_syncLayers);
          	if(l_timeAxis == null) // no time axis
          		return false;

			var i: int;
			var so: ISynchronisedObject;

			/*trace("InteractiveLayerComposer.moveFrame(): Overall timeaxis:");
       		for(i = 0; i < l_timeAxis.length; ++i) {
       			trace("  " + ISO8601Parser.dateToString(l_timeAxis[i]));
       		}*/

			var i_currentIndex: int = -1; 
          	for each(so in l_syncLayers) {
          		var frame: Date = so.getSynchronisedVariableValue("frame") as Date;
          		if(frame == null)
          			continue;
          		for(i = 0; i < l_timeAxis.length; ++i) {
          			if((l_timeAxis[i] as Date).time == frame.time) {
          				i_currentIndex = i;
          				break;
          			}
          		}
          		if(i_currentIndex >= 0)
          			break;
          	}
      		if(i_currentIndex < 0)
      			return false;
          	i_currentIndex += i_offset;
          	if(i_currentIndex < 0)
          		return false;
          	if(i_currentIndex >= l_timeAxis.length)
          		return false;

          	var newFrame: Date = l_timeAxis[i_currentIndex];
          	for each(so in l_syncLayers) {
          		if(so.synchroniseWith("frame", newFrame))
          			InteractiveLayer(so).refresh(false);
          	}
          	return true;
		}

		/**
		 * Return frames count 
		 * @return 
		 * 
		 */		
		public function get framesLength(): int
		{
			var l_syncLayers: Array = [];
			
			var l_timeAxis: Array = enumTimeAxis(l_syncLayers);
          	if(l_timeAxis == null) // no time axis
          		return 0;
          		
			return l_timeAxis.length;
		}
		
		public function getFrame(index: int): Date
		{
			var l_syncLayers: Array = [];
			
			var l_timeAxis: Array = enumTimeAxis(l_syncLayers);
          	if(l_timeAxis == null) // no time axis
          		return null;
          		
			if (l_timeAxis.length > index)
			{
				return l_timeAxis[index] as Date;
			}
			
			return null;	
		}
		
		public function setFrame(newFrame: Date, b_nearrest: Boolean = true): Boolean
		{
			for each(var l: InteractiveLayer in m_layers) {
            	var so: ISynchronisedObject = l as ISynchronisedObject;
            	if(so == null)
            		continue;
            	if(so.getSynchronisedVariableValue("frame") == null)
            		continue;
          		if(so.synchroniseWith("frame", newFrame))
          			l.refresh(false);
          	}
          	return true;
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
			var so: ISynchronisedObject = l as ISynchronisedObject;
			if(so != null) {
				l.addEventListener(SynchronisedVariableChangeEvent.SYNCHRONISED_VARIABLE_CHANGED,
						onSynchronisedVariableChanged);
				l.addEventListener(SynchronisedVariableChangeEvent.SYNCHRONISED_VARIABLE_DOMAIN_CHANGED,
						onSynchronisedVariableDomainChanged);
			}
		}
		
		protected function unbindSubLayer(l: InteractiveLayer): void
		{
			l.removeEventListener(FlexEvent.UPDATE_COMPLETE, onSignalSubLayerChange);
			l.removeEventListener(FlexEvent.SHOW, onSignalSubLayerChange);
			l.removeEventListener(FlexEvent.HIDE, onSignalSubLayerChange);
			var so: ISynchronisedObject = l as ISynchronisedObject;
			if(so != null) {
				l.removeEventListener(SynchronisedVariableChangeEvent.SYNCHRONISED_VARIABLE_CHANGED,
						onSynchronisedVariableChanged);
				l.removeEventListener(SynchronisedVariableChangeEvent.SYNCHRONISED_VARIABLE_DOMAIN_CHANGED,
						onSynchronisedVariableDomainChanged);
			}
		}
		
		protected function onLayerCollectionChanged(event: CollectionEvent): void
		{
//			trace("onLayerCollectionChanged kind: " + event.kind);
			
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
						addChildAt(l, 0);
					}
//					trace("onLayerCollectionChanged reverse order");
					notifyLayersChanged();
					break;
			}
			dispatchEvent(new DataEvent(TIME_AXIS_UPDATED));
		}
        
        private var _featureTooltipCallsRunning: Boolean;
        private var _featureTooltipCallsCount: int;
        private var _featureTooltipString: String;
        public function getFeatureTooltipForAllLayers(coord: Coord): void
        {
        	if (!_featureTooltipCallsRunning)
        	{
	        	_featureTooltipCallsCount = 0;
	        	_featureTooltipString = '';
	        	for each (var layer: InteractiveLayer in layers)
	        	{
	        		if (layer.hasFeatureInfo() && layer.visible)
	        		{
	        			_featureTooltipCallsCount++;
	        			layer.getFeatureInfo(coord, onFeatureInfoAvailable);
	        		}
	        	}
	        	if (_featureTooltipCallsCount > 0)
	        		_featureTooltipCallsRunning = true;
	        }
        }
        
        private function onFeatureInfoAvailable(s: String, layer: InteractiveLayer): void
        {
        	_featureTooltipCallsCount--;
        	s = s.replace(/<table>/g, "<table><br/>");
			s = s.replace(/<\/table>/g, "</table><br/>");
			s = s.replace(/<tr>/g, "<tr><br/>");
			s = s.replace(/<td>/g, "<td>&nbsp;");
			
			s = s.substring(s.indexOf('<body>'), s.length);
			s = s.substring(6,s.indexOf('</html>'));
			//remove body
			s = s.substring(0,s.indexOf('</body>'));
			var infoXML: XML = new XML(s);
			var info: String = infoXML.text();
//        	trace("LayerComposer onFeatureInfoAvailable : " + info + " for layer: " + layer.name);
        	_featureTooltipString += '<p><b><font color="#6EC1FF">'+layer.name+'</font></b></p>';
        	_featureTooltipString += '<p>'+s+'</p><p></p>';
        	
        	var ile: InteractiveLayerEvent = new InteractiveLayerEvent(InteractiveLayerEvent.FEATURE_INFO_RECEIVED, true);
        	ile.text = _featureTooltipString;
        	dispatchEvent(ile);
        	
        	if (_featureTooltipCallsCount < 1)
        	{
        		_featureTooltipCallsRunning = false;
        	}
        }
        
        public function isCompatibleWithCRS(crs: String): Boolean
        {
        	if (m_layers && m_layers.length > 0)
        	{
        		for each (var layer: InteractiveLayerWMS in m_layers)
        		{
        			if (!layer.configuration.isCompatibleWithCRS(crs))
        				return false;
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