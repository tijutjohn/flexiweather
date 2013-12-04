package com.iblsoft.flexiweather.components.charts
{
	import flash.display.Graphics;
	import flash.display.Sprite;
	import flash.events.Event;
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
		private var _labelYAxisPadding: int = 10;
		private var _labelXAxisPadding: int = 5;
		
		private var _leftPadding: int = 20;
		private var _bottomPadding: int = 20;
		private var _rightPadding: int = 20;
		private var _topPadding: int = 20;
		
		
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
		private var _xLabelsList: ChartLabelList;
		private var _yLabelsList: ChartLabelList;
		private var _usedLabels: Array;
		private var _unusedLabels: Array;
		private var _styleChanged: Boolean;
		private var _backgroundColor: uint;
		private var _axisColor: uint;
		private var _axisWidth: int;
		private var _gridColor: uint;
		private var _gridAlpha: Number;
		private var _labelsColor: uint;
		private var _xLabelsRotation: Number;
		private var _yLabelsRotation: Number;
		private var _serieColor: uint;
		private var _serieWidth: int;

		public function updatePadding(left: int, right: int, top: int, bottom: int): void
		{
			_leftPadding = left;
			_rightPadding = right;
			_topPadding = top ;
			_bottomPadding = bottom;
			
			refresh(true);
			
		}
		public function get backgroundColor(): uint
		{
			return _backgroundColor;
		}

		public function set backgroundColor(value: uint): void
		{
			if (_backgroundColor != value)
			{
				_backgroundColor = value;
				invalidateStyle();
			}
		}

		public function get axisColor(): uint
		{
			return _axisColor;
		}

		public function set axisColor(value: uint): void
		{
			if (_axisColor != value)
			{
				_axisColor = value;
				invalidateStyle();
			}
		}

		public function get axisWidth(): int
		{
			return _axisWidth;
		}

		public function set axisWidth(value: int): void
		{
			if (_axisWidth != value)
			{
				_axisWidth = value;
				invalidateStyle();
			}
		}

		public function get gridColor(): uint
		{
			return _gridColor;
		}

		public function set gridColor(value: uint): void
		{
			if (_gridColor != value)
			{
				_gridColor = value;
				invalidateStyle();
			}
		}

		public function get gridAlpha(): Number
		{
			return _gridAlpha;
		}

		public function set gridAlpha(value: Number): void
		{
			if (_gridAlpha != value)
			{
				_gridAlpha = value;
				invalidateStyle();
			}
		}

		public function get labelsColor(): uint
		{
			return _labelsColor;
		}

		public function set labelsColor(value: uint): void
		{
			if (_labelsColor != value)
			{
				_labelsColor = value;
				invalidateStyle();
			}
		}

		public function get xLabelsRotation(): Number
		{
			return _xLabelsRotation;
		}

		public function set xLabelsRotation(value: Number): void
		{
			if (_xLabelsRotation != value)
			{
				_xLabelsRotation = value;
				invalidateStyle();
			}
		}

		public function get yLabelsRotation(): Number
		{
			return _yLabelsRotation;
		}

		public function set yLabelsRotation(value: Number): void
		{
			if (_yLabelsRotation != value)
			{
				_yLabelsRotation = value;
				invalidateStyle();
			}
		}

		public function get serieColor(): uint
		{
			return _serieColor;
		}

		public function set serieColor(value: uint): void
		{
			if (_serieColor != value)
			{
				_serieColor = value;
				invalidateStyle();
			}
		}

		public function get serieWidth(): int
		{
			return _serieWidth;
		}

		public function set serieWidth(value: int): void
		{
			if (_serieWidth != value)
			{
				_serieWidth = value;
				invalidateStyle();
			}
		}

		public function get labelFunction(): Function
		{
			return _labelFunction;
		}

		public function set labelFunction(value: Function): void
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
			_xLabelsList = new ChartLabelList();
			_yLabelsList = new ChartLabelList();
			_backgroundColor = 0x000000;
			_axisColor = 0xcccccc;
			_axisWidth = 2;
			_gridColor = 0x333333;
			_gridAlpha = 1;
			_labelsColor = 0xffffff;
			_serieColor = 0xaa0000;
			_serieWidth = 2;
		}

		public function get data(): Array
		{
			return _data;
		}

		public function set data(value: Array): void
		{
			_data = value;
//			draw();
		}
		private var _enterFrameRunning: Boolean;

		private function invalidateStyle(): void
		{
			_styleChanged = true;
			if (!_enterFrameRunning)
			{
				addEventListener(Event.ENTER_FRAME, commitStyles);
				_enterFrameRunning = true;
			}
		}

		private function commitStyles(event: Event): void
		{
			removeEventListener(Event.ENTER_FRAME, commitStyles);
			_enterFrameRunning = false;
			_styleChanged = false;
			refresh(true);
		}

		public function refresh(b_redrawAll: Boolean = false): void
		{
			if (!_axisDrawn || b_redrawAll)
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
						values.push(currItem[xField]);
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
						values.push(currItem[yField]);
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
			drawBackround(w, h);
			if (data)
			{
				invalidateLabels();
				//labels needs to be drawn before axis to find out what space are reserved for labels
				drawLabels(w, h);
				
				customDrawAxes(w, h, _gridSprite.graphics);
				drawAxes(w, h);
				
				drawSeries(w, h);
				_axisDrawn = true;
			}
		}

		private function get chartXSteps(): int
		{
			var xValues: Array = getXFieldValues();
			var totalX: int = xValues.length;
			
			var stepsX: int = Math.min(10, totalX);
			
			return stepsX;
		}
		
		private function getChartAreaWidth(w: int): int
		{
			return  w - (_leftPadding + _rightPadding);
		}
		private function getChartAreaheight(h: int): int
		{
			return  h - (_topPadding + _bottomPadding);
		}
		
		private function drawSeries(w: int, h: int): void
		{
			var gr: Graphics = _dataSprite.graphics;
			gr.clear();
			var i: int;
			var chartW: int = getChartAreaWidth(w);
			var chartH: int = getChartAreaheight(h);
			
			var xValues: Array = getXFieldValues();
			var yValues: Array = getYFieldValues();
			var totalY: int = yValues.length;
			var totalX: int = xValues.length;
			var xDiff: Number = chartW / (totalX - 1);
			var max: Number = getMaximumYValue();
			
			var xPos: int;
			var xValue: Number;
			
			var stepsX: int = Math.min(totalX, chartW); //chartXSteps;
			
			gr.lineStyle(_serieWidth, _serieColor);
			for (i = 0; i < totalX; i++)
			{
				var yValue: Number = yValues[i] as Number;
				
				if (i == 0)
					xValue = 0;
				else
					xValue = int(totalX * i / stepsX);
				xPos = _leftPadding + (chartW * xValue / totalX);
				
				var yPos: Number = _topPadding + chartH - (chartH * yValue / max);
//				trace("drawSeries["+i+"] value: [0 , " + yValue + "]" + " Pos: [" + xPos + " , " + yPos + "]");
				if (i == 0)
					gr.moveTo(xPos, yPos);
				else
					gr.lineTo(xPos, yPos);
			}
		}

		public function customDrawAxes(w: int, h: int, gr: Graphics): void
		{
			
		}
		
		private function drawAxes(w: int, h: int): void
		{
			var gr: Graphics = _gridSprite.graphics;
			gr.clear();
			var i: int;
			var xValues: Array = getXFieldValues();
			var yValues: Array = getYFieldValues();
			if (!xValues || !yValues)
				return;
			var totalX: int = xValues.length;
			var totalY: int = yValues.length;
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
			
			if (w == 0 && h == 0)
				return;
			
			trace("DrawAxis _xAxisLabelsHeight: " + _xAxisLabelsHeight + " _yAxisLabelsWidth: " + _yAxisLabelsWidth);
			
//			var chartW: int = w - _yAxisLabelsWidth;
//			var chartH: int = h - _xAxisLabelsHeight;
			var chartW: int = w - (_leftPadding + _rightPadding);
			var chartH: int = h - (_topPadding + _bottomPadding);
			
			
			
			xDiff = chartW / (stepsX - 1);
			yDiff = chartH / (stepsY - 1);
			gr.lineStyle(1, _gridColor, _gridAlpha);
			
			//draw X axis grid
			for (i = 0; i < stepsX; i++)
			{
				if (i == 0)
					xValue = 0;
				else
					xValue = int(totalX * i / stepsX);
//				xPos = w - (w * xValue / totalX);
				xPos = _leftPadding + (chartW * xValue / totalX);
				
				gr.moveTo(xPos, _topPadding);
				gr.lineTo(xPos, _topPadding + chartH);
				
//				if (i == 0)
//					trace("drawAxis["+i+"] value: [" + xValue + ", 0]" + " Pos: [" + xPos + " , " + chartH + "]");
				
			}
			//draw Y axis grid
			for (i = 0; i <= stepsY; i++)
			{
				if (i == 0)
					yValue = 0;
				else
					yValue = maxY * i / stepsY;
				yPos = _topPadding + chartH - (chartH * yValue / maxY);

				gr.moveTo(_leftPadding, yPos);
				gr.lineTo(_leftPadding + chartW, yPos);
			}
			//main axis
			var gr2: Graphics = _axisSprite.graphics;
			gr2.clear();
			gr2.lineStyle(_axisWidth, _axisColor);
//			gr2.moveTo(_yAxisLabelsWidth, 0);
//			gr2.lineTo(_yAxisLabelsWidth, chartH);
			gr2.moveTo(_leftPadding, _topPadding);
			gr2.lineTo(_leftPadding, _topPadding + chartH);
			gr2.lineTo(_leftPadding + chartW, _topPadding + chartH);
			
//			if (i == 0)
//				trace("drawAxis["+i+"] value: [" + xValue + ", 0]" + " Pos: [" + _yAxisLabelsWidth + " , " + chartH + "]");
		}

		private function getLabel(rotation: Number): ChartLabel
		{
			var tf: ChartLabel;
			if (_unusedLabels.length > 0)
			{
				tf = _unusedLabels.shift() as ChartLabel;
				_usedLabels.push(tf);
				_labelsSprite.addChild(tf);
			}
			else
				tf = createLabel();
			tf.rotation = rotation;
			return tf;
		}

		private function invalidateLabels(): void
		{
			for each (var tf: ChartLabel in _usedLabels)
			{
				if (tf.parent == _labelsSprite)
					_labelsSprite.removeChild(tf);
				_unusedLabels.push(tf);
			}
		}

		private function createLabel(): ChartLabel
		{
			var tf: ChartLabel = new ChartLabel();
			_usedLabels.push(tf);
			_labelsSprite.addChild(tf);
			return tf;
		}

		private function drawBackround(w: int, h: int): void
		{
			var gr: Graphics = graphics;
			gr.clear();
			gr.beginFill(0x000000, 0.5);
			gr.drawRect(0, 0, w, h);
			gr.endFill();
		}

		private function drawLabels(w: int, h: int): void
		{
			_labelsSprite.graphics.clear();
			_xAxisLabelsHeight = 0;
			_yAxisLabelsWidth = 0;
			var i: int;
			var xValues: Array = getXFieldValues();
			var yValues: Array = getYFieldValues();
			if (!xValues || !yValues)
				return;
			var totalX: int = xValues.length;
			var totalY: int = yValues.length;
			var tf: TextField;
			var chartLabel: ChartLabel;
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
			if (w == 0 && h == 0)
				return;
			
			
			
			//1st pass will find out X labels height 
			for (i = 0; i < stepsX; i++)
			{
				if (i == 0)
					xValue = 0;
				else
					xValue = int(totalX * i / stepsX);
				
//				xPos = w - (w * xValue / totalX);
//				xPos = (chartW * xValue / totalX);
				
				
				var valueObj: Object = xValues[xValue];
				if (_labelFunction != null)
					valueObj = _labelFunction(valueObj);
				if (valueObj is String)
					xLabel = valueObj as String;
				if (valueObj is Number)
					xLabel = (valueObj as int).toString();
				chartLabel = getLabel(_xLabelsRotation);
				tf = chartLabel.textField;
				
//				trace("drawLabels i: " + i + " label: " + xLabel + " xPos: " + xPos);
				
				tf.text = xLabel;
				format = tf.getTextFormat();
				format.color = _labelsColor;
				format.align = 'left';
				format.font = 'defaultFontMX';
				tf.embedFonts = true;
				tf.setTextFormat(format);
				chartLabel.updatePosition();
//				chartLabel.x = xDiff * i - chartLabel.rotatedWidth / 2;
//				chartLabel.y = h - 3 - chartLabel.rotatedHeight;
				_xLabelsList.addChartLabel(chartLabel);
				_xAxisLabelsHeight = Math.max(_xAxisLabelsHeight, chartLabel.rotatedHeight + _labelXAxisPadding + _axisWidth);
			}
			//1st pass will find out Y labels width
			for (i = 0; i <= stepsY; i++)
			{
				if (i == 0)
					yValue = 0;
				else
					yValue = maxY * i / stepsY;
//				yPos = h - (h * yValue / maxY);
//				yPos = chartH - (chartH * yValue / maxY);
				
				chartLabel = getLabel(_yLabelsRotation);
				tf = chartLabel.textField;
				tf.text = int(yValue).toString();
				format = tf.getTextFormat();
				format.color = _labelsColor;
				format.align = 'left';
				format.font = 'defaultFontMX';
				tf.embedFonts = true;
				tf.setTextFormat(format);
				chartLabel.updatePosition();
//				chartLabel.x = tf.textWidth - tf.width;
//				chartLabel.y = yPos - tf.textHeight / 2;
				_yLabelsList.addChartLabel(chartLabel);
				_yAxisLabelsWidth = Math.max(_yAxisLabelsWidth, chartLabel.rotatedWidth + _labelYAxisPadding + _axisWidth);
			}
//			var chartW: int = w - _yAxisLabelsWidth;
//			var chartH: int = h - _xAxisLabelsHeight;
			
			var chartW: int = w - (_leftPadding + _rightPadding);
			var chartH: int = h - (_topPadding + _bottomPadding);
			
			xDiff = chartW / (stepsX - 1);
			yDiff = chartH / (stepsY - 1);
			//2nd pass will draw X axis grid
			for (i = 0; i < stepsX; i++)
			{
				if (i == 0)
					xValue = 0;
				else
					xValue = int(totalX * i / stepsX);
				xPos = _leftPadding + chartW - (chartW * xValue / totalX);
//				xPos = chartW - (chartW * xValue / totalX);
				
				
				valueObj = xValues[xValue];
				chartLabel = _xLabelsList.getChartLabel(xValue);
				if (chartLabel)
				{
					tf = chartLabel.textField;
					chartLabel.x = (xPos) - chartLabel.rotatedWidth / 2;
					chartLabel.y = _topPadding + chartH + chartLabel.rotatedHeight / 2 + _labelXAxisPadding;
					drawTextfieldBound(chartLabel);
				}
			}
			//2nd pass will draw Y axis grid
			for (i = 0; i <= stepsY; i++)
			{
				if (i == 0)
					yValue = 0;
				else
					yValue = maxY * i / stepsY;
				yPos = _topPadding + chartH - (chartH * yValue / maxY);
				chartLabel = _yLabelsList.getChartLabel(i);
				if (chartLabel)
				{
					tf = chartLabel.textField;
					chartLabel.x = _leftPadding - chartLabel.rotatedWidth / 2 - _labelYAxisPadding;
					chartLabel.y = yPos - chartLabel.rotatedHeight / 2;
					drawTextfieldBound(chartLabel);
				}
			}
			
		}

		private function drawTextfieldBound(chartLabel: ChartLabel): void
		{
			return;
			var gr: Graphics = _labelsSprite.graphics;
			var sx: int = chartLabel.x;
			var sy: int = chartLabel.y;
			var left: int = sx - chartLabel.rotatedWidth / 2;
			var top: int = sy - chartLabel.rotatedHeight / 2;
			gr.lineStyle(1, 0x444444);
			gr.drawRect(left, top, chartLabel.rotatedWidth, chartLabel.rotatedHeight);
		}

		override public function toString(): String
		{
			return "SimpleChart [" + name + "] ";
		}
	}
}
import flash.display.Graphics;
import flash.display.Sprite;
import flash.geom.Rectangle;
import flash.text.TextField;

