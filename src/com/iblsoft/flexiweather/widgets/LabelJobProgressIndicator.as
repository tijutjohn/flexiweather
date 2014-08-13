package com.iblsoft.flexiweather.widgets
{
	import flash.display.DisplayObject;
	import spark.components.Label;

	public class LabelJobProgressIndicator implements JobProgressIndicator
	{
		private var m_label: Label;
		private var _allowTooltip: Boolean;
		
		public function LabelJobProgressIndicator(label: Label)
		{
			m_label = label;
		}

		public function allowTooltip(b_allow: Boolean): void
		{
			_allowTooltip = b_allow;
			if (!_allowTooltip && m_label)
				m_label.text = null;
		}
		
		public function jobProgressUpdate(i_jobsDone: uint, i_jobsCount: uint, s_description: String): void
		{
			m_label.text = "Waiting jobs " + i_jobsDone + "/" + i_jobsCount + "...";
		}

		public function jobProgressFinished(): void
		{
			m_label.text = "";
		}

		public function jobProgressGetDisplayObject(): DisplayObject
		{
			return m_label;
		}
	}
}
