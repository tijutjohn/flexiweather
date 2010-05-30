package com.iblsoft.flexiweather.symbology
{
	import com.iblsoft.flexiweather.utils.CubicBezier;
	import com.iblsoft.flexiweather.utils.GraphicsCurveRenderer;
	
	import flash.display.Graphics;
	import flash.geom.Point;

	public class StyledLineCurveRenderer extends GraphicsCurveRenderer
	{
		public static const STYLE_SOLID: String = "Solid";
		public static const DASHED_SOLID: String = "Dashed";

		// style variables
		protected var mf_thickness: Number;
		protected var mi_color: uint;
		protected var mf_alpha: Number;
		protected var ms_style: String;
	
		// runtime variables
		protected var mf_currentDistance: Number = 0; 
		protected var mf_lastMarkDistance: Number = -1000; 
		protected var mf_markStep: Number = 6;
		protected var mi_counter: int = 0;
		
		function StyledLineCurveRenderer(g: Graphics,
			f_thickness: Number, i_color: uint, f_alpha: Number,
			s_style: String)
		{
			super(g);
			mf_thickness = f_thickness;
			mi_color = i_color;
			mf_alpha = f_alpha;
			ms_style = s_style;
			mf_markStep = f_thickness * 6;
		}
	
		override public function started(x: Number, y: Number): void
		{
			m_graphics.lineStyle(mf_thickness, mi_color, mf_alpha);
			m_graphics.moveTo(x, y);
			mi_counter = -1;
			mark();
		}
	
		override public function finished(x: Number, y: Number): void
		{
			m_graphics.moveTo(x, y);
		}
	
		override public function moveTo(x: Number, y: Number): void
		{
			m_lastX = x;
			m_lastY = y;
		}
	
		override public function lineTo(x: Number, y: Number): void
		{
			var f_dx: Number = x - m_lastX;
			var f_dy: Number = y - m_lastY;
			var f_sx: Number = m_lastX;
			var f_sy: Number = m_lastY;
			var f_len: Number = Math.sqrt(f_dx * f_dx + f_dy * f_dy);
	
			m_lastX = x;
			m_lastY = y;
	
			if(false && f_len < 1) {
				if(mf_lastMarkDistance + mf_markStep < mf_currentDistance) {
					mf_currentDistance += f_len;
					mf_lastMarkDistance = mf_currentDistance;
					mark();
				}
				else
					mf_currentDistance += f_len;
			}
			else {
				var f_distanceFinal: Number = mf_currentDistance + f_len;
				var f_distanceStart: Number = mf_currentDistance;
	
				var f_nextMarkDistance: Number =
						mf_lastMarkDistance < 0.0 ? 0.0 : (mf_lastMarkDistance + mf_markStep);
				while((			f_distanceStart < f_nextMarkDistance
							&&	f_nextMarkDistance <= f_distanceFinal
							&&	mf_markStep > 0)
						|| f_nextMarkDistance == 0.0)
				{
					var f_ratio: Number = (f_nextMarkDistance - f_distanceStart) / f_len;
					mf_currentDistance = f_distanceStart + f_ratio * f_len;
					
					var f_x: Number = f_sx + f_dx * f_ratio;
					var f_y: Number = f_sy + f_dy * f_ratio;
					var f_xPrev: Number = f_sx + f_dx * (f_ratio - 0.01); 
					var f_yPrev: Number = f_sy + f_dy * (f_ratio - 0.01);
					_lineTo(f_x, f_y);
					mark();
					
					mf_lastMarkDistance = f_nextMarkDistance;
					f_nextMarkDistance += mf_markStep;
				}
				mf_currentDistance = f_distanceFinal;
			}
			_lineTo(x, y); 
		}
	
		override public function curveTo(controlX: Number, controlY: Number, anchorX: Number, anchorY: Number): void
		{
			CubicBezier.drawCurve(this,
					new Point(m_lastX, m_lastY),
					new Point(controlX, controlY),
					new Point(controlX, controlY),
					new Point(anchorX, anchorY));
		}
		
		protected function mark(): void
		{
			++mi_counter;
		}
		
		protected function _lineTo(f_x: Number, f_y: Number): void
		{
			switch(ms_style)
			{
			case "Solid":
			default:
				m_graphics.lineTo(f_x, f_y);
				break;
			case "Dashed":
				if(mi_counter % 2 == 0) {
					m_graphics.lineTo(f_x, f_y);
				}
				else {
					m_graphics.moveTo(f_x, f_y);
				}
				break;
			}
			m_lastX = f_x;
			m_lastY = f_y;
		}
	}
}