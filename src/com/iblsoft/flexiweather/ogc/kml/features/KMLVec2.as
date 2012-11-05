package com.iblsoft.flexiweather.ogc.kml.features
{

	public class KMLVec2
	{
		private var _x: Number;
		private var _y: Number;
		private var _xunits: String;
		private var _yunits: String;

		public function KMLVec2(x: XML)
		{
			this._x = x.@x;
			this._y = x.@y;
			this._xunits = x.@xunits;
			this._yunits = x.@yunits;
		}

		public function get x(): Number
		{
			return _x;
		}

		public function get y(): Number
		{
			return _y;
		}

		public function get xunits(): String
		{
			return _xunits;
		}

		public function get yunits(): String
		{
			return _yunits;
		}

		public function toString(): String
		{
			return "KMLVec x: " + x + " y: " + y + " xUnits: " + xunits + " yUnits: " + yunits;
		}
	}
}
