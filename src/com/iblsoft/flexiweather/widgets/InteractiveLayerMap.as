package com.iblsoft.flexiweather.widgets
{
	import com.iblsoft.flexiweather.events.GetFeatureInfoEvent;
	import com.iblsoft.flexiweather.events.InteractiveLayerEvent;
	import com.iblsoft.flexiweather.events.InteractiveLayerMapEvent;
	import com.iblsoft.flexiweather.ogc.ISynchronisedObject;
	import com.iblsoft.flexiweather.ogc.InteractiveLayerMSBase;
	import com.iblsoft.flexiweather.ogc.InteractiveLayerQTTMS;
	import com.iblsoft.flexiweather.ogc.InteractiveLayerWMS;
	import com.iblsoft.flexiweather.ogc.SynchronisationRole;
	import com.iblsoft.flexiweather.ogc.SynchronisedVariableChangeEvent;
	import com.iblsoft.flexiweather.ogc.cache.ICache;
	import com.iblsoft.flexiweather.ogc.cache.ICachedLayer;
	import com.iblsoft.flexiweather.ogc.tiling.ITiledLayer;
	import com.iblsoft.flexiweather.proj.Coord;
	import com.iblsoft.flexiweather.utils.ArrayUtils;
	import com.iblsoft.flexiweather.utils.DateUtils;
	import com.iblsoft.flexiweather.utils.HTMLUtils;
	import com.iblsoft.flexiweather.utils.Serializable;
	import com.iblsoft.flexiweather.utils.Storage;
	import com.iblsoft.flexiweather.utils.XMLStorage;
	
	import flash.events.DataEvent;
	import flash.events.Event;
	import flash.events.TimerEvent;
	import flash.utils.Timer;
	
	import mx.collections.ArrayCollection;
	import mx.controls.Alert;
	import mx.events.CollectionEvent;
	import mx.events.DynamicEvent;
	
	public class InteractiveLayerMap extends InteractiveLayerComposer implements Serializable
	{
		public static const TIMELINE_CONFIGURATION_CHANGE: String = "timelineConfigurationChange";
		
		public static const LAYERS_SERIALIZED_AND_READY: String = "layersSerializedAndReady";
		[Event(name = LAYERS_SERIALIZED_AND_READY, type = "mx.events.DynamicEvent")]
		
		public static const TIME_AXIS_UPDATED: String = "timeAxisUpdated";
		[Event(name = TIME_AXIS_UPDATED, type = "flash.events.DataEvent")]
		
		public static const TIME_AXIS_ADDED: String = "timeAxisAdded";
		[Event(name = TIME_AXIS_ADDED, type = "mx.events.DynamicEvent")]
		
		public static const TIME_AXIS_REMOVED: String = "timeAxisRemoved";
		[Event(name = TIME_AXIS_REMOVED, type = "mx.events.DynamicEvent")]
		
		public static const PRIMARY_LAYER_CHANGED: String = "primaryLayerChanged";
		[Event(name = PRIMARY_LAYER_CHANGED, type = "flash.events.DataEvent")]

		public static const TIME_VARIABLE_CHANGED: String = "timeVariableChanged";
		[Event(name = TIME_VARIABLE_CHANGED, type = "mx.events.DynamicEvent")]
		
		public static const SYNCHRONISE_WITH: String = "synchroniseWith";
		[Event(name = SYNCHRONISE_WITH, type = "mx.events.DynamicEvent")]
		
		
		/**
		 * first frame date from last periodical check 
		 */		
		private var _currentFirstFrame: Date;

		/**
		 * last frame date from last periodical check 
		 */		
		private var _currentLastFrame: Date;
		
		/**
		 * now frame date from last periodical check 
		 */		
		private var _currentNowFrame: Date;
		
		private var _periodicTimer: Timer;
		
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
		
		private var m_timelineConfiguration: MapTimelineConfiguration;
		private var m_timelineConfigurationChanged: Boolean;
		[Bindable] 
		public function get timelineConfiguration(): MapTimelineConfiguration
		{
			return m_timelineConfiguration;
		}
		public function set timelineConfiguration(value: MapTimelineConfiguration): void
		{
			m_timelineConfiguration  = value;
			m_timelineConfigurationChanged = true;
			
			dispatchEvent(new Event(TIMELINE_CONFIGURATION_CHANGE));
		}
		
		public function InteractiveLayerMap(container:InteractiveWidget)
		{
			super(container);
			
			_periodicTimer = new Timer(10 * 1000);
			_periodicTimer.addEventListener(TimerEvent.TIMER, onPeriodicTimerTick);
			_periodicTimer.start();
		}
		
		private function onPeriodicTimerTick(event: TimerEvent): void
		{
			periodicCheck();
		}
		
		/**
		 * Function is called periodically to check if there are changes in frames. It checks current first, last and now frames and compares
		 * them with lastly first, last and now frames and if there is any change, it dispatch proper events 
		 * 
		 */		
		private function periodicCheck(): void
		{
			var firstDate: Date = getFirstFrame();
			var lastDate: Date = getLastFrame();
			var nowDate: Date = getNowFrame();
			
			var ilme: InteractiveLayerMapEvent;
			
			if (firstDate && (!_currentFirstFrame || _currentFirstFrame.time != firstDate.time))
			{
				//there were change in first frame
				_currentFirstFrame = firstDate;
				ilme = new InteractiveLayerMapEvent(InteractiveLayerMapEvent.FIRST_FRAME_CHANGED);
				ilme.frameDate = firstDate;
				dispatchEvent(ilme);
			}
			if (lastDate && (!_currentLastFrame || _currentLastFrame.time != lastDate.time))
			{
				//there were change in last frame
				_currentLastFrame = lastDate;
				ilme = new InteractiveLayerMapEvent(InteractiveLayerMapEvent.LAST_FRAME_CHANGED);
				ilme.frameDate = lastDate;
				dispatchEvent(ilme);
			}
			if (nowDate && (!_currentNowFrame || _currentNowFrame.time != nowDate.time))
			{
				//there were change in now frame
				_currentNowFrame = nowDate;
				ilme = new InteractiveLayerMapEvent(InteractiveLayerMapEvent.NOW_FRAME_CHANGED);
				ilme.frameDate = nowDate;
				dispatchEvent(ilme);
			}
		}
		
		override public function serialize(storage: Storage): void
		{
			var wrappers: ArrayCollection;
			var wrapper: LayerSerializationWrapper;
			var layer: InteractiveLayer;
			
			LayerSerializationWrapper.m_iw = container;
			if (storage.isLoading())
			{
				wrappers = new ArrayCollection();
				 
				storage.serializeNonpersistentArrayCollection("layer", wrappers, LayerSerializationWrapper);
				m_layers.removeAll();
				var total: int = wrappers.length - 1;
				
				var newLayers: Array = [];
				for (var i: int = total; i >= 0; i--)
				{
					wrapper = wrappers.getItemAt(i) as LayerSerializationWrapper;
					layer = wrapper.m_layer;
					if (layer is InteractiveLayerMSBase)
					{
						if ((layer as InteractiveLayerMSBase).isPrimaryLayer())
						{
							setPrimaryLayer(layer as InteractiveLayerMSBase);
						}
					}
					newLayers.push(layer);
				}
				
				var de: DynamicEvent = new DynamicEvent(LAYERS_SERIALIZED_AND_READY);
				de['layers'] = newLayers;
				dispatchEvent(de);

			} else {
				//create wrapper collection
				wrappers = new ArrayCollection();
				
				for each (layer in m_layers)
				{
					wrapper = new LayerSerializationWrapper();
					wrapper.m_layer = layer;
					wrappers.addItem(wrapper);
				}
				
				storage.serializeNonpersistentArrayCollection("layer", wrappers, LayerSerializationWrapper);
				trace("Map serialize: " + (storage as XMLStorage).xml);
			}
		}
		
		override protected function onLayerCollectionChanged(event: CollectionEvent): void
		{
			super.onLayerCollectionChanged(event);
			
			dispatchEvent(new DataEvent(TIME_AXIS_UPDATED));
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
		
		public function getLayersOrderString(): String
		{
			var str: String = '';
			for each (var l: InteractiveLayer in m_layers)
			{
				str += "\t layer: " + l.layerName + "\n";
			}
			return str;
		}
		
		override public function addLayer(l:InteractiveLayer):void
		{
			if (l)
			{
				super.addLayer(l);
				
				var dynamicEvent: DynamicEvent = new DynamicEvent(TIME_AXIS_ADDED);
				trace("InteractiveLayerMap addlayer: " + l.name);
				dynamicEvent['layer'] = l;
				dispatchEvent(dynamicEvent);
				
				if (getPrimaryLayer() == null)
				{
					var so: ISynchronisedObject = l as ISynchronisedObject;
	            	if(so == null)
	            		return;
	            	if(so.getSynchronisedVariables().indexOf("frame") < 0)
	            		return;
					
	            	//this layer can be primary layer and there is no primary layer set, set this one as primaty layer	
					setPrimaryLayer(l as InteractiveLayerMSBase);
				}
			} else {
				trace("Layer is null, do not add it to InteractiveLayerMap");
			}
		}
		
		/**
		 * Function find first suitable layer, which can primary layer (can have frames) 
		 * 
		 */		
		private function findNewPrimaryLayer(): void
		{
			for each (var l: InteractiveLayer in m_layers)
			{
				if ( l is InteractiveLayerMSBase)
				{
					var lWMS: InteractiveLayerMSBase = l as InteractiveLayerMSBase;
					var so: ISynchronisedObject = lWMS as ISynchronisedObject;
	            	if(so == null)
	            		continue;
	            	if(so.getSynchronisedVariables().indexOf("frame") < 0)
	            		continue;
	            	//this layer can be primary layer and there is no primary layer set, set this one as primaty layer	
					setPrimaryLayer(lWMS);
					return;
				}
			}
		}
		
		override public function removeLayer(l:InteractiveLayer):void
		{
			super.removeLayer(l);
			
			if ((l is InteractiveLayerMSBase) && (l as InteractiveLayerMSBase).isPrimaryLayer())
			{
				setPrimaryLayer(null);
				findNewPrimaryLayer();
			}
			var dynamicEvent: DynamicEvent = new DynamicEvent(TIME_AXIS_REMOVED);
			dynamicEvent['layer'] = l;
			dispatchEvent(dynamicEvent);
			
			l.destroy();
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
		
		private var m_primaryLayer: InteractiveLayerMSBase;
		public function getPrimaryLayer(): InteractiveLayerMSBase
		{
			for each (var layer: InteractiveLayer in m_layers)
			{
				if (layer is InteractiveLayerMSBase)
				{
					var layerMSBase: InteractiveLayerMSBase = layer as InteractiveLayerMSBase;
					if (layerMSBase.isPrimaryLayer())
						return layerMSBase;
				}
			}
			return null;
		}
		public function setPrimaryLayer(layer: InteractiveLayerMSBase): void
		{
			if (m_primaryLayer != layer)
			{
				if (m_primaryLayer)
				{
					//previous primary layer is not primary layer anymore, set synchronisation role to NONE
					m_primaryLayer.synchronisationRole.setRole(SynchronisationRole.NONE);
				}
				
				m_primaryLayer = layer;
				
				if (m_primaryLayer)
				{
					//there is new primary layer, set synchronisation role to PRIMARY
					m_primaryLayer.synchronisationRole.setRole(SynchronisationRole.PRIMARY);
				}
				
				primaryLayerHasChanged();
				
			}
		}
		/**
		 * Layer composer need to dispatch event when new layer becomes primary 
		 * 
		 */		
		private function primaryLayerHasChanged(): void
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
				if(so == null)
					continue;
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
          	var i: int;
			var so: ISynchronisedObject;
			
          	for each(so in l_syncLayers) 
          	{
				var value: Object = (so as InteractiveLayerMSBase).getWMSDimensionDefaultValue(dimName );
          	}

			return value;
		}
		
		/**
		 * get all dimensions for this layer map
		 *  
		 * @param dimName
		 * @param b_intersection
		 * @return 
		 * 
		 */		
		public function getDimensions(b_intersection: Boolean = true): Array
		{
			
			var l_syncLayers: Array = [];
			var l_timeAxis: Array = enumTimeAxis(l_syncLayers);
         	if(l_timeAxis == null) // no time axis
         		return null;
          		
          	var i: int;
			var so: ISynchronisedObject;
			
			var a_dimensions: Array;
          	for each(so in l_syncLayers) 
          	{
          		//trace("\n Composer getDimensionValues ["+dimName+"] get values for layer: " + (so as Object).name);
				var values: Array = (so as InteractiveLayerMSBase).getWMSDimensionsNames()
          		
          		if(a_dimensions == null)
    				a_dimensions = values;
    			else {
    				if(b_intersection)
    					a_dimensions = ArrayUtils.intersectedArrays(a_dimensions, values);
    				else
    					ArrayUtils.unionArrays(a_dimensions, values);
    			}	
          	}

			return a_dimensions;
				
		}
		
		/**
		 * get all WMS layers, which support dimension
		 *  
		 * @param dimName
		 * @return 
		 * 
		 */		
		public function getWMSLayersForDimension(dimName: String): Array
		{
			
			var l_syncLayers: Array = [];
			var l_timeAxis: Array = enumTimeAxis(l_syncLayers);
         	if(l_timeAxis == null) // no time axis
         		return null;
          		
          	var i: int;
			var so: ISynchronisedObject;
			
			var a_layers: Array = [];
          	for each(so in l_syncLayers) 
          	{
          		//trace("\n Composer getDimensionValues ["+dimName+"] get values for layer: " + (so as Object).name);
				if ((so as InteractiveLayerMSBase).supportWMSDimension(dimName))
					a_layers.push(so);
          	}

			return a_layers;
				
		}
		/**
		 * get all dimension values for this layer map
		 *  
		 * @param dimName
		 * @param b_intersection
		 * @return 
		 * 
		 */		
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
				var values: Array = (so as InteractiveLayerMSBase).getWMSDimensionsValues(dimName, true);
          		
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
				{
          			l.refresh(false);
				}
          	}
          	return true;
		}
		
		// helper methods        
		override protected function bindSubLayer(l: InteractiveLayer): void
		{
			super.bindSubLayer(l);
			
			var so: ISynchronisedObject = l as ISynchronisedObject;
			if(so != null) {
				l.addEventListener(SynchronisedVariableChangeEvent.SYNCHRONISED_VARIABLE_CHANGED,
						onSynchronisedVariableChanged);
				l.addEventListener(SynchronisedVariableChangeEvent.SYNCHRONISED_VARIABLE_DOMAIN_CHANGED,
						onSynchronisedVariableDomainChanged);
			}
		}
		
		override protected function unbindSubLayer(l: InteractiveLayer): void
		{
			super.unbindSubLayer(l);
			
			var so: ISynchronisedObject = l as ISynchronisedObject;
			if(so != null) {
				l.removeEventListener(SynchronisedVariableChangeEvent.SYNCHRONISED_VARIABLE_CHANGED,
						onSynchronisedVariableChanged);
				l.removeEventListener(SynchronisedVariableChangeEvent.SYNCHRONISED_VARIABLE_DOMAIN_CHANGED,
						onSynchronisedVariableDomainChanged);
			}
		}
		
		 private var _featureTooltipCallsRunning: Boolean;
        private var _featureTooltipCallsTotalCount: int;
        private var _featureTooltipCallsCount: int;
        private var _featureTooltipString: String;
        public function getFeatureTooltipForAllLayers(coord: Coord): void
        {
        	if (!_featureTooltipCallsRunning)
        	{
				_featureTooltipCallsTotalCount = 0;
	        	_featureTooltipCallsCount = 0;
	        	_featureTooltipString = '';
	        	for each (var layer: InteractiveLayer in layers)
	        	{
	        		if (layer.hasFeatureInfo() && layer.visible)
	        		{
						_featureTooltipCallsTotalCount++;
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

			if (s.indexOf('small') >= 0)
			{
				trace("Stop tag <small> is included in feature info");
			}
			trace("InteractiveLayerMap onFeatureInfoAvailable _featureTooltipCallsCount: " + _featureTooltipCallsCount + " _featureTooltipCallsTotalCount: " + _featureTooltipCallsTotalCount); 
			var firstFeatureInfo: Boolean = (_featureTooltipCallsCount == _featureTooltipCallsTotalCount);
			
        	_featureTooltipCallsCount--;
			
        	s = HTMLUtils.fixFeatureInfoHTML(s);
			
			var parsingCorrect: Boolean = true;
			try {
				var infoXML: XML = new XML(s);
			} catch (error: Error) {
				parsingCorrect = false;
				trace("ERROR parsing FEatureINFO");
				Alert.show(error.message, "Problem with parsing GetFeatureInfo request", Alert.OK);
			}
        	if (_featureTooltipCallsCount < 1)
        	{
        		_featureTooltipCallsRunning = false;
        	}
			
			var gfie: GetFeatureInfoEvent;
			
			if (parsingCorrect)
			{
				var info: String = infoXML.text();
	        	_featureTooltipString += '<p><b><font color="#6EC1FF">'+layer.name+'</font></b>';
				_featureTooltipString += s+'</p>';
	        	
				
				trace("InteractiveLayerMap onFeatureInfoAvailable _featureTooltipCallsRunning: " + _featureTooltipCallsRunning);
				
			} else {
				_featureTooltipString += '<p><b><font color="#6EC1FF">'+layer.name+'</font></b>';
				_featureTooltipString += 'parsing problem</p>'
					
			}
			gfie = new GetFeatureInfoEvent(GetFeatureInfoEvent.FEATURE_INFO_RECEIVED, true);
			gfie.text = _featureTooltipString;
			gfie.firstFeatureInfo = firstFeatureInfo;
			gfie.lastFeatureInfo = !_featureTooltipCallsRunning;
			dispatchEvent(gfie);
			trace("InteractiveLayerMap onFeatureInfoAvailable event gfie.firstFeatureInfo: " + gfie.firstFeatureInfo + " gfie.lastFeatureInfo: " + gfie.lastFeatureInfo);
        	
        }
        
         /**
		 * Clone interactiveLayer 
		 * 
		 */		
		override public function clone(): InteractiveLayer
		{
			var map: InteractiveLayerMap =  new InteractiveLayerMap(container);
			
			for each (var l: InteractiveLayer in layers)
			{
				var newLayer: InteractiveLayer = l.clone();
				map.addLayer(newLayer);
			}
			
			return map;
		}
		
		public function getLayersInfo(functionName: String): String
		{
			var retStr: String =  "InteractiveLayerMap getLayersInfo: " + functionName ;
			for each (var l: InteractiveLayer in layers)
			{
				try {
					var str: String = l[functionName]();
					retStr += "\n\t"+str;
				} catch (error: Error) {
					
				}
			}
			return retStr;
			
		}
		override public function toString(): String
		{
			var retStr: String =  "InteractiveLayerMap " ;
			for each (var l: InteractiveLayer in layers)
			{
				retStr += "\n\t"+l;
			}
			return retStr;
		}
	}
}

import com.iblsoft.flexiweather.ogc.ILayerConfiguration;
import com.iblsoft.flexiweather.ogc.LayerConfiguration;
import com.iblsoft.flexiweather.ogc.LayerConfigurationManager;
import com.iblsoft.flexiweather.utils.Serializable;
import com.iblsoft.flexiweather.utils.Storage;
import com.iblsoft.flexiweather.widgets.IConfigurableLayer;
import com.iblsoft.flexiweather.widgets.InteractiveLayer;
import com.iblsoft.flexiweather.widgets.InteractiveWidget;
	
class LayerSerializationWrapper implements Serializable
{
	public var m_layer: InteractiveLayer;
	public static var m_iw: InteractiveWidget;

	public function serialize(storage: Storage): void
	{
		if(storage.isLoading()) {
			var s_layerName: String = storage.serializeString("layer-name", null, null)
			var s_layerType: String = storage.serializeString("layer-type", null, s_layerName);
			var config: ILayerConfiguration = LayerConfigurationManager.getInstance().getLayerConfigurationByLabel(s_layerType);
			
			m_layer = config.createInteractiveLayer(m_iw);
			m_layer.layerName = s_layerName;
			if (m_layer is Serializable)
			{
				(m_layer as Serializable).serialize(storage);
			}
		}
		else {
			if (m_layer is Serializable)
			{
				storage.serializeString("layer-name", m_layer.layerName, null);
				var config2: ILayerConfiguration = (m_layer as IConfigurableLayer).configuration
				storage.serializeString("layer-type", config2.label, null);
				(m_layer as Serializable).serialize(storage);
			}
		}
	}
}