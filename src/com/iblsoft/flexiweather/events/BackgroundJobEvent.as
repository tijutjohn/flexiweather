package com.iblsoft.flexiweather.events
{
	import flash.events.Event;

	public class BackgroundJobEvent extends Event
	{
		public static const JOB_STARTED: String = 'jobStart';
		public static const JOB_FINISHED: String = 'jobFinish';
		public static const ALL_JOBS_FINISHED: String = 'jobJobsFinished';
		public var runningJobs: int;
		public var doneJobs: int;
		public var allJobs: int;

		public function BackgroundJobEvent(type: String, bubbles: Boolean = false, cancelable: Boolean = false)
		{
			super(type, bubbles, cancelable);
		}
	}
}
