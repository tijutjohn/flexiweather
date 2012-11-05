package com.iblsoft.flexiweather.symbology
{
	import flash.geom.Point;
	import com.iblsoft.flexiweather.utils.CubicBezier;
	import com.iblsoft.flexiweather.utils.DistanceMarkingCurveRenderer;
	import flash.display.Graphics;

	public class CloudCurveRenderer extends DistanceMarkingCurveRenderer
	{
		// style variables
		protected var mf_thickness: Number;
		protected var mi_color: uint;
		protected var mf_alpha: Number;
		// runtime variables
		protected var ml_marks: Array;

		function CloudCurveRenderer(g: Graphics,
				f_thickness: Number = 2.0, i_color: uint = 0x00ff00, f_alpha: Number = 1.0)
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
			ml_marks = [new Point(x, y)];
		}

		override public function finished(x: Number, y: Number): void
		{
			super.finished(x, y);
			var ptPrev: Point = null;
			for each (var pt: Point in ml_marks)
			{
				if (ptPrev == null)
				{
					m_graphics.moveTo(pt.x, pt.y);
					ptPrev = pt;
				}
				else
				{
					var ptDiff: Point = pt.subtract(ptPrev);
					var ptNormal: Point = new Point(-ptDiff.y, ptDiff.x);
					ptNormal.normalize(9);
					ptDiff.x /= 2.0;
					ptDiff.y /= 2.0;
					var ptControl: Point = ptPrev.add(ptDiff).add(ptNormal);
					m_graphics.moveTo(ptPrev.x, ptPrev.y);
					m_graphics.curveTo(ptControl.x, ptControl.y, pt.x, pt.y);
					ptPrev = pt;
				}
			}
			m_graphics.lineTo(x, y);
		}

		override protected function mark(f_x: Number, f_y: Number): void
		{
			var pt: Point = new Point(f_x, f_y);
			ml_marks.push(pt);
			nextMarkDistance += 14;
		}

		override protected function betweenMarkLineTo(f_x: Number, f_y: Number): void
		{
			super.moveTo(f_x, f_y);
		}
	}
}
