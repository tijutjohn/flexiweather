package com.iblsoft.flexiweather.widgets
{
	import com.iblsoft.flexiweather.ogc.ISynchronisedObject;
	import com.iblsoft.flexiweather.ogc.SynchronisedVariableChangeEvent;
	import com.iblsoft.flexiweather.utils.ArrayUtils;
	
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

		public function InteractiveLayerComposer(container: InteractiveWidget)
		{
			super(container);
			m_layers.addEventListener(CollectionEvent.COLLECTION_CHANGE, onLayerCollectionChanged);
		}
		
		public function addLayer(l: InteractiveLayer): void
		{
			m_layers.addItemAt(l, 0);
			bindSubLayer(l);
			dispatchEvent(new DataEvent(TIME_AXIS_UPDATED));
		}

		public function removeLayer(l: InteractiveLayer): void
		{
			var i : int = m_layers.getItemIndex(l);
			if(i >= 0) {
				unbindSubLayer(l);
				m_layers.removeItemAt(i);
			}
			dispatchEvent(new DataEvent(TIME_AXIS_UPDATED));
		}

		public function getLayerCount(): uint
		{ return m_layers.length; }

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
		
		protected function onSynchronisedVariableChanged(event: SynchronisedVariableChangeEvent): void
		{
			dispatchEvent(new DataEvent(TIME_AXIS_UPDATED));
		}
		
		// data global variables synchronisation
		public function moveFrame(i_offset: int): Boolean
		{
			var l_timeAxis: Array = null;
			var l_syncLayers: Array = [];
			var so: ISynchronisedObject;
			for each(var l: InteractiveLayer in m_layers) {
            	so = l as ISynchronisedObject;
            	if(so == null)
            		continue;
            	if(so.getSynchronisedVariables().indexOf("frame") < 0)
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
          	if(l_timeAxis == null) // no time axis
          		return false;

			var i: int;

			/*trace("Overall timeaxis:");
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
			}
		}
		
		protected function onLayerCollectionChanged(event: CollectionEvent): void
		{
			if(event.kind == CollectionEventKind.UPDATE)
				return;
			var l: InteractiveLayer;
			while(numChildren > 0) {
				l = getChildAt(0) as InteractiveLayer;
				//unbindSubLayer(l);
				removeChildAt(0);
			}
			// add layers as children in reversed order
			for each(l in m_layers) {
				addChildAt(l, 0);
				//bindSubLayer(l);
			}
		}
        
        public function getLayers(): ArrayCollection
        { return m_layers; }
	}
}