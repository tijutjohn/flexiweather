package com.iblsoft.flexiweather.ogc.editable.data.jetstream
{
	import com.iblsoft.flexiweather.proj.Coord;

	import flash.events.EventDispatcher;
	import flash.geom.Point;

	public class WindBarb extends EventDispatcher
	{
		private var _invalidated: Boolean;

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
			invalidate();
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
			if (point)
				validate();
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

		public function isValid(): Boolean
		{
			return !_invalidated;
		}
		private function validate(): void
		{
			_invalidated = false;
		}
		public function invalidate(): void
		{
			_invalidated = true;
		}

		/**
		 * This functionality needs to be down for moving windbarbs through dateline
		 */
		private var _needToCaptureMouse: Boolean
		public function get needToCaptureMouse(): Boolean
		{
			return _needToCaptureMouse;
		}
		public function captureMouse(): void
		{
			_needToCaptureMouse = true;
		}
		public function captureMouseDone(): void
		{
			_needToCaptureMouse = false;
		}

		override public function toString(): String
		{
			return "WindBard: " + point + " c: " + _coordinate + " invalidated: " + _invalidated; // ["+below+"/"+above+"]";
		}

	}
}