package com.iblsoft.flexiweather.widgets
{
	import com.iblsoft.flexiweather.proj.Coord;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.geom.Point;

	public class InteractiveLayerClickActionEvent extends Event
	{
		protected var m_coord: Coord;
		protected var m_localPoint: Point;

		public function InteractiveLayerClickActionEvent(type: String, bubbles: Boolean = false, cancelable: Boolean = false)
		{
			super(type, bubbles, cancelable);
		}

		internal function setup(iw: InteractiveWidget, mouseEvent: MouseEvent = null): InteractiveLayerClickActionEvent
		{
			if (mouseEvent != null)
			{
				m_coord = iw.pointToCoord(mouseEvent.localX, mouseEvent.localY);
				m_localPoint = new Point(mouseEvent.localX, mouseEvent.localY);
			}
			return this;
		}

		public function get coord(): Coord
		{
			return m_coord;
		}

		public function get localPoint(): Point
		{
			return m_localPoint;
		}
	}
}
