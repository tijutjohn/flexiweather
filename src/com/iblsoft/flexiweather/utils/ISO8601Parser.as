package com.iblsoft.flexiweather.utils
{

	public class ISO8601Parser
	{
		public var m_validator: DateTimeValidator = new DateTimeValidator();
		private static var sm_defaultParser: ISO8601Parser = new ISO8601Parser();
		protected var m_patternYYYYMMDD: RegExp = /\A(\d{4})-(\d{2})-(\d{2}$)\Z/;
		protected var m_patternHHMMSSsss: RegExp = /\A(\d{2})(:(\d{2})(:(\d{2})(\.(\d{3}))?)?)?Z?\Z/;
		protected var m_regExpDurationLike: RegExp = /\AP.*/;
		protected var m_regExpDuration: RegExp = /\AP((\d+)D)?(T((\d+)H)?((\d+)M)?((\d+)S)?)?\Z/;

		/**
		 * UTC DateTime has a format of YYYY-MM-DDThh:mm:ss.SSS without time zone offset
		 */
		public function parseDateTime(s: String): Date
		{
			if (s == null)
				return null;
			var ss: Array = s.split("T", 2); // separate the date and time components
			if (ss.length == 0)
				throw new Error("bad date format: " + s);
			var date: Date = parseDate(ss[0]);
			if (ss.length > 1)
			{
				var time: Date = parseTime(ss[1]);
				date.hoursUTC = time.hours;
				date.minutesUTC = time.minutes;
				date.secondsUTC = time.seconds;
				date.millisecondsUTC = time.milliseconds;
			}
			else
			{
				date.hoursUTC = 0;
				date.minutesUTC = 0;
				date.secondsUTC = 0;
				date.millisecondsUTC = 0;
			}
			return date;
		}

		public function parseDate(str: String): Date
		{
			if (str == null)
				throw new Error("invalid format, must be YYYY-MM-DD");
			var result: Object = m_patternYYYYMMDD.exec(str);
			if (result != null)
			{
				var i_year: uint = uint(result[1]);
				var i_month: uint = uint(result[2]);
				var i_day: uint = uint(result[3]);
				try
				{
					m_validator.validateDate(i_year, i_month, i_day);
				}
				catch (e: Error)
				{
					throw new Error("invalid date format: " + str + "\n\t" + e.message);
				}
				var date: Date = new Date();
				date.setUTCHours(0, 0, 0, 0);
				date.setUTCFullYear(i_year, i_month - 1, i_day);
				return date;
			}
			throw new Error("unsupported date format: '" + str + "'");
		}

		public function parseTime(str: String): Date
		{
			if (str == null)
				return null;
			if (str == null)
				throw new Error("invalid format, must be hh:mm:ss.SSS");
			var result: Object = m_patternHHMMSSsss.exec(str);
			if (result == null)
				throw new Error("unsupported time format: '" + str + "'");
			var i_hour: uint = uint(result[1]);
			var i_minute: uint = uint(result[3]);
			var i_second: uint = uint(result[5]);
			var i_millis: uint = uint(result[7]);
			try
			{
				m_validator.validateTime(i_hour, i_minute, i_second, i_millis);
			}
			catch (e: Error)
			{
				throw new Error("invalid time format: " + str + "\n\t" + e.message);
			}
			var date: Date = new Date(0, 0, 0, i_hour, i_minute, i_second, i_millis);
			return date;
		}

		public function looksLikeDuration(s: String): Boolean
		{
			return s.match(m_regExpDurationLike) != null;
		}

		public function parseDuration(s: String): Duration
		{
			if (s == null || s == '')
				return null;
			//throw new Error("invalid format, must be in ISO8601 duration form PddDThhHmmMssS");
			var result: Object = m_regExpDuration.exec(s);
			if (result == null)
				throw new Error("unsupported duration format: '" + s + "'");
			var d: Duration = new Duration();
			if (result[2])
				d.days = uint(result[2]);
			if (result[5])
				d.hours = uint(result[5]);
			if (result[7])
				d.minutes = uint(result[7]);
			if (result[9])
				d.seconds = uint(result[9]);
			return d;
		}

		public static function dateToDateString(dt: Date): String
		{
			var s: String;
			s = dt.fullYearUTC + "-" + (dt.monthUTC + 1 < 10 ? "0" : "") + (dt.monthUTC + 1) + "-" + (dt.dateUTC < 10 ? "0" : "") + (dt.dateUTC);
			return s;
		}

		public static function dateToString(dt: Date): String
		{
			var s: String;
			s = dt.fullYearUTC + "-" + (dt.monthUTC + 1 < 10 ? "0" : "") + (dt.monthUTC + 1) + "-" + (dt.dateUTC < 10 ? "0" : "") + (dt.dateUTC) + "T" + (dt.hoursUTC < 10 ? "0" : "") + dt.hoursUTC + ":" + (dt.minutesUTC < 10 ? "0" : "") + dt.minutesUTC + ":" + (dt.secondsUTC < 10 ? "0" : "") + dt.secondsUTC;
			if (dt.millisecondsUTC > 0)
				s += "." + (dt.millisecondsUTC < 10 ? "0" : "") + (dt.millisecondsUTC < 100 ? "0" : "") + dt.millisecondsUTC;
			s += "Z";
			return s;
		}

		public static function stringToDate(s: String): Date
		{
			//FIXME there were problem, that string was empty, do I did this basic fix. Is it needed to do something else
			if (s == '')
				return new Date();
			return sm_defaultParser.parseDateTime(s);
		}

		public static function stringToDuration(s: String): Duration
		{
			return sm_defaultParser.parseDuration(s);
		}
	}
}
