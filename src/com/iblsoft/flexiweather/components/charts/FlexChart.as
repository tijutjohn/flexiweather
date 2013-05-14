package com.iblsoft.flexiweather.components.charts
{
	import com.iblsoft.flexiweather.ogc.kml.features.Point;
	
	import flash.display.Graphics;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.text.TextField;
	import flash.text.TextFormat;
	
	import mx.collections.ArrayCollection;
	import mx.core.UIComponent;
	import mx.events.CollectionEvent;

	/**
	 * Display simple chart for Flex project
	 *
	 * @author fkormanak
	 *
	 */
	public class FlexChart extends UIComponent
	{
		private var _labelYAxisPadding: int = 10;
		private var _labelXAxisPadding: int = 5;
		
		private var _leftPadding: int = 20;
		private var _bottomPadding: int = 20;
		private var _rightPadding: int = 20;
		private var _topPadding: int = 20;
		
		public function get paddingLeft(): int
		{
			return _leftPadding;
		}
		public function get paddingRight(): int
		{
			return _rightPadding;
		}
		public function get paddingTop(): int
		{
			return _topPadding;
		}
		public function get paddingBottom(): int
		{
			return _bottomPadding;
		}
		
		private var _dataSprite: Sprite;
		private var _axisSprite: Sprite;
		private var _gridSprite: Sprite;
		private var _labelsSprite: Sprite;
		
		private var _data: Array;
		private var _dataUpdated: Boolean;
		
		private var _axisDrawn: Boolean;
		private var _yAxisLabelsWidth: int;
		private var _xAxisLabelsHeight: int;
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
		
		
		public var xField: String;
		public var yField: String;

		private var _labelFunction: Function;
		private var _labelFunctionChanged: Boolean;
		
		[Bindable(event = "labelFunctionChanged")]
		public function get labelFunction(): Function
		{
			return _labelFunction;
		}

		public function set labelFunction(value: Function): void
		{
			_labelFunction = value;
			_labelFunctionChanged = true;
			invalidateProperties();
			dispatchEvent(new Event("labelFunctionChanged"));
		}
		
		private var _labelXAxisFunction: Function;
		private var _labelXAxisFunctionChanged: Boolean;
		
		[Bindable(event = "labelXAxisFunctionChanged")]
		public function get labelXAxisFunction(): Function
		{
			return _labelXAxisFunction;
		}

		public function set labelXAxisFunction(value: Function): void
		{
			_labelXAxisFunction = value;
			_labelXAxisFunctionChanged = true;
			invalidateProperties();
			dispatchEvent(new Event("labelXAxisFunctionChanged"));
		}

		private var _dataProvider: ArrayCollection;
		private var _dataProviderChanged: Boolean;
		
		[Bindable]
		public function get dataProvider(): ArrayCollection
		{
			return _dataProvider;
		}

		public function set dataProvider(value: ArrayCollection): void
		{
			if (_dataProvider)
				_dataProvider.removeEventListener(CollectionEvent.COLLECTION_CHANGE, onDataProviderChange);
			_dataProvider = value;
			if (_dataProvider)
				_dataProvider.addEventListener(CollectionEvent.COLLECTION_CHANGE, onDataProviderChange);
			_dataProviderChanged = true;
			invalidateProperties();
		}
		
		private var _xAxisDataProvider: ArrayCollection;
		private var _xAxisDataProviderChanged: Boolean;
		
		[Bindable]
		public function get xAxisDataProvider(): ArrayCollection
		{
			return _xAxisDataProvider;
		}

		public function set xAxisDataProvider(value: ArrayCollection): void
		{
//			if (_xAxisDataProvider)
//				_xAxisDataProvider.removeEventListener(CollectionEvent.COLLECTION_CHANGE, onXAxisDataProviderChange);
			_xAxisDataProvider = value;
//			if (_xAxisDataProvider)
//				_xAxisDataProvider.addEventListener(CollectionEvent.COLLECTION_CHANGE, onXAxisDataProviderChange);
//			_xAxisDataProviderChanged = true;
			invalidateProperties();
		}
		
		
//		private var _styleChanged: Boolean;
//		private var _backgroundColor: uint;
//		private var _axisColor: uint;
//		private var _axisWidth: int;
//		private var _gridColor: uint;
//		private var _gridAlpha: Number;
//		private var _labelsColor: uint;
//		private var _xLabelsRotation: Number;
//		private var _yLabelsRotation: Number;
//		private var _serieColor: uint;
//		private var _serieWidth: int;

		
		public function updatePadding(left: int, right: int, top: int, bottom: int): void
		{
			_leftPadding = left;
			_rightPadding = right;
			_topPadding = top ;
			_bottomPadding = bottom;
			
			refresh(true);
			
		}

		[Bindable(event = "backgroundColorChanged")]
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
				notify("backgroundColorChanged");
			}
		}

		[Bindable(event = "axisColorChanged")]
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
				notify("axisColorChanged");
			}
		}

		[Bindable(event = "axisWidthChanged")]
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
				notify("axisWidthChanged");
			}
		}

		
		[Bindable(event = "gridColorChanged")]
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
				notify("gridColorChanged");
			}
		}

		[Bindable(event = "gridAlphaChanged")]
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
				notify("gridAlphaChanged");
			}
		}

		[Bindable(event = "labelsColorChanged")]
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
				notify("labelsColorChanged");
			}
		}

		[Bindable(event = "labelsRotationChanged")]
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
				notify("labelsRotationChanged");
			}
		}

		[Bindable(event = "labelsRotationChanged")]
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
				notify("labelsRotationChanged");
			}
		}

		
		[Bindable(event = "serieColorChanged")]
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
				notify("serieColorChanged");
			}
		}

		[Bindable(event = "serieWidthChanged")]
		public function get serieWidth(): int
		{
			return _serieWidth;
		}

		public function set serieWidth(value: int): void
		{
			if (serieWidth != value)
			{
				_serieWidth = value;
				invalidateStyle();
				notify("serieWidthChanged");
			}
		}
