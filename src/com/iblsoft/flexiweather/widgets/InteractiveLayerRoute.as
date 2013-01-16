package com.iblsoft.flexiweather.widgets
{
	import com.iblsoft.flexiweather.proj.Coord;
	import com.iblsoft.flexiweather.proj.Projection;
	import flash.display.Graphics;
	import flash.display.JointStyle;
	import flash.display.LineScaleMode;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.geom.Point;
	import mx.collections.ArrayCollection;
	import mx.events.CollectionEvent;
	import mx.events.FlexEvent;

	/**
	 *  Color of the route border.
	 *  if not overriden for the class, the default value is <code>0x000000</code>.
	 */
	[Style(name = "routeBorderColor", type = "uint", format = "Color", inherit = "no")]
	/**
	 *  The alpha of the content background for this component.
	 *
	 *  @langversion 3.0
	 *  @playerversion Flash 10
	 *  @playerversion AIR 1.5
	 *  @productversion Flex 4
	 */
	[Style(name = "routeBorderAlpha", type = "Number", inherit = "yes", theme = "spark, mobile", minValue = "0.0", maxValue = "1.0")]
	/**
	 *  The route border thickness.
	 *  The default value is 1.
	 */
	[Style(name = "routeBorderThickness", type = "Number", format = "Length", inherit = "no")]
	/**
	 *  The route thickness.
	 *  The default value is 1.
	 */
	[Style(name = "routeThickness", type = "Number", format = "Length", inherit = "no")]
	/**
	 *  Color of the fill of route.
	 *  if not overriden for the class, the default value is <code>0x00FF00</code>.
	 */
	[Style(name = "routeFillColor", type = "uint", format = "Color", inherit = "no")]
	/**
	 *  The alpha of the route fill.
	 *
	 *  @langversion 3.0
	 *  @playerversion Flash 10
	 *  @playerversion AIR 1.5
	 *  @productversion Flex 4
	 */
	[Style(name = "routeFillAlpha", type = "Number", inherit = "yes", theme = "spark, mobile", minValue = "0.0", maxValue = "1.0")]
	/**
	 *  Color of the placemark.
	 *  if not overriden for the class, the default value is <code>0x000000</code>.
	 */
	[Style(name = "placemarkBorderColor", type = "uint", format = "Color", inherit = "no")]
	/**
	 *  The route border thickness.
	 *  The default value is 1.
	 */
	[Style(name = "placemarkBorderThickness", type = "Number", format = "Length", inherit = "no")]
	/**
	 *  The route border thickness.
	 *  The default value is 5.
	 */
	[Style(name = "placemarkRadius", type = "Number", format = "Length", inherit = "no")]
	/**
	 *  The alpha of the content background for this component.
	 *
	 *  @langversion 3.0
	 *  @playerversion Flash 10
	 *  @playerversion AIR 1.5
	 *  @productversion Flex 4
	 */
	[Style(name = "placemarkAlpha", type = "Number", inherit = "yes", theme = "spark, mobile", minValue = "0.0", maxValue = "1.0")]
	/**
	 *  The alpha of the content background for this component.
	 *
	 *  @langversion 3.0
	 *  @playerversion Flash 10
	 *  @playerversion AIR 1.5
	 *  @productversion Flex 4
	 */
	[Style(name = "placemarkHighlightFillAlpha", type = "Number", inherit = "yes", theme = "spark, mobile", minValue = "0.0", maxValue = "1.0")]
	/**
	 *  Color of the route.
	 *  if not overriden for the class, the default value is <code>0x000000</code>.
	 */
	[Style(name = "placemarkFillColor", type = "uint", format = "Color", inherit = "no")]
	/**
	 *  The alpha of the content background for this component.
	 *
	 *  @langversion 3.0
	 *  @playerversion Flash 10
	 *  @playerversion AIR 1.5
	 *  @productversion Flex 4
	 */
	[Style(name = "placemarkHighlightFillAlpha", type = "Number", inherit = "yes", theme = "spark, mobile", minValue = "0.0", maxValue = "1.0")]
	/**
	 *  Color of the route.
	 *  if not overriden for the class, the default value is <code>0x000000</code>.
	 */
	[Style(name = "placemarkHighlightFillColor", type = "uint", format = "Color", inherit = "no")]
	/**
	 *  The alpha of the content background for this component.
	 *
	 *  @langversion 3.0
	 *  @playerversion Flash 10
	 *  @playerversion AIR 1.5
	 *  @productversion Flex 4
	 */
	[Style(name = "placemarkHighlightFillAlpha", type = "Number", inherit = "yes", theme = "spark, mobile", minValue = "0.0", maxValue = "1.0")]
	/**
	 *  Drawing mode. One of 2 possible values InteractiveLayerRoute.DRAW_MODE_PLAIN and InteractiveLayerRoute.DRAW_MODE_GREAT_ARC
	 *  if not overriden for the class, the default value is <code>InteractiveLayerRoute.DRAW_MODE_GREAT_ARC</code>.
	 */
	[Style(name = "drawMode", inherit = "no", type = "String", enumeration = "plain,greatArc")]
	[Event(name = "routeChanged", type = "flash.events.Event")]
	public class InteractiveLayerRoute extends InteractiveLayer
	{
		public static const ROUTE_CHANGED: String = 'routeChanged';
		public static const DRAW_MODE_PLAIN: String = 'plain';
		public static const DRAW_MODE_GREAT_ARC: String = 'greatArc';
		private var _ma_coords: ArrayCollection;
		protected var m_highlightedCoord: Coord = null;
		protected var m_selectedCoord: Coord = null;
//		protected var m_highlightedLineFrom: Coord = null;
		public static const CHANGE: String = "interactiveLayerRouteChanged";
		private var _drawMode: String;

		public function InteractiveLayerRoute(container: InteractiveWidget = null)
		{
			//this must be null 
			super(container);
			changeDrawMode(DRAW_MODE_GREAT_ARC);
			setStyle("routeThickness", 1);
			setStyle("routeBorderThickness", 1);
			setStyle("routeBorderColor", 0x000000);
			setStyle("routeBorderAlpha", 1.0);
			setStyle("routeFillColor", 0x00FF00);
			setStyle("routeFillAlpha", 1.0);
			setStyle("placemarkColor", 0x000000);
			setStyle("placemarkAlpha", 1.0);
			setStyle("placemarkFillColor", 0x00FF00);
			setStyle("placemarkFillAlpha", 1.0);
			setStyle("placemarkHighlightFillColor", 0xFFFFFF);
			setStyle("placemarkHighlightFillAlpha", 1.0);
			setStyle("placemarkBorderThickness", 1);
			setStyle("placemarkRadius", 5);
			coords = new ArrayCollection();
		}

		public function changeDrawMode(value: String): void
		{
			_drawMode = getStyle("drawMode");
			if (_drawMode != value)
			{
				setStyle("drawMode", value);
				invalidateDynamicPart(true);
			}
		}

		[Bindable(event = "coordsChanged")]
		public function get coords(): ArrayCollection
		{
			return _ma_coords;
		}

		public function set coords(value: ArrayCollection): void
		{
			if (_ma_coords)
				_ma_coords.removeEventListener(CollectionEvent.COLLECTION_CHANGE, onCoordsCollectionChanged);
			_ma_coords = value;
			if (_ma_coords)
				_ma_coords.addEventListener(CollectionEvent.COLLECTION_CHANGE, onCoordsCollectionChanged);
		}

		private function notifyChange(): void
		{
			dispatchEvent(new Event("coordsChanged"));
		}

		public function clearRoute(): void
		{
			_ma_coords.removeAll();
			invalidateDynamicPart();
		}

		override public function onAreaChanged(b_finalChange: Boolean): void
		{
			invalidateDynamicPart();
		}

		override public function onMouseDown(event: MouseEvent): Boolean
		{
			if (event.shiftKey || event.ctrlKey)
				return false;
			var c: Coord = container.pointToCoord(event.localX, event.localY);
			if (c == null)
				return false;
			var cHit: Coord = getHitCoord(new Point(event.localX, event.localY));
			if (cHit != null)
			{
				//setHighlightedCoord(cHit);
				m_selectedCoord = cHit;
			}
			else
			{
				_ma_coords.addItem(c);
				notifyChange();
				setHighlightedCoord(c);
				m_selectedCoord = c;
			}
			return true;
		}

		override public function onMouseUp(event: MouseEvent): Boolean
		{
			if (event.shiftKey || event.ctrlKey)
				return false;
			m_selectedCoord = null;
			invalidateDynamicPart();
			return true;
		}

		override public function onMouseMove(event: MouseEvent): Boolean
		{
			if (event.shiftKey || event.ctrlKey)
				return false;
			var c: Coord;
			if (m_selectedCoord == null)
			{
				var mousePt: Point = new Point(event.localX, event.localY);
				c = getHitCoord(mousePt);
				setHighlightedCoord(c);
			}
			else
			{
				c = container.pointToCoord(event.localX, event.localY);
				var i: int = _ma_coords.getItemIndex(m_selectedCoord);
				_ma_coords.setItemAt(c, i);
				notifyChange();
				m_selectedCoord = c;
				m_highlightedCoord = c;
				invalidateDynamicPart();
			}
			return true;
		}

		override public function onMouseDoubleClick(event: MouseEvent): Boolean
		{
			if (event.shiftKey || event.ctrlKey)
				return false;
			var c: Coord;
			var mousePt: Point = new Point(event.localX, event.localY);
			c = getHitCoord(mousePt);
			if (c != null)
			{
				var i: int = _ma_coords.getItemIndex(c);
				_ma_coords.removeItemAt(i);
				notifyChange();
				invalidateDynamicPart();
			}
			return true;
		}

		protected function onCoordsCollectionChanged(event: CollectionEvent): void
		{
			invalidateDynamicPart();
		}

		protected function drawLineSegment(c1: Coord, c2: Coord): void
		{
			if (_drawMode == DRAW_MODE_PLAIN)
				drawCoordsPath([c1, c2]);
			else if (_drawMode == DRAW_MODE_GREAT_ARC)
			{
				var coords: Array = Coord.interpolateGreatArc(c1, c2, distanceValidator);
				drawCoordsPath(coords);
			}
		}

		public function distanceValidator(c1: Coord, c2: Coord): Boolean
		{
			c1 = c1.toLaLoCoord();
			c2 = c2.toLaLoCoord();
			var dist: Number = c1.distanceTo(c2);
			return (dist < 100);
		}

		override public function draw(graphics: Graphics): void
		{
			super.draw(graphics);
			_drawMode = getStyle('drawMode');
			if (!_drawMode)
				_drawMode == DRAW_MODE_GREAT_ARC;
			if (_ma_coords.length > 1)
			{
				var pointer: int = 0;
				var total: int = _ma_coords.length - 1;
				while (pointer < total)
				{
					var c1: Coord = _ma_coords.getItemAt(pointer) as Coord;
					var c2: Coord = _ma_coords.getItemAt(pointer + 1) as Coord;
					drawLineSegment(c1, c2);
					pointer++;
				}
				var i_pointColor: uint = uint(getStyle("placemarkBorderColor"));
				var f_pointAlpha: uint = Number(getStyle("placemarkAlpha"));
				var i_pointFillColor: uint = uint(getStyle("placemarkFillColor"));
				var f_pointFillAlpha: uint = Number(getStyle("placemarkFillAlpha"));
				var i_pointHighlightFillColor: uint = uint(getStyle("placemarkHighlightFillColor"));
				var f_pointHighlightFillAlpha: uint = Number(getStyle("placemarkHighlightFillAlpha"));
				var f_pointBorder: uint = Number(getStyle("placemarkBorderThickness"));
				var f_pointRadius: uint = Number(getStyle("placemarkRadius"));
			}
			var pt: Point;
			for each (var c: Coord in _ma_coords)
			{
				pt = container.coordToPoint(c);
				graphics.beginFill(m_highlightedCoord != c ? i_pointFillColor : i_pointHighlightFillColor, f_pointFillAlpha);
				graphics.lineStyle(f_pointBorder, i_pointColor, f_pointAlpha);
				graphics.drawCircle(pt.x, pt.y, f_pointRadius);
				graphics.endFill();
			}
			notifyRouteChanged();
		}

		private function notifyRouteChanged(): void
		{
			dispatchEvent(new Event(ROUTE_CHANGED));
		}

		private function drawCoordsPath(coordsForDrawing: Array): void
		{
			var ptPrev: Point;
			var pt: Point;
			var i_routeBorderThickness: uint = uint(getStyle("routeBorderThickness"));
			var i_routeThickness: uint = uint(getStyle("routeThickness"));
			var i_routeColor: uint = uint(getStyle("routeBorderColor"));
			var f_routeAlpha: uint = Number(getStyle("routeBorderAlpha"));
			var i_routeFillColor: uint = uint(getStyle("routeFillColor"));
			var f_routeFillAlpha: uint = Number(getStyle("routeFillAlpha"));
			var total: int = coordsForDrawing.length;
			var ptX: Number;
			var ptY: Number;
			var ptDiff2X: Number;
			var ptDiff2Y: Number;
			var ptDiffX: Number;
			var ptDiffY: Number;
			var ptPerpX: Number;
			var ptPerpY: Number;
			for (var i: int = 0; i < total; i++)
			{
				var c: Coord = coordsForDrawing[i] as Coord;
				pt = container.coordToPoint(c);
				if (ptPrev != null)
				{
					ptX = pt.x;
					ptY = pt.y;
					//border
					graphics.beginFill(i_routeColor, f_routeAlpha);
					graphics.lineStyle(i_routeThickness + 2 * i_routeBorderThickness, i_routeColor, f_routeAlpha, false, LineScaleMode.NORMAL, null, JointStyle.MITER);
					graphics.moveTo(ptPrev.x, ptPrev.y);
					graphics.lineTo(ptX, ptY);
					graphics.endFill();
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
					if (i == (total - 1))
					{
						graphics.beginFill(i_routeFillColor, f_routeFillAlpha);
						graphics.moveTo(ptX - ptDiff2X, ptY - ptDiff2Y);
						graphics.lineTo(ptX + ptPerpX - ptDiffX, ptY + ptPerpY - ptDiffY);
						graphics.lineTo(ptX - ptPerpX - ptDiffX, ptY - ptPerpY - ptDiffY);
						graphics.lineTo(ptX - ptDiff2X, ptY - ptDiff2Y);
						graphics.endFill();
					}
					//fill route
					graphics.beginFill(i_routeFillColor, f_routeFillAlpha);
					graphics.lineStyle(i_routeThickness, i_routeFillColor, f_routeFillAlpha, false, LineScaleMode.NORMAL, null, JointStyle.MITER);
					graphics.moveTo(ptPrev.x, ptPrev.y);
					graphics.lineTo(ptX, ptY);
					graphics.endFill();
					if (i == (total - 1))
					{
						//end arrow fill
						graphics.beginFill(i_routeFillColor, f_routeFillAlpha);
						graphics.moveTo(ptX - ptDiff2X, ptY - ptDiff2Y);
						graphics.lineTo(ptX + ptPerpX - ptDiffX, ptY + ptPerpY - ptDiffY);
						graphics.lineTo(ptX - ptPerpX - ptDiffX, ptY - ptPerpY - ptDiffY);
						graphics.lineTo(ptX - ptDiff2X, ptY - ptDiff2Y);
						graphics.endFill();
					}
				}
				ptPrev = pt;
			}
		}

		protected function getHitCoord(ptHit: Point): Coord
		{
			var cBest: Coord = null;
			var f_best: Number = NaN;
			var placemarkRadius: uint = getStyle('placemarkRadius');
			var placemarkBorder: uint = getStyle('placemarkBorderThickness');
			var radius: int = placemarkBorder + placemarkRadius + 1;
			for each (var c: Coord in _ma_coords)
			{
				var pt: Point = container.coordToPoint(c);
				var f_dist: Number = pt.subtract(ptHit).length;
				if ((f_dist <= radius && cBest == null) || f_dist < f_best)
				{
					f_best = f_dist;
					cBest = c;
				}
			}
			return cBest;
		}

		protected function setHighlightedCoord(c: Coord): void
		{
			if (m_highlightedCoord != c)
			{
				m_highlightedCoord = c;
				invalidateDynamicPart();
			}
		}
	}
}
