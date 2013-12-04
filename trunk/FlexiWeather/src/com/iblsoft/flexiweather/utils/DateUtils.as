package com.iblsoft.flexiweather.utils
{
	import mx.formatters.DateBase;

	public class DateUtils
	{
		public static function dayOfTheWeek(dt: Date, b_useUTC: Boolean = true): String
		{
//			return (DateBase.dayNamesLong[dt.getDay()]);
			return (DateBase.dayNamesLong[b_useUTC ? dt.dayUTC : dt.day]);
		}

		public static function dayOfTheWeekAbbr(dt: Date, b_useUTC: Boolean = true): String
		{
//			return (DateBase.dayNamesShort[dt.getDay()]);
			return (DateBase.dayNamesShort[b_useUTC ? dt.dayUTC : dt.day]);
		}

		public static function monthName(dt: Date, b_useUTC: Boolean = true): String
		{
//			return (DateBase.monthNamesLong[dt.getMonth()]);
			return (DateBase.monthNamesLong[b_useUTC ? dt.monthUTC : dt.month]);
		}

		public static function monthNameAbbr(dt: Date, b_useUTC: Boolean = true): String
		{
//			return (DateBase.monthNamesShort[dt.getMonth()]);
			return (DateBase.monthNamesShort[b_useUTC ? dt.monthUTC : dt.month]);
		}

		// Just the following directives are currently supported:
		// %Y, %m, %d, %H, %M, %S, %a, %A, %b, %B, %%
		public static function strftime(dt: Date, s_format: String, b_useUTC: Boolean = true): String
		{
			if (!dt)
				return '';
			function convertDirective(s_directive: String, i_index: int, s_str: String): String
			{
				function twoDigitsStr(i_number: int): String
				{
					if (i_number < 10)
						return "0" + String(i_number);
					return String(i_number);
				}
				function fourDigitsStr(i_number: int): String
				{
					if (i_number < 10)
						return "000" + String(i_number);
					else if (i_number < 100)
						return "00" + String(i_number);
					else if (i_number < 1000)
						return "0" + String(i_number);
					return String(i_number);
				}
				switch (s_directive.charAt(1))
				{
					case "Y":  {return fourDigitsStr(b_useUTC ? dt.fullYearUTC : dt.fullYear);}
					case "m":  {return twoDigitsStr(b_useUTC ? dt.monthUTC + 1 : dt.month + 1);} // months start from 0 
					case "d":  {return twoDigitsStr(b_useUTC ? dt.dateUTC : dt.date);}
					case "H":  {return twoDigitsStr(b_useUTC ? dt.hoursUTC : dt.hours);}
					case "M":  {return twoDigitsStr(b_useUTC ? dt.minutesUTC : dt.minutes);}
					case "S":  {return twoDigitsStr(b_useUTC ? dt.secondsUTC : dt.seconds);}
					case "a":  {return dayOfTheWeekAbbr(dt, b_useUTC);}
					case "A":  {return dayOfTheWeek(dt, b_useUTC);}
					case "b":  {return monthNameAbbr(dt, b_useUTC);}
					case "B":  {return monthName(dt, b_useUTC);}
					case "%":  {return "%";}
					default:  {return s_directive;}
				}
			}
			if (s_format)
			{
				const directivePattern: RegExp = /%./g;
				return s_format.replace(directivePattern, convertDirective);
			}
			return dt.toString();
		}

		public static function strptime(s_datetime: String, s_format: String,
				b_useUTC: Boolean = true): Date
		{
			return parseStrTime(s_datetime, s_format, 0, "", b_useUTC)["date"];
		}

		public static function whichTimeGroup(s_datetime: String, s_format: String, i_position: int, b_useUTC: Boolean = true): String
		{
			return parseStrTime(s_datetime, s_format, i_position, "", b_useUTC)["inGroup"];
		}

		// Just the following directives are currently supported: %Y, %m, %d, %H, %M, %S, %b, %B
		public static function parseStrTime(s_datetime: String, s_format: String,
				i_position: int = 0, s_selectionForGroup: String = "", b_useUTC: Boolean = true): Object
		{
			var year: int = 2000;
			var month: int = 1;
			var day: int = 1;
			var hour: int = 0;
			var min: int = 0;
			var sec: int = 0;
			var ms: int = 0;
			var i_previousPosFormat: int = -1; //previous position in the formatting string
			var i_curPosInput: int = 0; // current position in the input datetime string
			var i_width: int = 0; // width of parsed datetime component
			var i_groupStart: int = -1;
			var i_groupEnd: int = -1;
			var i_nextGroupStart: int = -1;
			var i_nextGroupEnd: int = -1;
			var i_previousGroupStart: int = -1;
			var i_previousGroupEnd: int = -1;
			var s_inGroup: String = "unknown";
			var presentInFormat: Object;
			if (b_useUTC)
			{
				presentInFormat = {"fullYearUTC": false, "monthUTC": false, "dateUTC": false, "hoursUTC": false,
							"minutesUTC": false, "secondsUTC": false};
			}
			else
				presentInFormat = {"fullYear": false, "month": false, "date": false, "hours": false, "minutes": false, "seconds": false};
			var b_inputValid: Boolean = true;
			function parseDirective(s_directive: String, i_curPosFormat: int, s_str: String): String
			{
				function handleTimeGroup(s_timeGroup: String, a_listNames: Array = null): int
				{
					function isDigit(ch: String): Boolean
					{
						return (ch >= '0' && ch <= '9');
					}
					var i_expectedWidth: int = i_width;
					var i_value: int;
					var i: int;
					var s_group: String;
					presentInFormat[s_timeGroup] = true;

					if (a_listNames == null) // Parsing number
					{
						// Parse also numbers which take less digits than expected - adjust the width.
						for (i = 0; i < i_expectedWidth; i++)
						{
							if ((!isDigit(s_datetime.charAt(i_curPosInput + i))))
							{
								i_width = i;
								break;
							}
						}

						// If we expected number, but not present, the input is invalid.
						if (i_width == 0)
						{
							b_inputValid = false;
							return 0;
						}

						s_group = s_datetime.substr(i_curPosInput, i_width);
						if (a_listNames == null)
						{
							i_value = int(s_group);
							var x_value: Number = Number(s_group);
							if (i_value != x_value)
								b_inputValid = false;
						}
					}
					else // Parsing name
					{
						var b_found: Boolean = false;
						s_group = s_datetime.substr(i_curPosInput, i_width);
						for (i = 0; i < a_listNames.length; i++)
						{
							if (a_listNames[i].substr(0, i_width) == s_group)
							{
								i_width = a_listNames[i].length;
								s_group = s_datetime.substr(i_curPosInput, i_width);
								if (s_group == a_listNames[i])
								{
									i_value = i + 1;
									b_found = true;
								}
								break;
							}
						}
						if (!b_found)
							b_inputValid = false;
					}

					// Mark the next time group following the current time group
					if ((i_groupStart >= 0) && (i_nextGroupStart < 0))
					{
						i_nextGroupStart = i_curPosInput;
						i_nextGroupEnd = i_curPosInput + i_width;
					}

					// If no time group is set as the input string parameter, we use position inside the string to determine
					// the time group that should be selected
					if (s_selectionForGroup == "")
					{
						if ((i_position >= i_curPosInput) && (i_position <= i_curPosInput + i_width))
						{
							s_inGroup = s_timeGroup;
							i_groupStart = i_curPosInput;
							i_groupEnd = i_curPosInput + i_width;
						}
					}
					// If the time group is set as the input string parameter, we use it to determine
					// the time group that should be selected
					else
					{
						if (s_timeGroup == s_selectionForGroup)
						{
							i_groupStart = i_curPosInput;
							i_groupEnd = i_curPosInput + i_width;
						}
					}

					if (i_groupStart < 0)
					{
						i_previousGroupStart = i_curPosInput;
						i_previousGroupEnd = i_curPosInput + i_width;
					}

					return i_value;
				}

				var i_previousPosFormatEnd: int = 0;
				var i_previousPosInputEnd: int = 0;
				if (i_previousPosFormat >= 0)
				{
					i_previousPosFormatEnd = i_previousPosFormat + 2;
					i_previousPosInputEnd = i_curPosInput + i_width;
				}
				i_curPosInput += i_curPosFormat - i_previousPosFormatEnd + i_width;
				if (s_format.substring(i_previousPosFormatEnd, i_curPosFormat) != s_datetime.substring(i_previousPosInputEnd, i_curPosInput))
					b_inputValid = false;

				var s_postfix: String = "";
				if (b_useUTC)
					s_postfix = "UTC";
				switch (s_directive.charAt(1))
				{
					case "Y":
					{i_width = 4;
						year = handleTimeGroup("fullYear" + s_postfix);
						break;}
					case "m":
					{i_width = 2;
						month = handleTimeGroup("month" + s_postfix);
						break;}
					case "d":
					{i_width = 2;
						day = handleTimeGroup("date" + s_postfix);
						break;}
					case "H":
					{i_width = 2;
						hour = handleTimeGroup("hours" + s_postfix);
						break;}
					case "M":
					{i_width = 2;
						min = handleTimeGroup("minutes" + s_postfix);
						break;}
					case "S":
					{i_width = 2;
						sec = handleTimeGroup("seconds" + s_postfix);
						break;}
					case "b":
					{i_width = 3;
						month = handleTimeGroup("month" + s_postfix, DateBase.monthNamesShort);
						break;}
					case "B":
					{i_width = 3;
						month = handleTimeGroup("month" + s_postfix, DateBase.monthNamesLong);
						break;}
					default:
						break;
				}
				i_previousPosFormat = i_curPosFormat;
				return s_directive;
			}
			const directivePattern: RegExp = /%./g;
			// We use replace(...) just to parse the s_datetime string,
			// but in fact we do not replace anything.
			s_format.replace(directivePattern, parseDirective);
			var dt: Date;
			if (b_useUTC)
				dt = new Date(Date.UTC(year, month - 1, day, hour, min, sec, ms));
			else
				dt = new Date(year, month - 1, day, hour, min, sec, ms);
			if (!b_inputValid)
				dt.setTime(NaN);
			return {"date": dt, "groupStart": i_groupStart, "groupEnd": i_groupEnd, "inGroup": s_inGroup,
						"presentInFormat": presentInFormat, "nextGroupStart": i_nextGroupStart, "nextGroupEnd": i_nextGroupEnd,
						"previousGroupStart": i_previousGroupStart, "previousGroupEnd": i_previousGroupEnd};
		}

		/**
		 * change date in way that subtract timezoneOffset. So hoursUTC will be hours and so on...
		 * @param date
		 * @return
		 *
		 */
		public static function convertToLocalTime(date: Date): Date
		{
			var newDate: Date = new Date();
			newDate.setTime(date.time - date.timezoneOffset * 60 * 1000);
			return newDate;
		}

		/**
		 * change date in way that adds timezoneOffset. So hours will be hoursUTC and so on...
		 * @param date
		 * @return
		 *
		 */
		public static function convertToUTCDate(date: Date): Date
		{
			var newDate: Date = new Date();
			newDate.setTime(date.time + date.timezoneOffset * 60 * 1000);
			return newDate;
		}

		/**
		 * Return time "distance" between 2 dates
		 * @param date1
		 * @param date2
		 * @return
		 *
		 */
		public static function getDatesDistance(date1: Date, date2: Date): Number
		{
			return Math.abs(date1.time - date2.time);
		}
		/**
		 * Return time "distance" between 2 dates
		 * @param date1
		 * @param date2
		 * @return
		 *
		 */
		public static function getDatesDistanceInMinutes(date1: Date, date2: Date): Number
		{
			var minute: Number = 60 * 1000;
			return getDatesDistance(date1, date2) / minute;
		}

		public static function getTommorow(): Date
		{
			var now: Date = new Date();
			now.setHours(0);
			now.setMinutes(0);
			now.setSeconds(0);
			var dayMs: Number = 24 * 60 * 60 * 1000;
			var tommorow: Date = new Date(now.getTime() + dayMs);
			return tommorow;
		}

		public static function getMinimumDate(date: Date, maximumDate: Date): Date
		{
			if (date.time <= maximumDate.time)
				return date;
			return maximumDate;
		}

		public static function getMaximumDate(date: Date, minimumDate: Date): Date
		{
			if (date.time >= minimumDate.time)
				return date;
			return minimumDate;
		}
	}
}
