package com.iblsoft.flexiweather.ogc.editable
{
	import com.iblsoft.flexiweather.events.WFSCursorManagerTypes;
	import com.iblsoft.flexiweather.ogc.data.WFSEditableReflectionData;
	import com.iblsoft.flexiweather.ogc.editable.IClosableCurve;
	import com.iblsoft.flexiweather.ogc.editable.MoveablePoint;
	import com.iblsoft.flexiweather.ogc.editable.WFSFeatureEditable;
	import com.iblsoft.flexiweather.ogc.editable.WFSFeatureEditableMode;
	import com.iblsoft.flexiweather.ogc.managers.WFSCursorManager;
	import com.iblsoft.flexiweather.proj.Coord;
	import com.iblsoft.flexiweather.utils.ArrayUtils;
	import com.iblsoft.flexiweather.utils.CubicBezier;
	
	import flash.events.MouseEvent;
	import flash.geom.Point;
	
	import mx.collections.ArrayCollection;

	public class WFSFeatureEditableClosableCurveWithBaseTimeAndValidity extends WFSFeatureEditableCurveWithBaseTimeAndValidity implements IClosableCurve
	{
		protected var mb_closed: Boolean = false;

		public function WFSFeatureEditableClosableCurveWithBaseTimeAndValidity(s_namespace: String, s_typeName: String, s_featureId: String)
		{
			super(s_namespace, s_typeName, s_featureId);
		}

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

		override public function set editMode(i_mode: int): void
		{
			super.editMode = i_mode;
			if (mi_editMode == WFSFeatureEditableMode.ADD_POINTS_ON_CURVE)
			{
				// PREPARE CURVE POINTS
				ma_points = CubicBezier.calculateHermitSpline(m_points.toArray(), mb_closed);
					//ma_points = CubicBezier.calculateHermitSpline(m_points.toArray(),  
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
				var reflection: WFSEditableReflectionData;
				
				if (mb_closed)
				{
					// don't do anything if this click is on MoveablePoint belonging to this curve
					//FIXME fix this for all reflections
					reflection = ml_movablePoints.getReflection(0) as WFSEditableReflectionData;
					var moveablePoints: Array = reflection.moveablePoints;
					if (moveablePoints)
					{
						for each (var mp: MoveablePoint in moveablePoints)
						{
							if (mp.hitTestPoint(stagePt.x, stagePt.y, true))
								return false;
						}
					}
					var a: ArrayCollection = getPoints();
					var i_best: int = -1;
					var f_bestDistance: Number = 0;
					var b_keepDrag: Boolean = true;
					var b_curveHit: Boolean = hitTestPoint(stagePt.x, stagePt.y, true);
					if (b_curveHit)
					{
						// add point between 2 points
						//add first point at the end to check possibility to insert point between last and first point
						a.addItem((a.getItemAt(0) as Point).clone());
						
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
						a.removeItemAt(a.length - 1);
					}
					if (i_best != -1)
					{
						insertPointBefore(i_best, pt);
//						MoveablePoint(ml_movablePoints[i_best]).onMouseDown(pt);
						reflection = ml_movablePoints.getReflection(0) as WFSEditableReflectionData;
						if (reflection)
							var newPoint: MoveablePoint = reflection.moveablePoints[i_best] as MoveablePoint;
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
					if (m_points.length > 0)
					{
						var f_distanceToFirst: Number = pt.subtract(m_points[0]).length;
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
	}
}
