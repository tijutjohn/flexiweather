package com.iblsoft.flexiweather.ogc.managers
{
	import com.iblsoft.flexiweather.events.WFSCursorManagerEvent;
	import com.iblsoft.flexiweather.events.WFSCursorManagerTypes;
	import flash.display.DisplayObject;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import mx.core.UIComponent;

	public class WFSCursorManager extends UIComponent
	{
		public static var instance: WFSCursorManager;
		[Embed(source = "/assets/cursors/cursor_tablet_add_control_point_to_segment.png")]
		[Bindable]
		protected var clsCursor_AddPoint: Class;
		[Embed(source = "/assets/cursors/cursor_tablet_edit_closeable.png")]
		[Bindable]
		protected var clsCursor_CloseCurve: Class;
		protected var actCursor: DisplayObject;
		protected var actCursorType: int = 0;

		/**
		 *
		 */
		public function WFSCursorManager()
		{
			WFSCursorManager.instance = this;
			super();
			//mStage.addChild(this);
			//stage.addEventListener(MouseEvent.MOUSE_MOVE, onMouseMove);
			addEventListener(Event.ADDED_TO_STAGE, onAddedToStage);
		}

		/**
		 *
		 */
		protected function onSetCursorEvent(event: WFSCursorManagerEvent): void
		{
			WFSCursorManager.instance.changeCursor(event.cursorType);
		}

		/**
		 *
		 */
		protected function onClearCursorEvent(event: WFSCursorManagerEvent): void
		{
			WFSCursorManager.instance.changeCursor(WFSCursorManagerTypes.NO_CURSOR);
		}

		/**
		 *
		 */
		public static function getCursorType(): int
		{
			return (WFSCursorManager.instance.actCursorType);
		}

		/**
		 *
		 */
		public static function setCursor(cursorType: int): void
		{
			WFSCursorManager.instance.changeCursor(cursorType);
		}

		/**
		 *
		 */
		public static function clearCursor(): void
		{
			WFSCursorManager.instance.changeCursor(WFSCursorManagerTypes.NO_CURSOR);
		}

		/**
		 *
		 */
		protected function changeCursor(cursorType: int): void
		{
			if (cursorType != actCursorType)
			{
				if (actCursor && (actCursor.parent))
				{
					removeChild(actCursor);
					actCursor = null;
				}
				// DO NOT USE CURSOR NOW
				if (cursorType == WFSCursorManagerTypes.NO_CURSOR)
				{
				}
				else if (cursorType == WFSCursorManagerTypes.CURSOR_ADD_POINT)
					actCursor = new clsCursor_AddPoint();
				else if (cursorType == WFSCursorManagerTypes.CURSOR_CLOSE_CURVE)
					actCursor = new clsCursor_CloseCurve();
				actCursorType = cursorType;
				if (actCursor)
					addChild(actCursor);
			}
		}

		/**
		 *
		 */
		protected function onAddedToStage(evt: Event): void
		{
			stage.addEventListener(WFSCursorManagerEvent.CHANGE_CURSOR, onSetCursorEvent, true);
			stage.addEventListener(WFSCursorManagerEvent.CLEAR_CURSOR, onClearCursorEvent, true);
			this.x = parent.mouseX;
			this.y = parent.mouseY;
			stage.addEventListener(MouseEvent.MOUSE_MOVE, onMouseMove);
		}

		/**
		 *
		 */
		protected function onMouseMove(event: MouseEvent): void
		{
			this.x = parent.mouseX;
			this.y = parent.mouseY;
			event.updateAfterEvent();
		}
	}
}
