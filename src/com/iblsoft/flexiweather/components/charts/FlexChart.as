package com.iblsoft.flexiweather.components.charts
{
	import flash.display.Graphics;
	import flash.events.Event;
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
		override public function set name(value: String): void
		{
			super.name = value;
			if (simpleChart)
				simpleChart.name = value;
		}

		private var _dataProvider: ArrayCollection;

		private var _dataProviderChanged: Boolean;

		private var _xField: String;

		private var _yField: String;

		public function get xField(): String
		{
			return _xField;
		}

		public function set xField(value: String): void
		{
			_xField = value;
			if (simpleChart)
				simpleChart.xField = _xField;
		}

		public function get yField(): String
		{
			return _yField;
		}

		public function set yField(value: String): void
		{
			_yField = value;
			if (simpleChart)
				simpleChart.yField = _yField;
		}

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

		private var _labelFunction: Function;

		private var _labelFunctionChanged: Boolean;

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

		protected var simpleChart: SimpleChart;

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
		}

		private function invalidateStyle(): void
		{
			_styleChanged = true;
			commitProperties();
		}

		private function onDataProviderChange(event: CollectionEvent): void
		{
//			trace("onDataProviderChange " + event.kind);
			simpleChart.refresh();
		}

		override protected function commitProperties(): void
		{
			super.commitProperties();
			if (_labelFunctionChanged && simpleChart)
			{
				simpleChart.labelFunction = _labelFunction;
				_labelFunctionChanged = false;
			}
			if (_dataProviderChanged && simpleChart)
			{
				if (dataProvider)
					simpleChart.data = dataProvider.source;
				else
					simpleChart.data = [];
				_dataProviderChanged = false;
				simpleChart.refresh();
			}
			if (_styleChanged && simpleChart)
			{
				simpleChart.backgroundColor = _backgroundColor;
				simpleChart.gridColor = _gridColor;
				simpleChart.gridAlpha = _gridAlpha;
				simpleChart.axisColor = _axisColor;
				simpleChart.axisWidth = _axisWidth;
				simpleChart.labelsColor = _labelsColor;
				simpleChart.xLabelsRotation = _xLabelsRotation;
				simpleChart.yLabelsRotation = _yLabelsRotation;
				simpleChart.serieColor = _serieColor;
				simpleChart.serieWidth = _serieWidth;
				_styleChanged = false;
			}
			if (simpleChart)
				simpleChart.name = name;
		}

		override protected function createChildren(): void
		{
			super.createChildren();
			simpleChart = new SimpleChart();
			addChild(simpleChart);
			simpleChart.xField = xField;
			simpleChart.yField = yField;
			simpleChart.x = 0;
			simpleChart.y = 0;
			simpleChart.draw(width, height);
		}

		override protected function childrenCreated(): void
		{
			super.childrenCreated();
		}

		override protected function updateDisplayList(unscaledWidth: Number, unscaledHeight: Number): void
		{
			super.updateDisplayList(unscaledWidth, unscaledHeight);
			var gr: Graphics = graphics;
			gr.clear();
			gr.beginFill(0x000000);
			gr.drawRect(0, 0, unscaledWidth, unscaledHeight);
			gr.endFill();
			if (simpleChart)
				simpleChart.draw(unscaledWidth, unscaledHeight);
		}

		private function notify(type: String): void
		{
			dispatchEvent(new Event(type));
		}
	}
}
