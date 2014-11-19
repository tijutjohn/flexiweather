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

//			trace("\n\n WFSFeatureEditableCurveWithBaseTimeAndValidity update");
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
//			trace("WFSFeatureEditableCurveWithBaseTimeAndValidity computeCurve");

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

//			trace("WFSFeatureEditableCurveWithBaseTimeAndValidity drawCurve");

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
							//						trace("displaySprite.clear: pointsCount: " + pointsCount);
						} else {
							gr.clear();

							if (m_featureData.reflectionDelta == reflectionDelta)
							{
								var renderer: ICurveRenderer = getRenderer(reflectionDelta);
	//							drawFeatureReflection(renderer, reflection);
								drawFeatureData(renderer, m_featureData);
							} else {
								trace("\t\t Do not draw data for " + reflectionDelta + " Feature is drawn in " + m_featureData.reflectionDelta);
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

//			trace("\n\n");
//			trace("drawFeatureData");
			var p: Point;
			var points: Array = m_featureData.points;

			var linesCount: int = m_featureData.lines.length;
			var pointsCount: int = points.length;

//			if (pointsCount == 0 && m_featureData.computingScheduled)
//			{
//				m_featureData.validate();
//				points = m_featureData.points;
//				pointsCount = points.length;
//			}

			if (pointsCount > 0)
			{
				p = convertCoordToScreen(m_featureData.startPoint);

				var lastPoint: Point;

				// check NULL points...
				g.clear();

				g.start(p.x, p.y);
				g.moveTo(p.x, p.y);
				lastPoint = new Point(p.x, p.y);
				//				trace("\ndrawFeatureReflection moveTO: [" + p.x + " , " + p.y + " ]");
				var bNewLine: Boolean = false;
				for (var i: int = 1; i < pointsCount; i++)
				{
					p = points[i] as Point;
					if (p)
					{
						p = convertCoordToScreen(p);

						if (lastPoint)
						{
							var dist: Number = Point.distance(p, lastPoint);
//							trace("\tdrawFeatureData P: " + p + "   distance to last point: " + dist);
						}
						if (bNewLine) {
							g.finish(lastPoint.x, lastPoint.y);

							g.start(p.x, p.y);
							g.moveTo(p.x, p.y);
							//							trace("drawFeatureReflection moveTo: [" + p.x + " , " + p.y + " ]");
						} else {
							g.lineTo(p.x, p.y);
							//							trace("drawFeatureReflection lineTO: [" + p.x + " , " + p.y + " ]");
						}
						if (!p)
							trace("check why p is null");
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
				//				trace("\n");
			}

//			trace("End of drawFeatureData");
//			trace("\n\n");
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
//				trace("\ndrawFeatureReflection moveTO: [" + p.x + " , " + p.y + " ]");
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
//							trace("drawFeatureReflection moveTo: [" + p.x + " , " + p.y + " ]");
						} else {
							g.lineTo(p.x, p.y);
//							trace("drawFeatureReflection lineTO: [" + p.x + " , " + p.y + " ]");
						}
						if (!p)
							trace("check why p is null");
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
//				trace("\n");
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
				ma_points = CubicBezier.calculateHermitSpline(points, false);
				//ma_points = CubicBezier.calculateHermitSpline(m_points,
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
	}
}
