package com.iblsoft.flexiweather.widgets
{
	import com.iblsoft.flexiweather.widgets.JobProgressIndicator;
	import flash.display.DisplayObject;
	import flash.events.Event;
	import mx.controls.ProgressBar;
	import mx.controls.ProgressBarLabelPlacement;
	import mx.controls.ProgressBarMode;
	import mx.events.ResizeEvent;

	public class ProgressBarJobProgressIndicator implements JobProgressIndicator
	{
		private var m_progressBar: ProgressBar;

		function ProgressBarJobProgressIndicator(progressBar: ProgressBar): void
		{
			m_progressBar = progressBar;
			m_progressBar.labelPlacement = ProgressBarLabelPlacement.CENTER;
			progressBar.addEventListener(Event.ADDED, onParentChanged);
			onParentResize(null);
		}

		public function jobProgressUpdate(i_jobsDone: uint, i_jobsCount: uint, s_description: String): void
		{
			m_progressBar.label = i_jobsDone + "/" + i_jobsCount + " jobs done";
			if (i_jobsCount > 1)
			{
				m_progressBar.indeterminate = false;
				m_progressBar.minimum = 0;
				m_progressBar.maximum = i_jobsCount;
				m_progressBar.mode = ProgressBarMode.MANUAL;
				m_progressBar.setProgress(i_jobsDone, i_jobsCount);
			}
			else
			{
				m_progressBar.mode = ProgressBarMode.EVENT;
				m_progressBar.indeterminate = true;
			}
			m_progressBar.toolTip = s_description;
			m_progressBar.visible = true;
		}

		public function jobProgressFinished(): void
		{
			m_progressBar.visible = false;
		}

		public function jobProgressGetDisplayObject(): DisplayObject
		{
			return m_progressBar;
		}

		public function onParentChanged(event: Event): void
		{
			onParentResize(null);
		}

		public function onParentResize(event: ResizeEvent): void
		{
			m_progressBar.width = 200;
			if (m_progressBar.parent)
			{
				m_progressBar.parent.removeEventListener(ResizeEvent.RESIZE, onParentResize);
				m_progressBar.parent.addEventListener(ResizeEvent.RESIZE, onParentResize);
				m_progressBar.height = m_progressBar.parent.height - 5;
				m_progressBar.x = m_progressBar.parent.width - m_progressBar.width - 5;
				m_progressBar.y = (m_progressBar.parent.height - m_progressBar.height) / 2;
			}
		}
	}
}
