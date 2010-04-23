package com.iblsoft.flexiweather.utils
{
	/** Helper class used for interpolation of smooth curve/spline into series of line segments */
	public class CurveLineSegment
	{
		public function CurveLineSegment(
				i_originatingSegmentIndex: uint,
				x1: Number, y1: Number, x2: Number, y2: Number): void
		{
			mi_originatingSegmentIndex = i_originatingSegmentIndex;
			m_x1 = x1;
			m_y1 = y1;
			m_x2 = x2;
			m_y2 = y2;
		}
	
		public var mi_originatingSegmentIndex: uint;
		public var m_x1: Number;
		public var m_y1: Number;
		public var m_x2: Number;
		public var m_y2: Number;
	}
}