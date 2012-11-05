package com.iblsoft.flexiweather.utils
{
	import com.iblsoft.flexiweather.utils.geometry.LineSegment;

	/** Helper class used for interpolation of smooth curve/spline into series of line segments */
	public class CurveLineSegment extends LineSegment
	{
		public function CurveLineSegment(
				i_originatingSegmentIndex: uint,
				x1: Number, y1: Number, x2: Number, y2: Number): void
		{
			super(x1, y1, x2, y2);
			mi_originatingSegmentIndex = i_originatingSegmentIndex;
		}
		public var mi_originatingSegmentIndex: uint;
	}
}
