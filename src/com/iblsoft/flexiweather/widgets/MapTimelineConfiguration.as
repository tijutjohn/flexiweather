package com.iblsoft.flexiweather.widgets
{
	import com.iblsoft.flexiweather.utils.Serializable;
	import com.iblsoft.flexiweather.utils.Storage;
	
	[Bindable]
	public class MapTimelineConfiguration implements Serializable
	{
		public static const ANIMATION_TYPE_TO_LAST_FRAME:String = 'to-last-frame';
		public static const ANIMATION_TYPE_FROM_FIRST_FRAME:String = 'from-first-frame';
		public static const ANIMATION_TYPE_TO_NOW:String = 'to-now';
		public static const ANIMATION_TYPE_FROM_NOW:String = 'from-now';
		public static const ANIMATION_TYPE_FULL:String = 'full';
		public static const ANIMATION_TYPE_USER:String = 'user';
		
		public var mapVisibleUnderTimeline: Boolean = true;
		public var timelineVisibleAtStartup: Boolean;
		
		public var currentTimeFormat: String = '%H:%M %d.%m.%Y';
		public var dateFormat: String = '%d-%m';
		public var timeFormat: String = '%HZ';
		
		public var duration: int = 1000;
		public var durationStep: int = 100;
		public var minDuration: int = 100;
		public var maxDuration: int = 5000;
		
		public var animationExtent: String;
		public var animationType: String;
		
		public function MapTimelineConfiguration()
		{
			super();
			animationType = ANIMATION_TYPE_FULL;
			animationExtent = 'PT1H';
		}
		
		public function limitsChangedByUser(): void
		{
			animationType = ANIMATION_TYPE_USER;
		}
		
		public function serialize(storage: Storage): void
		{
			currentTimeFormat = storage.serializeString("current-time-format", currentTimeFormat, '%H:%M %d.%m.%Y');
			dateFormat = storage.serializeString("date-format", dateFormat, '%d-%m');
			dateFormat = storage.serializeString("time-format", dateFormat, '%HZ');
			duration = storage.serializeInt("duration", duration, 1000);
			durationStep = storage.serializeInt("duration-step", durationStep, 100);
			minDuration = storage.serializeInt("min-duration", minDuration, 100);
			maxDuration = storage.serializeInt("max-duration", maxDuration, 5000);
			animationExtent = storage.serializeString("animation-extent", animationExtent, null);
			animationType = storage.serializeString("animation-type", animationType, null);
			mapVisibleUnderTimeline = storage.serializeBool("map-visible-under-timeline", mapVisibleUnderTimeline, true);
			timelineVisibleAtStartup = storage.serializeBool("timeline-visible-at-startup", timelineVisibleAtStartup, true);
		}
		
	}
}