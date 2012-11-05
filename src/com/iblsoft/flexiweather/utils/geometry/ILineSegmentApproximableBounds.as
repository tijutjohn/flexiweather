package com.iblsoft.flexiweather.utils.geometry
{
	import flash.display.DisplayObject;

	/** Can be implemented by any DisplayObject whose bounds are approximable using line segments. */
	public interface ILineSegmentApproximableBounds
	{
		/**
		 * Returns array of LineSegment object which aproximate the bounds of this object.
		 **/
		function getLineSegmentApproximationOfBounds(): Array;
	}
}
