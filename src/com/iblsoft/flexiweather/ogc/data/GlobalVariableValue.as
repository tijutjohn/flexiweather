package com.iblsoft.flexiweather.ogc.data
{
	import com.iblsoft.flexiweather.utils.ISO8601Parser;
	import com.iblsoft.flexiweather.utils.Serializable;
	import com.iblsoft.flexiweather.utils.Storage;

	[Bindable]
	[RemoteClass(alias = "com.iblsoft.flexiweather.ogc.data.GlobalVariableValue")]
	public class GlobalVariableValue implements Serializable
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
		
		public function serialize(storage:Storage):void
		{
			label = storage.serializeString('label', label);
			
			if (storage.isStoring())
			{
				if (value is String)
				{
					storage.serializeString('data-type', 'string');
					storage.serializeString('value', value as String);
					storage.serializeString('data', data as String);
				} else if (value is Date) {
					storage.serializeString('data-type', 'date');
					storage.serializeString('value', ISO8601Parser.dateToString(value as Date));
					storage.serializeString('data', ISO8601Parser.dateToString(data as Date));
				} else if (value is Number) {
					storage.serializeString('data-type', 'number');
					storage.serializeNumber('value', value as Number);
					storage.serializeNumber('data', data as Number);
				} else if (value is int) {
					storage.serializeString('data-type', 'int');
					storage.serializeInt('value', value as Number);
					storage.serializeInt('data', data as Number);
				}
			} else {
				var dataType: String = storage.serializeString('data-type', null);
				switch (dataType)
				{
					case 'string':
						value = storage.serializeString('value', null);
						data = storage.serializeString('data', null);
						break;
					case 'date':
						value = ISO8601Parser.stringToDate(storage.serializeString('value', null));
						data = ISO8601Parser.stringToDate(storage.serializeString('data', null));
						break;
					case 'number':
						value = storage.serializeNumber('value', null);
						data = storage.serializeNumber('data', null);
						break;
					case 'int':
						value = storage.serializeInt('value', null);
						data = storage.serializeInt('data', null);
						break;
				}
			}
				
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
