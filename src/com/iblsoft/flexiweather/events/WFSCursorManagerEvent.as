package com.iblsoft.flexiweather.events
{
	import flash.events.Event;

	public class WFSCursorManagerEvent extends Event
	{
		public static var CHANGE_CURSOR: String = 'changeCursor';
		public static var CLEAR_CURSOR: String = 'clearCursor';
		public var cursorType: int;

		public function WFSCursorManagerEvent(type: String, _cursorType: int = 0, bubbles: Boolean = true, cancelable: Boolean = false)
		{
			super(type, bubbles, cancelable);
			cursorType = _cursorType;
		}
	}
}