//		protected var simpleChart: SimpleChart;

		public function FlexChart()
		{
			super();
			_backgroundColor = 0x000000;
			_axisColor = 0xcccccc;
			_axisWidth = 2;
			_gridColor = 0x333333;
			_gridAlpha = 1;
			_labelsColor = 0xffffff;
			_serieColor = 0xaa0000;
			_serieWidth = 2;
			
			
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
			_xLabelsList = new ChartLabelList("x");
			_yLabelsList = new ChartLabelList("y");
			_backgroundColor = 0x000000;
			_axisColor = 0xcccccc;
			_axisWidth = 2;
			_gridColor = 0x333333;
			_gridAlpha = 1;
			_labelsColor = 0xffffff;
			_serieColor = 0xaa0000;
			_serieWidth = 2;
		}

//		private function invalidateStyle(): void
//		{
//			_styleChanged = true;
//			commitProperties();
//		}

		private function onXAxisDataProviderChange(event: CollectionEvent): void
		{
			refresh();
		}
	
		private function onDataProviderChange(event: CollectionEvent): void
		{
			refresh();
		}

		override protected function commitProperties(): void
		{
			super.commitProperties();
			if (_labelXAxisFunctionChanged)
			{
//				refresh();
				_labelXAxisFunctionChanged = false;
			}
			if (_labelFunctionChanged)
			{
				refresh();
				_labelFunctionChanged = false;
			}
			if (_xAxisDataProviderChanged)
			{
				if (dataProvider)
					data = dataProvider.source;
				else
					data = [];
				
				recountChartProperties();
				
				refresh();
				_xAxisDataProviderChanged = false;
			}
			if (_dataProviderChanged)
			{
				if (dataProvider)
					data = dataProvider.source;
				else
					data = [];
				
				recountChartProperties();
				
				refresh();
				_dataProviderChanged = false;
			}
			if (_dataUpdated)
			{
				recountChartProperties();
				_dataUpdated = false;
			}
//			if (_styleChanged && simpleChart)
			if (_styleChanged)
			{
//				simpleChart.backgroundColor = _backgroundColor;
//				simpleChart.gridColor = _gridColor;
//				simpleChart.gridAlpha = _gridAlpha;
//				simpleChart.axisColor = _axisColor;
//				simpleChart.axisWidth = _axisWidth;
//				simpleChart.labelsColor = _labelsColor;
//				simpleChart.xLabelsRotation = _xLabelsRotation;
//				simpleChart.yLabelsRotation = _yLabelsRotation;
//				simpleChart.serieColor = _serieColor;
//				simpleChart.serieWidth = _serieWidth;
				
				refresh(true);
				_styleChanged = false;
			}
//			if (simpleChart)
//				simpleChart.name = name;
		}

		override protected function createChildren(): void
		{
			super.createChildren();
//			simpleChart = new SimpleChart();
//			addChild(simpleChart);
//			simpleChart.xField = xField;
//			simpleChart.yField = yField;
//			simpleChart.x = 0;
//			simpleChart.y = 0;
//			simpleChart.draw(width, height);
		}

		override protected function childrenCreated(): void
		{
			super.childrenCreated();
		}

