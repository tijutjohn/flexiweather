package com.iblsoft.flexiweather.components.charts
{
	import flash.display.Graphics;
	
	import mx.core.UIComponent;
	
	import spark.components.Group;
	import spark.components.HGroup;
	import spark.components.Label;
	import spark.components.VGroup;
	import spark.primitives.Line;
	
	public class FlexChartLegend extends Group
	{
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
								addElement(item);
								_items.push(item);
								
							}
						} else {
							for (i = 0; i < (ic - yfc); i++)
							{
								item = _items.shift();
								removeElement(item);
							}
						}
						height = item.height * 20;
					}
				}
				updateItems();
			}
		}
		
		override protected function updateDisplayList(unscaledWidth:Number, unscaledHeight:Number):void
		{
			super.updateDisplayList(unscaledWidth, unscaledHeight);
		
			var gr: Graphics = graphics;
			
			gr.clear();
			gr.lineStyle(1, 0x888888);
			gr.beginFill(0x333333, 0.7);
			gr.drawRect(0, 0, unscaledWidth, unscaledHeight);
			gr.endFill();
		}
		
		private function updateItems(): void
		{
			var cnt: int = 0;
			for each (var serie: ChartSerie in _yFields)
			{
				var item: ItemGroup = _items[cnt] as ItemGroup;
				item.y = cnt * 20;
				item.update(serie);
				cnt++;
			}
		}
		
	}
}
import com.iblsoft.flexiweather.components.charts.ChartSerie;

import flash.display.CapsStyle;
import flash.display.Graphics;
import flash.display.JointStyle;
import flash.display.LineScaleMode;

import flashx.textLayout.formats.VerticalAlign;

import mx.core.UIComponent;

import spark.components.CheckBox;
import spark.components.Group;
import spark.components.HGroup;
import spark.components.Label;
import spark.primitives.Line;

class ItemGroup extends Group
{
	private var _label: Label;
	private var _ui: UIComponent;
	private var _checkBox: CheckBox;
	
	override protected function createChildren():void
	{
		super.createChildren();
		
		_label = new Label();
		_ui = new UIComponent();
		_checkBox = new CheckBox();
	}
	
	override protected function childrenCreated(): void
	{
		super.childrenCreated();
		
		addElement(_checkBox);
		addElement(_label);
		addElement(_ui);
	}
	
	
	override protected function measure():void
	{
		super.measure();
		
		measuredWidth = _label.getExplicitOrMeasuredWidth() + _checkBox.getExplicitOrMeasuredWidth() + 50;
		measuredHeight = 20;
	}
	public function update(serie: ChartSerie): void
	{
		if (_label)
		{
			_label.text = serie.label;
			var gr: Graphics = _ui.graphics;
			gr.lineStyle(5, serie.color, 1, true, LineScaleMode.NONE, CapsStyle.SQUARE, JointStyle.MITER);
			gr.moveTo(0,15);
			gr.lineTo(50,15);
			
			_checkBox.selected = serie.visible;
			
			_label.width = 100;
			_label.height = 20;
			_label.setStyle('verticalAlign', VerticalAlign.BOTTOM);
			
			_checkBox.x = 0;
			_checkBox.y = 20 - _checkBox.height;
			_label.x = _checkBox.width + 5;
			_ui.x = _label.x + _label.width + 5;
			
			trace("ItemGroup: ["+serie.label+"]" + _label.x + " , " + _ui.x);
			
		} else {
			callLater(update, [serie]);
		}
	}
}