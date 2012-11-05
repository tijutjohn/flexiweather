package com.iblsoft.flexiweather.utils
{
	import flash.display.Graphics;
	import flash.geom.Point;

	public class DistanceMarkingCurveRenderer extends GraphicsCurveRenderer
	{
		// runtime variables
		protected var mf_currentDistance: Number = 0;
		protected var mf_lastMarkDistance: Number = -1000;
		protected var mf_nextMarkDistance: Number = 10;

		public function DistanceMarkingCurveRenderer(graphics: Graphics)
		{
			super(graphics);
		}

		override public function lineTo(x: Number, y: Number): void
		{
			var f_dx: Number = x - m_lastX;
			var f_dy: Number = y - m_lastY;
			var f_sx: Number = m_lastX;
			var f_sy: Number = m_lastY;
			var f_len: Number = Math.sqrt(f_dx * f_dx + f_dy * f_dy);
			var f_distanceFinal: Number = mf_currentDistance + f_len;
			var f_distanceStart: Number = mf_currentDistance;
			var f_nextMarkDistance: Number = mf_nextMarkDistance;
			while (f_distanceStart < f_nextMarkDistance && f_nextMarkDistance <= f_distanceFinal && mf_currentDistance < f_distanceFinal)
			{
				var f_ratio: Number = (f_nextMarkDistance - f_distanceStart) / f_len;
				mf_currentDistance = f_distanceStart + f_ratio * f_len;
				var f_x: Number = f_sx + f_dx * f_ratio;
				var f_y: Number = f_sy + f_dy * f_ratio;
				var f_xPrev: Number = f_sx + f_dx * (f_ratio - 0.01);
				var f_yPrev: Number = f_sy + f_dy * (f_ratio - 0.01);
				betweenMarkLineTo(f_x, f_y);
				mf_nextMarkDistance = mf_currentDistance;
				mark(f_x, f_y);
				f_nextMarkDistance = mf_nextMarkDistance;
			}
			mf_currentDistance = f_distanceFinal;
			betweenMarkLineTo(x, y);
		}

		override public function curveTo(controlX: Number, controlY: Number, anchorX: Number, anchorY: Number): void
		{
			CubicBezier.drawCurve(this, new Point(m_lastX, m_lastY), new Point(controlX, controlY), new Point(controlX, controlY), new Point(anchorX, anchorY));
		}

		// API to be reimplemented in derived classes
		/**
		 * Default implemnetation which just draw a line.
		 * Reimplement this method, it's not necessary to call this one.
		 **/
		protected function betweenMarkLineTo(x: Number, y: Number): void
		{
			super.lineTo(x, y);
		}

		/**
		 * Default implemetation which creates a mark each 10 pixels.
		 * Reimplement this method, it's not necessary to call this one.
		 **/
		protected function mark(x: Number, y: Number): void
		{
			nextMarkDistance += 10;
		}

		// getters & setters
		public function set nextMarkDistance(f: Number): void
		{
			if (f < mf_nextMarkDistance)
				throw new Error("Curve distance marks must form an increasing sequence!");
			mf_nextMarkDistance = f;
		}

		public function get nextMarkDistance(): Number
		{
			return mf_nextMarkDistance;
		}

		public function get walkedDistance(): Number
		{
			return mf_currentDistance;
		}
	}
}
