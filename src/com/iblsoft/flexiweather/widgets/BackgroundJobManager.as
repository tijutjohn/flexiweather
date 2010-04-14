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

		internal var m_default_progressBar: ProgressBar
		
		public var m_progressBar: JobPreloader;
		
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
			if (m_default_progressBar)
				m_default_progressBar.labelPlacement = ProgressBarLabelPlacement.CENTER;
			parent.addEventListener(ResizeEvent.RESIZE, onParentResize);
			parent.addChild(m_default_progressBar);
			onParentResize(null);
		}
		
		public function createDefaultPreloader():void
		{
			m_default_progressBar = new ProgressBar();
		}
		
		public function onParentResize(event: ResizeEvent): void
		{
			if (m_default_progressBar)
			{
				m_default_progressBar.width = 200;
				m_default_progressBar.height = m_default_progressBar.parent.height - 5;
				m_default_progressBar.setStyle("trackHeight", 23);
				m_default_progressBar.labelPlacement = ProgressBarLabelPlacement.CENTER;
				m_default_progressBar.x = m_default_progressBar.parent.width - m_default_progressBar.width - 5;
				m_default_progressBar.y = (m_default_progressBar.parent.height - m_default_progressBar.height) / 2;
			}
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
				
				var s: String = "Pending jobs:";
				for each(var job: BackgroundJob in m_jobs) {
					s += "\n  " + job.ms_label;
				}
				
				if (m_progressBar)
				{
					m_progressBar.updateUI(mi_doneJobs, mi_maxJobs);
					m_progressBar.visible = true;
					m_progressBar.toolTip = s;
				}
				
				if (m_default_progressBar)
				{
					m_default_progressBar.label = mi_doneJobs + "/" + mi_maxJobs + " jobs done";
					
					if(mi_maxJobs > 1) {
						m_default_progressBar.indeterminate = false;
						m_default_progressBar.minimum = 0;
						m_default_progressBar.maximum = mi_maxJobs;
						m_default_progressBar.mode = ProgressBarMode.MANUAL;
						m_default_progressBar.setProgress(mi_doneJobs, mi_maxJobs);
					}
					else {
						m_default_progressBar.mode = ProgressBarMode.EVENT;
						m_default_progressBar.indeterminate = true;
					}
					m_default_progressBar.toolTip = s;
					m_default_progressBar.visible = true;
				}
				
				
			}
			else {
				if (m_progressBar)
					m_progressBar.visible = false;
				if (m_default_progressBar)
					m_default_progressBar.visible = false;
			}
		}
		
		public function hasJobs(): Boolean
		{ return m_jobs.length > 0; }
	}
}