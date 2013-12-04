package com.iblsoft.flexiweather.ogc.multiview.synchronization.events
{
	import com.iblsoft.flexiweather.ogc.InteractiveLayerMSBase;
	import com.iblsoft.flexiweather.widgets.InteractiveWidget;
	
	import flash.events.Event;

	public class SynchronisationEvent extends Event
	{
		public static const SYNCHRONISATION_DONE: String = 'synchronisationDone';
		
		public static const MAP_READY: String = 'synchronisatorMapReady';
		
		public static const START_GLOBAL_VARIABLE_SYNCHRONIZATION: String = 'startGlobalVariableSynchronization';
		public static const STOP_GLOBAL_VARIABLE_SYNCHRONIZATION: String = 'stopGlobalVariableSynchronization';
		
		public var globalVariable: String;
		public var globalVariableValue: Object;

		public var layer: InteractiveLayerMSBase;
		public var widget: InteractiveWidget;
		
		public function SynchronisationEvent(type: String, bubbles: Boolean = false, cancelable: Boolean = false)
		{
			super(type, bubbles, cancelable);
		}
		
		override public function clone():Event
		{
			var se: SynchronisationEvent = new SynchronisationEvent(type, bubbles, cancelable);
			se.globalVariable = globalVariable;
			se.globalVariableValue = globalVariableValue;
			se.layer = layer;
			se.widget = widget;
			
			return se;
		}
	}
}
