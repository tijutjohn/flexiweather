package com.iblsoft.flexiweather.widgets
{

	public class BackgroundJob extends Object
	{
		internal var ms_label: String;
		internal var m_manager: BackgroundJobManager;

		public function BackgroundJob(s_label: String, manager: BackgroundJobManager)
		{
			ms_label = s_label;
			m_manager = manager;
		}

		public function finish(): void
		{
			m_manager.finishJob(this);
		}

		public function cancel(): void
		{
			m_manager.finishJob(this);
		}

		public function getLabel(): String
		{
			return ms_label;
		}
	}
}
