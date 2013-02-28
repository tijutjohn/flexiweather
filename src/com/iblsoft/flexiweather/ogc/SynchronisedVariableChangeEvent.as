package com.iblsoft.flexiweather.ogc
{
	import flash.events.Event;

	public class SynchronisedVariableChangeEvent extends Event
	{
		public static const SYNCHRONISED_VARIABLE_CHANGED: String = "synchronisedVariableChanged";
		public static const SYNCHRONISED_VARIABLE_DOMAIN_CHANGED: String = "synchronisedVariableDomainChanged";
		//[Event(name = SYNCHRONISED_VARIABLE_CHANGED, type = "com.iblsoft.flexiweather.ogc.SynchronisedVariableChangeEvent")]
		protected var ms_variableId: String;

		public function SynchronisedVariableChangeEvent(
				s_type: String,
				s_variableId: String,
				bubbles:Boolean=false, cancelable:Boolean=false)
		{
			super(s_type, bubbles, cancelable);
			ms_variableId = s_variableId;
		}

		override public function clone(): Event
		{
			var svce: SynchronisedVariableChangeEvent = new SynchronisedVariableChangeEvent(type, variableId);
			return svce;
		}

		public function get variableId(): String
		{
			return ms_variableId;
		}
	}
}
