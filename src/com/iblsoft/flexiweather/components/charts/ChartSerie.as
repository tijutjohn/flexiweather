package com.iblsoft.flexiweather.components.charts
{
	public class ChartSerie
	{
		public var colorData: Array;
		
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
		public function set color(value:uint):void
		{
			_color = value;
		}

		public function get chartType():String
		{
			return _chartType;
		}
		public function set chartType(value:String):void
		{
			_chartType = value;
		}

		public function get lineWidth():int
		{
			return _lineWidth;
		}
		public function set lineWidth(value:int):void
		{
			_lineWidth = value;
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
		public function set visible(value: Boolean): void
		{
			if (_visible != value)
			{
				_visible = value;
			}
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
		
		public function getMinimumMaximumValues(pixelValues: Array): Array
		{
			if (pixelValues && pixelValues.length > 0)
			{
				var minimum: Number = Number.POSITIVE_INFINITY;
				var maximum: Number = Number.NEGATIVE_INFINITY;
				
				for each (var currValueObj: Object in pixelValues)
				{
					if (isValidValue(currValueObj))
					{
						var currValue: Number = getValue(currValueObj);
						if (currValue < minimum)
							minimum = currValue;
						
						if (currValue > maximum)
							maximum = currValue;
					}
				}
				return [minimum, maximum];
			}
			return [0,0];
		}
		
		public function averageValues(pixelValues: Array): Number
		{
			if (pixelValues && pixelValues.length > 0)
			{
//				if (_label == "Clouds")
//				{
//					trace("check Clouds average");
//				}
				var value: Number = 0;
				var counted: int = 0;
				for each (var currValueObj: Object in pixelValues)
				{
					if (isValidValue(currValueObj))
					{
//						if (_label == "Clouds")
//						{
//							trace("check Clouds average");
//						}
						var currValue: Number = getValue(currValueObj);
						value += currValue;
						counted++;
					}
				}
				if (counted > 0)
				{
//					trace("averageValues: " + value + " from " + counted + " values");
					return value / counted;
				}
			}
			return 0;
		}
		
		public function isValidValue(value: Object): Boolean
		{
			if (value is Number)
			{
				var val: Number = value as Number;
				return (val != 0 && val != 99999 && !isNaN(val))
			}
			
			return false;
		}
		
		public function getValue(valueObject: Object): Number
		{
			if (!valueObject)
				return 0;
			
			if (_field && !(valueObject is Number))
				return valueObject[_field];
			
			return valueObject as Number;
		}
			
		public function findMaximum(): void
		{
			var max: Number = Number.NEGATIVE_INFINITY;
			var yValue: Number;
			
			var firstItem: Object;
			if (data && data.length > 0)
				firstItem = data[0];
			
			if (firstItem)
			{
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
			} else {
				firstItem = 0;
			}
			_maximumValue = max;
		}
		
		public function getColorForYValue(value: int): uint
		{
			if (!colorData)
				return color;
			
			var previousColorMinimumValue: int = 0;
			var currentColorMaximumValue: int = 0;
			
			for (var i: int = 0; i < colorData.length; i++)
			{
				currentColorMaximumValue = colorData[i].toValue;
				if (value >= previousColorMinimumValue && value <= currentColorMaximumValue)
					return colorData[i].color;
				
				previousColorMinimumValue = currentColorMaximumValue;
			}
			
			return color;	
		}
	}
}