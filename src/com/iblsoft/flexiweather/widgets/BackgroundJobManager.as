package com.iblsoft.flexiweather.widgets
{
	import com.iblsoft.flexiweather.events.BackgroundJobEvent;
	
	import flash.display.DisplayObject;
	import flash.events.EventDispatcher;
	import flash.events.TimerEvent;
	import flash.utils.Timer;
	
	import mx.collections.ArrayCollection;
	import mx.controls.ProgressBar;
	import mx.controls.ProgressBarLabelPlacement;
	import mx.controls.ProgressBarMode;
	import mx.core.IFlexDisplayObject;
	import mx.core.IVisualElement;
	import mx.core.UIComponent;
	import mx.events.ResizeEvent;
	
	import org.osmf.events.TimeEvent;
	
	import spark.components.Group;
	import spark.components.VGroup;
	import spark.components.supportClasses.GroupBase;

	public class BackgroundJobManager extends EventDispatcher
	{
		internal static var sm_instance: BackgroundJobManager;
		public static var maximumTileDescriptionCount: int = 25;
		public var m_progressBar: JobProgressIndicator;
		internal var m_jobs: ArrayCollection = new ArrayCollection();
		internal var m_finishedJobs: ArrayCollection = new ArrayCollection();
		internal var mi_jobsCount: int = 0;
		internal var mi_jobsDone: int = 0;
		private var ms_pendingJobsDescription: String;
		private var m_clearTimer: Timer;

		public function get pendingJobsDescription(): String
		{
			return ms_pendingJobsDescription;
		}

		public function BackgroundJobManager()
		{
			if (sm_instance != null)
				throw new Error("BackgroundJobManager can only be accessed through BackgroundJobManager.getInstance");
			

			m_clearTimer = new Timer(30000);
			m_clearTimer.addEventListener(TimerEvent.TIMER, onClearTimerTick);
			m_clearTimer.start();
		}

		public static function getInstance(): BackgroundJobManager
		{
			if (sm_instance == null)
				sm_instance = new BackgroundJobManager();
			return sm_instance;
		}

		public function setupIndicator(parent: IFlexDisplayObject): void
		{
			if (parent is Group)
				Group(parent).addElement(m_progressBar.jobProgressGetDisplayObject() as IVisualElement);
			else if (parent is UIComponent)
				UIComponent(parent).addChild(m_progressBar.jobProgressGetDisplayObject() as DisplayObject);
		}

		public function createDefaultPreloader(): void
		{
			m_progressBar = new ProgressBarJobProgressIndicator(new ProgressBar());
		}

		private function updateTotalJobsStatus(): void
		{
//			mi_jobsCount -= mi_jobsDone;
//			mi_jobsDone = 0;
		}

		public function startJob(s_label: String): BackgroundJob
		{
			var job: BackgroundJob = new BackgroundJob(s_label, this);
			m_jobs.addItem(job);
			if (mi_jobsDone == mi_jobsCount)
			{
				// all jobs done, start counting from scratch
				mi_jobsDone = 0;
				mi_jobsCount = 0;
			}
			mi_jobsCount++;
			updateUI();
			dispatchJobEvent(BackgroundJobEvent.JOB_STARTED);
			return job;
		}

		private function dispatchJobEvent(type: String): void
		{
			var bje: BackgroundJobEvent = new BackgroundJobEvent(type);
			bje.runningJobs = m_jobs.length;
			bje.doneJobs = mi_jobsDone;
			bje.allJobs = mi_jobsCount;
			dispatchEvent(bje);
		}

		public function finishJob(job: BackgroundJob): void
		{
			var i: int = m_jobs.getItemIndex(job);
			if (i >= 0)
			{
				m_jobs.removeItemAt(i);
				m_finishedJobs.addItem(job);
				mi_jobsDone++;
				updateUI();
			}
			dispatchJobEvent(BackgroundJobEvent.JOB_FINISHED);
			if (m_jobs.length == 0)
			{
				mi_jobsDone = 0;
				mi_jobsCount = 0;
				m_jobs.removeAll();
				m_finishedJobs.removeAll();
				noJobs();
				dispatchJobEvent(BackgroundJobEvent.ALL_JOBS_FINISHED);
			}
		}

		protected function updateUI(): void
		{
			updateTotalJobsStatus();
			if (m_jobs.length > 0)
			{
				var job: BackgroundJob;
				ms_pendingJobsDescription = "Pending jobs:";
				if (m_jobs.length > maximumTileDescriptionCount)
				{
					//fix for many jobs queue. Just display first let's say 50 and 1 sentence (... and (total - 50) pending jobs)
					for (var i: int = 0; i < maximumTileDescriptionCount; i++)
					{
						job = m_jobs.getItemAt(i) as BackgroundJob;
						ms_pendingJobsDescription += "\n  " + job.ms_label;
					}
					ms_pendingJobsDescription += "\n... and " + (m_jobs.length - maximumTileDescriptionCount) + " more pending jobs";
				}
				else
				{
					for each (job in m_jobs)
					{
						ms_pendingJobsDescription += "\n  " + job.ms_label;
					}
				}
				if (m_progressBar != null)
					m_progressBar.jobProgressUpdate(mi_jobsDone, mi_jobsCount, ms_pendingJobsDescription);
			}
			else
			{
				noJobs();
				if (m_progressBar)
					m_progressBar.jobProgressFinished();
			}
		}

		private function onClearTimerTick(event: TimerEvent): void
		{
			if (mi_jobsDone > 0)
			{
				mi_jobsCount -= mi_jobsDone;
				mi_jobsDone = 0;
				updateUI();
			}
		}
		
		private function noJobs(): void
		{
			ms_pendingJobsDescription = 'No pending jobs at all';
		}

		public function hasJobs(): Boolean
		{
			return m_jobs.length > 0;
		}
	}
}