class ChartLabel extends Sprite
{
	private var _tf: TextField;

	public function get textField(): TextField
	{
		return _tf;
	}

	public function ChartLabel()
	{
		_tf = new TextField();
		addChild(_tf);
	}

	public function updatePosition(): void
	{
		_tf.x = -1 * _tf.textWidth / 2;
		_tf.y = -1 * _tf.textHeight / 2;
//		_tf.width = _tf.textWidth;
//		_tf.height = _tf.textHeight;
	/*
	var gr: Graphics = graphics;
	gr.beginFill(0x222222);
	gr.drawRect(0,0, _tf.textWidth, _tf.textHeight);
	*/
	}

	public function get rotatedWidth(): Number
	{
		var rot: Number = rotation;
		if (isNaN(rot))
			rot = 0;
		
		var r: Rectangle = fitRect(_tf.textWidth, _tf.textHeight, Math.PI / 180 * rot);
		if (isNaN(r.width))
			return 0;
		return r.width;
	}

	public function get rotatedHeight(): Number
	{
		var rot: Number = rotation;
		if (isNaN(rot))
			rot = 0;
		
		var r: Rectangle = fitRect(_tf.textWidth, _tf.textHeight, Math.PI / 180 * rot);
		if (isNaN(r.height))
			return 0;
		return r.height;
	}

