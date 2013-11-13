package com.iblsoft.flexiweather.ogc.configuration
{
	import com.iblsoft.flexiweather.ogc.animation.AnimationDirection;
	import com.iblsoft.flexiweather.utils.ISO8601Parser;
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
		public static const DELAY_CHANGED: String = 'delayChanged';
		public static const DIRECTION_CHANGED: String = 'directionChanged';
		
		public static const ANIMATION_TYPE_TO_LAST_FRAME: String = 'to-last-frame';
		public static const ANIMATION_TYPE_FROM_FIRST_FRAME: String = 'from-first-frame';
		public static const ANIMATION_TYPE_TO_NOW: String = 'to-now';
		public static const ANIMATION_TYPE_FROM_NOW: String = 'from-now';
		public static const ANIMATION_TYPE_FULL: String = 'full';
		public static const ANIMATION_TYPE_USER: String = 'user';
		
		public static const ANIMATION_TYPE_TO_LAST_FRAME_LABEL: String = 'To Last Frame';
		public static const ANIMATION_TYPE_FROM_FIRST_FRAME_LABEL: String = 'From First Frame';
		public static const ANIMATION_TYPE_TO_NOW_LABEL: String = 'To Now';
		public static const ANIMATION_TYPE_FROM_NOW_LABEL: String = 'From Now';
		public static const ANIMATION_TYPE_FULL_LABEL: String = 'Full';
		public static const ANIMATION_TYPE_USER_LABEL: String = 'User Defined';
		
		public static const DEFAULT_DURATION: int = 100;
		public static const DEFAULT_DURATION_STEP: int = 50;
		public static const DEFAULT_DELAY: int = 700;
		public static const DEFAULT_MIN_DURATION: int = 50;
		public static const DEFAULT_MAX_DURATION: int = 5000;
		
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
		public var minDuration: int;
		[Bindable]
		public var maxDuration: int;

		private var _durationStep: int;
		private var _duration: int;
		private var _delay: int;
		
		private var _animationExtent: String;
		private var _animationType: String;
		private var _animationDirection: String;
		
		private var _animationUserLeftLimit: Date;
		private var _animationUserRightLimit: Date;

		public function MapTimelineConfiguration()
		{
			super();
			
			minDuration = DEFAULT_MIN_DURATION;
			maxDuration = DEFAULT_MAX_DURATION;
			_animationExtent = "PT6H";
			_duration = DEFAULT_DURATION;
			_durationStep = DEFAULT_DURATION_STEP;
			_delay = DEFAULT_DELAY;
			
			reset();
		}


		[Bindable (event=TYPE_CHANGED)]
		public function get animationType():String
		{
			return _animationType;
		}

		public function set animationType(value:String):void
		{
			if (_animationType != value)
			{
				_animationType = value;
				
				var de: DynamicEvent = new DynamicEvent(TYPE_CHANGED);
				de['value'] = _animationType;
				dispatchEvent(de);
				
				notifyConfigurationIsChanged();
			}
		}

		[Bindable (event=EXTENT_CHANGED)]
		public function get animationExtent():String
		{
			return _animationExtent;
		}

		public function set animationExtent(value:String):void
		{
			if (_animationExtent != value)
			{
				_animationExtent = value;
				
				var de: DynamicEvent = new DynamicEvent(EXTENT_CHANGED);
				de['value'] = _animationExtent;
				dispatchEvent(de);

				notifyConfigurationIsChanged();
			}
		}
		
		[Bindable (event=EXTENT_CHANGED)]
		public function get animationUserLeftLimit():Date
		{
			return _animationUserLeftLimit;
		}

		public function set animationUserLeftLimit(value: Date):void
		{
			if (_animationUserLeftLimit != value)
			{
				_animationUserLeftLimit = value;
				
				var de: DynamicEvent = new DynamicEvent(EXTENT_CHANGED);
				de['value'] = _animationExtent;
				dispatchEvent(de);

				notifyConfigurationIsChanged();
			}
		}
		
		[Bindable (event=EXTENT_CHANGED)]
		public function get animationUserRightLimit():Date
		{
			return _animationUserRightLimit;
		}

		public function set animationUserRightLimit(value:Date):void
		{
			if (_animationUserRightLimit != value)
			{
				_animationUserRightLimit = value;
				
				var de: DynamicEvent = new DynamicEvent(EXTENT_CHANGED);
				de['value'] = _animationExtent;
				dispatchEvent(de);

				notifyConfigurationIsChanged();
			}
		}

		[Bindable (event=DIRECTION_CHANGED)]
		public function get animationDirection():String
		{
			return _animationDirection;
		}

		public function set animationDirection(value:String):void
		{
			if (_animationDirection != value)
			{
				_animationDirection = value;
				
				var de: DynamicEvent = new DynamicEvent(DIRECTION_CHANGED);
				de['value'] = _animationDirection;
				dispatchEvent(de);

				notifyConfigurationIsChanged();
			}
		}

		[Bindable (event=DELAY_CHANGED)]
		public function get delay():int
		{
			return _delay;
		}

		public function set delay(value:int):void
		{
			if (_delay != value)
			{
				_delay = value;
				
				var de: DynamicEvent = new DynamicEvent(DELAY_CHANGED);
				de['delay'] = _delay;
				dispatchEvent(de);

				notifyConfigurationIsChanged();
			}
		}
		
		[Bindable (event=DURATION_CHANGED)]
		public function get duration():int
		{
			return _duration;
		}

		public function set duration(value:int):void
		{
			
			if (_duration)
			{
				_duration = value;
				
				var de: DynamicEvent = new DynamicEvent(DURATION_CHANGED);
				de['value'] = _duration;
				de['step'] = _durationStep;
				dispatchEvent(de);

				notifyConfigurationIsChanged();
			}
		}
		
		[Bindable (event=DURATION_CHANGED)]
		public function get durationStep():int
		{
			return _durationStep;
		}

		public function set durationStep(value:int):void
		{
			if (_durationStep != value)
			{
				_durationStep = value;
				
				var de: DynamicEvent = new DynamicEvent(DURATION_CHANGED);
				de['value'] = _duration;
				de['step'] = _durationStep;
				dispatchEvent(de);

				notifyConfigurationIsChanged();
			}
		}

		public function get mapVisibleUnderTimeline(): Boolean
		{
			return _mapVisibleUnderTimeline;
		}

		public function set mapVisibleUnderTimeline(value: Boolean): void
		{
			_mapVisibleUnderTimeline = value;
		}

		public function limitsChangedByUser(animationDateFrom: Date, animationDateTo: Date): void
		{
			animationType = ANIMATION_TYPE_USER;
			animationUserLeftLimit = animationDateFrom;
			animationUserRightLimit = animationDateTo;
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
			delay = storage.serializeInt("delay", delay, DEFAULT_DELAY);
			duration = storage.serializeInt("duration", duration, DEFAULT_DURATION);
			durationStep = storage.serializeInt("duration-step", durationStep, DEFAULT_DURATION_STEP);
			minDuration = storage.serializeInt("min-duration", minDuration, DEFAULT_MIN_DURATION);
			maxDuration = storage.serializeInt("max-duration", maxDuration, DEFAULT_MAX_DURATION);
			animationType = storage.serializeString("animation-type", animationType, null);
			
			if (animationType == ANIMATION_TYPE_USER)
			{
				if (storage.isLoading())
				{
					animationUserLeftLimit = ISO8601Parser.stringToDate(storage.serializeString("animation-user-left-limit", null, null));
					animationUserRightLimit = ISO8601Parser.stringToDate(storage.serializeString("animation-user-right-limit", null, null));
				} else {
					storage.serializeString("animation-user-left-limit", ISO8601Parser.dateToString(animationUserLeftLimit), null);
					storage.serializeString("animation-user-right-limit", ISO8601Parser.dateToString(animationUserRightLimit), null);
				}
			} else {
				animationExtent = storage.serializeString("animation-extent", animationExtent, null);
			}
			
			animationDirection = storage.serializeString("animation-direction", animationDirection, null);
			mapVisibleUnderTimeline = storage.serializeBool("map-visible-under-timeline", mapVisibleUnderTimeline, true);
			timelineVisibleAtStartup = storage.serializeBool("timeline-visible-at-startup", timelineVisibleAtStartup, true);
		}
		
		public function reset(): void
		{
			animationDirection = AnimationDirection.ANIMATION_DIRECTION_FORWARD;
			animationType = ANIMATION_TYPE_FULL;
			animationExtent = 'PT6H';
			duration = 100;
			delay = 700;
		}

		private function notifyConfigurationIsChanged(): void
		{
			dispatchEvent(new Event(Event.CHANGE));
		}
		public function copyConfiguration(timelineConfiguration: MapTimelineConfiguration): void
		{
			timelineConfiguration.animationDirection = _animationDirection;
			timelineConfiguration.animationExtent = _animationExtent;
			timelineConfiguration.animationType = _animationType;
			timelineConfiguration.animationUserLeftLimit = _animationUserLeftLimit;
			timelineConfiguration.animationUserRightLimit = _animationUserRightLimit;
			timelineConfiguration.delay = _delay;
			timelineConfiguration.duration = _duration;
			timelineConfiguration.durationStep =_durationStep;
		}
	}
}