//		public function updatePadding(left: int, right: int, top: int, bottom: int): void
//		{
//			if (simpleChart)
//				simpleChart.updatePadding(left, right, top, bottom);
			
//		}
		
		override protected function updateDisplayList(unscaledWidth: Number, unscaledHeight: Number): void
		{
			super.updateDisplayList(unscaledWidth, unscaledHeight);
			var gr: Graphics = graphics;
			gr.clear();
			gr.beginFill(0x000000);
			gr.drawRect(0, 0, unscaledWidth, unscaledHeight);
			gr.endFill();
			
			
			chartWidth = getChartAreaWidth(unscaledWidth);
			chartHeight = getChartAreaheight(unscaledHeight);
			
//			if (simpleChart)
//				simpleChart.draw(unscaledWidth, unscaledHeight);
			
			draw();
		}
		
//		protected function customDrawAxes(w: int, h: int, gr: Graphics): void
//		{
//			if (simpleChart)
//				simpleChart.customDrawAxes(w, h, gr);
//		}

		private function notify(type: String): void
		{
			dispatchEvent(new Event(type));
		}
		
		
		
		
		
		public function get data(): Array
		{
			return _data;
		}
		
		public function set data(value: Array): void
		{
			_data = value;
			_dataUpdated = true;
			invalidateProperties();
		}
//		private var _enterFrameRunning: Boolean;
		
		private function invalidateStyle(): void
		{
			_styleChanged = true;
			invalidateProperties();
//			if (!_enterFrameRunning)
//			{
//				addEventListener(Event.ENTER_FRAME, commitStyles);
//				_enterFrameRunning = true;
//			}
		}
		
