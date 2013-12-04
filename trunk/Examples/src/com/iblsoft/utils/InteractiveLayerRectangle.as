package com.iblsoft.utils
{
	import com.iblsoft.flexiweather.proj.Coord;
	import com.iblsoft.flexiweather.widgets.InteractiveLayer;
	import com.iblsoft.flexiweather.widgets.InteractiveWidget;
	import flash.display.Graphics;
	import flash.events.MouseEvent;
	import flash.geom.Point;

	public class InteractiveLayerRectangle extends InteractiveLayer
	{
		protected var m_coord1: Coord = null;
		protected var m_coord2: Coord = null;
		protected var mb_rectangleCompleted: Boolean = true;

		public function InteractiveLayerRectangle(container: InteractiveWidget = null)
		{
			super(container);
		}

		public function get coord1(): Coord
		{
			return m_coord1;
		}

		public function get coord2(): Coord
		{
			return m_coord2;
		}

		override public function onMouseClick(event: MouseEvent): Boolean
		{
			if (event.altKey || event.shiftKey || event.ctrlKey)
				return false;
			var c: Coord = container.pointToCoord(event.localX, event.localY);
			if (mb_rectangleCompleted)
			{
				m_coord1 = c;
				mb_rectangleCompleted = false;
			}
			else
				mb_rectangleCompleted = true;
			m_coord2 = c;
			invalidateDynamicPart(true);
			return true;
		}

		override public function draw(graphics: Graphics): void
		{
			graphics.clear();
			if (mb_rectangleCompleted)
				graphics.lineStyle(2, 0xff0000, 0.7, true);
			else
				graphics.lineStyle(2, 0x00ff00, 0.7, true);
			if (m_coord1 && m_coord2)
			{
				var p1: flash.geom.Point = container.coordToPoint(m_coord1);
				var p2: flash.geom.Point = container.coordToPoint(m_coord2);
				graphics.moveTo(p1.x, p1.y);
				graphics.lineTo(p2.x, p1.y);
				graphics.lineTo(p2.x, p2.y);
				graphics.lineTo(p1.x, p2.y);
				graphics.lineTo(p1.x, p1.y);
			}
			super.draw(graphics);
		}

		override public function onMouseMove(event: MouseEvent): Boolean
		{
			if (mb_rectangleCompleted)
				return false;
			m_coord2 = container.pointToCoord(event.localX, event.localY);
			invalidateDynamicPart(true);
			return true;
		}

		override public function onAreaChanged(b_finalChange: Boolean): void
		{
			invalidateDynamicPart(true);
		}
	}
}
