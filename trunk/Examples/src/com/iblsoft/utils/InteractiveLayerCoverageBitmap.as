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
	import flash.geom.Rectangle;
	import flash.utils.ByteArray;

	public class InteractiveLayerCoverageBitmap extends InteractiveLayer
	{
		protected var m_bitmapData: BitmapData = null;
		protected var m_coord1: Coord = null;
		protected var m_coord2: Coord = null;
		protected var ma_values: Array = null;
		protected var m_colorGradient: ColorGradient = null;

		public function InteractiveLayerCoverageBitmap(container: InteractiveWidget = null)
		{
			super(container);
		}

		override protected function createChildren(): void
		{
			super.createChildren();
		}

		public function setCoverageData(coord1: Coord, coord2: Coord, a_values: Array, colorGradient: ColorGradient): void
		{
			m_coord1 = coord1;
			m_coord2 = coord2;
			ma_values = a_values;
			m_colorGradient = colorGradient;
			invalidateDynamicPart(true);
		}

		override public function draw(graphics: Graphics): void
		{
			if (m_bitmapData)
				m_bitmapData.dispose();
			if (width == 0 || height == 0)
				return;
			if (!m_coord1 || !m_coord2 || !ma_values)
				return;
			var p1: flash.geom.Point = container.coordToPoint(m_coord1);
			var p2: flash.geom.Point = container.coordToPoint(m_coord2);
			var f_x: Number;
			var f_y: Number;
			var f_width: Number;
			var f_height: Number;
			if (p1.x < p2.x)
			{
				f_x = p1.x;
				f_width = p2.x - p1.x;
			}
			else
			{
				f_x = p2.x;
				f_width = p1.x - p2.x;
			}
			if (p1.y < p2.y)
			{
				f_y = p1.y;
				f_height = p2.y - p1.y;
			}
			else
			{
				f_y = p2.y;
				f_height = p1.y - p2.y;
			}
			var i_bitMapWidth: int = (ma_values[0] as Array).length;
			var i_bitMapHeight: int = ma_values.length;
			m_bitmapData = new BitmapData(i_bitMapWidth, i_bitMapHeight, true, 0xCC000000);
			var a_colorMap: Array = new Array(512);
			var f_min: Number = m_colorGradient.minimumValue;
			var f_range: Number = m_colorGradient.maximumValue - f_min;
			for (var i: int = 0; i < 512; i++)
			{
				var f_value: Number = (i / 511.0) * f_range + f_min;
				a_colorMap[i] = m_colorGradient.getColorForValue(f_value);
			}
			//var b: ByteArray = new ByteArray();
			//byte* ptr = (byte*)m_bitmapData.Scan0;
			m_bitmapData.lock();
			for (var i_y: uint = 0; i_y < i_bitMapHeight; ++i_y)
			{
				var a_row: Array = ma_values[i_y];
				var i_targetY: uint = i_bitMapHeight - i_y - 1;
				for (var i_x: uint = 0; i_x < i_bitMapWidth; ++i_x)
				{
					var i_colorIndex: int = int((a_row[i_x] - f_min) / f_range * 511);
					if (i_colorIndex < 0)
						i_colorIndex = 0;
					if (i_colorIndex > 511)
						i_colorIndex = 511;
					m_bitmapData.setPixel(i_x, i_targetY, a_colorMap[i_colorIndex]);
						//b.writeUnsignedInt(a_colorMap[i_colorIndex]);
				}
			}
			m_bitmapData.unlock();
			//b.position = 0;
			//m_bitmapData.setPixels(new Rectangle(0, 0, i_bitMapWidth, i_bitMapHeight), b);
			/*for (var s_y: String in ma_values)
			{
				var i_y: int = int(s_y);
				for (var s_x: String in (ma_values[i_y] as Array))
				{
					var i_x: int = int(s_x);
					var i_color: uint = m_colorGradient.getColorForValue(ma_values[i_y][i_x]);
					m_bitmapData.setPixel(i_x, i_bitMapHeight - i_y - 1, i_color);
				}
			}*/
			var matrix: Matrix = new Matrix();
			matrix.scale(f_width / i_bitMapWidth, f_height / i_bitMapHeight);
			matrix.translate(f_x, f_y);
			graphics.beginBitmapFill(m_bitmapData, matrix, false, false);
			graphics.drawRect(f_x, f_y, f_width, f_height);
			graphics.endFill();
		}

		override public function onAreaChanged(b_finalChange: Boolean): void
		{
			draw(graphics);
		}
	}
}
