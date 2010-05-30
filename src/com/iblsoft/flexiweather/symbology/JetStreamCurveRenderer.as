package com.iblsoft.flexiweather.symbology
{
	import com.iblsoft.flexiweather.utils.GraphicsCurveRenderer;
	import flash.display.Graphics;
	import flash.geom.Point;
	import com.iblsoft.flexiweather.utils.CubicBezier;
	
	public class JetStreamCurveRenderer extends GraphicsCurveRenderer
	{
		// style variables
		protected var mf_thickness: Number;
		protected var mi_color: uint;
		protected var mf_alpha: Number;
		
		protected var mf_lastDX: Number = 0; 
		protected var mf_lastDY: Number = 0; 
	
		function JetStreamCurveRenderer(g: Graphics,
			f_thickness: Number, i_color: uint, f_alpha: Number)
		{
			super(g);
			mf_thickness = f_thickness;
			mi_color = i_color;
			mf_alpha = f_alpha;
		}
	
		override public function started(x: Number, y: Number): void
		{
			m_graphics.lineStyle(mf_thickness, mi_color, mf_alpha);
			m_graphics.moveTo(x, y);
			mf_lastDX = 0;
			mf_lastDY = 0;
		}
	
		override public function finished(x: Number, y: Number): void
		{
			var p: Point = new Point(mf_lastDX, mf_lastDY);
			p.normalize(1);
			var pp: Point = new Point(p.y, -p.x);
			m_graphics.lineStyle(1, mi_color, mf_alpha);
			pp.x *= 6;
			pp.y *= 6;
			m_graphics.beginFill(mi_color, mf_alpha);
			m_graphics.moveTo(x + pp.x, y + pp.y);
			m_graphics.lineTo(x - pp.x, y - pp.y);
			m_graphics.lineTo(x + p.x * 10, y + p.y * 10);
			m_graphics.lineTo(x + pp.x, y + pp.y);
			m_graphics.endFill();
		}
	
		override public function moveTo(x: Number, y: Number): void
		{
			super.moveTo(x, y);
		}
	
		override public function lineTo(x: Number, y: Number): void
		{
			if(x != m_lastX || y != m_lastY) { 
				mf_lastDX = x - m_lastX;
				mf_lastDY = y - m_lastY;
			}
			super.lineTo(x, y);
		}
	
		override public function curveTo(controlX: Number, controlY: Number, anchorX: Number, anchorY: Number): void
		{
			//super.curveTo(controlX, controlY, anchorX, anchorY);
			CubicBezier.drawCurve(this,
					new Point(m_lastX, m_lastY),
					new Point(controlX, controlY),
					new Point(controlX, controlY),
					new Point(anchorX, anchorY));
		}
	}
}