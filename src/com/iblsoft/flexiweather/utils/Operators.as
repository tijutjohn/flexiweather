package com.iblsoft.flexiweather.utils
{
	public class Operators
	{
		public static function equalsStrictly(o1: Object, o2: Object): Boolean
		{
			return o1 === o2;
		}

		public static function equals(o1: Object, o2: Object): Boolean
		{
			return o1 == o2;
		}

		public static function equalsByLabels(o1: Object, o2: Object): Boolean
		{
			if(!o1.hasOwnProperty('label') || !o2.hasOwnProperty('label'))
				return false;
			return o1.label == o2.label;
		}
	}
}