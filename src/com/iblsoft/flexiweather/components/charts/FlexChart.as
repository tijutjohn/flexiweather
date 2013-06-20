package com.iblsoft.flexiweather.components.charts
{
	import com.iblsoft.flexiweather.ogc.kml.features.Point;
	import com.iblsoft.flexiweather.utils.ArrayUtils;
	
	import flash.display.CapsStyle;
	import flash.display.Graphics;
	import flash.display.LineScaleMode;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.text.TextField;
	import flash.text.TextFormat;
	
	import mx.collections.ArrayCollection;
	import mx.core.UIComponent;
	import mx.events.CollectionEvent;
	import mx.events.CollectionEventKind;

	/**
	 * Display simple chart for Flex project
	 *
	 * @author fkormanak
	 *
	 */
	public class FlexChart extends UIComponent
	{
		public var verticalParts: int = 6;
		public var displayLegend: Boolean;
		
		private var _labelYAxisPadding: int = 10;
		private var _labelXAxisPadding: int = 5;
		
		private var _leftPadding: int = 20;
		private var _bottomPadding: int = 20;
		private var _rightPadding: int = 20;
		private var _topPadding: int = 20;
		private var _legendPadding: int = 0;
		


		public function get maximumYValue():Number
		{
			return _userDefinedYMaximum;
		}

		public function set maximumYValue(value:Number):void
		{
			_userDefinedYMaximum = value;
		}

		public function get paddingLegend(): int
		{
			return _legendPadding;
		}
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
		
//		private var _data: Array;
		private var _dataUpdated: Boolean;
		
		private var _userDefinedYMaximum: Number;
		
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
//		private var _serieColor: uint;
//		private var _serieWidth: int;
		
		protected var _yMaximumValue: Number;
		
		private var _chartLegend: FlexChartLegend;
		public function get chartLegend(): FlexChartLegend
		{
			return _chartLegend;
		}
		
		public var xField: String;
		private var _yFields: Array;
		public function get yFields():Array
		{
			return _yFields;
		}
		
		public function set yFields(value:Array):void
		{
			_yFields = value;
			if (_chartLegend)
			{
				_chartLegend.yFields = value;
			}
		}
		
		
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
		private var _labelYAxisFunction: Function;
		private var _labelAxisFunctionChanged: Boolean;
		
		[Bindable(event = "labelAxisFunctionChanged")]
		public function get labelYAxisFunction(): Function
		{
			return _labelYAxisFunction;
		}

		public function set labelYAxisFunction(value: Function): void
		{
			_labelYAxisFunction = value;
			_labelAxisFunctionChanged = true;
			invalidateProperties();
			dispatchEvent(new Event("labelAxisFunctionChanged"));
		}
		
		[Bindable(event = "labelAxisFunctionChanged")]
		public function get labelXAxisFunction(): Function
		{
			return _labelXAxisFunction;
		}

		public function set labelXAxisFunction(value: Function): void
		{
			_labelXAxisFunction = value;
			_labelAxisFunctionChanged = true;
			invalidateProperties();
			dispatchEvent(new Event("labelAxisFunctionChanged"));
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
			_xAxisDataProviderChanged = true;
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
			
			invalidateDisplayList();
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
		
		private var _headlineColor: uint;
		
		[Bindable(event = "headlineColorChanged")]
		public function get headlineColor():uint
		{
			return _headlineColor;
		}
		
		public function set headlineColor(value:uint):void
		{
			if (_headlineColor != value)
			{
				_headlineColor = value;
				invalidateStyle();
				notify("headlineColorChanged");
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
				invalidateLabels();
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
				invalidateLabels();
				notify("labelsRotationChanged");
			}
		}

		
//		[Bindable(event = "serieColorChanged")]
//		public function get serieColor(): uint
//		{
//			return _serieColor;
//		}
//
//		public function set serieColor(value: uint): void
//		{
//			if (_serieColor != value)
//			{
//				_serieColor = value;
//				invalidateStyle();
//				notify("serieColorChanged");
//			}
//		}

//		[Bindable(event = "serieWidthChanged")]
//		public function get serieWidth(): int
//		{
//			return _serieWidth;
//		}
//
//		public function set serieWidth(value: int): void
//		{
//			if (serieWidth != value)
//			{
//				_serieWidth = value;
//				invalidateStyle();
//				notify("serieWidthChanged");
//			}
//		}

		public function FlexChart()
		{
			super();
			
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
			_labelsColor = 0x333333;
			
			_userDefinedYMaximum = Number.NEGATIVE_INFINITY;
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
//			trace("FlexChart onDataProviderChange: " + event.kind);
//			
//			if (event.kind == CollectionEventKind.ADD)
//			{
//				trace("ADd item to dataprovider");
//			}
			_dataProviderChanged = true;
			invalidateProperties();
		}

		override protected function commitProperties(): void
		{
			super.commitProperties();
			
			if (_xAxisDataProviderChanged)
			{
//				if (dataProvider)
//					data = dataProvider.source;
//				else
//					data = [];
				
				recountChartProperties();
				
				refresh(true	);
				_xAxisDataProviderChanged = false;
			}
			if (_dataProviderChanged)
			{
//				trace("FlexChart commitProperties _dataProviderChanged");
//				if (dataProvider)
//					data = dataProvider.source;
//				else
//					data = [];
				
				recountChartProperties();
				
				refresh();
				_dataProviderChanged = false;
			}
			if (_dataUpdated)
			{
				recountChartProperties();
				_dataUpdated = false;
			}
			
			if (_labelAxisFunctionChanged)
			{
				drawLabels();
				_labelAxisFunctionChanged = false;
			}
			if (_labelFunctionChanged)
			{
				drawLabels();
				_labelFunctionChanged = false;
			}
			
			if (_styleChanged)
			{
				refresh(true);
				_styleChanged = false;
			}
		}

		override protected function createChildren(): void
		{
			super.createChildren();
			
			_chartLegend = new FlexChartLegend();
		}

		override protected function childrenCreated(): void
		{
			super.childrenCreated();
			
			addChild(_chartLegend);
			if (_yFields)
			{
				_chartLegend.yFields = _yFields;
			}
		}
		
		override protected function updateDisplayList(unscaledWidth: Number, unscaledHeight: Number): void
		{
			super.updateDisplayList(unscaledWidth, unscaledHeight);
			var gr: Graphics = graphics;
			gr.clear();
			gr.beginFill(0x000000);
			gr.drawRect(0, 0, unscaledWidth, unscaledHeight);
			gr.endFill();
			
			_chartLegend.visible = displayLegend;
			chartWidth = getChartAreaWidth(unscaledWidth);
			chartHeight = getChartAreaHeight(unscaledHeight);
			
//			trace("updateDisplayList ["+unscaledWidth+","+unscaledHeight+"]");	
//			trace("chart size ["+chartWidth+","+chartHeight+"]");	
			draw();
		}

		private function notify(type: String): void
		{
			dispatchEvent(new Event(type));
		}
		
		
		
		
		
//		public function get data(): Array
//		{
//			return _data;
//		}
//		
//		public function set data(value: Array): void
//		{
//			_data = value;
//			_dataUpdated = true;
//			invalidateProperties();
//		}
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
		
		public function getValueForSerie(xValue: Object, serie: ChartSerie): Number
		{
			if (dataProvider && dataProvider.length > 0)
			{
				for each (var currItem: Object in dataProvider)
				{
					if (currItem.hasOwnProperty(serie.field))
					{
						var value: Object = currItem[serie.field];
						if (value == xValue)
							return currItem[serie.field];
					}
				}
			}
			return 0;
		}
		
		
		
		protected function getYFieldMaximumValue(): Number
		{
			if (_userDefinedYMaximum != Number.NEGATIVE_INFINITY)
			{
				return _userDefinedYMaximum;
			}
			
			var value: Number = Number.NEGATIVE_INFINITY;
			
			for each (var serie: ChartSerie in yFields)
			{
				value = Math.max(value, serie.maximumValue);
			}
			
			//rounding
			value = updateYFieldMaximumValue(value);
			return value;
		}
		
		protected function updateYFieldMaximumValue(value: Number): Number
		{
			return value;
		}
		
		protected function getXFieldValues(): Array
		{
			if (dataProvider && dataProvider.length > 0)
			{
				var values: Array = []
				var item: Object;
				for each (var currItem: Object in dataProvider)
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
			var values: Array = [];
			for each (var serie: ChartSerie in yFields)
			{
				ArrayUtils.unionArrays(values, serie.data);
			}
			return values;
		}
		private function getYFieldValuesForSerie(serie: ChartSerie): Array
		{
			if (dataProvider && dataProvider.length > 0)
			{
				var values: Array = [];
				var item: Object;
				for each (var currItem: Object in dataProvider)
				{
					if (currItem && currItem.hasOwnProperty(serie.field))
						values.push(currItem[serie.field]);
				}
				return values;
			}
			return null;
		}
		
		
		protected function draw(): void
		{
			if (isNaN(chartWidth) || isNaN(chartHeight))
				return;
				
			if (dataProvider)
			{
				if (displayLegend)
				{
					var _chartLegendWidth: int = 60; //_chartLegend.width;
					_chartLegend.x = _leftPadding + chartWidth / 2 - _chartLegendWidth / 2; 
					_chartLegend.y = 10;
				}
				
				drawBackround();
//				invalidateLabels();
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
		protected function getChartAreaHeight(h: int): int
		{
			var areaHeight: Number =  h - (_topPadding + _bottomPadding);
			if (_chartLegend)
			{
				if (displayLegend)
				{
					_legendPadding = _chartLegend.items.length * 20;//_chartLegend.height;
					areaHeight -= _legendPadding;
				}
			}
			
			return areaHeight;
		}
		
		private var xAxisValues: Array;
		private var yAxisValues: Array;
		private var totalXAxis: int;
		private var totalYAxis: int;
		
		private var xValues: Array;
		private var totalX: int;
		
//		private var yValues: Array;
//		private var totalY: int;
//		private var yMaximumValue: Number;
		
		protected var chartWidth: Number;
		protected var chartHeight: Number;
		
		
		private function recountChartProperties(): void
		{
			xAxisValues = xAxisDataProvider.source;
			totalXAxis = xAxisValues.length;
			
			xValues = getXFieldValues();
			totalX = 0;
			if (xValues)
				totalX = xValues.length;
			
			for each (var serie: ChartSerie in yFields)
			{
				serie.data = getYFieldValuesForSerie(serie);
			}
			
//			trace("FlexChart recountChartProperties totalX: " + totalX + " totalXAxis: " + totalXAxis + " serie: " + serie.data.length);
		}
		
		private var _currentDrawnSerie: ChartSerie;
		private var _currentDrawnPosition: int;
		
		protected function getChartYValue(serie: ChartSerie, valueObject: Object, maxValue: Number): Number
		{
			var value: Number;
			if (valueObject)
				value = serie.getValue(valueObject);
			else
				value = 0;
			
			var yPos: Number = _topPadding + _legendPadding + chartHeight - (chartHeight * value / maxValue);
			return yPos;
		}
		
		
		
		protected var startX: Number;
		protected var endX: Number;
		protected var endY: Number;
		protected var stopDrawing: Boolean;
		
		protected function getSerieGraphics(): Graphics
		{
			return _dataSprite.graphics;
		}
		
		protected function finishDrawSerie(gr: Graphics, serie: ChartSerie): void
		{
			if (serie.chartType == ChartType.LINE_FILL)
			{
				var yPosMax: Number = getChartYValue(serie, _yMaximumValue, _yMaximumValue);
				
				gr.lineTo(endX, endY);
				gr.lineTo(endX, yPosMax);
				gr.lineTo(startX, yPosMax);
				gr.endFill();
			}
		}
		protected function drawSeriePoint(gr: Graphics, serie: ChartSerie, position: int,  xValue: Number, yValue: Object, xPos: Number, yPos: Number, yPosMax: Number): void
		{
			var pointLineHalfLine: Number = 3;
			
			var yValueNumber: Number = yValue as Number;
			
			if (serie.chartType == ChartType.LINE_FILL)
			{
				if (serie.isValidValue(yValueNumber))
				{
					if (position == 0 || stopDrawing) {
						
						gr.beginFill(serie.color, 0.5);
						
						startX = xPos;
						
						gr.moveTo(xPos, yPosMax);
					}
					gr.lineTo(xPos, yPos);
					
					endX = xPos;
					endY = yPos;
					stopDrawing = false;
					
				} else {
					
					stopDrawing = true;
					
					gr.lineTo(endX, endY);
					gr.lineTo(endX, yPosMax);
					gr.lineTo(startX, yPosMax);
					gr.endFill();
					
				}
				
			} else if (serie.chartType == ChartType.LINE)
			{
				//								trace("drawSeries uncondensed["+i+"] value: [" + yValue + "]" + " Pos: [" + xPos + " , " + yPos + "] chart ["+_leftPadding+","+(_leftPadding+chartWidth)+"]");
				if (serie.isValidValue(yValueNumber))
				{
					if (position == 0 || stopDrawing)
						gr.moveTo(xPos, yPos);
					else
						gr.lineTo(xPos, yPos);
					stopDrawing = false;
				} else {
					stopDrawing = true;
				}
			} else if (serie.chartType == ChartType.POINT) {
				
				if (serie.isValidValue(yValueNumber))
				{
					//									trace("POINT uncondensed: ["+xPos+","+yPos+"]["+j+"]");
					
//					gr.moveTo(xPos, yPos - pointLineHalfLine);
//					gr.lineTo(xPos, yPos + pointLineHalfLine);
					
					gr.beginFill(serie.getColorForYValue(yValueNumber), 1);
					gr.lineStyle(0, serie.color,0);
					gr.drawCircle(xPos, yPos, serie.lineWidth);
					gr.endFill();
					stopDrawing = false;
				} else {
					stopDrawing = true;
				}
			}
			if (isNaN(yValueNumber))
			{
				trace("null yValue");
			}
		}
		protected function drawCustomSeries(): void
		{
			
		}
		
		protected function getXPositionForValue(xValue: Object, field: String = null): Number
		{
			var minXValue: Number;
			var maxXValue: Number;
			
			var xValues: Array = getXFieldValues();
			var totalX: int = xValues.length;
			
			var position: int = -1;
			var xValueNumber: Number = xValue[field];
			var cnt: int = 0;
			for each (var currXValue: Object in xValues)
			{
				if (currXValue && currXValue.hasOwnProperty(field))
				{
					var currValue: Number = currXValue[field] as Number;
					if (currValue == xValue)
					{
						position = cnt;
						break;
					}
				}
				cnt++;
			}
			
			var xPos: Number;
			var stepsX: int = Math.min(totalX, chartWidth);
			
			if (totalX < chartWidth)
			{
//				if (position == 0)
//					xValue = 0;
//				else
//					xValue = int(totalX * position / stepsX);
				xPos = _leftPadding + (chartWidth * position / totalX);
			} else {
				
				var pointsPerPixel: Number = Number(totalX / chartWidth);
				pointsPerPixel = Math.max(1, pointsPerPixel);
				
				xPos = _leftPadding + (chartWidth * (position / pointsPerPixel) / totalX);
				
			}
			return xPos;
				
		}
		
		protected function drawSeries(): void
		{
//			trace("\n\n DRAW SERIE: " + totalX + " chart: " + chartWidth);
			
			_yMaximumValue = getYFieldMaximumValue();
			
			var gr: Graphics = _dataSprite.graphics;
			gr.clear();
			
			var yMaximumValue: Number = getYFieldMaximumValue();
			
			drawCustomSeries();
			
			for each (var serie: ChartSerie in yFields)
			{
				if (serie.visible)
				{
//					if (serie.data.length != 300)
//					{
//						trace("check serie["+serie.name+"]: " + serie.data.length);
//					}
					gr.lineStyle(serie.lineWidth, serie.color);
					
					var i: int;
					var j: int;
					var xPos: int;
					var xValue: Number;
					
					var xDiff: Number = chartWidth / (totalX - 1);
					var stepsX: int = Math.min(totalX, chartWidth); //chartXSteps;
				
					if (serie.field == "coverage")
					{
						trace("Coverage rendering");
					}
					var yValues: Array = serie.data;
					var yValue: Object;
					var yValueAverage: Number;
					var yValueMinimumMaximum: Array;
					
					var yPosMax: Number = getChartYValue(serie, yMaximumValue, yMaximumValue);
					var valuesForDraw: int;
					var isArray: Boolean;
					
					if (xValues.length != yValues.length)
					{
						trace("ATTENTION, xValues and yValues array has different items length");
					}
					if (totalX < chartWidth)
					{
						stopDrawing = true;
						
	//					trace("draw uncondesed graph");
						for (i = 0; i < totalX; i++)
						{
							valuesForDraw = 1;
							isArray = false;
							if (yValues[i] is Array)
							{
								valuesForDraw = (yValues[i] as Array).length;
								isArray = true;
							} else {
								yValue = yValues[i];
							}
							
							
							for (j = 0; j < valuesForDraw; j++)
							{
								if (isArray)
								{
									yValue = yValues[i][j];
								}
							
								
								if (i == 0)
									xValue = 0;
								else
									xValue = int(totalX * i / stepsX);
								xPos = _leftPadding + (chartWidth * xValue / totalX);
								
								var yPos: Number = getChartYValue(serie, yValue, yMaximumValue);
								
								
								drawSeriePoint(gr, serie, i, xValue, yValue, xPos, yPos, yPosMax);
							}
						}
						
						finishDrawSerie(gr, serie);
						
	//					trace("drawSeries END of uncondensed["+i+"] chart ["+_leftPadding+","+(_leftPadding+chartWidth)+"]");
					} else {
						//there are more points than width (in pixel) of chart, so points must be condensed
	//					trace("draw condesed graph");
						var pointCounter: int = 0;
						var pixelPosition: int = 0;
						var pixelValues: Array = [];
						
						var pointsPerPixel: Number = Number(totalX / chartWidth);
						pointsPerPixel = Math.max(1, pointsPerPixel);
						
						stopDrawing = true;
						var previousPointWasDrawn: Boolean;
						var nextPixelPosition: Number = 1 * pointsPerPixel;
						while (pointCounter < totalX)
						{
							valuesForDraw = 1;
							isArray = false;
							if (yValues[pointCounter] is Array)
							{
								valuesForDraw = (yValues[pointCounter] as Array).length;
								isArray = true;
							} else {
								yValue = yValues[pointCounter];
							}
							
							
							pointCounter++;
							
							if (pointCounter >= nextPixelPosition)
							{
								pixelPosition++;
								
								
								xPos = _leftPadding + pixelPosition;
								
								previousPointWasDrawn = true;
								nextPixelPosition = (pixelPosition * pointsPerPixel);
							} else {
								previousPointWasDrawn = false;
							}
							
							
							for (j = 0; j < valuesForDraw; j++)
							{
								if (isArray)
								{
									yValue = yValues[pointCounter - 1][j];
								}
								
								if (!pixelValues[j])
									pixelValues[j] = [];
								
								(pixelValues[j] as Array).push(yValue);
								
								if (previousPointWasDrawn)
								{
									yValueAverage = averageValues(serie, pixelValues[j]);
									yPos = _topPadding + _legendPadding + chartHeight - (chartHeight * yValueAverage / yMaximumValue);
									drawSeriePoint(gr, serie, pointCounter, xValue, yValue, xPos, yPos, yPosMax);
									
									pixelValues[j] = [];
									
								} else {
									
								}
							}
							
						}
						
						if (!previousPointWasDrawn)
						{
							for (j = 0; j < valuesForDraw; j++)
							{
								//drawLastPoint
								yValueAverage = averageValues(serie, pixelValues[j]);
								yValueMinimumMaximum = getMinimumMaximumValues(serie, pixelValues[j]);
							
								trace("condensed min: " + yValueMinimumMaximum[0] + " average: " + yValueAverage + " max: " + yValueMinimumMaximum[1]);
							
								xPos = _leftPadding + pixelPosition;
								yPos = _topPadding + _legendPadding + chartHeight - (chartHeight * yValueAverage / yMaximumValue);
							
								drawSeriePoint(gr, serie, pointCounter, xValue, yValue, xPos, yPos, yPosMax);
							}
						}
						
						finishDrawSerie(gr, serie);
						
	//					trace("drawSeries END of condensed["+pixelPosition+"] chart ["+_leftPadding+","+(_leftPadding+chartWidth)+"]");
					}
				}
			}
		}
		
		protected function averageValues(serie: ChartSerie, pixelValues: Array): Number
		{
			return serie.averageValues(pixelValues);
		}
		protected function getMinimumMaximumValues(serie: ChartSerie, pixelValues: Array): Array
		{
			return serie.getMinimumMaximumValues(pixelValues);
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
//			var xValues: Array = getXFieldValues();
//			var yValues: Array = getYFieldValues();
			if (!xValues)
				return;
			
//			var totalX: int = xValues.length;
//			var totalY: int = yValues.length;
			var xLabel: String;
			var xValue: Number;
			var xPos: Number;
			var yLabel: String;
			var yValue: Number;
			var yPos: Number;
			
			var stepsX: int = totalXAxis;
			var stepsY: int = verticalParts
			
			
			var xDiff: int = chartWidth / (stepsX - 1);
			var yDiff: int = chartHeight / (stepsY - 1);
			
			if (chartWidth == 0 && chartHeight == 0)
				return;
			
//			trace("DrawAxis _xAxisLabelsHeight: " + _xAxisLabelsHeight + " _yAxisLabelsWidth: " + _yAxisLabelsWidth);
			
			var yMaximumValue: Number = getYFieldMaximumValue();
			
			xDiff = chartWidth / (stepsX - 1);
			yDiff = chartHeight / (stepsY - 1);
			gr.lineStyle(1, _gridColor, _gridAlpha);
			
			//draw X axis grid
			for (i = 0; i < stepsX; i++)
			{
				xPos = _leftPadding + i * xDiff;
				
//				trace("DRAW X AXIS: ["+i+"] at " + xPos);
				gr.moveTo(xPos, _topPadding + _legendPadding);
				gr.lineTo(xPos, _topPadding + _legendPadding + chartHeight);
				
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
				yPos = _topPadding + _legendPadding + chartHeight - (chartHeight * yValue / yMaximumValue);
				
				gr.moveTo(_leftPadding, yPos);
				gr.lineTo(_leftPadding + chartWidth, yPos);
			}
			//main axis
			var gr2: Graphics = _axisSprite.graphics;
			gr2.clear();
			gr2.lineStyle(_axisWidth, _axisColor, 1, true, LineScaleMode.NONE, CapsStyle.NONE);
			//			gr2.moveTo(_yAxisLabelsWidth, 0);
			//			gr2.lineTo(_yAxisLabelsWidth, chartH);
			gr2.moveTo(_leftPadding - _axisWidth / 2, _topPadding + _legendPadding);
			gr2.lineTo(_leftPadding - _axisWidth / 2, _topPadding + _legendPadding + chartHeight + _axisWidth / 2);
			gr2.lineTo(_leftPadding + chartWidth, _topPadding + _legendPadding + chartHeight + _axisWidth / 2);
			
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
			_labelFunctionChanged = true;
//			for each (var tf: ChartLabel in _usedLabels)
//			{
//				if (tf.parent == _labelsSprite)
//					_labelsSprite.removeChild(tf);
//				_unusedLabels.push(tf);
//			}
			invalidateProperties();
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
//			gr.lineStyle(1, 0x555555);
			gr.beginFill(backgroundColor);
			gr.drawRect(_leftPadding, _topPadding + _legendPadding, chartWidth, chartHeight);
			gr.endFill();
		}
		
		private function drawLabels(): void
		{
			_labelsSprite.graphics.clear();
			_xAxisLabelsHeight = 0;
			_yAxisLabelsWidth = 0;
			var i: int;
//			var xValues: Array = getXFieldValues();
//			var yValues: Array = getYFieldValues();
			if (!xValues)
				return;
//			var totalX: int = xValues.length;
//			var totalY: int = yValues.length;
			
			
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
			var stepsY: int = verticalParts;
			
			var xDiff: int = chartWidth / (stepsX - 1);
			var yDiff: int = chartHeight / (stepsY - 1);
			
			
			if (chartWidth == 0 && chartHeight == 0)
				return;
			
			var yMaximumValue: Number = getYFieldMaximumValue();
			
			//**************************************************************
			// 1st pass
			//**************************************************************

			//1st pass will find out X labels height 
			for (i = 0; i < totalXAxis; i++)
			{
				
				var valueObj: Object = xAxisValues[i];
				if (_labelXAxisFunction != null)
					xLabel = _labelXAxisFunction(valueObj);
				else if (valueObj is Date)
					xLabel = valueObj.toString();
				else if (valueObj is String)
					xLabel = valueObj as String;
				else if (valueObj is Number)
					xLabel = (valueObj as int).toString();
				//				trace("drawLabels i: " + i + " label: " + xLabel + " xPos: " + xPos);
				
				if (!_xLabelsList.chartLabelAtExists(i))
				{
					chartLabel = getLabel(xLabelsRotation);
					_xLabelsList.addChartLabelAt(chartLabel, i);
				} else {
					chartLabel = _xLabelsList.getChartLabelAt(i);
				}
				tf = chartLabel.textField;
				tf.text = xLabel;
				format = tf.getTextFormat();
				format.color = _labelsColor;
				format.align = 'left';
				format.font = 'defaultFontMX';
				tf.embedFonts = true;
				tf.setTextFormat(format);
				chartLabel.updatePosition();
				_xAxisLabelsHeight = Math.max(_xAxisLabelsHeight, chartLabel.rotatedHeight + _labelXAxisPadding + _axisWidth);
			}
			//1st pass will find out Y labels width
			for (i = 0; i <= stepsY; i++)
			{
				yValue = yMaximumValue * i / stepsY;
					
				if (_labelYAxisFunction != null)
					yValue = _labelYAxisFunction(yValue);
				
				if (!_yLabelsList.chartLabelAtExists(i))
				{
					chartLabel =  getLabel(yLabelsRotation);
					_yLabelsList.addChartLabelAt(chartLabel, i);
				} else {
					chartLabel = _yLabelsList.getChartLabelAt(i);
//					chartLabel = getLabel(_yLabelsRotation);
				}
				tf = chartLabel.textField;
				tf.text = int(yValue).toString();
				format = tf.getTextFormat();
				format.color = _labelsColor;
				format.align = 'left';
				format.font = 'defaultFontMX';
				tf.embedFonts = true;
				tf.setTextFormat(format);
				chartLabel.updatePosition();
				_yAxisLabelsWidth = Math.max(_yAxisLabelsWidth, chartLabel.rotatedWidth + _labelYAxisPadding + _axisWidth);
			}
			
			
			//**************************************************************
			// 2nd pass
			//**************************************************************
			
//			xDiff = chartWidth / (totalXAxis - 1);
//			yDiff = chartHeight / (stepsY - 1);
			
			
			//2nd pass will draw X axis grid
			for (i = 0; i < totalXAxis; i++)
			{
				xPos = _leftPadding + i * xDiff;
				
				
				valueObj = xAxisValues[i];
				
				if (_xLabelsList.chartLabelAtExists(i))
				{
					chartLabel = _xLabelsList.getChartLabelAt(i);
					tf = chartLabel.textField;
					tf.rotation = xLabelsRotation;
					
//					trace("DRAW X LABEL: ["+i+"] at " + xPos + " : " + tf.text + " xDiff: " + xDiff);
					
					chartLabel.x = (xPos) - chartLabel.rotatedWidth / 2;
					chartLabel.y = _topPadding + _legendPadding + chartHeight + chartLabel.rotatedHeight / 2 + _labelXAxisPadding;
					drawTextfieldBound(chartLabel);
				}
			}
			//2nd pass will draw Y axis grid
			for (i = 0; i <= stepsY; i++)
			{
				yValue = yMaximumValue * i / stepsY;
					
				yPos = _topPadding + _legendPadding + chartHeight - (chartHeight * yValue / yMaximumValue);
				
				if (_yLabelsList.chartLabelAtExists(i))
				{
					chartLabel = _yLabelsList.getChartLabelAt(i);
					tf = chartLabel.textField;
					tf.rotation = yLabelsRotation;
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

import mx.charts.chartClasses.ChartLabel;

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
	
	public function getChartLabelAt(nr: int): ChartLabel
	{
		if (_list && _list[nr] is ChartLabel)
		{
			return (_list[nr] as ChartLabel);
		}
		return null;
	}
	public function chartLabelAtExists(nr: int): Boolean
	{
//		if (_name == "x")
//			trace("ChartLabelList getChartLabel["+nr+"] total: " + _list.length);
		
		if (_list)
		{
			return (_list[nr] is ChartLabel);
		}
		return false
	}
	
	public function addChartLabelAt(tf: ChartLabel, position: int): void
	{
		_list[position] = tf;
	}
//	public function addChartLabel(tf: ChartLabel): void
//	{
//		_list.push(tf);
		
//		if (_name == "x")
//			trace("ChartLabelList addChartLabel: " + _list.length);
//	}
}