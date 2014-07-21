package com.iblsoft.flexiweather.ogc.editable.data
{
	import flash.geom.Point;
	
	public class FeatureDataPoint extends Point
	{
		public var movablePoint: MoveablePoint;
		public var isReflectionEdgePoint:Boolean;
		
		public function FeatureDataPoint(x:Number=0, y:Number=0)
		{
			super(x, y);
		}
		
		public function addPoint(point: FeatureDataPoint): void
		{
			x += point.x;
			y += point.y;
		}
		override public function clone(): Point
		{
			var fdp: FeatureDataPoint = new FeatureDataPoint(x,y);
			fdp.movablePoint = movablePoint;
			fdp.isReflectionEdgePoint = isReflectionEdgePoint;
			
			return fdp;
		}
	}
}