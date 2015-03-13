package com.iblsoft.flexiweather.ogc.editable
{
	import com.iblsoft.flexiweather.ogc.FeatureUpdateContext;
	import com.iblsoft.flexiweather.ogc.editable.IObjectWithBaseTimeAndValidity;
	import com.iblsoft.flexiweather.ogc.editable.WFSFeatureEditableCurve;
	import com.iblsoft.flexiweather.ogc.editable.WFSFeatureEditableMode;
	import com.iblsoft.flexiweather.ogc.editable.data.FeatureData;
	import com.iblsoft.flexiweather.ogc.editable.data.FeatureDataReflection;
	import com.iblsoft.flexiweather.ogc.wfs.IWFSCurveFeature;
	import com.iblsoft.flexiweather.ogc.wfs.WFSFeatureEditableSprite;
	import com.iblsoft.flexiweather.proj.Coord;
	import com.iblsoft.flexiweather.utils.CubicBezier;
	import com.iblsoft.flexiweather.utils.ICurveRenderer;
	import com.iblsoft.flexiweather.utils.ISO8601Parser;
	import com.iblsoft.flexiweather.utils.draw.DrawMode;
	import com.iblsoft.flexiweather.widgets.InteractiveWidget;

	import flash.display.Graphics;
	import flash.geom.Point;
	import flash.geom.Rectangle;

	public class WFSFeatureEditableCurveWithBaseTimeAndValidity extends WFSFeatureEditableCurve implements IObjectWithBaseTimeAndValidity, IWFSCurveFeature
	{
		protected var m_baseTime: Date;
		protected var m_validity: Date;
		protected var m_curvePoints: Array;

		public function WFSFeatureEditableCurveWithBaseTimeAndValidity(
				s_namespace: String, s_typeName: String, s_featureId: String)
		{
			super(s_namespace, s_typeName, s_featureId);
		}

		public function getRenderer(reflection: int): ICurveRenderer
		{
			return null;
		}

		public function getRendererGraphics(reflection: int): Graphics
		{
			var gr: Graphics = graphics;

			var displaySprite: WFSFeatureEditableSprite = getDisplaySpriteForReflectionAt(reflection);
			if (displaySprite)
			{
				gr = displaySprite.graphics;
			}
			return gr;
		}

		public function clearGraphics(): void
		{
			graphics.clear();
		}

		override public function update(changeFlag: FeatureUpdateContext): void
		{
			if (!master)
				return;

//			debug("\n\n WFSFeatureEditableCurveWithBaseTimeAndValidity update");
			super.update(changeFlag);

			clearGraphics();

			beforeCurveComputing();

			//precompute curve (FeatureData) for drawing
			computeCurve();

			beforeCurveRendering();

			// draw curve
			drawCurve();

			//draw editable points (user can drag them)
			updateEditablePoints(changeFlag);

			afterCurveRendering();
		}

		protected function isReflectionEdgePoint(points: Array, position: int): Boolean
		{
			var total: int = points.length;
			//check if next point is null
			if (position < (total - 1))
			{
				if (points[position + 1] == null)
					return true;
			}
			//check if previous point is null
			if (position > 0)
			{
				if (points[position - 1] == null)
					return true;
			}
			return false;
		}

		/**
		 * This function is called before computeCurve method. You can update data or properties, which are needed for computeCurve method()
		 *
		 */
		protected function beforeCurveComputing(): void
		{

		}

		/**
		 * This method is called after computeCurve and before drawCurve()
		 *
		 */
		protected function beforeCurveRendering(): void
		{
			var reflection: FeatureDataReflection;
			var a_points: Array = getPoints();

			//create sprites for reflections
			if (m_featureData && m_featureData.reflections)
			{

				var pointsCount: int = a_points.length;
				var reflectionIDs: Array = m_featureData.reflectionsIDs;

				if (reflectionIDs.length > 0)
				{
					if (!presentInViewBBox)
					{
						notifyFeatureInsideViewBBox();
						return;
					}
				} else if (presentInViewBBox) {
					notifyFeatureOutsideViewBBox();
				}
			} else if (presentInViewBBox) {
				notifyFeatureOutsideViewBBox();
			}


		}

		/**
		 * This method is called after drawCurve method
		 *
		 */
		protected function afterCurveRendering(): void
		{

		}

		protected function computeCurve(): void
		{
//			debug("WFSFeatureEditableCurveWithBaseTimeAndValidity computeCurve");

			var a_points: Array = getPoints();

//			if(a_points.length > 0)
//			{
				if (master)
				{

					initializeFeatureData();
					//DEBUG - check for non smooth (to have less coordinates
//					smooth = false;

					var b_justCompute: Boolean = true;
					var iw: InteractiveWidget = master.container;

					//curves will be not drawn, just compute, to be able to draw each reflection separately
					if (smooth)
						iw.drawSmoothPolyLine(getRenderer, a_points, DrawMode.PLAIN, false, b_justCompute, m_featureData);
					else
						iw.drawGeoPolyLine(getRenderer, a_points, DrawMode.PLAIN, false, b_justCompute, m_featureData);

					m_featureData.joinLinesFromReflections();
				}
//			}
		}

	 	protected function drawCurve(): void
		{
//			return;

//			debug("WFSFeatureEditableCurveWithBaseTimeAndValidity drawCurve");

			var reflection: FeatureDataReflection;
			var _addToLabelLayout: Boolean;

			var a_points: Array = getPoints();

			//create sprites for reflections
			if (m_featureData && m_featureData.reflections)
			{
				var displaySprite: WFSFeatureEditableSprite;

				var pointsCount: int = a_points.length;
				var ptAvg: Point;
				var gr: Graphics;

//				m_featureData.debug();

				graphics.clear();

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

						displaySprite = getDisplaySpriteForReflectionAt(reflectionDelta);
						gr = displaySprite.graphics;

						if(pointsCount <= 1)
						{
							displaySprite.clear();
							//						debug("displaySprite.clear: pointsCount: " + pointsCount);
						} else {
							gr.clear();

							if (m_featureData.reflectionDelta == reflectionDelta)
							{
								var renderer: ICurveRenderer = getRenderer(reflectionDelta);
	//							drawFeatureReflection(renderer, reflection);
								drawFeatureData(renderer, m_featureData);
							} else {
								debug("\t\t Do not draw data for " + reflectionDelta + " Feature is drawn in " + m_featureData.reflectionDelta);
							}
							if (displaySprite)
								displaySprite.points = reflection.points;
						}
					}
				}
			}
		}

		protected function convertCoordToScreen(p: Point): Point
		{
			return p;

//			var result: Point = master.container.coordToPoint(new Coord(master.container.crs, p.x, p.y));
//			return result
		}

		protected function drawFeatureData(g: ICurveRenderer, m_featureData: FeatureData): void
		{
			if (!g || !m_featureData || !m_featureData.lines)
			{
				return;
			}

			if (!m_featureData.startPoint)
			{
				trace("Problem: Start point is null");
				return;
			}

			//get last point added by user
			var editablePoints: Array = getPoints(0);
			var firstEditablePoint: Point = editablePoints[0] as Point;
			var lastEditablePoint: Point = editablePoints[editablePoints.length - 1] as Point;


//			debug("\n\n");
//			debug("drawFeatureData");
			var p: Point;
			var points: Array = m_featureData.points;
			var linesCount: int = m_featureData.lines.length;
			var pointsCount: int = points.length;

			var iw: InteractiveWidget = master.container;
			var projectionHalf: Number = iw.getProjectionWidthInPixels() / 2;

			if (pointsCount > 0)
			{
				p = convertCoordToScreen(m_featureData.startPoint);

				var lastPoint: Point;

				// check NULL points...
				g.clear();

				g.start(p.x, p.y);
				if (isSameAsEditablePoint(p, firstEditablePoint))
				{
					g.firstPoint(p.x, p.y);
				}
				g.moveTo(p.x, p.y);
				lastPoint = new Point(p.x, p.y);
				debugStrangePoints(p,"drawFeatureReflection moveTO 1: [" + p.x + " , " + p.y + " ]");
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
//							debugStrangePoints(p,"\tdrawFeatureData P: " + p + "   distance to last point: " + dist);
							var dist: Number = Point.distance(p, lastPoint);
							if (dist > projectionHalf)
							{
								bNewLine = true;
							}
						}
						if (bNewLine) {

							debugStrangePoints(lastPoint,"\t drawFeatureReflection finish 1 lastPoint loop: [" + lastPoint.x + " , " + lastPoint.y + " ]");
							g.finish(lastPoint.x, lastPoint.y);
							//check if this is real last point (last added point by user) and in that case, use g.finish()
							if (isSameAsEditablePoint(lastPoint, lastEditablePoint))
							{
								//it is real last point
								g.lastPoint(lastPoint.x, lastPoint.y);
								debugStrangePoints(lastPoint,"\t drawFeatureReflection lastPoint 1 lastPoint loop: [" + lastPoint.x + " , " + lastPoint.y + " ]");
								//this is just last point of curve, but not real last point added by user
							}
							g.start(p.x, p.y);
							if (isSameAsEditablePoint(p, firstEditablePoint))
							{
								g.firstPoint(p.x, p.y);
							}
							g.moveTo(p.x, p.y);
							debugStrangePoints(p,"\t drawFeatureReflection moveTo 2: [" + p.x + " , " + p.y + " ]");
						} else {
							g.lineTo(p.x, p.y);
							debugStrangePoints(p,"\t drawFeatureReflection lineTO 1: [" + p.x + " , " + p.y + " ]");
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
					g.finish(p.x, p.y);
					debugStrangePoints(p,"drawFeatureReflection finish 2: [" + p.x + " , " + p.y + " ]");
					if (isSameAsEditablePoint(p, lastEditablePoint))
					{
						g.lastPoint(p.x, p.y);
						debugStrangePoints(p,"drawFeatureReflection lastPoint 2: [" + p.x + " , " + p.y + " ]");
					}
				} else {
					g.finish(lastPoint.x, lastPoint.y);
					debugStrangePoints(lastPoint,"drawFeatureReflection finish 3: [" + lastPoint.x + " , " + lastPoint.y + " ]");
					if (isSameAsEditablePoint(lastPoint, lastEditablePoint))
					{
						g.lastPoint(lastPoint.x, lastPoint.y);
						debugStrangePoints(lastPoint,"drawFeatureReflection lastPoint 3: [" + lastPoint.x + " , " + lastPoint.y + " ]");
					}
					debug("\n");
				}
			}

