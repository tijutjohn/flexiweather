package com.iblsoft.flexiweather.ogc.multiview.synchronization.events
{
	import flash.events.Event;

	public class SynchronisationEvent extends Event
	{
		public static const START_GLOBAL_VARIABLE_SYNCHRONIZATION: String = 'startGlobalVariableSynchronization';
		public static const STOP_GLOBAL_VARIABLE_SYNCHRONIZATION: String = 'stopGlobalVariableSynchronization';
		public var globalVariable: String;
		public var globalVariableValue: Object;

		public function SynchronisationEvent(type: String, bubbles: Boolean = false, cancelable: Boolean = false)
		{
			super(type, bubbles, cancelable);
		}
	}
}
