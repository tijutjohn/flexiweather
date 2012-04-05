package com.iblsoft.flexiweather.utils
{
	import flash.utils.getTimer;

	public class ProfilerUtils
	{
		static public function startProfileTimer(): int
		{
			return getTimer();
		}
		/**
		 * Return time interval in seconds 
		 * @param startTime
		 * @return 
		 * 
		 */		
		static public function stopProfileTimer(startTime: int): Number
		{
			var diff: int = getTimer() - startTime;
			return diff;
		}
	}
}