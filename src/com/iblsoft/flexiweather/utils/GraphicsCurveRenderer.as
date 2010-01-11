package com.iblsoft.flexiweather.utils
{
	import flash.display.Graphics;
	import flash.geom.Point;

	/**
	 * Simple implementation of ICurveRenderer over flash.display.Graphics .
	 **/
	public class GraphicsCurveRenderer implements ICurveRenderer
	{
		protected var m_graphics: Graphics;
		protected var m_lastX: Number = 0;
		protected var m_lastY: Number = 0;
		
		public function GraphicsCurveRenderer(graphics: Graphics)
		{
			m_graphics = graphics;
		}

		public function start(x: Number, y: Number): void
		{}

		public function finish(x: Number, y: Number): void
		{}

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
	}
}