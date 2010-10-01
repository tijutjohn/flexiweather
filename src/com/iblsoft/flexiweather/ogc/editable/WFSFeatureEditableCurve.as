package com.iblsoft.flexiweather.ogc.editable
{
	import com.iblsoft.flexiweather.ogc.GMLUtils;
	import com.iblsoft.flexiweather.proj.Coord;
	import com.iblsoft.flexiweather.utils.ArrayUtils;
	import com.iblsoft.flexiweather.utils.CubicBezier;
	import com.iblsoft.flexiweather.utils.CurveLineSegment;
	import com.iblsoft.flexiweather.utils.CurveLineSegmentRenderer;
	
	import flash.geom.Point;
	
	import mx.collections.ArrayCollection;
	
	public class WFSFeatureEditableCurve extends WFSFeatureEditable
			implements IMouseEditableItem
	{
		public function WFSFeatureEditableCurve(s_namespace: String, s_typeName: String, s_featureId:String)
		{
			super(s_namespace, s_typeName, s_featureId);
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
			if (gml.ns::curve[0] != null) {
				var xmlCurve: XML = gml.ns::curve[0];
				var xmlCoordinates: XML = xmlCurve.nsGML::LineString[0];
				setEffectiveCoordinates(GMLUtils.parseGML3Coordinates2D(xmlCoordinates));
			} else {
				trace("Curve is null ...");
			}
		}
		
		/** Returns curve approximation using line segments in "coordinates" space */
		public function getLineSegmentApproximation(): Array
		{
			// assume we use smooth curve be default
			return createSmoothLineSegmentApproximation();
		}

		public function createStraightLineSegmentApproximation(): Array
		{
			var l: Array = [];
			var cPrev: Coord = null;
			var i_segment: uint = 0;
			for each(var c: Coord in coordinates) {
				if(cPrev != null) {
					l.push(new CurveLineSegment(i_segment,
						cPrev.x, cPrev.y, c.x, c.y));
				}
				++i_segment;
				cPrev = c;
			} 
			var b_closed: Boolean = (this is IClosableCurve) && IClosableCurve(this).isCurveClosed();
			if(b_closed && cPrev != null) {
				l.push(new CurveLineSegment(i_segment,
					cPrev.x, cPrev.y, coordinates[0].x, coordinates[0].y));
			}
			var segmentRenderer: CurveLineSegmentRenderer = new CurveLineSegmentRenderer();
			CubicBezier.curveThroughPoints(segmentRenderer, coordinates);			
			return l;
		}

		public function createSmoothLineSegmentApproximation(): Array
		{
			var segmentRenderer: CurveLineSegmentRenderer = new CurveLineSegmentRenderer();
			var b_closed: Boolean = (this is IClosableCurve) && IClosableCurve(this).isCurveClosed();
			CubicBezier.curveThroughPoints(segmentRenderer, coordinates, b_closed);			
			return segmentRenderer.segments;
		}

		// IMouseEditableItem implementation
		public function onMouseMove(pt: Point): Boolean
		{ return false; }

		public function onMouseClick(pt: Point): Boolean
		{
			if(selected)
				return true;
			return false;
		}

		public function onMouseDoubleClick(pt: Point): Boolean
		{
			return false;
		}

		public function onMouseDown(pt: Point): Boolean
		{
			if(!selected)
				return false;

			// snap to existing MoveablePoint
			pt = snapPoint(pt);

			if ((mi_editmode == WFSFeatureEditableMode.MOVE_POINTS) || 
				(mi_editmode == WFSFeatureEditableMode.ADD_POINTS_WITH_MOVE_POINTS)){
				// don't do anything if this click is on MoveablePoint belonging to this curve
				var stagePt: Point = localToGlobal(pt);
				for each(var mp: MoveablePoint in ml_movablePoints) {
					if(mp.hitTestPoint(stagePt.x, stagePt.y, true))
						return false;
				}
			}
			
			if ((mi_editmode == WFSFeatureEditableMode.ADD_POINTS) ||
				(mi_editmode == WFSFeatureEditableMode.ADD_POINTS_WITH_MOVE_POINTS)){
				var a: ArrayCollection = getPoints();
				var i_best: int = -1;
				var f_bestDistance: Number = 0;
				var b_keepDrag: Boolean = true;
				var b_curveHit: Boolean = hitTestPoint(stagePt.x, stagePt.y, true);
				if(b_curveHit) {
					// add point between 2 points
					for(var i: int = 1; i < a.length; ++i) {
						var ptPrev: Point = Point(a[i - 1]); 
						var ptCurr: Point = Point(a[i]);
						var f_distance: Number = ptPrev.subtract(pt).length + ptCurr.subtract(pt).length;
						if(f_distance > ptCurr.subtract(ptPrev).length * 1.3)
							continue; // skip, clicked to far from point 
						if(i_best == -1 || f_distance < f_bestDistance) {
							i_best = i;
							f_bestDistance = f_distance;
						}  
					}
				}
				else {
					// add point at one of curve's ends
					// check end point first, to prefer adding at the end point being added is
					// the second point of the curve
					var f_distanceToLast: Number = pt.subtract(a[a.length - 1]).length;
					if(i_best == -1 || f_distanceToLast < f_bestDistance) {
						i_best = a.length;
						f_bestDistance = f_distanceToLast;
						b_keepDrag = false;
					}
					var f_distanceToFirst: Number = pt.subtract(a[0]).length;
					if(i_best == -1 || f_distanceToFirst < f_bestDistance) {
						i_best = 0;
						f_bestDistance = f_distanceToFirst;
						b_keepDrag = false;
					}
				}
				if(i_best != -1) {
					insertPointBefore(i_best, pt);
					MoveablePoint(ml_movablePoints[i_best]).onMouseDown(pt);
					if(!b_keepDrag) {
						MoveablePoint(ml_movablePoints[i_best]).onMouseUp(pt);
						MoveablePoint(ml_movablePoints[i_best]).onMouseClick(pt);
					}
				}
				return true;
			} else {
				return false;
			}
		}

		public function onMouseUp(pt: Point): Boolean
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
			if(super.selected != b) {
				if(b)
					m_editableItemManager.setMouseClickCapture(this);
				else
					m_editableItemManager.releaseMouseClickCapture(this);
			}
			super.selected = b;
		}
	}
}