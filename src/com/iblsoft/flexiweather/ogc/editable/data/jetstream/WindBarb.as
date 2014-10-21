package com.iblsoft.flexiweather.ogc.editable.data.jetstream
{
	import com.iblsoft.flexiweather.proj.Coord;
	
	import flash.events.EventDispatcher;
	import flash.geom.Point;

	public class WindBarb extends EventDispatcher
	{
		private var _coordinate: Coord;
		
		private var _point: Point;
		
		public var maxWindPoint: int;
		
		public var windSpeed: int;
		
		public var flightLevel: int;
		
		public var below: int;
		
		public var above: int;
		
		/**
		 * 
		 */
		public function WindBarb()
		{
			super();
		}


		public function get coordinate():Coord
		{
			return _coordinate;
		}

		public function set coordinate(value:Coord):void
		{
			_coordinate = value;
		}

		public function get point():Point
		{
			return _point;
		}

		public function set point(value:Point):void
		{
			_point = value;
		}
		
		public function clone(): WindBarb
		{
			var wb: WindBarb = new WindBarb();
			wb.coordinate = coordinate;
			wb.point = point;
			wb.maxWindPoint = maxWindPoint;
			wb.windSpeed = windSpeed;
			wb.flightLevel = flightLevel;
			wb.below = below;
			wb.above = above;
			
			return wb;
		}
		
		override public function toString(): String
		{
			return "WindBard: " + point + " ["+below+"/"+above+"]";
		}

	}
}