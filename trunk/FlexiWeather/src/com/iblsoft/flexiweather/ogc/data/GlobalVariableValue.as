package com.iblsoft.flexiweather.ogc.data
{

	[Bindable]
	[RemoteClass(alias = "com.iblsoft.flexiweather.ogc.data.GlobalVariableValue")]
	public class GlobalVariableValue
	{
		public var data: Object;
		public var value: Object;
		public var label: String;

//		public function GlobalVariableValue(label: String, value: Object, data: Object)
		public function GlobalVariableValue()
		{
		}

		public function toString(): String
		{
			return label;
		}
		
		public function clone(): Object
		{
			var variable: GlobalVariableValue = new GlobalVariableValue();
			variable.data = data;
			variable.value = value;
			variable.label = label;
			
			return variable;
		}
	}
}
