package com.iblsoft.flexiweather.utils
{
	import flash.utils.getTimer;

	public class ProfilerUtils
	{
		static public function startProfileTimer(): Number
		{
			return getTimer();
		}

		/**
		 * Return time interval in seconds
		 * @param startTime
		 * @return
		 *
		 */
		static public function stopProfileTimer(startTime: Number): Number
		{
			var diff: Number = getTimer() - startTime;
			return diff;
		}
		static public function formatStringProfileTimer(startTime: Number, text: String = ''): String
		{
			var diff: Number = getTimer() - startTime;
			return text + " took " + diff + "ms.";
		}
	}
}
