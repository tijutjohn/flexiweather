package com.iblsoft.flexiweather.widgets
{
	import com.iblsoft.flexiweather.ogc.BBox;
	import com.iblsoft.flexiweather.ogc.editable.data.FeatureData;
	import com.iblsoft.flexiweather.ogc.editable.data.FeatureDataReflection;
	import com.iblsoft.flexiweather.proj.Coord;
	import com.iblsoft.flexiweather.proj.Projection;
	import com.iblsoft.flexiweather.utils.ICurveRenderer;
	import com.iblsoft.flexiweather.utils.draw.DrawMode;
	import com.iblsoft.flexiweather.utils.draw.FillStyle;
	import com.iblsoft.flexiweather.utils.draw.LineStyle;

	import flash.display.Graphics;
	import flash.display.JointStyle;
	import flash.display.LineScaleMode;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.utils.getTimer;

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

		private var _ma_coords: Array;
		private var _ma_points: Array;

		protected var m_highlightedCoord: Coord = null;
		protected var m_selectedCoord: Coord = null;
//		protected var m_highlightedLineFrom: Coord = null;
		public static const CHANGE: String = "interactiveLayerRouteChanged";
		private var _drawMode: String;

		override public function set container(value:InteractiveWidget):void
		{
			super.container = value;
		}

		public function InteractiveLayerRoute(container: InteractiveWidget = null)
		{
			//this must be null
			super(container);
			changeDrawMode(DrawMode.GREAT_ARC);
			setStyle("routeThickness", 5);
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

			coords = [];
			_ma_points = [];
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

		[Bindable(event = "pointsChanged")]
		public function get points(): Array
		{
			return _ma_points;
		}

		[Bindable(event = "coordsChanged")]
		public function get coords(): Array
		{
			return _ma_coords;
		}

		public function set coords(value: Array): void
		{
//			if (_ma_coords)
//				_ma_coords.removeEventListener(CollectionEvent.COLLECTION_CHANGE, onCoordsCollectionChanged);

			_ma_coords = value;
			_ma_points = getPointsFromCoords();

//			if (_ma_coords)
//				_ma_coords.addEventListener(CollectionEvent.COLLECTION_CHANGE, onCoordsCollectionChanged);
		}

		private function getPointsFromCoords(): Array {
			var points: Array = [];
			var total: int = _ma_coords.length;
			for (var i: int = 0; i < total; i++)
			{
				var coord: Coord = _ma_coords[i] as Coord;
				points.push(container.coordToPoint(coord));
			}
			return points;
		}

		private function notifyChange(): void
		{
			dispatchEvent(new Event("coordsChanged"));
		}

		public function clearRoute(): void
		{
			_ma_coords.splice(0, _ma_coords.length);
			_ma_points.splice(0, _ma_points.length);

//			_ma_coords.removeAll();
//			_ma_points.removeAll();
			invalidateDynamicPart();
		}

		override public function onAreaChanged(b_finalChange: Boolean): void
		{
			var total: int = _ma_coords.length;
			for (var i: int = 0; i < total; i++)
			{
				var coord: Coord = _ma_coords[i] as Coord;
				var p: Point = container.coordToPoint(coord);
				_ma_points[i] = p;
			}

			invalidateDynamicPart();
		}

		override public function onMouseDown(event: MouseEvent): Boolean
		{
			if (event.shiftKey || event.ctrlKey)
				return false;
			var c: Coord = container.pointToCoord(event.localX, event.localY);
			if (c == null)
				return false;

			var mousePoint: Point = new Point(event.localX, event.localY);
			var cHit: Coord = getHitCoord(mousePoint);
			if (cHit != null)
			{
				//setHighlightedCoord(cHit);
				m_selectedCoord = cHit;
			}
			else
			{
				_ma_coords.push(updateCoordToExtent(c));
				_ma_points.push(mousePoint);
				debugCoords("ADDed coord at then end");
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

		private function updateCoordToExtent(c: Coord): Coord
		{
			var projection: Projection = container.getCRSProjection();
			return projection.moveCoordToExtent(c);
		}

		override public function onMouseMove(event: MouseEvent): Boolean
		{
			if (event.shiftKey || event.ctrlKey)
				return false;
			var c: Coord;
			var mousePt: Point = new Point(event.localX, event.localY);
			if (m_selectedCoord == null)
			{
				c = getHitCoord(mousePt);
				setHighlightedCoord(c);
			}
			else
			{
				c = updateCoordToExtent(container.pointToCoord(event.localX, event.localY));

				var i: int = getCoordIndex(m_selectedCoord);
				if (i >= 0)
				{
					_ma_coords[i] = c;
					_ma_points[i] = mousePt;

					debugCoords("Update coord at " + i);
					notifyChange();
					m_selectedCoord = c;
					m_highlightedCoord = c;
					invalidateDynamicPart();
				}
			}
			return false;
		}

		private function getCoordIndex(coord: Coord): int
		{
			if (_ma_coords && _ma_coords.length > 0)
			{
				var total: int = _ma_coords.length;
				var proj: Projection = container.getCRSProjection();
				var crs: String = container.crs;
				for (var i: int = 0; i < total; i++)
				{
					var currCoord: Coord = _ma_coords[i] as Coord;
					if (currCoord.crs != crs)
					{
						currCoord = currCoord.convertToProjection(proj);
					}
					if (currCoord.equalsCoord(coord))
					{
						return i;
					}
				}
			}
			return -1;

		}

		private function debugCoords(str: String = ''): void
		{
			return;
			debug("debugCoords: " + str);
			var total: int = _ma_coords.length;
			for  (var i: int = 0; i < total; i++)
			{
				var coord: Coord = _ma_coords[i] as Coord;
				debug("\tILR coord["+i+"]: " + coord);
			}
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
				var i: int = _ma_coords.indexOf(c);
				_ma_coords.splice(i, 1);
				_ma_points.splice(i, 1);
				notifyChange();
				invalidateDynamicPart();
			}
			return true;
		}

		protected function onCoordsCollectionChanged(event: CollectionEvent): void
		{
			invalidateDynamicPart();
		}

		override public function draw(graphics: Graphics): void
		{
			super.draw(graphics);

			graphics.clear();
//			debug("\n\n *******************************************************************************************\n\n");
//			var time:  Number = getTimer();
			_drawMode = getStyle('drawMode');
			if (!_drawMode)
				_drawMode == DrawMode.GREAT_ARC;


			if (_ma_coords.length > 1)
			{
				var featureData: FeatureData = new FeatureData('layerRoute');
				var iw: InteractiveWidget = container;
				featureData.clippingRectangle = new Rectangle(iw.areaX, iw.areaY, iw.areaWidth, iw.areaHeight);
				featureData.featureSplitter = iw.featureSplitter;

				container.drawGeoPolyLine(getRouteRenderer, _ma_points, _drawMode, false, true, featureData);
				featureData.joinLinesFromReflections();
//				drawFeatureData(getRouteRenderer("0"), featureData);
				drawCurve(featureData);
			}

			//draw points
			drawDraggablePoints();

			notifyRouteChanged();
//			debug("Time draw: " + (getTimer() - time) + "ms");
//			debug("\n\n *******************************************************************************************\n\n");
		}

		protected function convertCoordToScreen(p: Point): Point
		{
			return p;

			//			var result: Point = master.container.coordToPoint(new Coord(master.container.crs, p.x, p.y));
			//			return result
		}
		protected function isSameAsEditablePoint(currentPoint: Point, editablePoint: Point): Boolean
		{
			var iw: InteractiveWidget = container;
			var projWidth: Number = iw.getProjectionWidthInPixels();

			var pointReflection: int = iw.pointReflection(currentPoint.x, currentPoint.y);
			if (pointReflection != 0)
				currentPoint = new Point(currentPoint.x  - pointReflection * projWidth, currentPoint.y);

			pointReflection = iw.pointReflection(editablePoint.x, editablePoint.y);
			if (pointReflection != 0)
				editablePoint = new Point(editablePoint.x  - pointReflection * projWidth, editablePoint.y);

			var distance: Number = Point.distance(currentPoint, editablePoint);

//			debug("ILR isLastEditablePoint [currentPoint: " + currentPoint + "] lastEditablePoint: " + editablePoint + " DISTANCE: " + distance);

			var isLast: Boolean = distance < 5;
			return isLast;
		}

		protected function drawCurve(m_featureData: FeatureData): void
		{
			//			return;

			//			debug("WFSFeatureEditableCurveWithBaseTimeAndValidity drawCurve");

			var reflection: FeatureDataReflection;
			var _addToLabelLayout: Boolean;

			var a_points: Array = _ma_points; //getPoints();

			//create sprites for reflections
			if (m_featureData && m_featureData.reflections)
			{
//				var displaySprite: WFSFeatureEditableSprite;

				var pointsCount: int = a_points.length;
				var ptAvg: Point;
				var gr: Graphics;

				//				m_featureData.debug();
				var totalReflections: int = m_featureData.reflectionsLength;

//				graphics.clear();

				var reflectionIDs: Array = m_featureData.reflectionsIDs;

				for (var i: int = 0; i < totalReflections; i++)
				{
					var reflectionDelta: int = reflectionIDs[i];

					reflection = m_featureData.getReflectionAt(reflectionDelta);
					if (reflection)
					{
						if (m_featureData)
							ptAvg = m_featureData.getReflectionAt(reflectionDelta).center;
						else if (pointsCount == 1)
							ptAvg = a_points[0] as Point;

//						displaySprite = getDisplaySpriteForReflectionAt(reflectionDelta);
//						gr = displaySprite.graphics;
						gr = graphics;

						if(pointsCount <= 1)
						{
//							displaySprite.clear();
//							gr.clear();
							//						debug("displaySprite.clear: pointsCount: " + pointsCount);
						} else {
//							gr.clear();

							if (m_featureData.reflectionDelta == reflectionDelta)
							{
								var renderer: ICurveRenderer = getRouteRenderer(reflectionDelta.toString());
								//							drawFeatureReflection(renderer, reflection);
								drawFeatureData(renderer, m_featureData);
							} else {
								debug("\t\t Do not draw data for " + reflectionDelta + " Feature is drawn in " + m_featureData.reflectionDelta);
							}
//							if (displaySprite)
//								displaySprite.points = reflection.points;
						}
					}
				}
			}
		}

		private function drawFeatureData(g:ICurveRenderer, m_featureData:FeatureData):void
		{
			//drawing closed feature... there must be special handling of non-visible part of feature polyline

			if (!g || !m_featureData || !m_featureData.lines)
			{
				return;
			}

			//get last point added by user
			var editablePoints: Array = _ma_points;
			var firstEditablePoint: Point = editablePoints[0] as Point;
			var lastEditablePoint: Point = editablePoints[editablePoints.length - 1] as Point;

			var p: Point;
			var points: Array = m_featureData.points;

			var linesCount: int = m_featureData.lines.length;
			var pointsCount: int = points.length;

			var iw: InteractiveWidget = container;
			var projectionHalf: Number = iw.getProjectionWidthInPixels() / 2;

			if (pointsCount > 0)
			{
				p = convertCoordToScreen(m_featureData.startPoint);

				var lastPoint: Point;

				// check NULL points...
//				g.clear();

				g.start(p.x, p.y);
				if (isSameAsEditablePoint(p, firstEditablePoint))
				{
					g.firstPoint(p.x, p.y);
				}
				g.moveTo(p.x, p.y);
				lastPoint = new Point(p.x, p.y);
//				debug(p,"ILR drawFeatureData moveTO 1: [" + p.x + " , " + p.y + " ]");
				var bNewLine: Boolean = false;
				for (var i: int = 1; i < pointsCount; i++)
				{
					p = points[i] as Point;
					if (p)
					{
						p = convertCoordToScreen(p);

						if (lastPoint)
						{
							//							var dist: Number = Point.distance(p, lastPoint);
							//							debug(p,"\tdrawFeatureData P: " + p + "   distance to last point: " + dist);
							var dist: Number = Point.distance(p, lastPoint);
							if (dist > projectionHalf)
							{
								bNewLine = true;
							}
						}
						if (bNewLine) {

//							debug("\t ILR drawFeatureData finish 1 lastPoint loop: [" + lastPoint.x + " , " + lastPoint.y + " ]");
							if (isSameAsEditablePoint(lastPoint, lastEditablePoint))
							{
								//it is real last point
								g.lastPoint(lastPoint.x, lastPoint.y);
//								debug("\t ILR drawFeatureData lastPoint 1 lastPoint loop: [" + lastPoint.x + " , " + lastPoint.y + " ]");
							}
							//this is just last point of curve, but not real last point added by user
							g.finish(lastPoint.x, lastPoint.y);
							//check if this is real last point (last added point by user) and in that case, use g.finish()
							g.start(p.x, p.y);
							if (isSameAsEditablePoint(p, firstEditablePoint))
							{
								g.firstPoint(p.x, p.y);
							}
							g.moveTo(p.x, p.y);
//							debug(p,"\t ILR drawFeatureData moveTo 2: [" + p.x + " , " + p.y + " ]");
						} else {
							g.lineTo(p.x, p.y);
//							debug(p,"\t ILR drawFeatureData lineTO 1: [" + p.x + " , " + p.y + " ]");
						}
						if (!p)
							debug("check why p is null");
						lastPoint = new Point(p.x, p.y);
						bNewLine = false;
					} else {
						bNewLine = true;
					}
				}

				if (p) {
					if (isSameAsEditablePoint(p, lastEditablePoint))
					{
						g.lastPoint(p.x, p.y);
//						debug(p,"ILR drawFeatureData lastPoint 2: [" + p.x + " , " + p.y + " ]");
					}
					g.finish(p.x, p.y);
//					debug(p,"ILR drawFeatureData finish 2: [" + p.x + " , " + p.y + " ]");
				} else {
					if (isSameAsEditablePoint(lastPoint, lastEditablePoint))
					{
						g.lastPoint(lastPoint.x, lastPoint.y);
						trace("ILR drawFeatureData lastPoint 3: [" + lastPoint.x + " , " + lastPoint.y + " ]");
					}
					g.finish(lastPoint.x, lastPoint.y);
//					debug("ILR drawFeatureData finish 3: [" + lastPoint.x + " , " + lastPoint.y + " ]");
					debug("\n");
				}
			}
		}

		public function getRouteRenderer(reflectionString: String): RouteCurveRenderer
		{
			var i_routeBorderThickness: uint = uint(getStyle("routeBorderThickness"));
			var i_routeThickness: uint = uint(getStyle("routeThickness"));
			var i_routeColor: uint = uint(getStyle("routeBorderColor"));
			var f_routeAlpha: uint = Number(getStyle("routeBorderAlpha"));

			var i_routeFillColor: uint = uint(getStyle("routeFillColor"));
			var f_routeFillAlpha: uint = Number(getStyle("routeFillAlpha"));

			var lineStyle: LineStyle = new LineStyle(i_routeThickness + 2 * i_routeBorderThickness, i_routeColor, f_routeAlpha, false, LineScaleMode.NORMAL, null, JointStyle.MITER);
			var fillStyle: FillStyle = new FillStyle(i_routeColor, f_routeAlpha);

			var lineStyle2: LineStyle = new LineStyle(i_routeThickness, i_routeFillColor, f_routeFillAlpha, false, LineScaleMode.NORMAL, null, JointStyle.MITER);
			var fillStyle2: FillStyle = new FillStyle(i_routeFillColor, f_routeFillAlpha);

			var routeLineRenderer: RouteCurveRenderer = new RouteCurveRenderer(graphics, lineStyle, fillStyle, lineStyle2, fillStyle2);
			routeLineRenderer.reflectionID = reflectionString;
			return routeLineRenderer;
		}

		private function drawDraggablePoints(): void
		{

			var pt: Point;
			var proj: Projection = container.getCRSProjection();
			var total: int = _ma_coords.length;
			for (var i: int = 0; i < total; i++)
			{
				var c: Coord = _ma_coords[i] as Coord;
//				debug("Route drawDraggablePoints: " + c + " ["+i+"] " + (_ma_points[i] as Point));
				if (c.crs != container.crs)
				{
					c = c.convertToProjection(proj);
				}
//				pt = container.coordToPoint(c);
				container.drawGeoSprite(c, drawDraggablePoint);
			}
		}

		public function drawDraggablePoint(c: Coord, x: Number, y: Number): void
		{
			var i_pointColor: uint = uint(getStyle("placemarkBorderColor"));
			var f_pointAlpha: uint = Number(getStyle("placemarkAlpha"));
			var i_pointFillColor: uint = uint(getStyle("placemarkFillColor"));
			var f_pointFillAlpha: uint = Number(getStyle("placemarkFillAlpha"));
			var i_pointHighlightFillColor: uint = uint(getStyle("placemarkHighlightFillColor"));
			var f_pointHighlightFillAlpha: uint = Number(getStyle("placemarkHighlightFillAlpha"));
			var f_pointBorder: uint = Number(getStyle("placemarkBorderThickness"));
			var f_pointRadius: uint = Number(getStyle("placemarkRadius"));

			var bHighlightCoord: Boolean = false;
			if (m_highlightedCoord && m_highlightedCoord.equalsCoord(c))
				bHighlightCoord = true;

			graphics.beginFill(bHighlightCoord ? i_pointHighlightFillColor : i_pointFillColor, f_pointFillAlpha);
			graphics.lineStyle(f_pointBorder, i_pointColor, f_pointAlpha);
			graphics.drawCircle(x, y, f_pointRadius);
			graphics.endFill();

		}
		private function notifyRouteChanged(): void
		{
			dispatchEvent(new Event(ROUTE_CHANGED));
		}

		protected function getHitCoord(ptHit: Point): Coord
		{
			var cBest: Coord = null;
			var f_best: Number = NaN;
			var placemarkRadius: uint = getStyle('placemarkRadius');
			var placemarkBorder: uint = getStyle('placemarkBorderThickness');
			var radius: int = placemarkBorder + placemarkRadius + 1;

			var projection: Projection = container.getCRSProjection();
			var projectionWidth: Number = projection.extentBBox.width;
			var crs: String = projection.crs;

			var total: int = _ma_coords.length;
			for (var i: int = 0; i < total; i++)
			{
				var c: Coord = _ma_coords[i] as Coord;
				if (c.crs != crs)
				{
					c = c.convertToProjection(projection);
				}
				for (var delta: int = -3; delta <= 3; delta++)
				{
					var deltaWidth: Number = projectionWidth * delta;
					var pt: Point = container.coordToPoint(new Coord(crs, c.x + deltaWidth, c.y));

					var f_dist: Number = pt.subtract(ptHit).length;
//					debug("ILR getHitCoord delta: "+ delta + "pt: "+ pt + " dist: "+ f_dist + " for "+ c.toLaLoCoord().toString());
					if ((f_dist <= radius && cBest == null) || f_dist < f_best)
					{
						f_best = f_dist;
						cBest = c;
					}
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

		private function debug(txt: String): void
		{
			trace("InteractiveLayerRoute: " + txt);
		}
	}
}