	private function fitRect(rw: int, rh: int, angle: Number): Rectangle
	{
		var x1: Number = -rw / 2;
		var x2: Number = rw / 2;
		var x3: Number = rw / 2;
		var x4: Number = -rw / 2;
		var y1: Number = rh / 2;
		var y2: Number = rh / 2;
		var y3: Number = -rh / 2;
		var y4: Number = -rh / 2;
		var x11: Number = x1 * Math.cos(angle) + y1 * Math.sin(angle);
		var y11: Number = -x1 * Math.sin(angle) + y1 * Math.cos(angle);
		var x21: Number = x2 * Math.cos(angle) + y2 * Math.sin(angle);
		var y21: Number = -x2 * Math.sin(angle) + y2 * Math.cos(angle);
		var x31: Number = x3 * Math.cos(angle) + y3 * Math.sin(angle);
		var y31: Number = -x3 * Math.sin(angle) + y3 * Math.cos(angle);
		var x41: Number = x4 * Math.cos(angle) + y4 * Math.sin(angle);
		var y41: Number = -x4 * Math.sin(angle) + y4 * Math.cos(angle);
		var x_min: Number = Math.min(x11, x21, x31, x41);
		var x_max: Number = Math.max(x11, x21, x31, x41);
		var y_min: Number = Math.min(y11, y21, y31, y41);
		var y_max: Number = Math.max(y11, y21, y31, y41);
		return new Rectangle(0, 0, x_max - x_min, y_max - y_min);
	}
}

class ChartLabelList
{
	private var _list: Array;

	public function ChartLabelList()
	{
		_list = new Array();
	}

	public function getChartLabel(nr: int): ChartLabel
	{
		if (_list && _list.length > nr)
			return _list[nr] as ChartLabel;
		return null
	}

	public function addChartLabel(tf: ChartLabel): void
	{
		_list.push(tf);
	}
}
