package com.iblsoft.flexiweather.widgets
{
	import flash.display.DisplayObject;
	
	import mx.core.UIComponent;

	public dynamic class JobPreloader extends UIComponent implements JobProgressIndicator
	{
		private var _allowTooltip: Boolean;
		
		public function JobPreloader()
		{
			super();
		}

		public function updateUI(i_jobsDone: int, i_maxJobs: int): void
		{
		}

		public function allowTooltip(b_allow: Boolean): void
		{
			_allowTooltip = b_allow;
			if (!_allowTooltip)
				toolTip = null;
		}
		
		public function jobProgressUpdate(i_jobsDone: uint, i_maxJobs: uint, s_description: String): void
		{
			updateUI(i_jobsDone, i_jobsDone);
			visible = true;
			if (_allowTooltip)
				toolTip = s_description;
		}

		public function jobProgressFinished(): void
		{
			visible = false;
		}

		public function jobProgressGetDisplayObject(): DisplayObject
		{
			return this as DisplayObject;
		}
	}
}
