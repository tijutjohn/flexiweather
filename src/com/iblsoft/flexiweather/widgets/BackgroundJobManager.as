package com.iblsoft.flexiweather.widgets
{
	import mx.collections.ArrayCollection;
	import mx.controls.ProgressBar;
	import mx.controls.ProgressBarLabelPlacement;
	import mx.controls.ProgressBarMode;
	import mx.core.UIComponent;
	import mx.events.ResizeEvent;
	
	public class BackgroundJobManager
	{
		internal static var sm_instance: BackgroundJobManager;

		internal var m_progressBar: ProgressBar = new ProgressBar();
		internal var m_jobs: ArrayCollection = new ArrayCollection();
		
		internal var mi_maxJobs: int = 0;
		internal var mi_doneJobs: int = 0;
 
		public function BackgroundJobManager()
		{
            if (sm_instance != null) {
                throw new Error("BackgroundJobManager can only be accessed through BackgroundJobManager.getInstance");
            }
		}
		
		public static function getInstance(): BackgroundJobManager
		{
			if(sm_instance == null)
				sm_instance = new BackgroundJobManager();
			return sm_instance;
		}
		
		public function setupIndicator(parent: UIComponent): void
		{
			//m_progressBar.labelPlacement = ProgressBarLabelPlacement.CENTER;
			parent.addEventListener(ResizeEvent.RESIZE, onParentResize);
			parent.addChild(m_progressBar);
			onParentResize(null);
		}
		
		public function onParentResize(event: ResizeEvent): void
		{
			m_progressBar.width = 200;
			m_progressBar.height = m_progressBar.parent.height - 5;
			m_progressBar.setStyle("trackHeight", 23);
			m_progressBar.labelPlacement = ProgressBarLabelPlacement.CENTER;
			m_progressBar.x = m_progressBar.parent.width - m_progressBar.width - 5;
			m_progressBar.y = (m_progressBar.parent.height - m_progressBar.height) / 2;
		}
		
		public function startJob(s_label: String): BackgroundJob
		{
			var job: BackgroundJob = new BackgroundJob(s_label, this);
			m_jobs.addItem(job);
			if(mi_doneJobs == mi_maxJobs) {
				// all jobs done, start counting from scratch
				mi_doneJobs = 0;
				mi_maxJobs = 0;
			}
			mi_maxJobs++;
			updateUI();
			return job;
		}
		
		public function finishJob(job: BackgroundJob): void
		{
			var i: int = m_jobs.getItemIndex(job);
			if(i >= 0) {
				m_jobs.removeItemAt(i);
				mi_doneJobs++;
				updateUI();
			}
		}
		
		protected function updateUI(): void
		{
			if(m_jobs.length > 0) {
//				if(m_jobs.length > 1)
					m_progressBar.label = mi_doneJobs + "/" + mi_maxJobs + " jobs done";
//				else
//					m_progressBar.label = m_jobs.getItemAt(0).getLabel();
				if(mi_maxJobs > 1) {
					m_progressBar.indeterminate = false;
					m_progressBar.minimum = 0;
					m_progressBar.maximum = mi_maxJobs;
					m_progressBar.mode = ProgressBarMode.MANUAL;
					m_progressBar.setProgress(mi_doneJobs, mi_maxJobs);
				}
				else {
					m_progressBar.mode = ProgressBarMode.EVENT;
					m_progressBar.indeterminate = true;
				}
				var s: String = "Pending jobs:";
				for each(var job: BackgroundJob in m_jobs) {
					s += "\n  " + job.ms_label;
				}
				m_progressBar.toolTip = s;
				m_progressBar.visible = true;
			}
			else {
				m_progressBar.visible = false;
			}
		}
	}
}