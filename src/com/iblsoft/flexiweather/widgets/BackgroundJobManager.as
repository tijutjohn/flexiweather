package com.iblsoft.flexiweather.widgets
{
	import com.iblsoft.flexiweather.events.BackgroundJobEvent;
	
	import flash.events.EventDispatcher;
	
	import mx.collections.ArrayCollection;
	import mx.controls.ProgressBar;
	import mx.controls.ProgressBarLabelPlacement;
	import mx.controls.ProgressBarMode;
	import mx.core.IFlexDisplayObject;
	import mx.core.UIComponent;
	import mx.events.ResizeEvent;
	
	import spark.components.Group;
	import spark.components.VGroup;
	import spark.components.supportClasses.GroupBase;
	
	public class BackgroundJobManager extends EventDispatcher
	{
		internal static var sm_instance: BackgroundJobManager;

		internal var m_defaultProgressBar: ProgressBar;
		
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
		
		public function setupIndicator(parent: IFlexDisplayObject): void
		{
			if (m_defaultProgressBar)
				m_defaultProgressBar.labelPlacement = ProgressBarLabelPlacement.CENTER;
			parent.addEventListener(ResizeEvent.RESIZE, onParentResize);
			if(parent is Group)
				Group(parent).addElement(m_defaultProgressBar);
			else if(parent is UIComponent)
				UIComponent(parent).addChild(m_defaultProgressBar);
			onParentResize(null);
		}
		
		public function createDefaultPreloader():void
		{
			m_defaultProgressBar = new ProgressBar();
		}
		
		public function onParentResize(event: ResizeEvent): void
		{
			if (m_defaultProgressBar)
			{
				m_defaultProgressBar.width = 200;
				m_defaultProgressBar.height = m_defaultProgressBar.parent.height - 5;
				m_defaultProgressBar.labelPlacement = ProgressBarLabelPlacement.CENTER;
				m_defaultProgressBar.x = m_defaultProgressBar.parent.width - m_defaultProgressBar.width - 5;
				m_defaultProgressBar.y = (m_defaultProgressBar.parent.height - m_defaultProgressBar.height) / 2;
			}
		}
		
		private function updateTotalJobsStatus(): void
		{
			mi_maxJobs -= mi_doneJobs;
			mi_doneJobs = 0;
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
			
			dispatchJobEvent(BackgroundJobEvent.JOB_STARTED);
			
			return job;
		}
		
		private function dispatchJobEvent(type: String): void
		{
			var bje: BackgroundJobEvent = new BackgroundJobEvent(type);
			bje.runningJobs = m_jobs.length;
			bje.doneJobs = mi_doneJobs;
			bje.allJobs = mi_maxJobs;
			dispatchEvent(bje);
		}
		public function finishJob(job: BackgroundJob): void
		{
			var i: int = m_jobs.getItemIndex(job);
			if(i >= 0) {
				m_jobs.removeItemAt(i);
				mi_doneJobs++;
				updateUI();
			}
			
			
			dispatchJobEvent(BackgroundJobEvent.JOB_FINISHED);
			
			if (m_jobs.length == 0)
			{
				dispatchJobEvent(BackgroundJobEvent.ALL_JOBS_FINISHED);
			}
		}
		
		protected function updateUI(): void
		{
			updateTotalJobsStatus();
			
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
				
				if (m_defaultProgressBar)
				{
					m_defaultProgressBar.label = mi_doneJobs + "/" + mi_maxJobs + " jobs done";
					
					if(mi_maxJobs > 1) {
						m_defaultProgressBar.indeterminate = false;
						m_defaultProgressBar.minimum = 0;
						m_defaultProgressBar.maximum = mi_maxJobs;
						m_defaultProgressBar.mode = ProgressBarMode.MANUAL;
						m_defaultProgressBar.setProgress(mi_doneJobs, mi_maxJobs);
					}
					else {
						m_defaultProgressBar.mode = ProgressBarMode.EVENT;
						m_defaultProgressBar.indeterminate = true;
					}
					m_defaultProgressBar.toolTip = s;
					m_defaultProgressBar.visible = true;
				}
				
				
			}
			else {
				if (m_progressBar)
					m_progressBar.visible = false;
				if (m_defaultProgressBar)
					m_defaultProgressBar.visible = false;
			}
		}
		
		public function hasJobs(): Boolean
		{ return m_jobs.length > 0; }
	}
}
