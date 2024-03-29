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
		public var unit: String;
		public var unitSymbol: String;

//		public function GlobalVariableValue(label: String, value: Object, data: Object)
		public function GlobalVariableValue()
		{
		}

		public function toString(): String
		{
			return label;
		}

		public function get dataWithUnit(): String
		{
			if (unitSymbol)
			{
				if (data is String)
					return (data as String) + unit;

				return data.toString() + unit;

			} else if (data is String)
				return data as String;

			return data.toString();
		}

		public function get dataWithUnitSymbol(): String
		{
			if (unitSymbol)
			{
				if (data is String)
					return (data as String) + unitSymbol;

				return data.toString() + unitSymbol;

			} else if (data is String)
				return data as String;

			return data.toString();
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
					storage.serializeString('unit', unit as String);
					storage.serializeString('unit-symbol', unitSymbol as String);
				} else if (value is Date) {
					storage.serializeString('data-type', 'date');
					storage.serializeString('value', ISO8601Parser.dateToString(value as Date));
					storage.serializeString('data', ISO8601Parser.dateToString(data as Date));
					storage.serializeString('unit', unit as String);
					storage.serializeString('unit-symbol', unitSymbol as String);
				} else if (value is Number) {
					storage.serializeString('data-type', 'number');
					storage.serializeNumber('value', value as Number);
					storage.serializeNumber('data', data as Number);
					storage.serializeString('unit', unit as String);
					storage.serializeString('unit-symbol', unitSymbol as String);
				} else if (value is int) {
					storage.serializeString('data-type', 'int');
					storage.serializeInt('value', value as Number);
					storage.serializeInt('data', data as Number);
					storage.serializeString('unit', unit as String);
					storage.serializeString('unit-symbol', unitSymbol as String);
				}
			} else {
				var dataType: String = storage.serializeString('data-type', null);
				switch (dataType)
				{
					case 'string':
						value = storage.serializeString('value', null);
						data = storage.serializeString('data', null);
						unit = storage.serializeString('unit', null);
						unitSymbol = storage.serializeString('unit-symbol', null);
						break;
					case 'date':
						value = ISO8601Parser.stringToDate(storage.serializeString('value', null));
						data = ISO8601Parser.stringToDate(storage.serializeString('data', null));
						unit = storage.serializeString('unit', null);
						unitSymbol = storage.serializeString('unit-symbol', null);
						break;
					case 'number':
						value = storage.serializeNumber('value', Number.NaN);
						data = storage.serializeNumber('data', Number.NaN);
						unit = storage.serializeString('unit', null);
						unitSymbol = storage.serializeString('unit-symbol', null);
						break;
					case 'int':
						value = storage.serializeInt('value', 0);
						data = storage.serializeInt('data', 0);
						unit = storage.serializeString('unit', null);
						unitSymbol = storage.serializeString('unit-symbol', null);
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
			variable.unit = unit;
			variable.unitSymbol = unitSymbol;

			return variable;
		}
	}
}
