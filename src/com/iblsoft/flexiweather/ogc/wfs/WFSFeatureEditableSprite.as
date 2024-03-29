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
	import com.iblsoft.flexiweather.utils.geometry.LineSegment;
	import com.iblsoft.flexiweather.widgets.InteractiveWidget;

	import flash.display.Sprite;
	import flash.geom.Point;

	public class WFSFeatureEditableSprite extends Sprite implements ILineSegmentApproximableBounds, IAnticollisionLayoutObject
	{
		public static var UID: int = 0;

		public var id: int;

		private var _points: Array;
		protected var _feature: WFSFeatureEditable;


		public function get points():Array
		{
			return _points;
		}

		public function set points(value:Array):void
		{
			_points = value;
		}

		override public function set visible(value:Boolean):void
		{
			value = value && _feature.presentInViewBBox;

			super.visible = value;
		}

		/**
		 * For feature with icons
		 */
		protected var mb_bitmapLoaded: Boolean;
		public function get bitmapLoaded(): Boolean
		{
			return mb_bitmapLoaded;
		}

		public function WFSFeatureEditableSprite(feature: WFSFeatureEditable)
		{
			id = UID++;
			_feature = feature;
		}

		public function clear(): void
		{
			graphics.clear();
		}

		public function getPointsForLineSegmentApproximationOfBounds(): Array
		{
			return [];
		}
		public function getLineSegmentApproximationOfBounds(): Array
		{
			if (points && points.length > 0)
			{
				var a: Array = [];
				var ptFirst: Point = null;
				var ptPrev: Point = null;

				var pts: Array = getPointsForLineSegmentApproximationOfBounds();

				var useEvery: int = 1;
				if (pts.length > 100){
					useEvery = int(pts.length / 20);
				} else if (pts.length > 50){
					useEvery = int(pts.length / 10);
				}

				var actPUse: int = 0;
				for each(var pt: Point in pts) {
					if (pt)
					{
						if ((actPUse % useEvery) == 0){
							if(ptPrev != null)
								a.push(new LineSegment(ptPrev.x, ptPrev.y, pt.x, pt.y));
							ptPrev = pt;
						}
						actPUse++;
					}
				}

				return a;
			}
			return null;
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
//			var splinePoints: Array = CubicBezier.calculateHermitSpline(points, b_closed, null, 0.005);
			var iw: InteractiveWidget = _feature.master.container;

			var splinePoints: Array = CubicBezier.calculateHermitSpline(points, b_closed, iw.pixelDistanceValidator, iw.datelineBetweenPixelPositions);
			var coords: Array = [];
			//what is the best way to check in which projection was front created? For now we check CRS of first coordinate
			var crs: String = (_feature.coordinates[0] as Coord).crs;
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