//			debug("End of drawFeatureData");
//			debug("\n\n");
		}

		protected function isSameAsEditablePoint(currentPoint: Point, editablePoint: Point): Boolean
		{
			var iw: InteractiveWidget = master.container;
			var pointReflection: int = iw.pointReflection(currentPoint.x, currentPoint.y);
			if (pointReflection != 0)
				currentPoint = new Point(currentPoint.x  - pointReflection * iw.getProjectionWidthInPixels(), currentPoint.y);

			var distance: Number = Point.distance(currentPoint, editablePoint);

			trace("isLastEditablePoint [currentPoint: " + currentPoint + "] lastEditablePoint: " + editablePoint + " DISTANCE: " + distance);

			var isLast: Boolean = distance < 5;
			return isLast;
		}
		protected function drawFeatureReflection(g: ICurveRenderer, m_featureDataReflection: FeatureDataReflection): void
		{
			if (!g || !m_featureDataReflection || !m_featureDataReflection.lines)
			{
				return;
			}

			var p: Point;
			var points: Array = m_featureDataReflection.points;

			var linesCount: int = m_featureDataReflection.lines.length;
			var pointsCount: int = points.length;

			if (pointsCount == 0 && m_featureDataReflection.computingScheduled)
			{
				m_featureDataReflection.validate();
				points = m_featureDataReflection.points;
				pointsCount = points.length;
			}

			if (pointsCount > 0)
			{
				p = convertCoordToScreen(m_featureDataReflection.startPoint);

				var lastPoint: Point;

				g.clear();

				g.start(p.x, p.y);
				g.moveTo(p.x, p.y);
				lastPoint = new Point(p.x, p.y);
//				debug("\ndrawFeatureReflection moveTO: [" + p.x + " , " + p.y + " ]");
				var bNewLine: Boolean = false;
				for (var i: int = 1; i < pointsCount; i++)
				{
					p = points[i] as Point;
					if (p)
					{
						p = convertCoordToScreen(p);
						if (bNewLine) {
							g.finish(lastPoint.x, lastPoint.y);

							g.start(p.x, p.y);
							g.moveTo(p.x, p.y);
//							debug("drawFeatureReflection moveTo: [" + p.x + " , " + p.y + " ]");
						} else {
							g.lineTo(p.x, p.y);
//							debug("drawFeatureReflection lineTO: [" + p.x + " , " + p.y + " ]");
						}
						if (!p)
							debug("check why p is null");
						lastPoint = new Point(p.x, p.y);
						bNewLine = false;
					} else {
						bNewLine = true;
					}
				}
				if (p)
					g.finish(p.x, p.y);
				else
					g.finish(lastPoint.x, lastPoint.y);
//				debug("\n");
			}

		}

		override public function toInsertGML(xmlInsert: XML): void
		{
			addInsertGMLProperty(xmlInsert, null, "baseTime", ISO8601Parser.dateToString(m_baseTime));
			addInsertGMLProperty(xmlInsert, null, "validity", ISO8601Parser.dateToString(m_validity));
			super.toInsertGML(xmlInsert);
		}

		override public function toUpdateGML(xmlUpdate: XML): void
		{
			addUpdateGMLProperty(xmlUpdate, null, "baseTime", ISO8601Parser.dateToString(m_baseTime));
			addUpdateGMLProperty(xmlUpdate, null, "validity", ISO8601Parser.dateToString(m_validity));
			super.toUpdateGML(xmlUpdate);
		}

		override public function fromGML(gml: XML): void
		{
			var ns: Namespace = new Namespace(ms_namespace);
			m_baseTime = ISO8601Parser.stringToDate(gml.ns::baseTime);
			m_validity = ISO8601Parser.stringToDate(gml.ns::validity);
			super.fromGML(gml);
		}

		public function get baseTime(): Date
		{
			return m_baseTime;
		}

		public function set baseTime(baseTime: Date): void
		{
			m_baseTime = baseTime;
		}

		public function get validity(): Date
		{
			return m_validity;
		}

		public function set validity(validity: Date): void
		{
			m_validity = validity;
		}

		override public function set editMode(i_mode: int): void
		{
			super.editMode = i_mode;
			if (mi_editMode == WFSFeatureEditableMode.ADD_POINTS_ON_CURVE)
			{
				// PREPARE CURVE POINTS
				var points: Array = m_points.getPointsForReflection(0);
				var iw: InteractiveWidget = master.container;
				ma_points = CubicBezier.calculateHermitSpline(points, false,  iw.pixelDistanceValidator, iw.datelineBetweenPixelPositions);
			}
			if (mi_editMode == WFSFeatureEditableMode.MOVE_POINTS)
			{
				if (mi_actSelectedMoveablePointIndex > -1)
				{
					selectMoveablePoint(mi_actSelectedMoveablePointIndex, mi_actSelectedMoveablePointReflectionIndex);
				}
			}
		}

		protected function createHitMask(curvesPoints: Array): void
		{
			for each (var curvePoints: Array in curvesPoints)
			{
				if (curvePoints.length > 1)
				{
					// CREATE CURVE MASK
					graphics.lineStyle(10, 0xFF0000, 0.0);
					graphics.moveTo(curvePoints[0].x, curvePoints[0].y);
					for (var p: int = 1; p < curvePoints.length; p++)
					{
						graphics.lineTo(curvePoints[p].x, curvePoints[p].y);
					}
				}
			}
		}

		private var oldPoint: Point;
		private function debugStrangePoints(point: Point, str: String, type: String = "Info", tag: String = "CurveWithTime"): void
		{
//			if (point.x > 1000)
				debug(str);

			oldPoint = new Point(point.x, point.y);
		}

		private function debug(str: String, type: String = "Info", tag: String = "CurveWithTime"): void
		{
			if (str != null)
			{
//				trace(this + "| " + type + "| " + str);
			}
		}
	}
}
