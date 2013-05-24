package com.iblsoft.flexiweather.components.charts
{
	import flash.display.Graphics;
	
	import mx.core.UIComponent;
	
	import spark.components.Group;
	import spark.components.HGroup;
	import spark.components.Label;
	import spark.components.VGroup;
	import spark.primitives.Line;
	
	[Event(name="serieVisibilityChange", type="com.iblsoft.flexiweather.components.charts.FlexChartLegendEvent")]
	public class FlexChartLegend extends Group
	{
		[Bindable]
		public var color: uint = 0xffffff;
		[Bindable]
		public var backgroundColor: uint = 0x000000;
		[Bindable]
		public var backgroundAlpha: Number = 0;
		
		private var _yFields: Array;
		private var _yFieldsChanged: Boolean;
		
		public function get yFields():Array
		{
			return _yFields;
		}

		public function set yFields(value:Array):void
		{
			_yFields = value;
			_yFieldsChanged = true;
			invalidateProperties();
		}
		
		private var _items: Array = [];
		public function get items(): Array
		{
			return _items;
		}
		public function FlexChartLegend()
		{
			super();
		}
		
		override protected function measure():void
		{
			super.measure();
			
			if (_items && _items.length > 0)
			{
				measuredHeight = Math.max(measuredHeight, _items.length * 20);
			} else {
				measuredHeight = 20;
			}
			measuredWidth = 120;
			
		}
		override protected function commitProperties(): void
		{
			super.commitProperties();
			
			if (_yFieldsChanged)
			{
				
				if (_yFields)
				{
					var yfc: int = _yFields.length;
					var ic: int = _items.length;
					
					if (yfc != ic)
					{
						var item: ItemGroup;
						var i: int;
						if (yfc > ic)
						{
							for (i = ic; i < yfc; i++)
							{
								item = new ItemGroup();
								item.addEventListener(FlexChartLegendEvent.SERIE_VISIBILITY_CHANGE, redispatchVisibilityChange);
								addElement(item);
								_items.push(item);
								
							}
						} else {
							for (i = 0; i < (ic - yfc); i++)
							{
								item = _items.shift();
								item.removeEventListener(FlexChartLegendEvent.SERIE_VISIBILITY_CHANGE, redispatchVisibilityChange);
								removeElement(item);
							}
						}
						height = item.height * 20;
					}
				}
				updateItems();
			}
		}
		
		private function redispatchVisibilityChange(event: FlexChartLegendEvent): void
		{
			dispatchEvent(event);
		}
		
		override protected function updateDisplayList(unscaledWidth:Number, unscaledHeight:Number):void
		{
			super.updateDisplayList(unscaledWidth, unscaledHeight);
		
			var gr: Graphics = graphics;
			
			gr.clear();
//			gr.lineStyle(1, 0x888888);
			gr.beginFill(backgroundColor, backgroundAlpha);
			gr.drawRect(0, 0, unscaledWidth, unscaledHeight);
			gr.endFill();
		}
		
		private function updateItems(): void
		{
			var cnt: int = 0;
			for each (var serie: ChartSerie in _yFields)
			{
				var item: ItemGroup = _items[cnt] as ItemGroup;
				item.color = color;
				item.serie = serie;
				item.y = cnt * 20;
				item.update(serie);
				cnt++;
			}
		}
		
	}
}
import com.iblsoft.flexiweather.components.charts.ChartSerie;
import com.iblsoft.flexiweather.components.charts.FlexChartLegendEvent;

import flash.display.CapsStyle;
import flash.display.Graphics;
import flash.display.JointStyle;
import flash.display.LineScaleMode;
import flash.events.Event;

import flashx.textLayout.formats.VerticalAlign;

import mx.core.UIComponent;

import spark.components.CheckBox;
import spark.components.Group;
import spark.components.HGroup;
import spark.components.Label;
import spark.primitives.Line;

class ItemGroup extends Group
{
	public var serie: ChartSerie;
	
//	private var _label: Label;
	private var _ui: UIComponent;
	private var _checkBox: CheckBox;
	public var color: uint;
	
	public function ItemGroup()
	{
	}
	override protected function createChildren():void
	{
		super.createChildren();
		
//		_label = new Label();
		_ui = new UIComponent();
		_checkBox = new CheckBox();
	}
	
	override protected function childrenCreated(): void
	{
		super.childrenCreated();
		
		addElement(_checkBox);
//		addElement(_label);
		addElement(_ui);
	}
	
	
	override protected function measure():void
	{
		super.measure();
		
		measuredWidth = _checkBox.getExplicitOrMeasuredWidth() + 50;
		measuredHeight = 20;
	}
	
	private function onCheckBoxChange(event: Event): void
	{
		var fcle: FlexChartLegendEvent = new FlexChartLegendEvent(FlexChartLegendEvent.SERIE_VISIBILITY_CHANGE);
		fcle.serie = serie;
		fcle.visibility = _checkBox.selected;
		
		dispatchEvent(fcle);
	}
	
	public function update(serie: ChartSerie): void
	{
		if (_checkBox)
		{
			_checkBox.label = serie.label;
			_checkBox.setStyle('color', color);
			var gr: Graphics = _ui.graphics;
			gr.lineStyle(5, serie.color, 1, true, LineScaleMode.NONE, CapsStyle.SQUARE, JointStyle.MITER);
			gr.moveTo(0,10);
			gr.lineTo(50,10);
			
			_checkBox.selected = serie.visible;
			
//			_label.width = 100;
//			_label.height = 20;
//			_label.setStyle('verticalAlign', VerticalAlign.BOTTOM);
			
			_checkBox.x = 0;
//			_checkBox.y = 20 - _checkBox.height;
			_checkBox.validateNow();
			
			_checkBox.addEventListener(Event.CHANGE, onCheckBoxChange);
			
//			_label.x = _checkBox.width + 5;
			_ui.x = 120; //_checkBox.x + _checkBox.width + 5;
			
//			trace("ItemGroup: ["+serie.label+"]" + _label.x + " , " + _ui.x);
			
		} else {
			callLater(update, [serie]);
		}
	}
}