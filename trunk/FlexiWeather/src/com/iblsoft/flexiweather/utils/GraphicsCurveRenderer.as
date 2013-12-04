package com.iblsoft.flexiweather.utils
{
	import flash.display.Graphics;
	import mx.controls.NumericStepper;

	/**
	 * Simple implementation of ICurveRenderer over flash.display.Graphics .
	 **/
	public class GraphicsCurveRenderer implements ICurveRenderer
	{
		protected var m_graphics: Graphics;
		protected var m_lastX: Number = 0;
		protected var m_lastY: Number = 0;
		protected var mi_recursionDepth: uint = 0;

		public function GraphicsCurveRenderer(graphics: Graphics)
		{
			m_graphics = graphics;
		}

		public final function start(x: Number, y: Number): void
		{
			if (mi_recursionDepth == 0)
				started(x, y);
			++mi_recursionDepth;
		}

		public final function finish(x: Number, y: Number): void
		{
			--mi_recursionDepth;
			if (mi_recursionDepth == 0)
				finished(x, y);
		}

		public function moveTo(x: Number, y: Number): void
		{
			m_graphics.moveTo(x, y);
			m_lastX = x;
			m_lastY = y;
		}

		public function lineTo(x: Number, y: Number): void
		{
			m_graphics.lineTo(x, y);
			m_lastX = x;
			m_lastY = y;
		}

		public function curveTo(controlX: Number, controlY: Number, anchorX: Number, anchorY: Number): void
		{
			m_graphics.curveTo(controlX, controlY, anchorX, anchorY);
			m_lastX = anchorX;
			m_lastY = anchorY;
		}

		public function started(x: Number, y: Number): void
		{
		}

		public function finished(x: Number, y: Number): void
		{
		}
	}
}
