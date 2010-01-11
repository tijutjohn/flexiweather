package com.iblsoft.flexiweather.ogc.editable
{
	import flash.geom.Point;
	
	import mx.collections.ArrayCollection;
	
	public class WFSFeatureEditableCurve extends WFSFeatureEditable
			implements IMouseEditableItem
	{
		public function WFSFeatureEditableCurve(s_namespace: String, s_typeName: String, s_featureId:String)
		{
			super(s_namespace, s_typeName, s_featureId);
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

			// don't do anything if this click is on MoveablePoint belonging to this curve
			var stagePt: Point = localToGlobal(pt);
			for each(var mp: MoveablePoint in ml_movablePoints) {
				if(mp.hitTestPoint(stagePt.x, stagePt.y, true))
					return false;
			}
			
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
		}

		public function onMouseUp(pt: Point): Boolean
		{
			return false;
		}

		// getters & setters 
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