package com.iblsoft.flexiweather.utils
{
	import flash.geom.Point;

	/**
	 * Implementation of ICurveRenderer which renders convers a smooth curve spline into
	 * an Array of CurveLineSegment objects.
	 **/
	public class CurveLineSegmentRenderer implements ICurveRenderer
	{
		private var ml_segments: Array = [];
		private var m_lastX: Number;
		private var m_lastY: Number;
		public var mi_originatingSegmentIndex: uint = 0;

		public function CurveLineSegmentRenderer(): void
		{
		}

		public function start(x: Number, y: Number): void
		{
		}

		public function finish(x: Number, y: Number): void
		{
//			++mi_originatingSegmentIndex;
		}

		public function moveTo(x: Number, y: Number): void
		{
			m_lastX = x;
			m_lastY = y;
		}

		public function lineTo(x: Number, y: Number): void
		{
			
			ml_segments.push(new CurveLineSegment(mi_originatingSegmentIndex, m_lastX, m_lastY, x, y));
			m_lastX = x;
			m_lastY = y;
			mi_originatingSegmentIndex++;
		}

		public function curveTo(controlX: Number, controlY: Number, anchorX: Number, anchorY: Number): void
		{
			CubicBezier.drawCurve(this,
					new Point(m_lastX, m_lastY),
					new Point(controlX, controlY),
					new Point(controlX, controlY),
					new Point(anchorX, anchorY));
			m_lastX = anchorX;
			m_lastY = anchorY;
		}

		public function get segments(): Array
		{
			return ml_segments;
		}
	}
}
