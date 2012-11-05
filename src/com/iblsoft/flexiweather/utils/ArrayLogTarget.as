package com.iblsoft.flexiweather.utils
{
	import mx.collections.ArrayCollection;
	import mx.logging.ILogger;
	import mx.logging.LogEvent;
	import mx.logging.targets.LineFormattedTarget;

	public class ArrayLogTarget extends LineFormattedTarget
	{
		protected var ma_logs: ArrayCollection = new ArrayCollection();

		public function ArrayLogTarget()
		{
			super();
		}

		public override function logEvent(event: LogEvent): void
		{
			//super.logEvent(event);
			ma_logs.addItem({
						date: ISO8601Parser.dateToString(new Date()),
						level: LogEvent.getLevelString(event.level),
						message: event.message,
						category: ILogger(event.target).category
					});
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
