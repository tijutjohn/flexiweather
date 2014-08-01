package com.iblsoft.flexiweather.ogc.editable.data
{
	import com.iblsoft.flexiweather.utils.geometry.LineSegment;
	
	public class FeatureDataLineSegment extends LineSegment
	{
		// true if first point (x1,y1) is original editable point created by user input and not by interpolation
		public var firstEditablePoint: Boolean;
		
		// true if second point (x1,y1) is original editable point created by user input and not by interpolation
		public var secondEditablePoint: Boolean;
		
		public function FeatureDataLineSegment(x1:Number, y1:Number, x2:Number, y2:Number, bFirstEditablePoint: Boolean = false, bSecondEditablePoint: Boolean = false)
		{
			super(x1, y1, x2, y2);
			
			firstEditablePoint = bFirstEditablePoint;
			secondEditablePoint = bSecondEditablePoint;
		}
	}
}