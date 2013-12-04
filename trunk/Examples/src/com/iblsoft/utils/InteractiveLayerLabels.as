package com.iblsoft.utils
{
	import com.iblsoft.flexiweather.proj.Coord;
	import com.iblsoft.flexiweather.widgets.InteractiveLayer;
	import com.iblsoft.flexiweather.widgets.InteractiveWidget;
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.Graphics;
	import flash.geom.Matrix;
	import flash.geom.Point;
	import flash.text.TextField;
	import flash.text.TextFieldAutoSize;
	import flash.text.TextFormat;
	import mx.collections.ArrayCollection;
	import mx.states.AddChild;
	import mx.states.OverrideBase;

	public class InteractiveLayerLabels extends InteractiveLayer
	{
		protected var ma_labels: ArrayCollection;
		protected var m_bitmapData: BitmapData = null;
		protected var m_bitmap: Bitmap = null;

		public function InteractiveLayerLabels(container: InteractiveWidget = null)
		{
			super(container);
			ma_labels = new ArrayCollection();
		}

		override protected function createChildren(): void
		{
			super.createChildren();
			m_bitmap = new Bitmap(m_bitmapData);
			addChild(m_bitmap);
		}

		override protected function childrenCreated(): void
		{
			super.childrenCreated();
		}

		public function clearLabels(): void
		{
			m_bitmapData.dispose();
			m_bitmapData = new BitmapData(width, height, true, 0x00000000);
			m_bitmap.bitmapData = m_bitmapData;
			ma_labels.removeAll();
		}

		public function addLabel(coord: Coord, s_text: String, format: TextFormat, i_xShift: int = 0, i_yShift: int = 0): void
		{
			var labelObj: Object = new Object();
			labelObj["text"] = s_text;
			labelObj["format"] = format;
			labelObj["coord"] = coord;
			labelObj["xShift"] = i_xShift;
			labelObj["yShift"] = i_yShift;
			ma_labels.addItem(labelObj);
			invalidateDynamicPart(true);
		}

		override public function draw(graphics: Graphics): void
		{
			if (m_bitmapData)
				m_bitmapData.dispose();
			if (width == 0 || height == 0)
				return;
			m_bitmapData = new BitmapData(width, height, true, 0x00000000);
			m_bitmap.bitmapData = m_bitmapData;
			for each (var labelObj: Object in ma_labels)
			{
				var coord: Coord = labelObj["coord"];
				var i_xShift: int = labelObj["xShift"];
				var i_yShift: int = labelObj["yShift"];
				var s_text: String = labelObj["text"];
				var format: TextFormat = labelObj["format"];
				var point: flash.geom.Point = container.coordToPoint(coord);
				var textField: TextField = new TextField();
				textField.text = s_text;
				textField.setTextFormat(format);
				var m: Matrix = new Matrix();
				m.translate(point.x - textField.textWidth / 2 + i_xShift, point.y - textField.textHeight / 2 + i_yShift);
				m_bitmapData.draw(textField, m);
			}
		}

		override public function onAreaChanged(b_finalChange: Boolean): void
		{
			draw(graphics);
		}
	}
}
