package com.iblsoft.flexiweather.utils
{

	public class Operators
	{
		public static function getOperatorForDimension(s_dimName: String): Function
		{
			var fnc: Function = Operators.equalsStrictly;
			s_dimName = s_dimName.toLowerCase();

			switch (s_dimName)
			{
				case 'run':
				case 'frame':
					fnc = Operators.equalsByData;
					break;
				case 'elevation':
				case 'level':
					fnc = Operators.equalsByLabels;
					break;
			}
			return fnc;
		}

		public static function equalsStrictly(o1: Object, o2: Object): Boolean
		{
			return o1 === o2;
		}

		public static function equals(o1: Object, o2: Object): Boolean
		{
			return o1 == o2;
		}

		public static function equalsByDataWithUnit(o1: Object, o2: Object): Boolean
		{
			if (!o1.hasOwnProperty('dataWithUnit') || !o2.hasOwnProperty('dataWithUnit'))
				return false;
			return o1.dataWithUnit == o2.dataWithUnit;
		}
		public static function equalsByLabels(o1: Object, o2: Object): Boolean
		{
			if (!o1.hasOwnProperty('label') || !o2.hasOwnProperty('label'))
				return false;
			return o1.label == o2.label;
		}
		public static function equalsByData(o1: Object, o2: Object): Boolean
		{
			if (!o1.hasOwnProperty('data') || !o2.hasOwnProperty('data'))
				return false;
			return o1.data == o2.data;
		}
		public static function equalsByDates(d1: Date, d2: Date): Boolean
		{
			if (!(d1 is Date) || !(d2 is Date))
				return false;
			return d1.time == d2.time;
		}
	}
}
