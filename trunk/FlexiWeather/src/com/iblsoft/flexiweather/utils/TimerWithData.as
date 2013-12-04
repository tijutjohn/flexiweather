package com.iblsoft.flexiweather.utils
{
	import flash.utils.Timer;

	public class TimerWithData extends Timer
	{
		public var associatedData: Object;

		public function TimerWithData(delay: Number, repeatCount: int = 0, data: Object = null)
		{
			super(delay, repeatCount);
			associatedData = data;
		}
	}
}
