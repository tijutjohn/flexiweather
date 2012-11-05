package com.iblsoft.flexiweather.utils
{

	public class DateTimeValidator
	{
		public const MIN_YEAR: uint = 1582
		public const MAX_YEAR: uint = 2999
		public const MIN_MONTH: uint = 1
		public const MAX_MONTH: uint = 12
		public const MIN_DAY: uint = 1
		public const MAX_HOUR: uint = 23
		public const MAX_MINUTE: uint = 59
		public const MAX_SECOND: uint = 59
		public const MAX_MILLIS: uint = 999

		/**
		 * Validate year = 1582..2999, month = 1..12, day = 1..n where n is 31, or 30 or 29/28 depending on month and leap year
		 */
		public function validateDate(year: uint, month: uint, day: uint): Boolean
		{
			if (year < MIN_YEAR || year > MAX_YEAR)
				throw(new Error("invalid year, must be between " + MIN_YEAR + " and " + MAX_YEAR))
			if (month < MIN_MONTH || month > MAX_MONTH)
				throw(new Error("invalid month, must be between " + MIN_MONTH + " and " + MAX_MONTH))
			if (day < MIN_DAY)
				throw(new Error("invalid day, must be > 0"))
			switch (month)
			{
				case 4, 6, 9, 11: // apr, june, sep, nov
				{
					if (day > 31)
						throw(new Error("invalid days " + day + " for month " + month))
					break;
				}
				case 2: // feb
				{
					var leap: Boolean = ((year % 4 == 0) && (!(year % 100 == 0) || (year % 400 == 0)))
					var max_days: uint = (leap ? 29 : 28)
					if (day > max_days)
						throw(new Error("invalid days " + day + " for month " + month))
					break;
				}
				default:
				{
					if (day > 31)
						throw(new Error("invalid days " + day + " for month " + month))
				}
			}
			return true;
		}

		/**
		 * validate for 0..23, 0..59, 0..59, 0..999
		 */
		public function validateTime(hour: uint, minute: uint, second: uint, millis: uint): Boolean
		{
			if (hour < 0 || hour > MAX_HOUR)
				throw(new Error("invalid hours: " + hour))
			if (minute < 0 || minute > MAX_MINUTE)
				throw(new Error("invalid minutes: " + minute))
			if (second < 0 || second > MAX_SECOND)
				throw(new Error("invalid seconds: " + second))
			if (millis < 0 || millis > MAX_MILLIS)
				throw(new Error("invalid milliseconds: " + millis))
			return true
		}
	}
}
