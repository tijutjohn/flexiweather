package com.iblsoft.flexiweather.components.charts
{
	import flash.display.Graphics;
	import flash.display.Sprite;
	import flash.text.TextField;
	import flash.text.TextFormat;
	import flash.text.TextFormatAlign;
	
	/**
	 * Simple chart is class for display simple line chart. It can be used in pure AS3 project
	 *  
	 * @author fkormanak
	 * 
	 */	
	public class SimpleChart extends Sprite
	{
		private var _chartWidth: int;
		private var _chartHeight: int;
		
		private var _dataSprite: Sprite;
		private var _axisSprite: Sprite;
		private var _gridSprite: Sprite;
		private var _labelsSprite: Sprite;
		
		private var _data: Array;
		
		private var _axisDrawn: Boolean;
		private var _yAxisLabelsWidth: int;
		private var _xAxisLabelsHeight: int;
		
		public var xField: String;
		public var yField: String;
		
		private var _xLabelsList: TextFieldList;
		private var _yLabelsList: TextFieldList;
		
		private var _usedLabels: Array;
		private var _unusedLabels: Array;
		
		public function get labelFunction():Function
		{
			return _labelFunction;
		}

		public function set labelFunction(value:Function):void
		{
			_labelFunction = value;
			refresh();
		}

		private var _labelFunction: Function;
		
		public function SimpleChart()
		{
			_unusedLabels = [];
			_usedLabels = [];
			
			_gridSprite = new Sprite();
			_axisSprite = new Sprite();
			_labelsSprite = new Sprite();
			_dataSprite = new Sprite();
			
			addChild(_gridSprite);
			addChild(_axisSprite);
			addChild(_labelsSprite);
			addChild(_dataSprite);
			
			_xLabelsList = new TextFieldList();
			_yLabelsList = new TextFieldList();
		}
		

		public function get data():Array
		{
			return _data;
		}

		public function set data(value:Array):void
		{
			_data = value;
//			draw();
		}

		public function refresh(): void
		{
			trace(this + "refresh " + _chartWidth + " , " + _chartHeight);
			if (!_axisDrawn)
				draw(_chartWidth, _chartHeight);
			else
				drawSeries(_chartWidth, _chartHeight);
		}
		
		public function getValue(xValue: Object): Number
		{
			if (data && data.length > 0)
			{
				for each (var currItem: Object in data)
				{
					if (currItem.hasOwnProperty(xField))
					{
						var value: Object = currItem[xField];
						if (value == xValue)
							return currItem[yField];
					}
				}
			}
			
			return 0;
		}
		
		private function getXFieldValues(): Array
		{
			if (data && data.length > 0)
			{
				var values: Array = []
				var item: Object;
				for each (var currItem: Object in data)
				{
					if (currItem && currItem.hasOwnProperty(xField))
					{
						values.push(currItem[xField]);
					}
				}
				return values;
			}
			return null;
		}
		private function getYFieldValues(): Array
		{
			if (data && data.length > 0)
			{
				var values: Array = []
				var item: Object;
				for each (var currItem: Object in data)
				{
					if (currItem && currItem.hasOwnProperty(yField))
					{
						values.push(currItem[yField]);
					}
				}
				return values;
			}
			return null;
		}
		
		private function getMaximumYValue(): Number
		{
			var yValues: Array = getYFieldValues();
			var max: Number = Number.NEGATIVE_INFINITY;
			for each (var yValue: Number in yValues)
			{
				max = Math.max(max, yValue);
			}
			return max;
		}
		
		public function draw(w: int, h: int): void
		{
			_chartWidth = w;
			_chartHeight = h;
			
			
			trace(this + "draw " + _chartWidth + " , " + _chartHeight);
			
			drawBackround(w,h);
			
			if (data)
			{
				invalidateLabels();
				drawAxis(w,h);
				drawSeries(w,h);
				_axisDrawn = true;
			}
		}
		
		private function drawSeries(w: int, h: int): void
		{
			trace(this + " drawSeries: " + w + " , " + h + " labels: " + _yAxisLabelsWidth + " , " + _xAxisLabelsHeight);
			
			var gr: Graphics = _dataSprite.graphics;
			gr.clear();
			var i: int;
			
			var chartW: int = w - _yAxisLabelsWidth;
			var chartH: int = h - _xAxisLabelsHeight;
			
			var xValues: Array = getXFieldValues();
			var yValues: Array = getYFieldValues();
			
			var totalX: int = xValues.length;
			var totalY: int = yValues.length;
			
			var xDiff: Number = chartW / (totalX - 1);
			
			var max: Number = getMaximumYValue();
			
			gr.lineStyle(1, 0xff0000);
			
			trace("xDiff: " + xDiff + " totalX " + totalX + " chartW: " + chartW);
			for (i = 0; i < totalX; i++)
			{
				var yValue: Number = yValues[i] as Number;
				var xPos: int = _yAxisLabelsWidth + xDiff * i;
				var yPos: Number = chartH - (chartH * yValue / max); 
				if (i == 0)
				{
					gr.moveTo(xPos, yPos);
				} else {
					gr.lineTo(xPos, yPos);
				}
			}
			
			
		}
		
		private function drawAxis(w: int, h: int): void
		{
			trace(this + "DRAW AXIS: " + w + " , " + h);
			
			_xAxisLabelsHeight = 0;
			_yAxisLabelsWidth = 0;
			
			var gr: Graphics = _gridSprite.graphics;
			gr.clear();
			var i: int;
			
			var xValues: Array = getXFieldValues();
			var yValues: Array = getYFieldValues();
			
			if (!xValues || !yValues)
				return;
			
			var totalX: int = xValues.length;
			var totalY: int = yValues.length;
			
			gr.lineStyle(1, 0x333333);
			
			
			var tf: TextField;
			var format: TextFormat;

			var xLabel: String;
			var xValue: Number;
			var xPos: Number;
			
			var yLabel: String;
			var yValue: Number;
			var yPos: Number;
			
			var maxY: Number = getMaximumYValue();
			
			var stepsX: int = Math.min(10, totalX);
			var stepsY: int = Math.min(10, totalY);
			
			var xDiff: int = w / (stepsX - 1);
			var yDiff: int = h / (stepsY - 1);
			
			if (w > 0 && h > 0)
				trace("stop");
			else
				return;
			
			//1st pass will find out X labels height 
			for (i = 0; i < stepsX; i++)
			{
				if (i == 0)
					xValue = 0;
				else
					xValue = int(totalX * i / stepsX);
				
				xPos = w - (w * xValue / totalX);
				
				var valueObj: Object = xValues[xValue];
				
				if (_labelFunction != null)
					valueObj = _labelFunction(valueObj);
				
				if (valueObj is String)
					xLabel = valueObj as String;
				if (valueObj is Number)
					xLabel = (valueObj as int).toString();
				
				tf = getLabel();
				tf.text = xLabel;
				format = tf.getTextFormat();
				format.color = 0xaaaaaa;
				tf.setTextFormat(format);
				
				tf.x = xDiff * i - tf.textWidth / 2;
				tf.y = h - 3 - tf.textHeight;
				
				_xLabelsList.addTextField(tf);
				
				_xAxisLabelsHeight = Math.max(_xAxisLabelsHeight, tf.textHeight + 3);
				
			}
			
			//1st pass will find out Y labels width
			for (i = 0; i <= stepsY; i++)
			{
				if (i == 0)
					yValue = 0;
				else
					yValue = maxY * i / stepsY;
				
				yPos = h - (h * yValue / maxY);
				
				tf = getLabel();
				tf.text = int(yValue).toString();
				format = tf.getTextFormat();
				format.color = 0xaaaaaa;
				format.align = TextFormatAlign.RIGHT;
				
				tf.setTextFormat(format);
				
				tf.x = tf.textWidth - tf.width;
				tf.y = yPos - tf.textHeight / 2;
				
				_yLabelsList.addTextField(tf);
				
				_yAxisLabelsWidth = Math.max(_yAxisLabelsWidth, tf.textWidth + 5);
			}
			
			var chartW: int = w - _yAxisLabelsWidth;
			var chartH: int = h - _xAxisLabelsHeight;
			
			xDiff = chartW / (stepsX - 1);
			yDiff = chartH / (stepsY - 1);
			
			//2nd pass will draw X axis grid
			for (i = 0; i < stepsX; i++)
			{
				
				if (i == 0)
					xValue = 0;
				else
					xValue = int(totalX * i / stepsX);
				
				xPos = w - (w * xValue / totalX);
				
				valueObj = xValues[xValue];
				
				gr.moveTo(xPos, 0);
				gr.lineTo(xPos, chartH);
				
				tf = _xLabelsList.getTextField(xValue);
				if (tf)
				{
					tf.x = (xPos) - tf.textWidth / 2;
					tf.y = h - tf.textHeight - 1;
				}
			}
			
			//2nd pass will draw Y axis grid
			for (i = 0; i <= stepsY; i++)
			{
				if (i == 0)
					yValue = 0;
				else
					yValue = maxY * i / stepsY;
				
				yPos = chartH - (chartH * yValue / maxY);
				
				gr.moveTo(_yAxisLabelsWidth, yPos);
				gr.lineTo(w, yPos);
				
				tf = _yLabelsList.getTextField(i);
				
				tf.x = tf.textWidth - tf.width;
				tf.y = yPos - tf.textHeight / 2;
			}
			
			//main axis
			var gr2: Graphics = _axisSprite.graphics;
			gr2.clear();
			
			gr2.lineStyle(1,0xaaaaaa);
			gr2.moveTo(_yAxisLabelsWidth,0);
			gr2.lineTo(_yAxisLabelsWidth, chartH);
			gr2.lineTo(w, chartH);
		}
		
		private function getLabel(): TextField
		{
			var tf: TextField;
			if (_unusedLabels.length > 0)
			{
				tf = _unusedLabels.shift() as TextField;
				
				_usedLabels.push(tf);
				_labelsSprite.addChild(tf);
			} else {
				tf = createLabel();
			}
			return tf;
		}
		
		private function invalidateLabels(): void
		{
			for each (var tf: TextField in _usedLabels)
			{
				if (tf.parent == _labelsSprite)
					_labelsSprite.removeChild(tf);
				_unusedLabels.push(tf);
			}
		}
		private function createLabel(): TextField
		{
			var tf: TextField = new TextField();
			
			_usedLabels.push(tf);
			_labelsSprite.addChild(tf);
			return tf;
		}
		private function drawBackround(w: int, h: int): void
		{
			var gr: Graphics = graphics;
			
			gr.clear();
			gr.beginFill(0x000000);
			gr.drawRect(0,0,w,h);
			gr.endFill();
			
		}
		
		override public function toString(): String
		{
			return "SimpleChart ["+name+"] ";
		}
	}
}
import flash.text.TextField;

class TextFieldList
{
	private var _list: Array;
	
	public function TextFieldList()
	{
		_list = new Array();	
	}
	
	public function getTextField(nr: int): TextField
	{
		if (_list && _list.length > nr)
		{
			return _list[nr] as TextField;
		}
		return null
	}
	public function addTextField(tf: TextField): void
	{
		_list.push(tf);
	}
}