package com.iblsoft.flexiweather.ogc
{

	public class Version
	{
		internal var _v1: int;
		internal var _v2: int;
		internal var _v3: int;

		public function Version(v1: int, v2: int, v3: int)
		{
			_v1 = v1;
			_v2 = v2;
			_v3 = v3;
		}

		public function equals(v1: int, v2: int, v3: int): Boolean
		{
			return _v1 == v1 && _v2 == v2 && _v3 == v3;
		}

		public function equalsVersion(v: Version): Boolean
		{
			return equals(v._v1, v._v2, v._v3);
		}

		public function isLessThan(v1: int, v2: int, v3: int): Boolean
		{
			if (_v1 < v1)
				return true;
			if (_v1 > v1)
				return false;
			if (_v2 < v2)
				return true;
			if (_v2 > v2)
				return false;
			if (_v3 < v3)
				return true;
			if (_v3 > v3)
				return false;
			return false;
		}

		public function isLessThanVersion(other: Version): Boolean
		{
			return isLessThan(other._v1, other._v2, other._v3);
		}

		public function toString(): String
		{
			return _v1 + "." + _v2 + "." + _v3;
		}

		public static function fromString(s: String): Version
		{
			var a: Array = s.match(/\A(\d+)\.(\d+)\.(\d+)\Z/);
			if (a == null)
				return new Version(0, 0, 0);
			return new Version(int(a[1]), int(a[2]), int(a[3]));
		}
	}
}
