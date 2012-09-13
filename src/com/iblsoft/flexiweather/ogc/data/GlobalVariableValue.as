package com.iblsoft.flexiweather.ogc.data
{
	[Bindable]
	public class GlobalVariableValue
	{
		public var data: Object;
		public var value: Object;
		public var label: String;
		
		public function GlobalVariableValue(label: String, value: Object, data: Object)
		{
			this.data = data;
			this.value = value;
			this.label = label;
		}
		
		public function toString(): String
		{
			return label;
		}
	}
}