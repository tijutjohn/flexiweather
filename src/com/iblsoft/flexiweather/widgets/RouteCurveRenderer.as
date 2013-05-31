package com.iblsoft.flexiweather.widgets
{
	import com.iblsoft.flexiweather.utils.GraphicsCurveRenderer;
	import com.iblsoft.flexiweather.utils.draw.FillStyle;
	import com.iblsoft.flexiweather.utils.draw.LineStyle;
	
	import flash.display.Graphics;
	import flash.geom.Point;
	
	import spark.layouts.RowAlign;
	
	public class RouteCurveRenderer extends GraphicsCurveRenderer
	{
		public static const ROUTE_NORMAL: uint = 0;
		public static const ROUTE_NORMAL_ARROW: uint = 1;
		public static const ROUTE_FILL: uint = 2;
		public static const ROUTE_FILL_ARROW: uint = 3;
		
		private var m_arrowLineStyle: LineStyle;
		private var m_arrowFillStyle: FillStyle;
		
		private var m_lineStyle: LineStyle;
		private var m_fillStyle: FillStyle;
		
		private var mi_routeType: uint;
		
		private var mi_lastOneMoreX: int;
		private var mi_lastOneMoreY: int;
		
		public function RouteCurveRenderer(graphics:Graphics, i_routeType: uint, lineStyle: LineStyle = null, fillSyle: FillStyle = null, arrowLineStyle: LineStyle = null, arrowFillStyle: FillStyle = null )
		{
			super(graphics);
			
			changeStyle(i_routeType, lineStyle, fillSyle);
			arrowStyle(arrowLineStyle, arrowFillStyle);
		}
		
		public function arrowStyle(lineStyle: LineStyle = null, fillSyle: FillStyle = null): void
		{
			m_arrowLineStyle = lineStyle;
			m_arrowFillStyle = fillSyle;
		}
		
		public function changeStyle(i_routeType: uint, lineStyle: LineStyle = null, fillSyle: FillStyle = null): void
		{
			m_lineStyle = lineStyle;
			m_fillStyle = fillSyle;
			mi_routeType = i_routeType;
		}
		
		override public function started(x: Number, y: Number): void
		{
//			trace("Route renderer started: " + mi_recursionDepth);
			if (m_lineStyle)
				m_graphics.lineStyle(m_lineStyle.thickness, m_lineStyle.color, m_lineStyle.alpha, m_lineStyle.pixelHinting, m_lineStyle.scaleMode, m_lineStyle.caps, m_lineStyle.joints, m_lineStyle.miterLimit );
			
			if (m_fillStyle)
				m_graphics.beginFill(m_fillStyle.color, m_fillStyle.alpha);
		}
		
		override public function lineTo(x:Number, y:Number):void
		{
			mi_lastOneMoreX = m_lastX;
			mi_lastOneMoreY = m_lastY;
			
			super.lineTo(x, y);
		}
		private function drawArrow(x: Number, y: Number): void
		{
			if (isNaN(mi_lastOneMoreX))
				return;
				
			var ptDiffX: int;
			var ptDiffY: int;
			var ptDiff2X: int;
			var ptDiff2Y: int;
			var ptPerpX: int;
			var ptPerpY: int;
			
			var pt: Point = new Point(x,y);
//			var ptPrev: Point =  new Point(x, y + 5);
			var ptPrev: Point =  new Point(mi_lastOneMoreX, mi_lastOneMoreY);
			
//			trace("Route renderer drawArrow: " + mi_recursionDepth + " ["+pt+"] last ["+ptPrev+"]");
			
			var ptDiff: Point = pt.subtract(ptPrev);
			ptDiff.normalize(15);
			ptDiffX = ptDiff.x;
			ptDiffY = ptDiff.y;
			var ptDiff2: Point = new Point(ptDiffX, ptDiffY);
			ptDiff2.normalize(8);
			ptDiff2X = ptDiff2.x;
			ptDiff2Y = ptDiff2.y;
			var ptPerp: Point = new Point(ptDiffY, -ptDiffX);
			ptPerp.normalize(5);
			ptPerpX = ptPerp.x;
			ptPerpY = ptPerp.y;
			
			if (m_arrowLineStyle)
				m_graphics.lineStyle(m_arrowLineStyle.thickness, m_arrowLineStyle.color, m_arrowLineStyle.alpha, m_arrowLineStyle.pixelHinting, m_arrowLineStyle.scaleMode, m_arrowLineStyle.caps, m_arrowLineStyle.joints, m_arrowLineStyle.miterLimit );
			
			if (m_arrowFillStyle)
				m_graphics.beginFill(m_arrowFillStyle.color, m_arrowFillStyle.alpha);
			
			moveTo(x - ptDiff2X, y - ptDiff2Y);
			lineTo(x + ptPerpX - ptDiffX, y + ptPerpY - ptDiffY);
			lineTo(x - ptPerpX - ptDiffX, y - ptPerpY - ptDiffY);
			lineTo(x - ptDiff2X, y - ptDiff2Y);
			
			if (m_arrowFillStyle)
				m_graphics.endFill();
		}
		
		override public function finished(x: Number, y: Number): void
		{
//			trace("Route renderer finished: " + mi_recursionDepth + " ["+x+","+y+"] last ["+m_lastX+","+m_lastY+"]");
			
			if (m_fillStyle)
				m_graphics.endFill();
			
			
			
			switch(mi_routeType)
			{
				case ROUTE_NORMAL_ARROW:
				case ROUTE_FILL_ARROW:
					drawArrow(x, y);
			}
		}
	}
}