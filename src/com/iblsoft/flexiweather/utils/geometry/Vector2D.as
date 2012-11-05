package com.iblsoft.flexiweather.utils.geometry
{
	import flash.geom.Point;

	public class Vector2D extends Point
	{
		public function Vector2D(x: Number, y: Number)
		{
			super(x, y);
		}

		/**
		 * Returns scalar product of "this . v"
		 **/
		public function dot(v: Vector2D): Number
		{
			return x * v.x + y * v.y;
		}

		public function times(f_scale: Number): Vector2D
		{
			return new Vector2D(x * f_scale, y * f_scale);
		}
	}
}
