package com.iblsoft.flexiweather.utils
{

	public class Duration
	{
		private var mf_secondTotal: Number;

		public function Duration(f_secondsTotal: Number = 0)
		{
			mf_secondTotal = f_secondsTotal;
		}

		public function toHoursString(): String
		{
			var s: String = "+" + hoursTotal + "h";
			if (minutes > 0)
				s += " " + minutes + "m";
			if (seconds > 0 || miliseconds > 0)
			{
				s += " " + seconds;
				if (miliseconds > 0)
					s += "." + miliseconds;
				s += "s";
			}
			return s;
		}

		public function get secondsTotal(): Number
		{
			return mf_secondTotal;
		}

		public function get secondsTotalAsInt(): int
		{
			return int(Math.round(mf_secondTotal));
		}

		public function get miliseconds(): Number
		{
			return int((mf_secondTotal - int(mf_secondTotal)) * 1000);
		}

		public function get milisecondsTotal(): Number
		{
			return mf_secondTotal * 1000;
		}

		public function get seconds(): Number
		{
			return int(mf_secondTotal) % 60;
		}

		public function set seconds(f: Number): void
		{
			mf_secondTotal = mf_secondTotal - seconds + f;
		}

		public function get minutes(): Number
		{
			return int(int(mf_secondTotal) / 60) % 60;
		}

		public function set minutes(f: Number): void
		{
			mf_secondTotal = mf_secondTotal - minutes * 60 + f * 60;
		}

		public function get hours(): Number
		{
			return int(int(mf_secondTotal) / 3600) % 24;
		}

		public function get hoursTotal(): Number
		{
			return int(int(mf_secondTotal) / 3600);
		}

		public function set hours(f: Number): void
		{
			mf_secondTotal = mf_secondTotal - minutes * 3600 + f * 3600;
		}

		public function get days(): Number
		{
			return int(int(mf_secondTotal) / 86400);
		}

		public function set days(f: Number): void
		{
			mf_secondTotal = mf_secondTotal - days * 86400 + f * 86400;
		}

		public function add(other: Duration): void
		{
			mf_secondTotal += other.secondsTotal;
		}
	}
}
