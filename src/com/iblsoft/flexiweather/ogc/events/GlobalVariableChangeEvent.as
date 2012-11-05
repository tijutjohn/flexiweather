package com.iblsoft.flexiweather.ogc.events
{
	import com.iblsoft.flexiweather.ogc.data.GlobalVariableValue;
	import flash.events.Event;

	public class GlobalVariableChangeEvent extends Event
	{
		public static const DIMENSION_VALUE_CHANGED: String = 'dimensionValueChanged';
		public var dimensionName: String;
		public var dimensionValue: Object;

		public function GlobalVariableChangeEvent(type: String, dimensionName: String, dimensionValue: Object, bubbles: Boolean = false, cancelable: Boolean = false)
		{
			super(type, bubbles, cancelable);
			this.dimensionName = dimensionName;
			this.dimensionValue = dimensionValue;
		}

		override public function clone(): Event
		{
			return new GlobalVariableChangeEvent(type, dimensionName, dimensionValue);
		}
	}
}
