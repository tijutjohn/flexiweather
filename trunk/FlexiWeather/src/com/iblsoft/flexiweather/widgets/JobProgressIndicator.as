package com.iblsoft.flexiweather.widgets
{
	import flash.display.DisplayObject;

	public interface JobProgressIndicator
	{
		function jobProgressUpdate(i_jobsDone: uint, i_jobsTotal: uint, s_description: String): void;
		function jobProgressFinished(): void;
		function jobProgressGetDisplayObject(): DisplayObject;
	}
}
