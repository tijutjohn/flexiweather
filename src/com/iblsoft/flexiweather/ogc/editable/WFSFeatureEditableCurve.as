package com.iblsoft.flexiweather.ogc.editable
{
	import com.iblsoft.flexiweather.ogc.GMLUtils;
	import com.iblsoft.flexiweather.ogc.editable.data.FeatureDataReflection;
	import com.iblsoft.flexiweather.ogc.editable.data.MoveablePoint;
	import com.iblsoft.flexiweather.utils.CubicBezier;
	import com.iblsoft.flexiweather.utils.CurveLineSegment;
	import com.iblsoft.flexiweather.utils.CurveLineSegmentRenderer;
	import com.iblsoft.flexiweather.widgets.InteractiveWidget;

	import flash.display.Sprite;
	import flash.events.MouseEvent;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.utils.Dictionary;

	public class WFSFeatureEditableCurve extends WFSFeatureEditable implements IMouseEditableItem
	{
		protected var mb_smooth: Boolean = true;
		public function get smooth():Boolean
		{
			return mb_smooth;
		}

		public function set smooth(value:Boolean):void
		{
			mb_smooth = value;
		}

		public function WFSFeatureEditableCurve(s_namespace: String, s_typeName: String, s_featureId: String)
		{
			super(s_namespace, s_typeName, s_featureId);
		}


		/**
		 * Function is called from computeCurve method. You can override method if you need update featureData in any way
		 *
		 */
		protected function initializeFeatureData(): void
		{
			if (!m_featureData)
				m_featureData = createFeatureData();
			else
				m_featureData.clear();

			var iw: InteractiveWidget = master.container;
			m_featureData.clippingRectangle = new Rectangle(iw.areaX, iw.areaY, iw.areaWidth, iw.areaHeight);
			m_featureData.featureSplitter = iw.featureSplitter;
		}

		override public function toInsertGML(xmlInsert: XML): void
		{
			super.toInsertGML(xmlInsert);
			var line: XML = <gml:LineString xmlns:gml="http://www.opengis.net/gml"></gml:LineString>;
			line.appendChild(GMLUtils.encodeGML3Coordinates2D(getEffectiveCoordinates()));
			addInsertGMLProperty(xmlInsert, null, "curve", line);
		}

		override public function toUpdateGML(xmlUpdate: XML): void
		{
			super.toUpdateGML(xmlUpdate);
			var line: XML = <gml:LineString xmlns:gml="http://www.opengis.net/gml"></gml:LineString>;
			line.appendChild(GMLUtils.encodeGML3Coordinates2D(getEffectiveCoordinates()));
			addUpdateGMLProperty(xmlUpdate, null, "curve", line);
		}

		override public function fromGML(gml: XML): void
		{
			super.fromGML(gml);
			var ns: Namespace = new Namespace(ms_namespace);
			var nsGML: Namespace = new Namespace("http://www.opengis.net/gml");
			if (gml.ns::curve[0] != null)
			{
				var xmlCurve: XML = gml.ns::curve[0];
				var xmlCoordinates: XML = xmlCurve.nsGML::LineString[0];
				setEffectiveCoordinates(GMLUtils.parseGML3Coordinates2D(xmlCoordinates));
			}
			else
				trace("Curve is null ...");
		}

		/** Returns curve approximation using line segments in "coordinates" space */
		/*
		public function getLineSegmentApproximation(): Array
		{
			// assume we use smooth curve be default
			return createSmoothLineSegmentApproximation();
		}

		public function createStraightLineSegmentApproximation(b_useCoordinates: Boolean = true): Array
		{
			var l: Array = [];
			var i_segment: uint = 0;
			var b_closed: Boolean = (this is IClosableCurve) && IClosableCurve(this).isCurveClosed();

			var cPrev: Point = null;
			var cFirst: Point = null;
			// we use here, that Coord is derived from Point, and Coord.crs is not used
			var a_coordinates: Array = b_useCoordinates ? coordinates : getPoints();
			for each(var c: Point in a_coordinates) {
				if(cPrev != null) {
					l.push(new CurveLineSegment(i_segment,
						cPrev.x, cPrev.y, c.x, c.y));
					++i_segment;
				}
				else
					cFirst = c;
				cPrev = c;
			}
			if(b_closed && cPrev != null) {
				l.push(new CurveLineSegment(i_segment,
					cPrev.x, cPrev.y, cFirst.x, cFirst.y));
			}
			return l;
		}

		public function createSmoothLineSegmentApproximation(b_useCoordinates: Boolean = true): Array
		{
			var segmentRenderer: CurveLineSegmentRenderer = new CurveLineSegmentRenderer();
			var b_closed: Boolean = (this is IClosableCurve) && IClosableCurve(this).isCurveClosed();

			var newSegmentRenderer: CurveLineSegmentRenderer = new CurveLineSegmentRenderer();

			CubicBezier.drawHermitSpline(
					newSegmentRenderer,
					b_useCoordinates ? coordinates : getPoints(),
					b_closed, false, 0.005, true);

			/*CubicBezier.curveThroughPoints(
					segmentRenderer,
					b_useCoordinates ? coordinates : getPoints(),
					b_closed);*/
		//return segmentRenderer.segments;
		/*
					return newSegmentRenderer.segments;
				}
		*/
		// IMouseEditableItem implementation
		public function onMouseMove(pt: Point, event: MouseEvent): Boolean
		{
			if ((mi_editMode == WFSFeatureEditableMode.ADD_POINTS_ON_CURVE) && (selected))
			{
				var minIndex: uint = 0;
				var minDist: Number = Math.abs(pt.subtract(Point(ma_points[0])).length);
				var i: uint = 1;
				var tDist: Number;
				while (i < ma_points.length)
				{
					tDist = getDist(pt, Point(ma_points[i]));
					if (tDist < minDist)
					{
						minDist = tDist;
						minIndex = i;
					}
					i++;
				}
				if (minDist < 20)
					return (true);
				else
					return (false);
			}
			else
				return false;
		}

		protected function getDist(p0: Point, p1: Point): Number
		{
			var p: Point = p0.subtract(p1);
			return (Math.abs(p.length));
		}

		public function onMouseClick(pt: Point, event: MouseEvent): Boolean
		{
			if (selected)
				return true;
			return false;
		}

		public function onMouseDoubleClick(pt: Point, event: MouseEvent): Boolean
		{
			return false;
		}

		public function onMouseDown(pt: Point, event: MouseEvent): Boolean
		{
			if (!selected || justSelectable)
				return false;
			var stagePt: Point = localToGlobal(pt);
			// snap to existing MoveablePoint
			pt = snapPoint(pt);
			if ((mi_editMode == WFSFeatureEditableMode.MOVE_POINTS) || (mi_editMode == WFSFeatureEditableMode.ADD_POINTS_WITH_MOVE_POINTS))
			{
				// don't do anything if this click is on MoveablePoint belonging to this curve
				var reflectionDelta: int = 0;

				var clickedMoveablePoint: MoveablePoint = event.target as MoveablePoint;
				if (clickedMoveablePoint)
					reflectionDelta = clickedMoveablePoint.reflectionDelta;

				var moveablePoints: Array = getEditablePointsForReflection(reflectionDelta);

				for each (var mpSprite: Sprite in moveablePoints)
				{
					if (mpSprite.hitTestPoint(stagePt.x, stagePt.y, true))
						return false;
				}
			}
			if ((mi_editMode == WFSFeatureEditableMode.ADD_POINTS) || (mi_editMode == WFSFeatureEditableMode.ADD_POINTS_WITH_MOVE_POINTS))
			{
				var a: Array = getPoints();
				var i_best: int = -1;
				var f_bestDistance: Number = 0;
				var b_keepDrag: Boolean = true;
				var b_curveHit: Boolean = hitTestPoint(stagePt.x, stagePt.y, true);
				if (b_curveHit)
				{
					// add point between 2 points
					for (var i: int = 1; i < a.length; ++i)
					{
						var ptPrev: Point = Point(a[i - 1]);
						var ptCurr: Point = Point(a[i]);
						var f_distance: Number = ptPrev.subtract(pt).length + ptCurr.subtract(pt).length;
						if (f_distance > ptCurr.subtract(ptPrev).length * 1.3)
							continue; // skip, clicked to far from point
						if (i_best == -1 || f_distance < f_bestDistance)
						{
							i_best = i;
							f_bestDistance = f_distance;
						}
					}
				}
				else
				{
					// add point at one of curve's ends
					// check end point first, to prefer adding at the end point being added is
					// the second point of the curve
					var f_distanceToLast: Number = pt.subtract(a[a.length - 1]).length;
					if (i_best == -1 || f_distanceToLast < f_bestDistance)
					{
						i_best = a.length;
						f_bestDistance = f_distanceToLast;
						b_keepDrag = false;
					}
					/*var f_distanceToFirst: Number = pt.subtract(a[0]).length;
					if(i_best == -1 || f_distanceToFirst < f_bestDistance) {
						i_best = 0;
						f_bestDistance = f_distanceToFirst;
						b_keepDrag = false;
					}*/
				}
				if (i_best != -1)
				{
					reflectionDelta = master.container.pointReflection(pt.x, pt.y);

//					insertPointBefore(i_best, pt, reflectionDelta);
					var newPoint: IMouseEditableItem = setPoint(i_best, pt, reflectionDelta);


					var totalMoveablePoints: int = getEditablePointsForReflection(0).length;
//
					//FIXME Test if this is ok
//					if (i_best < totalMoveablePoints)
//					{
						//FIXME... question is if this needs to be done for 1 reflection or for all reflections
//						var ids: Array = m_featureData.reflectionsIDs;
//						for (var i: int = 0; i < totalReflections; i++)
//						{
//							var reflectionDelta: int = ids[i];
//							var reflection: FeatureDataReflection = m_featureData.getReflectionAt(reflectionDelta);
//							newPoint = getEditablePointForReflectionAt(reflectionDelta, i_best) as IMouseEditableItem;

							if (newPoint)
							{
								newPoint.onMouseDown(pt, event);
								if (!b_keepDrag)
								{
									newPoint.onMouseUp(pt, event);
									newPoint.onMouseClick(pt, event);
								}
							}
//						}
//					}
				}
				return true;
			}
			else
				return false;
		}

		public function onMouseUp(pt: Point, event: MouseEvent): Boolean
		{
			return false;
		}

		// getters & setters
		protected function getEffectiveCoordinates(): Array
		{
			return coordinates;
		}

		protected function setEffectiveCoordinates(l_coordinates: Array): void
		{
			coordinates = l_coordinates;
		}

		public override function set selected(b: Boolean): void
		{
			if (super.selected != b)
			{
				super.selected = b;
				// releaseMouseClickCapture can throw exception if some of the mouse events are lost
				if (b)
					m_editableItemManager.setMouseClickCapture(this);
				else
					m_editableItemManager.releaseMouseClickCapture(this);
			}
		}
	}
}
