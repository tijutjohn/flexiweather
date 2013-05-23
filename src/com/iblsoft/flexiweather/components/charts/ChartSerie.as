package com.iblsoft.flexiweather.components.charts
{
	public class ChartSerie
	{
		private var _field: String;
		private var _label: String;
		private var _color: uint;
		private var _chartType: String;
		private var _lineWidth: int;
		private var _data: Array;
		private var _maximumValue: Number;
		private var _visible: Boolean;

		public function get color():uint
		{
			return _color;
		}

		public function get chartType():String
		{
			return _chartType;
		}

		public function get lineWidth():int
		{
			return _lineWidth;
		}

		public function get maximumValue():Number
		{
			return _maximumValue;
		}

		public function set maximumValue(value:Number):void
		{
			_maximumValue = value;
		}

		public function get data():Array
		{
			return _data;
		}

		public function set data(value:Array):void
		{
			_data = value;
			findMaximum();
		}

		public function get field(): String
		{
			return _field;
		}
		public function get label(): String
		{
			return _label;
		}
		
		public function get visible(): Boolean
		{
			return _visible;
		}
		
		/**
		 * 
		 * @param field
		 * @param color
		 * @param chartType - one of ChartType constatns
		 * @param lineWidth
		 * 
		 */
		public function ChartSerie(field: String, label: String, color: uint = 0xffffff, chartType: String = 'line', lineWidth: int = 2)
		{
			_field = field;
			_color = color;
			_label = label;
			_chartType = chartType;
			_lineWidth = lineWidth;
			_visible = true;
		}
		
		public function getValue(valueObject: Object): Number
		{
			if (_field)
				return valueObject[_field];
			
			return valueObject as Number;
		}
			
		public function findMaximum(): void
		{
			var max: Number = Number.NEGATIVE_INFINITY;
			var yValue: Number;
			
			if (data[0] is Number)
			{
				for each (yValue in data)
				{
					max = Math.max(max, yValue);
				}
			} else if (data[0] is Array) {
				
				for each (var yValueArr: Array in data)
				{
					for each (yValue in yValueArr)
					{
						max = Math.max(max, yValue);
					}
				}
				
			}
			_maximumValue = max;
		}
	}
}