package com.iblsoft.flexiweather.ogc.configuration
{
	import com.iblsoft.flexiweather.ogc.animation.AnimationDirection;
	import com.iblsoft.flexiweather.utils.LoggingUtils;
	import com.iblsoft.flexiweather.utils.Serializable;
	import com.iblsoft.flexiweather.utils.Storage;
	
	import flash.events.Event;
	import flash.events.EventDispatcher;
	
	import mx.events.DynamicEvent;

	[Event(name="durationChanged", type="mx.events.DynamicEvent")]
	[Event(name="directionChanged", type="mx.events.DynamicEvent")]
	[Event(name="extentChanged", type="mx.events.DynamicEvent")]
	[Event(name="typeChanged", type="mx.events.DynamicEvent")]
	public class MapTimelineConfiguration extends EventDispatcher implements Serializable
	{
		public static const TYPE_CHANGED: String = 'typeChanged';
		public static const EXTENT_CHANGED: String = 'extentChanged';
		public static const ANIMATION_CHANGED: String = 'animationChanged';
		public static const DURATION_CHANGED: String = 'durationChanged';
		public static const DIRECTION_CHANGED: String = 'directionChanged';
		
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
		public var minDuration: int = 100;
		[Bindable]
		public var maxDuration: int = 5000;

		private var _durationStep: int = 100;
		private var _animationExtent: String;
		private var _animationType: String;
		private var _animationDirection: String;

		public function MapTimelineConfiguration()
		{
			super();
			animationDirection = AnimationDirection.ANIMATION_DIRECTION_FORWARD;
			animationType = ANIMATION_TYPE_FULL;
			animationExtent = 'PT1H';
		}

		private var _duration: int = 1000;

		[Bindable (event=TYPE_CHANGED)]
		public function get animationType():String
		{
			return _animationType;
		}

		public function set animationType(value:String):void
		{
			_animationType = value;
			
			debug("Type : " + value);
			
			var de: DynamicEvent = new DynamicEvent(TYPE_CHANGED);
			de['value'] = _animationType;
			dispatchEvent(de);
		}

		[Bindable (event=EXTENT_CHANGED)]
		public function get animationExtent():String
		{
			return _animationExtent;
		}

		public function set animationExtent(value:String):void
		{
			_animationExtent = value;
			
			debug("Extent : " + value);
			
			var de: DynamicEvent = new DynamicEvent(EXTENT_CHANGED);
			de['value'] = _animationExtent;
			dispatchEvent(de);
		}

		[Bindable (event=DIRECTION_CHANGED)]
		public function get animationDirection():String
		{
			return _animationDirection;
		}

		public function set animationDirection(value:String):void
		{
			_animationDirection = value;
			
			debug("Direction : " + value);
			
			var de: DynamicEvent = new DynamicEvent(DIRECTION_CHANGED);
			de['value'] = _animationDirection;
			dispatchEvent(de);
		}

		[Bindable (event=DURATION_CHANGED)]
		public function get durationStep():int
		{
			return _duration;
		}

		public function set durationStep(value:int):void
		{
			_duration = value;
			
			debug("Duration : " + value);
			
			var de: DynamicEvent = new DynamicEvent(DURATION_CHANGED);
			de['value'] = _duration;
			dispatchEvent(de);
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

		private function debug(str: String): void
		{
			LoggingUtils.dispatchLogEvent(this, "MapTimelineConfiguration: " + str);
		}
		
		public function serialize(storage: Storage): void
		{
			currentTimeFormat = storage.serializeString("current-time-format", currentTimeFormat, '%H:%M %d.%m.%Y');
			dateFormat = storage.serializeString("date-format", dateFormat, '%d-%m');
			dateFormat = storage.serializeString("time-format", dateFormat, '%HZ');
			durationStep = storage.serializeInt("duration", durationStep, 1000);
			durationStep = storage.serializeInt("duration-step", durationStep, 100);
			minDuration = storage.serializeInt("min-duration", minDuration, 100);
			maxDuration = storage.serializeInt("max-duration", maxDuration, 5000);
			animationExtent = storage.serializeString("animation-extent", animationExtent, null);
			animationType = storage.serializeString("animation-type", animationType, null);
			animationDirection = storage.serializeString("animation-direction", animationDirection, null);
			mapVisibleUnderTimeline = storage.serializeBool("map-visible-under-timeline", mapVisibleUnderTimeline, true);
			timelineVisibleAtStartup = storage.serializeBool("timeline-visible-at-startup", timelineVisibleAtStartup, true);
		}
	}
}
