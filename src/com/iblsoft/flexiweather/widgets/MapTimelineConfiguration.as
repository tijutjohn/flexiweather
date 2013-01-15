package com.iblsoft.flexiweather.widgets
{
	import com.iblsoft.flexiweather.utils.Serializable;
	import com.iblsoft.flexiweather.utils.Storage;
	
	import flash.events.Event;
	import flash.events.EventDispatcher;

	public class MapTimelineConfiguration extends EventDispatcher implements Serializable
	{
		public static const ANIMATION_TYPE_TO_LAST_FRAME: String = 'to-last-frame';
		public static const ANIMATION_TYPE_FROM_FIRST_FRAME: String = 'from-first-frame';
		public static const ANIMATION_TYPE_TO_NOW: String = 'to-now';
		public static const ANIMATION_TYPE_FROM_NOW: String = 'from-now';
		public static const ANIMATION_TYPE_FULL: String = 'full';
		public static const ANIMATION_TYPE_USER: String = 'user';
		private var _mapVisibleUnderTimeline: Boolean = true;
	
		[Bindable]
		public var timelineVisibleAtStartup: Boolean;
		[Bindable]
		public var currentTimeFormat: String = '%H:%M %d.%m.%Y';
		[Bindable]
		public var dateFormat: String = '%d-%m';
		[Bindable]
		public var timeFormat: String = '%HZ';
		[Bindable]
		public var durationStep: int = 100;
		[Bindable]
		public var minDuration: int = 100;
		[Bindable]
		public var maxDuration: int = 5000;
		[Bindable]
		public var animationExtent: String;
		[Bindable]
		public var animationType: String;

		public function MapTimelineConfiguration()
		{
			super();
			animationType = ANIMATION_TYPE_FULL;
			animationExtent = 'PT1H';
		}

		private var _duration: int = 1000;

		[Bindable (event="durationChanged")]
		public function get duration():int
		{
			return _duration;
		}

		public function set duration(value:int):void
		{
			_duration = value;
			dispatchEvent(new Event("durationChanged"));
		}

		public function get mapVisibleUnderTimeline(): Boolean
		{
			return _mapVisibleUnderTimeline;
		}

		public function set mapVisibleUnderTimeline(value: Boolean): void
		{
			_mapVisibleUnderTimeline = value;
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