//		private function commitStyles(event: Event): void
//		{
//			removeEventListener(Event.ENTER_FRAME, commitStyles);
//			_enterFrameRunning = false;
//			_styleChanged = false;
//			refresh(true);
//		}
		
		public function refresh(b_redrawAll: Boolean = false): void
		{
			if (!_axisDrawn || b_redrawAll)
				draw();
			else
				drawSeries();
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
		
		public function draw(): void
		{
			if (isNaN(chartWidth) || isNaN(chartHeight))
				return;
				
			if (data)
			{
				drawBackround();
				invalidateLabels();
				//labels needs to be drawn before axis to find out what space are reserved for labels
				drawLabels();
				
				drawAxes();
				customDrawAxes(_gridSprite.graphics);
				
				drawSeries();
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
		
		protected function getChartAreaWidth(w: int): int
		{
			return  w - (_leftPadding + _rightPadding);
		}
		protected function getChartAreaheight(h: int): int
		{
			return  h - (_topPadding + _bottomPadding);
		}
		
		private var xAxisValues: Array;
		private var yAxisValues: Array;
		private var totalXAxis: int;
		private var totalYAxis: int;
		
		private var xValues: Array;
		private var yValues: Array;
		private var totalX: int;
		private var totalY: int;
		
		
		private var yMaximumValue: Number;
		private var chartWidth: Number;
		private var chartHeight: Number;
		
		
		private function recountChartProperties(): void
		{
			xAxisValues = xAxisDataProvider.source;
			totalXAxis = xAxisValues.length;
			
			xValues = getXFieldValues();
			yValues = getYFieldValues();
			totalY = yValues.length;
			totalX = xValues.length;
			yMaximumValue = getMaximumYValue();
		}
		
		private function drawSeries(): void
		{
			var gr: Graphics = _dataSprite.graphics;
			gr.clear();
			var i: int;
			
			var xDiff: Number = chartWidth / (totalX - 1);
			
			var xPos: int;
			var xValue: Number;
			
			var stepsX: int = Math.min(totalX, chartWidth); //chartXSteps;
			
			gr.lineStyle(_serieWidth, _serieColor);
			for (i = 0; i < totalX; i++)
			{
				var yValue: Number = yValues[i] as Number;
				
				if (i == 0)
					xValue = 0;
				else
					xValue = int(totalX * i / stepsX);
				xPos = _leftPadding + (chartWidth * xValue / totalX);
				
				var yPos: Number = _topPadding + chartHeight - (chartHeight * yValue / yMaximumValue);
				//				trace("drawSeries["+i+"] value: [0 , " + yValue + "]" + " Pos: [" + xPos + " , " + yPos + "]");
				if (i == 0)
					gr.moveTo(xPos, yPos);
				else
					gr.lineTo(xPos, yPos);
			}
		}
		
//		protected function moveTo(x: Number, y: Number): void
//		{
//			var gr: Graphics = _dataSprite.graphics;
//			
//			var xValue: Number;
//			
//			if (x == 0)
//				xValue = 0;
//			else
//				xValue = int(totalX * i / stepsX);
//			xPos = _leftPadding + (chartWidth * xValue / totalX);
//			
//			var yPos: Number = _topPadding + chartHeight - (chartHeight * yValue / yMaximumValue);
//			//				trace("drawSeries["+i+"] value: [0 , " + yValue + "]" + " Pos: [" + xPos + " , " + yPos + "]");
//			if (i == 0)
//				gr.moveTo(xPos, yPos);
//		}
		protected function drawLine(fromPoint: Point, toPoint: Point): void
		{
			
		}
		
		protected function customDrawAxes(gr: Graphics): void
		{
			
		}
		
		private function drawAxes(): void
		{
			var gr: Graphics = _gridSprite.graphics;
			gr.clear();
			var i: int;
			var xValues: Array = getXFieldValues();
			var yValues: Array = getYFieldValues();
			if (!xValues || !yValues)
				return;
			
//			var totalX: int = xValues.length;
			var totalY: int = yValues.length;
			var xLabel: String;
			var xValue: Number;
			var xPos: Number;
			var yLabel: String;
			var yValue: Number;
			var yPos: Number;
			
			var stepsX: int = totalXAxis;
			var stepsY: int = Math.min(10, totalY);
			
			
			var xDiff: int = chartWidth / (stepsX - 1);
			var yDiff: int = chartHeight / (stepsY - 1);
			
			if (chartWidth == 0 && chartHeight == 0)
				return;
			
			trace("DrawAxis _xAxisLabelsHeight: " + _xAxisLabelsHeight + " _yAxisLabelsWidth: " + _yAxisLabelsWidth);
			
			xDiff = chartWidth / (stepsX - 1);
			yDiff = chartHeight / (stepsY - 1);
			gr.lineStyle(1, _gridColor, _gridAlpha);
			
			//draw X axis grid
			for (i = 0; i < stepsX; i++)
			{
				if (i == 0)
					xValue = 0;
				else
					xValue = int(totalX * i / stepsX);
				//				xPos = w - (w * xValue / totalX);
				xPos = _leftPadding + (chartWidth * xValue / totalX);
				
				gr.moveTo(xPos, _topPadding);
				gr.lineTo(xPos, _topPadding + chartHeight);
				
				//				if (i == 0)
				//					trace("drawAxis["+i+"] value: [" + xValue + ", 0]" + " Pos: [" + xPos + " , " + chartHeight + "]");
				
			}
			//draw Y axis grid
			for (i = 0; i <= stepsY; i++)
			{
				if (i == 0)
					yValue = 0;
				else
					yValue = yMaximumValue * i / stepsY;
				yPos = _topPadding + chartHeight - (chartHeight * yValue / yMaximumValue);
				
				gr.moveTo(_leftPadding, yPos);
				gr.lineTo(_leftPadding + chartWidth, yPos);
			}
			//main axis
			var gr2: Graphics = _axisSprite.graphics;
			gr2.clear();
			gr2.lineStyle(_axisWidth, _axisColor);
			//			gr2.moveTo(_yAxisLabelsWidth, 0);
			//			gr2.lineTo(_yAxisLabelsWidth, chartH);
			gr2.moveTo(_leftPadding, _topPadding);
			gr2.lineTo(_leftPadding, _topPadding + chartHeight);
			gr2.lineTo(_leftPadding + chartWidth, _topPadding + chartHeight);
			
			//			if (i == 0)
			//				trace("drawAxis["+i+"] value: [" + xValue + ", 0]" + " Pos: [" + _yAxisLabelsWidth + " , " + chartHeight + "]");
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
		
		private function drawBackround(): void
		{
			var gr: Graphics = graphics;
			gr.clear();
			gr.beginFill(0x000000, 0.5);
			gr.drawRect(0, 0, chartWidth, chartHeight);
			gr.endFill();
		}
		
		private function drawLabels(): void
		{
			_labelsSprite.graphics.clear();
			_xAxisLabelsHeight = 0;
			_yAxisLabelsWidth = 0;
			var i: int;
			var xValues: Array = getXFieldValues();
			var yValues: Array = getYFieldValues();
			if (!xValues || !yValues)
				return;
//			var totalX: int = xValues.length;
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
			
			
			var stepsX: int = totalXAxis;
			var stepsY: int = Math.min(10, totalY);
			
			var xDiff: int = chartWidth / (stepsX - 1);
			var yDiff: int = chartHeight / (stepsY - 1);
			
			
			if (chartWidth == 0 && chartHeight == 0)
				return;
			
			//1st pass will find out X labels height 
			for (i = 0; i < totalXAxis; i++)
			{
//				if (i == 0)
//					xValue = 0;
//				else
//					xValue = int(totalX * i / stepsX);
				
				var valueObj: Object = xAxisValues[i];
				if (_labelXAxisFunction != null)
					xLabel = _labelXAxisFunction(valueObj);
				else if (valueObj is Date)
					xLabel = valueObj.toString();
				else if (valueObj is String)
					xLabel = valueObj as String;
				else if (valueObj is Number)
					xLabel = (valueObj as int).toString();
				
				
				chartLabel = getLabel(_xLabelsRotation);
				tf = chartLabel.textField;
				
				//				trace("drawLabels i: " + i + " label: " + xLabel + " xPos: " + xPos);
				
				if (!xLabel)
				{
					trace("Text is NULL");
				}
				tf.text = xLabel;
				format = tf.getTextFormat();
				format.color = _labelsColor;
				format.align = 'left';
				format.font = 'defaultFontMX';
				tf.embedFonts = true;
				tf.setTextFormat(format);
				chartLabel.updatePosition();
				_xLabelsList.addChartLabel(chartLabel);
				_xAxisLabelsHeight = Math.max(_xAxisLabelsHeight, chartLabel.rotatedHeight + _labelXAxisPadding + _axisWidth);
			}
			//1st pass will find out Y labels width
			for (i = 0; i <= stepsY; i++)
			{
				if (i == 0)
					yValue = 0;
				else
					yValue = yMaximumValue * i / stepsY;
				
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
				_yLabelsList.addChartLabel(chartLabel);
				_yAxisLabelsWidth = Math.max(_yAxisLabelsWidth, chartLabel.rotatedWidth + _labelYAxisPadding + _axisWidth);
			}
			
			xDiff = chartWidth / (totalXAxis - 1);
			yDiff = chartHeight / (stepsY - 1);
			
			
			
			//2nd pass will draw X axis grid
			for (i = 0; i < totalXAxis; i++)
			{
//				if (i == 0)
//					xValue = 0;
//				else
//					xValue = int(totalXAxis * i / i);
				
//				xPos = _leftPadding + chartWidth - (chartWidth * xValue / totalXAxis);
				xPos = _leftPadding + i * xDiff;
				
				
				valueObj = xAxisValues[i];
				chartLabel = _xLabelsList.getChartLabel(i);
				if (chartLabel)
				{
					tf = chartLabel.textField;
					chartLabel.x = (xPos) - chartLabel.rotatedWidth / 2;
					chartLabel.y = _topPadding + chartHeight + chartLabel.rotatedHeight / 2 + _labelXAxisPadding;
					drawTextfieldBound(chartLabel);
				}
			}
			//2nd pass will draw Y axis grid
			for (i = 0; i <= stepsY; i++)
			{
				if (i == 0)
					yValue = 0;
				else
					yValue = yMaximumValue * i / stepsY;
				yPos = _topPadding + chartHeight - (chartHeight * yValue / yMaximumValue);
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
	private var _name: String
	private var _list: Array;
	
	public function ChartLabelList(name: String)
	{
		_name = name;
		_list = new Array();
	}
	
	public function getChartLabel(nr: int): ChartLabel
	{
		if (_name == "x")
			trace("ChartLabelList getChartLabel["+nr+"] total: " + _list.length);
		
		if (_list && _list.length > nr)
			return _list.shift() as ChartLabel;
		return null
	}
	
	public function addChartLabel(tf: ChartLabel): void
	{
		_list.push(tf);
		
		if (_name == "x")
			trace("ChartLabelList addChartLabel: " + _list.length);
	}
}