package com.iblsoft.flexiweather.ogc.wfs
{
	import com.iblsoft.flexiweather.ogc.editable.IClosableCurve;
	import com.iblsoft.flexiweather.ogc.editable.WFSFeatureEditable;
	import com.iblsoft.flexiweather.proj.Coord;
	import com.iblsoft.flexiweather.utils.CubicBezier;
	import com.iblsoft.flexiweather.utils.CurveLineSegment;
	import com.iblsoft.flexiweather.utils.CurveLineSegmentRenderer;
	import com.iblsoft.flexiweather.utils.anticollision.AnticollisionLayoutObject;
	import com.iblsoft.flexiweather.utils.anticollision.IAnticollisionLayoutObject;
	import com.iblsoft.flexiweather.utils.geometry.ILineSegmentApproximableBounds;
	import com.iblsoft.flexiweather.widgets.InteractiveWidget;
	import flash.display.Sprite;
	import flash.geom.Point;

	public class WFSFeatureEditableSprite extends Sprite implements ILineSegmentApproximableBounds, IAnticollisionLayoutObject
	{
		public var points: Array;
		protected var _feature: WFSFeatureEditable;

		override public function set visible(value:Boolean):void
		{
			value = value && _feature.presentInViewBBox;
			
			super.visible = value;
		}
		
		public function WFSFeatureEditableSprite(feature: WFSFeatureEditable)
		{
			_feature = feature;
		}

		public function clear(): void
		{
			graphics.clear();
		}
		
		public function getLineSegmentApproximationOfBounds(): Array
		{
			return [];
		}

		/**
		 * Returns line approximation (input - points, output - points)
		 *
		 * @param b_useCoordinates
		 * @return
		 *
		 */
		public function createStraightLineSegmentApproximation(b_useCoordinates: Boolean = true): Array
		{
			var l: Array = [];
			var i_segment: uint = 0;
			var b_closed: Boolean = (_feature is IClosableCurve) && IClosableCurve(_feature).isCurveClosed();
			var cPrev: Point = null;
			var cFirst: Point = null;
			// we use here, that Coord is derived from Point, and Coord.crs is not used
//			var a_coordinates: Array = b_useCoordinates ? coordinates : getPoints(); 
			var a_coordinates: Array = points;
			for each (var c: Point in a_coordinates)
			{
				if (cPrev != null)
				{
					l.push(new CurveLineSegment(i_segment,
							cPrev.x, cPrev.y, c.x, c.y));
					++i_segment;
				}
				else
					cFirst = c;
				cPrev = c;
			}
			if (b_closed && cPrev != null)
			{
				l.push(new CurveLineSegment(i_segment,
						cPrev.x, cPrev.y, cFirst.x, cFirst.y));
			}
			return l;
		}

		public function createSmoothLineSegmentApproximation(b_useCoordinates: Boolean = true): Array
		{
//			return createStraightLineSegmentApproximation(b_useCoordinates);
//			var segmentRenderer: CurveLineSegmentRenderer = new CurveLineSegmentRenderer();
//			
//			var newSegmentRenderer: CurveLineSegmentRenderer = new CurveLineSegmentRenderer();
			var b_closed: Boolean = (_feature is IClosableCurve) && IClosableCurve(_feature).isCurveClosed();
			var splinePoints: Array = CubicBezier.calculateHermitSpline(points, b_closed, 0.005);
			var coords: Array = [];
			//what is the best way to check in which projection was front created? For now we check CRS of first coordinate
			var crs: String = (_feature.coordinates[0] as Coord).crs;
			var iw: InteractiveWidget = _feature.master.container;
			//convert points to Coords
			for each (var p: Point in splinePoints)
			{
				coords.push(iw.pointToCoord(p.x, p.y));
			}
			var splineReflections: Array = iw.getSplineReflections(coords, b_closed);
			var featurePoints: Array = splineReflections[0] as Array;
			var l: Array = [];
			var i_segment: uint = 0;
			var cPrev: Point = null;
			var cFirst: Point = null;
			for each (var c: Point in featurePoints)
			{
				if (cPrev != null)
				{
					l.push(new CurveLineSegment(i_segment,
							cPrev.x, cPrev.y, c.x, c.y));
					++i_segment;
				}
				else
					cFirst = c;
				cPrev = c;
			}
			if (b_closed && cPrev != null)
			{
				l.push(new CurveLineSegment(i_segment,
						cPrev.x, cPrev.y, cFirst.x, cFirst.y));
			}
			return l;
		}
		private var _anticollisionLayoutObject: AnticollisionLayoutObject;

		public function set anticollisionLayoutObject(object: AnticollisionLayoutObject): void
		{
			_anticollisionLayoutObject = object;
		}

		public function get anticollisionLayoutObject(): AnticollisionLayoutObject
		{
			return _anticollisionLayoutObject;
		}
	}
}
