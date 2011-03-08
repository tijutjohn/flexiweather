package com.iblsoft.flexiweather.widgets
{
	[Bindable]
	public class MapTimelineConfiguration
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
		public var durationStep: int = 1000;
		public var minDuration: int = 1000;
		public var maxDuration: int = 10000;
		
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
		
	}
}