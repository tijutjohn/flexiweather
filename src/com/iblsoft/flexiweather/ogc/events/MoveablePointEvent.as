package com.iblsoft.flexiweather.ogc.events
{
	import com.iblsoft.flexiweather.ogc.FeatureBase;
	import com.iblsoft.flexiweather.ogc.editable.MoveablePoint;
	import flash.events.Event;

	public class MoveablePointEvent extends Event
	{
		public static const MOVEABLE_POINT_SELECTION_CHANGE: String = 'moveablePointSelectionChange';
		
		public static const MOVEABLE_POINT_CLICK: String = 'moveablePointClick';
		public static const MOVEABLE_POINT_MOVE: String = 'moveablePointDown';
		public static const MOVEABLE_POINT_DOWN: String = 'moveablePointDown';
		public static const MOVEABLE_POINT_UP: String = 'moveablePointUp';
		public static const MOVEABLE_POINT_OVER: String = 'moveablePointOver';
		public static const MOVEABLE_POINT_OUT: String = 'moveablePointOut';
		public static const MOVEABLE_POINT_DRAG_START: String = 'moveablePointDragStart';
		public static const MOVEABLE_POINT_DRAG_END: String = 'moveablePointDragEnd';
		public var x: int;
		public var y: int;
		public var point: MoveablePoint;
		public var feature: FeatureBase;

		public function MoveablePointEvent(type: String, bubbles: Boolean = false, cancelable: Boolean = false)
		{
			super(type, bubbles, cancelable);
		}

		override public function clone(): Event
		{
			var event: MoveablePointEvent = new MoveablePointEvent(type, bubbles);
			event.x = x;
			event.y = y;
			event.point = point;
			event.feature = feature;
			return event;
		}
	}
}
