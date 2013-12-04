package com.iblsoft.flexiweather.symbology
{
	import com.iblsoft.flexiweather.utils.DistanceMarkingCurveRenderer;
	import flash.display.Graphics;

	public class TurbulenceCurveRenderer extends DistanceMarkingCurveRenderer
	{
		// style variables
		protected var mf_thickness: Number;
		protected var mi_color: uint;
		protected var mf_alpha: Number;
		// runtime variables
		protected var mi_counter: int = 0;

		function TurbulenceCurveRenderer(g: Graphics,
				f_thickness: Number = 2.0, i_color: uint = 0x000000, f_alpha: Number = 1.0)
		{
			super(g);
			mf_thickness = f_thickness;
			mi_color = i_color;
			mf_alpha = f_alpha;
		}

		override public function started(x: Number, y: Number): void
		{
			super.started(x, y);
			m_graphics.lineStyle(mf_thickness, mi_color, mf_alpha);
			mi_counter = 0;
		}

		override protected function mark(f_x: Number, f_y: Number): void
		{
			++mi_counter;
			nextMarkDistance += 7;
		}

		override protected function betweenMarkLineTo(f_x: Number, f_y: Number): void
		{
			if (mi_counter % 2 == 0)
				m_graphics.lineTo(f_x, f_y);
			super.moveTo(f_x, f_y);
		}
	}
}
