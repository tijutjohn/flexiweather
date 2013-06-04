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
		
		private var mi_startX: Number;
		private var mi_startY: Number;
		
		private var _allPoints: Array;
		
//		private var mi_lastOneMoreX: Number;
//		private var mi_lastOneMoreY: Number;
		
		private var _pointsCount: int = 0;
		
		private var _traceString: String;
		private var _wasLineTo: Boolean;
		
		public function RouteCurveRenderer(graphics:Graphics, lineStyle: LineStyle = null, fillStyle: FillStyle = null, arrowLineStyle: LineStyle = null, arrowFillStyle: FillStyle = null )
		{
			super(graphics);
//			trace("new RouteCurveRenderer");
			changeStyle(ROUTE_NORMAL, lineStyle, fillStyle);
			arrowStyle(arrowLineStyle, arrowFillStyle);
		}
		

		public function get routeType():uint
		{
			return mi_routeType;
		}

		public function set routeType(value:uint):void
		{
			mi_routeType = value;
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
			routeType = i_routeType;
		}
		
		override public function started(x: Number, y: Number): void
		{
			_traceString = '';
			_wasLineTo = false;
			
			if (mi_routeType == ROUTE_NORMAL)
			{
				_pointsCount = 0;
				m_lastX = x;
				m_lastY = y;
				
				mi_startX = x;
				mi_startY = y;
				
				_allPoints = [];
				
				if (m_lineStyle)
					m_graphics.lineStyle(m_lineStyle.thickness, m_lineStyle.color, m_lineStyle.alpha, m_lineStyle.pixelHinting, m_lineStyle.scaleMode, m_lineStyle.caps, m_lineStyle.joints, m_lineStyle.miterLimit );
				
				if (m_fillStyle)
					m_graphics.beginFill(m_fillStyle.color, m_fillStyle.alpha);
				
			} else if  (mi_routeType == ROUTE_FILL) {
				
				if (m_arrowLineStyle)
					m_graphics.lineStyle(m_arrowLineStyle.thickness, m_arrowLineStyle.color, m_arrowLineStyle.alpha, m_arrowLineStyle.pixelHinting, m_arrowLineStyle.scaleMode, m_arrowLineStyle.caps, m_arrowLineStyle.joints, m_arrowLineStyle.miterLimit );
				
				if (m_arrowFillStyle)
					m_graphics.beginFill(m_arrowFillStyle.color, m_arrowFillStyle.alpha);
			}
		}
		
		override public function moveTo(x:Number, y:Number):void
		{
			if (mi_routeType == ROUTE_NORMAL)
				_allPoints.push(new Point(x, y));
			
			_traceString += "moveTo("+x+","+y+") mi_routeType: " + mi_routeType + " _allPoints: " + _allPoints.length+"\n";
			super.moveTo(x, y);
		}
		override public function lineTo(x:Number, y:Number):void
		{
			if (mi_routeType == ROUTE_NORMAL)
				_allPoints.push(new Point(x, y));
			
			_wasLineTo = true;
			_traceString += "lineTo("+x+","+y+") mi_routeType: " + mi_routeType + " _allPoints: " + _allPoints.length+"\n";
			super.lineTo(x, y);
		}
		
		private function drawArrow(x: Number, y: Number, prevX: Number, prevY: Number): void
		{
//			if (isNaN(mi_lastOneMoreX))
			if (isNaN(prevX))
				return;
				
			var ptDiffX: int;
			var ptDiffY: int;
			var ptDiff2X: int;
			var ptDiff2Y: int;
			var ptPerpX: int;
			var ptPerpY: int;
			
			var pt: Point = new Point(x,y);
			var ptPrev: Point =  new Point(prevX, prevY);
			
			
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
			_traceString += "finished("+x+","+y+") mi_routeType: " + mi_routeType + " _allPoints: " + _allPoints.length+"\n";
			if (_wasLineTo)
				trace(_traceString);
			
//			trace("finished("+x+","+y+")");
			if (mi_routeType == ROUTE_NORMAL)
			{
				
				if (m_fillStyle)
					m_graphics.endFill();
				
			} else if (mi_routeType == ROUTE_FILL) {
			
				if (m_arrowFillStyle)
					m_graphics.endFill();
			}

			
			switch(mi_routeType)
			{
				case ROUTE_NORMAL_ARROW:
				case ROUTE_FILL_ARROW:
//					trace("\tRouterenderer finished: type: " + mi_routeType + " ["+x+","+y+"] start ["+mi_startX+","+mi_startY+"] last ["+m_lastX+","+m_lastY+"] last-1 ["+mi_lastOneMoreX+","+mi_lastOneMoreY+"]");
					drawArrow(x, y, mi_startX, mi_startY);
					break;
			}
			
			if (mi_routeType == ROUTE_NORMAL)
			{
				if (_allPoints.length > 0)
				{
					if (_allPoints.length > 1)
					{
						trace("debug");
					}
					routeType = ROUTE_FILL;
					var currPoint: Point = _allPoints.shift() as Point;
					started(currPoint.x, currPoint.y)
					var cnt: int = 0;
					while (currPoint)
					{
						if (cnt == 0)
							moveTo(currPoint.x, currPoint.y);
						else
							lineTo(currPoint.x, currPoint.y);
						
						if (_allPoints.length == 0)
						{
							finished(currPoint.x, currPoint.y);
						}
						
						cnt++;
						currPoint = _allPoints.shift() as Point;
					}
					
					routeType = ROUTE_NORMAL;
					
				}
				
			}
		}
	}
}