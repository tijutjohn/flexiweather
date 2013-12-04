package com.iblsoft.utils
{
	import com.iblsoft.flexiweather.proj.Coord;
	import com.iblsoft.flexiweather.widgets.InteractiveLayer;
	import com.iblsoft.flexiweather.widgets.InteractiveWidget;
	import flash.display.Graphics;
	import flash.events.MouseEvent;
	import flash.geom.Point;
	import spark.primitives.Graphic;

	public class InteractiveLayerPoint extends InteractiveLayer
	{
		protected var m_point: Coord = new Coord("CRS:84", 0, 0);

		public function InteractiveLayerPoint(container: InteractiveWidget = null)
		{
			super(container);
		}

		public function getPoint(): Coord
		{
			return m_point;
		}

		public function setPoint(c: Coord): void
		{
			m_point = c;
			invalidateDynamicPart(true);
		}

		override public function draw(graphics: Graphics): void
		{
			drawPoint(graphics);
			super.draw(graphics);
		}

		private function drawPoint(graphics: Graphics): void
		{
			if (!container)
				return;
			var i_crossSize: int = 3;
			graphics.lineStyle(2, 0xff0000, 0.7, true);
			var p: flash.geom.Point = container.coordToPoint(m_point);
			graphics.moveTo(p.x - i_crossSize, p.y - i_crossSize);
			graphics.lineTo(p.x + i_crossSize, p.y + i_crossSize);
			graphics.moveTo(p.x + i_crossSize, p.y - i_crossSize);
			graphics.lineTo(p.x - i_crossSize, p.y + i_crossSize);
		}

		override public function onMouseClick(event: MouseEvent): Boolean
		{
			if (event.altKey || event.shiftKey || event.ctrlKey)
				return false;
			m_point = container.pointToCoord(event.localX, event.localY);
			invalidateDynamicPart(true);
			return true;
		}
	}
}
