package com.iblsoft.flexiweather.utils
{
	import mx.collections.ArrayCollection;
	import mx.formatters.DateFormatter;
	import mx.logging.ILogger;
	import mx.logging.LogEvent;
	import mx.logging.targets.LineFormattedTarget;

	public class ArrayLogTarget extends LineFormattedTarget
	{
		protected var ma_logs: ArrayCollection = new ArrayCollection();

		public var startDate: Date;
		private var dateFormatter: DateFormatter;

		public function ArrayLogTarget()
		{
			super();
			startDate = new Date();
			dateFormatter = new DateFormatter();
			dateFormatter.formatString = "JJh NNm SSs";
		}

		public override function logEvent(event: LogEvent): void
		{
			//super.logEvent(event);
			var now: Date = new Date();
			var interval: Number = now.time - startDate.time;
//			var newDate = new Date(interval);
			var intervalString: String = convertToHHMMSS(interval/1000);
//			var intervalString2: String = dateFormatter.format(interval/1000);

			var level: String = LogEvent.getLevelString(event.level);
			var message: String = event.message;
			if (!isSame(level, message))
			{
				ma_logs.addItemAt({
							date: ISO8601Parser.dateToString(new Date()),
							timeInterval: intervalString,
							level: level,
							message: message,
							count: 1,
							category: ILogger(event.target).category
						},0);
			} else {
				var item: Object = ma_logs.getItemAt(0);
				item.count++;
			}
		}

		private function isSame(level: String, message: String): Boolean
		{
			if (ma_logs.length > 0)
			{
				var item: Object = ma_logs.getItemAt(0);
				return item.level == level && item.message == message;
			}
			return false;
		}

		private function convertToHHMMSS(seconds:Number):String
		{
			var s:Number = seconds % 60;
			var m:Number = Math.floor((seconds % 3600 ) / 60);
			var h:Number = Math.floor(seconds / (60 * 60));

			var hourStr:String = (h == 0) ? "" : doubleDigitFormat(h) + "h";
			var minuteStr:String = (m == 0) ? "" : doubleDigitFormat(m) + "m ";
			var secondsStr:String = doubleDigitFormat(s) + "s ";

			return hourStr + minuteStr + secondsStr;
		}

		private function doubleDigitFormat(num:uint):String
		{
			if (num < 10)
			{
				return ("0" + num);
			}
			return String(num);
		}

		protected function internalLog(s_message: String): void
		{
		}

		public function clear(): void
		{
			ma_logs.removeAll();
		}

		public function get logEntryCollection(): ArrayCollection
		{
			return ma_logs;
		}
	}
}
