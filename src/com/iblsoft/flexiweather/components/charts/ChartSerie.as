package com.iblsoft.flexiweather.components.charts
{
	public class ChartSerie
	{
		private var _field: String;
		private var _color: uint;
		private var _chartType: String;
		private var _lineWidth: int;
		private var _data: Array;
		private var _maximumValue: Number;
		


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
		
		/**
		 * 
		 * @param field
		 * @param color
		 * @param chartType - one of ChartType constatns
		 * @param lineWidth
		 * 
		 */
		public function ChartSerie(field: String, color: uint = 0xffffff, chartType: String = 'line', lineWidth: int = 2)
		{
			_field = field;
			_color = color;
			_chartType = chartType;
			_lineWidth = lineWidth;
		}
		
		public function findMaximum(): void
		{
			var max: Number = Number.NEGATIVE_INFINITY;
			for each (var yValue: Number in data)
			{
				max = Math.max(max, yValue);
			}
			_maximumValue = max;
		}
	}
}