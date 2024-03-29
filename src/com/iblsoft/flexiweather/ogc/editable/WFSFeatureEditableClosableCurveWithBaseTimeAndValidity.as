package com.iblsoft.flexiweather.ogc.editable
{
	import com.iblsoft.flexiweather.events.WFSCursorManagerTypes;
	import com.iblsoft.flexiweather.ogc.FeatureUpdateContext;
	import com.iblsoft.flexiweather.ogc.editable.IClosableCurve;
	import com.iblsoft.flexiweather.ogc.editable.WFSFeatureEditable;
	import com.iblsoft.flexiweather.ogc.editable.WFSFeatureEditableMode;
	import com.iblsoft.flexiweather.ogc.editable.data.FeatureData;
	import com.iblsoft.flexiweather.ogc.editable.data.FeatureDataPoint;
	import com.iblsoft.flexiweather.ogc.editable.data.FeatureDataReflection;
	import com.iblsoft.flexiweather.ogc.editable.data.MoveablePoint;
	import com.iblsoft.flexiweather.ogc.managers.WFSCursorManager;
	import com.iblsoft.flexiweather.ogc.wfs.IWFSCurveFeature;
	import com.iblsoft.flexiweather.ogc.wfs.WFSFeatureEditableSprite;
	import com.iblsoft.flexiweather.proj.Coord;
	import com.iblsoft.flexiweather.utils.ArrayUtils;
	import com.iblsoft.flexiweather.utils.CubicBezier;
	import com.iblsoft.flexiweather.utils.ICurveRenderer;
	import com.iblsoft.flexiweather.utils.draw.DrawMode;
	import com.iblsoft.flexiweather.widgets.InteractiveWidget;

	import flash.display.Graphics;
	import flash.events.MouseEvent;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.utils.Dictionary;

	public class WFSFeatureEditableClosableCurveWithBaseTimeAndValidity extends WFSFeatureEditableCurveWithBaseTimeAndValidity implements IClosableCurve, IWFSCurveFeature
	{
		protected var mb_closed: Boolean = false;

		public function WFSFeatureEditableClosableCurveWithBaseTimeAndValidity(s_namespace: String, s_typeName: String, s_featureId: String)
		{
			super(s_namespace, s_typeName, s_featureId);
		}

		override protected function initializeFeatureData():void
		{
			super.initializeFeatureData();
			m_featureData.closed = isCurveClosed();
		}

		override protected function computeCurve(): void
		{
			var a_points: Array = getPoints();

//			if(a_points && a_points.length > 1)
//			{
				if (master)
				{
					//TODO Optimization: do not create new FeatureData everytime, but reuse old ones
					initializeFeatureData();

					var iw: InteractiveWidget = master.container;

					// feature is computed via drawSmoothPolyLine() or drawGeoPolyLine() method
					if (smooth)
						iw.drawSmoothPolyLine(getRenderer, a_points, DrawMode.PLAIN, isCurveClosed(), true, m_featureData);
					else
						iw.drawGeoPolyLine(getRenderer, a_points, DrawMode.PLAIN, isCurveClosed(), true, m_featureData);
				}

				m_featureData.joinLinesFromReflections();

//			}
		}
		override protected function drawCurve(): void
		{
			var reflection: FeatureDataReflection;
			var _addToLabelLayout: Boolean;

			var a_points: Array = getPoints();

			if (!a_points)
				return;

			//create sprites for reflections
			if (m_featureData && m_featureData.reflections)
			{
				var displaySprite: WFSFeatureEditableSprite;

				var pointsCount: int = a_points.length;
				var ptAvg: Point;
				var gr: Graphics;

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
								drawFeatureData(renderer, m_featureData);
							} else {
								debug("\t\t Do not draw data for " + reflectionDelta + " Feature is drawn in " + m_featureData.reflectionDelta);
							}
							displaySprite.points = reflection.points;

						}
					}
				}
			}
		}

		override protected function drawFeatureData(g:ICurveRenderer, m_featureData:FeatureData):void
		{
			if (!isCurveFilled())
			{
				super.drawFeatureData(g, m_featureData);
				return;
			}

			//drawing closed feature... there must be special handling of non-visible part of feature polyline

			if (!g || !m_featureData || !m_featureData.lines)
			{
				return;
			}

			//get last point added by user
			var editablePoints: Array = getPoints(0);
			var firstEditablePoint: Point = editablePoints[0] as Point;
			var lastEditablePoint: Point = editablePoints[editablePoints.length - 1] as Point;

			var p: Point;
			var points: Array = m_featureData.points;

			var linesCount: int = m_featureData.lines.length;
			var pointsCount: int = points.length;

			var iw: InteractiveWidget = master.container;
			var projectionHalf: Number = iw.getProjectionWidthInPixels() / 2;

			if (pointsCount > 0)
			{
				p = convertCoordToScreen(m_featureData.startPoint);

				var firstPoint: Point;
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
				debugStrangePoints(p, "\ndrawFeatureReflection start: [" + p.x + " , " + p.y + " ]");
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
							//							debug("\tdrawFeatureData P: " + p + "   distance to last point: " + dist);
							if (dist > projectionHalf)
							{
								debugStrangePoints(lastPoint, "drawFeatureReflection finish: [" + lastPoint.x + " , " + lastPoint.y + " ]");
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
								debugStrangePoints(p, "drawFeatureReflection start: [" + p.x + " , " + p.y + " ]");
							}
						}
						g.lineTo(p.x, p.y);
						debugStrangePoints(p, "drawFeatureReflection lineTO: [" + p.x + " , " + p.y + " ]");
						if (!p)
							debug("check why p is null");
						if (!firstPoint)
							firstPoint = new Point(p.x, p.y);
						lastPoint = new Point(p.x, p.y);
						bNewLine = false;
					} else {
						bNewLine = true;
					}
				}
				if (p) {
					debugStrangePoints(p, "drawFeatureReflection finish: [" + p.x + " , " + p.y + " ]");
					g.finish(p.x, p.y);
					if (isSameAsEditablePoint(p, lastEditablePoint))
					{
						g.lastPoint(p.x, p.y);
						debugStrangePoints(p,"drawFeatureReflection lastPoint 2: [" + p.x + " , " + p.y + " ]");
					}
				} else {
					g.finish(lastPoint.x, lastPoint.y);
					debugStrangePoints(lastPoint, "drawFeatureReflection finish: [" + lastPoint.x + " , " + lastPoint.y + " ]");
					if (isSameAsEditablePoint(lastPoint, lastEditablePoint))
					{
						g.lastPoint(lastPoint.x, lastPoint.y);
						debugStrangePoints(lastPoint,"drawFeatureReflection lastPoint 3: [" + lastPoint.x + " , " + lastPoint.y + " ]");
						debug("\n");
					}
					debug("\n");
				}
			}
		}


		/*
		override public function toInsertGML(xmlInsert: XML): void
		{
			super.toInsertGML(xmlInsert);
		}

		override public function toUpdateGML(xmlUpdate: XML): void
		{
			super.toUpdateGML(xmlUpdate);
		}

		override public function fromGML(gml: XML): void
		{
			super.fromGML(gml);
		}
*/
		override public function clone(): WFSFeatureEditable
		{
			var feature: WFSFeatureEditable = super.clone();
			WFSFeatureEditableClosableCurveWithBaseTimeAndValidity(feature).mb_closed = mb_closed;
			return feature;
		}

		override protected function getEffectiveCoordinates(): Array
		{
			if (isCurveClosed())
			{
				var l: Array = ArrayUtils.dupArray(coordinates);
				if (l.length > 0)
					l.push(l[0]); // duplicate the start point
				return l;
			}
			return coordinates;
		}

		override protected function setEffectiveCoordinates(l_coordinates: Array): void
		{
			if (l_coordinates.length > 1 &&
					Coord(l_coordinates[0]).equalsCoord(l_coordinates[l_coordinates.length - 1]))
			{
				l_coordinates.pop();
				mb_closed = true;
			}
			coordinates = l_coordinates;
		}

		// IClosableCurve implementation
		public function closeCurve(): void
		{
			if (!mb_closed)
			{
				mb_closed = true;
				update(null);
			}
		}

		public function openCurve(i_afterPointIndex: uint, cSplitPoint: Coord = null): void
		{
			if (mb_closed)
			{
				mb_closed = false;
				var i: uint;
				var a_coords: Array = [];
				if (cSplitPoint != null)
					a_coords.push(cSplitPoint.clone());
				for (i = i_afterPointIndex + 1; i < coordinates.length; ++i)
				{
					a_coords.push(coordinates[i]);
				}
				for (i = 0; i <= i_afterPointIndex && i < m_points.length; ++i)
				{
					a_coords.push(coordinates[i]);
				}
				if (cSplitPoint != null)
					a_coords.push(cSplitPoint.clone());
				coordinates = a_coords;
				update(null);
			}
		}

		public function isCurveClosed(): Boolean
		{
			return mb_closed;
		}
		public function isCurveFilled(): Boolean
		{
			return false;
		}

		override public function set editMode(i_mode: int): void
		{
			super.editMode = i_mode;
			if (mi_editMode == WFSFeatureEditableMode.ADD_POINTS_ON_CURVE)
			{
				// PREPARE CURVE POINTS
				//FIXME move this elsewhere else
				var points: Array = m_points.getPointsForReflection(0);
				var iw: InteractiveWidget = master.container;
				ma_points = CubicBezier.calculateHermitSpline(points, mb_closed, iw.pixelDistanceValidator, iw.datelineBetweenPixelPositions);
			}
		}

		/**
		 *
		 */
		override public function onMouseMove(pt: Point, event: MouseEvent): Boolean
		{
			if ((mi_editMode == WFSFeatureEditableMode.ADD_POINTS_ON_CURVE)
					|| (mi_editMode == WFSFeatureEditableMode.ADD_POINTS_WITH_MOVE_POINTS)
					&& selected
					&& !mb_closed)
			{
				var stagePt: Point = localToGlobal(pt);
				var f_distanceToFirst: Number = pt.subtract(m_points[0]).length;
				if ((f_distanceToFirst < 10) && (m_points.length > 2))
					showCloseCurveCursor();
				else
					removeCustomCursor();
			}
			return (super.onMouseMove(pt, event));
		}

		protected function removeCustomCursor(): void
		{
			WFSCursorManager.clearCursor();
		}

		protected function showCloseCurveCursor(): void
		{
			WFSCursorManager.setCursor(WFSCursorManagerTypes.CURSOR_CLOSE_CURVE);
		}

		/**
		 *
		 */
		override public function onMouseDown(pt: Point, event: MouseEvent): Boolean
		{
			var useThisOverride: Boolean = false;
			var stagePt: Point = localToGlobal(pt);
			if ((mi_editMode == WFSFeatureEditableMode.ADD_POINTS_ON_CURVE)
					|| (mi_editMode == WFSFeatureEditableMode.ADD_POINTS_WITH_MOVE_POINTS)
					&& selected)
			{
				var reflection: FeatureDataReflection;

				if (mb_closed)
				{
					// don't do anything if this click is on MoveablePoint belonging to this curve
					var ids: Array = m_featureData.reflectionsIDs;
					for each (var id: int in ids)
					{
						reflection = m_featureData.getReflectionAt(id) as FeatureDataReflection;
						var moveablePoints: Array = getEditablePointsForReflection(reflection.reflectionDelta);
						if (moveablePoints)
						{
							for each (var mp: MoveablePoint in moveablePoints)
							{
								if (mp.hitTestPoint(stagePt.x, stagePt.y, true))
									return false;
							}
						}
					}

					//FIXME how to get correct points for feature, which is crossing dateline?
					iw = master.container;
					var clickedReflection: int = iw.pointReflection(stagePt.x, stagePt.y);
					var a: Array = getPoints(clickedReflection);

					if (!a)
						return false;

					var i_best: int = -1;
					var f_bestDistance: Number = 0;
					var b_keepDrag: Boolean = true;
					var b_curveHit: Boolean = hitTestPoint(stagePt.x, stagePt.y, true);
					if (b_curveHit)
					{
						// add point between 2 points
						//add first point at the end to check possibility to insert point between last and first point
						a.push((a[0] as Point).clone());


						for (var i: int = 1; i < a.length; ++i)
						{
							var ptPrev: Point = Point(a[i - 1]);
							var ptCurr: Point = Point(a[i]);
							var f_distance: Number = ptPrev.subtract(pt).length + ptCurr.subtract(pt).length;
							var f_distCurrPrev: Number = ptCurr.subtract(ptPrev).length * 1.3;
							if (f_distance > ptCurr.subtract(ptPrev).length * 1.3)
								continue; // skip, clicked to far from point
							if (i_best == -1 || f_distance < f_bestDistance)
							{
								i_best = i;
								f_bestDistance = f_distance;
							}
						}

						//remove last point as we have added it just for this test
						a.splice(a.length - 1, 1);
					}
					if (i_best != -1)
					{
						var newPoint: IMouseEditableItem;

						var reflectionDelta: int = master.container.pointReflection(pt.x, pt.y);

						insertPointBefore(i_best, pt, reflectionDelta);

						reflection = m_featureData.getReflectionAt(reflectionDelta);
						newPoint = getEditablePointForReflectionAt(reflectionDelta, i_best) as IMouseEditableItem;
						if (newPoint)
						{
							newPoint.onMouseDown(pt, event);
							if (!b_keepDrag)
							{
								newPoint.onMouseUp(pt, event);
								newPoint.onMouseClick(pt, event);
							}
							return (true);
						}
						return (false);
					}
					else
						return (false);
				}
				else
				{
					// IF USER CLICK NEAR BY FIRST POINT AND CURVE HAS MORE THAN 2 POINTS (IT CAN BE CLOSED)
					if (m_points && m_points.length > 0)
					{
						var iw: InteractiveWidget = master.container;
						clickedReflection = iw.pointReflection(pt.x, pt.y);

						//get points from reflection when user clicks
						var points: Array = m_points.getPointsForReflection(clickedReflection);
						var f_distanceToFirst: Number = pt.subtract(points[0]).length;
						if ((f_distanceToFirst < 10) && (m_points.length > 2))
						{
							closeCurve();
							useThisOverride = true;
						}
					}
				}
			}
			if (useThisOverride)
				return true;
			else
				return (super.onMouseDown(pt, event));
		}

		private var oldPoint: Point;
		private function debugStrangePoints(point: Point, str: String, type: String = "Info", tag: String = "ClosableCurveWithTime"): void
		{
			if (point.x > 1000)
				debug(str);

			oldPoint = new Point(point.x, point.y);
		}
		private function debug(str: String, type: String = "Info", tag: String = "ClosableCurveWithTime"): void
		{
//			if (str != null)
//			{
//				trace(this + "| " + type + "| " + str);
//			}
		}
	}
}
