package com.iblsoft.flexiweather.widgets.containers.skins
{
	import flash.display.Graphics;
	
	import mx.utils.GraphicsUtil;
	
	import spark.primitives.Rect;
	
	public class GroupBoxBorder extends Rect
	{
		public var spaceFrom: Number;
		public var spaceTo: Number;
		
		public function GroupBoxBorder()
		{
			super();
		}
		
		override protected function draw(g: Graphics): void
		{
			if (radiusX != 0)
			{
				var rX: Number = radiusX;
				var rY: Number = (radiusY == 0) ? radiusX : radiusY;

				const q: Number = 0.292893218813453 // (srqt(2) - 1) / sqrt(2)
				var aX:Number = q * rX;		// radius - anchor pt
				var aY:Number = q * rY;		// radius - anchor pt
				var sX:Number = 2 * aX; 	// radius - control pt
				var sY:Number = 2 * aY; 	// radius - control pt

				g.moveTo(drawX + rX, drawY);
				g.lineTo(drawX + spaceFrom, drawY);
				g.moveTo(drawX + spaceTo, drawY);
				g.lineTo(drawX + width - rX, drawY);
				g.curveTo(drawX + width - sX, drawY, drawX + width - aX, drawY + aY);
				g.curveTo(drawX + width, drawY + sY, drawX + width, drawY + rY);
				g.lineTo(drawX + width, drawY + height - rY);
				g.curveTo(drawX + width, drawY + height - sY, drawX + width - aX, drawY + height - aY);
				g.curveTo(drawX + width - sX, drawY + height, drawX + width - rX, drawY + height);
				g.lineTo(drawX + rX, drawY + height);
				g.curveTo(drawX + sX, drawY + height, drawX + aX, drawY + height - aY);
				g.curveTo(drawX, drawY + height - sY, drawX, drawY + height - rY);
				g.lineTo(drawX, drawY + rY);
				g.curveTo(drawX, drawY + sX, drawX + aX, drawY + aY);
				g.curveTo(drawX + sX, drawY, drawX + rX, drawY);
			}
			else
			{
				g.moveTo(drawX, drawY);
				g.lineTo(drawX + spaceFrom, drawY);
				g.moveTo(drawX + spaceTo, drawY);
				g.lineTo(drawX + width, drawY);
				g.lineTo(drawX + width, drawY + height);
				g.lineTo(drawX, drawY + height);
				g.lineTo(drawX, drawY);
			}
		}
	}
}