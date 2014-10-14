package com.iblsoft.flexiweather.ogc.editable.data
{
	import com.iblsoft.flexiweather.utils.geometry.LineSegment;
	
	public class FeatureDataLineSegment extends LineSegment
	{
		/**
		 * Used for lines which should not be visible (outside of ViewBBox) 
		 */		
		public var visible: Boolean;
		
		// true if first point (x1,y1) is original editable point created by user input and not by interpolation
		public var firstEditablePoint: Boolean;
		
		// true if second point (x1,y1) is original editable point created by user input and not by interpolation
		public var secondEditablePoint: Boolean;
		
		public function FeatureDataLineSegment(x1:Number, y1:Number, x2:Number, y2:Number, bVisible: Boolean, bFirstEditablePoint: Boolean = false, bSecondEditablePoint: Boolean = false)
		{
			super(x1, y1, x2, y2);
			
			visible = bVisible;
			
			firstEditablePoint = bFirstEditablePoint;
			secondEditablePoint = bSecondEditablePoint;
		}
	}
}