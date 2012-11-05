package com.iblsoft.flexiweather.widgets
{
	import flash.events.MouseEvent;
	import mx.controls.Text;

	public class InteractiveLayerClickAction extends InteractiveLayer
	{
		internal var m_textLabel: Text;
		public static const MOUSE_DOWN: String = "ilcaMouseDown";
		public static const MOUSE_MOVE: String = "ilcaMouseMoved";
		public static const MOUSE_PRESSED_MOVE: String = "ilcaMousePressedAndMoved";
		public static const MOUSE_UP: String = "ilcaMouseUp";
		public static const MOUSE_CLICKED: String = "ilcaMouseClicked";

		public function InteractiveLayerClickAction(container: InteractiveWidget)
		{
			super(container);
		}

		override public function onMouseDown(event: MouseEvent): Boolean
		{
			if (event.shiftKey || event.ctrlKey)
				return false;
			if (hasEventListener(MOUSE_DOWN))
			{
				dispatchEvent(new InteractiveLayerClickActionEvent(MOUSE_DOWN).setup(container, event));
				return true;
			}
			return false;
		}

		override public function onMouseUp(event: MouseEvent): Boolean
		{
			if (event.shiftKey || event.ctrlKey)
				return false;
			if (hasEventListener(MOUSE_UP))
			{
				dispatchEvent(new InteractiveLayerClickActionEvent(MOUSE_UP).setup(container, event));
				return true;
			}
			return false;
		}

		override public function onMouseMove(event: MouseEvent): Boolean
		{
			if (event.shiftKey || event.ctrlKey)
				return false;
			var b_handled: Boolean = false;
			if (hasEventListener(MOUSE_MOVE))
			{
				dispatchEvent(new InteractiveLayerClickActionEvent(MOUSE_MOVE).setup(container, event));
				b_handled = true;
			}
			if (event.buttonDown && hasEventListener(MOUSE_PRESSED_MOVE))
			{
				dispatchEvent(new InteractiveLayerClickActionEvent(MOUSE_PRESSED_MOVE).setup(container, event));
				b_handled = true;
			}
			return b_handled;
		}

		override public function onMouseClick(event: MouseEvent): Boolean
		{
			if (event.shiftKey || event.ctrlKey)
				return false;
			if (hasEventListener(MOUSE_CLICKED))
			{
				dispatchEvent(new InteractiveLayerClickActionEvent(MOUSE_CLICKED).setup(container, event));
				return true;
			}
			return false;
		}
	}
}
