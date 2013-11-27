package com.iblsoft.flexiweather.ogc
{
	import com.iblsoft.flexiweather.ogc.editable.IClosableCurve;
	import com.iblsoft.flexiweather.ogc.events.FeatureEvent;
	import com.iblsoft.flexiweather.ogc.kml.renderer.IKMLRenderer;
	import com.iblsoft.flexiweather.proj.Coord;
	import com.iblsoft.flexiweather.utils.CubicBezier;
	import com.iblsoft.flexiweather.utils.CurveLineSegment;
	import com.iblsoft.flexiweather.utils.CurveLineSegmentRenderer;
	import com.iblsoft.flexiweather.widgets.InteractiveWidget;
	
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.geom.Point;
	
	import mx.core.UIComponentGlobals;
	import mx.core.mx_internal;
	import mx.events.CollectionEvent;
	import mx.events.CollectionEventKind;
	import mx.events.DynamicEvent;
	import mx.events.PropertyChangeEvent;
	import mx.managers.ISystemManager;

	use namespace mx_internal;
	
	public class FeatureBase extends Sprite
	{
		private var _next: FeatureBase;
		private var _previous: FeatureBase;

		public function set next(node: FeatureBase): void
		{
			_next = node;
		}

		public function get next(): FeatureBase
		{
			return _next;
		}

		public function set previous(node: FeatureBase): void
		{
			_previous = node;
		}

		public function get previous(): FeatureBase
		{
			return _previous;
		}
		private var _parentFeature: FeatureBase;

		public function get parentFeature(): FeatureBase
		{
			return _parentFeature;
		}

		public function set parentFeature(value: FeatureBase): void
		{
			_parentFeature = value;
		}
		protected var m_master: InteractiveLayerFeatureBase;
		protected var ms_namespace: String;
		protected var ms_typeName: String;
		protected var ms_featureId: String;
		protected var ms_internalFeatureId: String;
		
//		protected var m_coordinates: ArrayCollection = new ArrayCollection();
//		protected var m_points: ArrayCollection = new ArrayCollection();
		
		protected var m_coordinates: Array;
		protected var m_points: Array;
		
		protected var mb_pointsDirty: Boolean = false;
		protected var mb_spritesAddedToLabelLayout: Boolean
		
		protected var mb_presentInViewBBox: Boolean
		
		public function get presentInViewBBox(): Boolean
		{
			return mb_presentInViewBBox;
		}
		
		public function set presentInViewBBox(value: Boolean): void
		{
			mb_presentInViewBBox = value;
		}
		
		public function FeatureBase(s_namespace: String, s_typeName: String, s_featureId: String)
		{
			super();
			ms_namespace = s_namespace;
			ms_typeName = s_typeName;
			ms_featureId = s_featureId;
			mouseEnabled = false;
			mouseChildren = false;
			doubleClickEnabled = false;
			
			mb_presentInViewBBox = true;
			
			m_coordinates = [];
		}

		/** Called after the feature is added to master, before first call to update(). */
		public function setMaster(master: InteractiveLayerFeatureBase): void
		{
			m_master = master;
		}
		
//		private function onPointsChanged(event: CollectionEvent): void
//		{
//			var changeEvent: PropertyChangeEvent
//			if (event.kind == CollectionEventKind.UPDATE)
//			{
//				changeEvent = event.items[0] as PropertyChangeEvent;
//			}
//			if (event.kind == CollectionEventKind.REPLACE)
//			{
//				changeEvent = event.items[0] as PropertyChangeEvent;
//			}
//		}
		
		public function addPointAt(point: Point, index: uint): void
		{
			m_points.splice(index, 0, point);
		}
		
		public function addPoint(point: Point): void
		{
			m_points.push(point);
		}
		
		public function insertPointBefore(i_pointIndex: uint, pt: Point): void
		{
//			m_points.addItemAt(pt, i_pointIndex);
//			m_coordinates.addItemAt(m_master.container.pointToCoord(pt.x, pt.y), i_pointIndex);
			
			m_points.splice(i_pointIndex, 0, pt);
			m_coordinates.splice(i_pointIndex, 0, m_master.container.pointToCoord(pt.x, pt.y));
				
			update(FeatureUpdateContext.fullUpdate());
		}
		
		private function initializePoints(): void
		{
			m_points = [];
			
//			if (m_points)
//				m_points.removeEventListener(CollectionEvent.COLLECTION_CHANGE, onPointsChanged);
//			m_points = new ArrayCollection();
//			m_points.addEventListener(CollectionEvent.COLLECTION_CHANGE, onPointsChanged);
		}

		/** Called after the feature is added to master or after any change (e.g. area change). */
		public function update(changeFlag: FeatureUpdateContext): void
		{
			if (mb_pointsDirty)
			{
				mb_pointsDirty = false;
				initializePoints();
				
				/**
				 * this function needs also check all coordinates reflection, because feature can be displayed in other reflections (and this algorithm without reflection would dispatch that feature is outside of view BBox
				 */
				if (m_coordinates.length)
				{
					var iw: InteractiveWidget = m_master.container;
//					var viewBBox: BBox = iw.getViewBBox();
					
					var total: int = m_coordinates.length;
					var oldPoint: Point;
					var oldCoordNotInside: Coord;
					var previousPointVisible: Boolean;
					var pt: Point;
					var featureIsInside: Boolean = false;
//					trace("\nFeatureBase update m_coordinates: " + total);
					for (var i: uint = 0; i < total; ++i)
					{
						var c: Coord = m_coordinates[i];
						
						var reflectedCoords: Array = iw.mapCoordToViewReflections(c);
//						trace("FeatureBase update reflectedCoords["+i+"] = " + reflectedCoords.length + " c : " + c + " viewBBox: " + iw.getViewBBox());
						
						for each (var currCoordObject: Object in reflectedCoords)
						{
							var currPoint: Point = (currCoordObject.point as Point)
							var currCoord: Coord = new Coord(iw.crs, currPoint.x, currPoint.y);
							
							if (iw.coordInside(currCoord))
							{
								featureIsInside = true;
								notifyCoordinateInside(c, i, currCoordObject.reflection);
							} else {
								trace("coord is outside");
								notifyCoordinateOutside(c, i, currCoordObject.reflection);
							}
						}
							
						pt = iw.coordToPoint(c);
						m_points.push(pt);
						
						if (reflectedCoords && reflectedCoords.length == 0)
						{
							//coordinates has no reflection, has to be hiden
							trace("coordinates has no reflection, has to be hiden");
							notifyCoordinateOutside(c, i, 0); //currCoordObject.reflection);
						}
					}
					if (presentInViewBBox != featureIsInside)
					{
//						trace("coordinatesvisibility change: " + featureIsInside);
						var event: FeatureEvent = new FeatureEvent(FeatureEvent.PRESENCE_IN_VIEW_BBOX_CHANGED, true);
						event.insideViewBBox = featureIsInside;
						dispatchEvent(event);
					}
					presentInViewBBox = featureIsInside;
				}
			}
		}

		protected function notifyCoordinateInside(coord: Coord, coordIndex: uint, coordReflection: uint): void
		{
			var event: FeatureEvent = new FeatureEvent(FeatureEvent.COORDINATE_VISIBLE, true);
			event.coordinate = coord;
			event.coordinateIndex = coordIndex;
			event.coordinateReflection = coordReflection;
			dispatchEvent(event);
		}
		
		protected function notifyCoordinateOutside(coord: Coord, coordIndex: uint, coordReflection: uint): void
		{
			var event: FeatureEvent = new FeatureEvent(FeatureEvent.COORDINATE_INVISIBLE, true);
			event.coordinate = coord;
			event.coordinateIndex = coordIndex;
			dispatchEvent(event);
		}
		/** Called internally before the feature is removed from the master. */
		public function cleanup(): void
		{
			m_master = null;
//			m_coordinates.removeAll();
//			m_points.removeAll();
			if (m_coordinates)
				m_coordinates.splice(0, m_coordinates.length);
			if (m_points)
				m_points.splice(0, m_points.length);
		}

		public function get master(): InteractiveLayerFeatureBase
		{
			return m_master;
		}

		public function getPoints(): Array
		{
			return m_points;
		}

		public function getAveragePoint():Point
		{
			var ret:Point = new Point();
			var len: int = m_points.length;
			for (var i:int = 0; i < len; i++) {
				ret.x = ret.x + m_points[i].x;
				ret.y = ret.y + m_points[i].y;
			}
			ret.x = ret.x / len;
			ret.y = ret.y / len;
			
			return ret;
		}
		
		public function getPoint(i_pointIndex: uint): Point
		{
			if (m_points && m_points.length > i_pointIndex)
				return m_points[i_pointIndex];
			return null;
		}

		public function invalidatePoints(): void
		{
			mb_pointsDirty = true;
		}

		// helpers methods
		private function getArea(b_useCoordinates: Boolean = true): Number
		{
			var area: Number = 0;
			var a_coordinates: Array = b_useCoordinates ? coordinates : getPoints();
			var total: int = a_coordinates.length;
			var j: int = total - 1;
			var p1: Point;
			var p2: Point;
			for (var i: int = 0; i < total; j = i++)
			{
				p1 = a_coordinates[i];
				p2 = a_coordinates[j];
				area += p1.x * p2.y;
				area -= p1.y * p2.x;
			}
			area /= 2;
			return area;
		}
			
		public function getExtent(): CRSWithBBox
		{
			var a_coordinates: Array = coordinates;
			if (a_coordinates && a_coordinates.length == 1)
			{
				//point has no bounding box
				return null;
			}
			return getExtentFromCoordinates(a_coordinates);
		}

		protected function getExtentFromCoordinates(a_coordinates: Array): CRSWithBBox
		{
			var north: Number = Number.NEGATIVE_INFINITY;
			var south: Number = Number.POSITIVE_INFINITY;
			var east: Number = Number.NEGATIVE_INFINITY;
			var west: Number = Number.POSITIVE_INFINITY;
			for each (var coord: Coord in a_coordinates)
			{
				north = Math.max(coord.y, north);
				south = Math.min(coord.y, south);
				east = Math.max(coord.x, east);
				west = Math.min(coord.x, west);
			}
			var bbox2: BBox = new BBox(west, south, east, north);
			//add 20% as padding
			var ewPadding: Number = (east - west) * 1.2;
			var nsPadding: Number = (north - south) * 1.2;
			west -= ewPadding;
			east += ewPadding;
			north += nsPadding;
			south -= nsPadding;
			var bbox: BBox = new BBox(west, south, east, north);
			return new CRSWithBBox('CRS:84', bbox);
		}

		public function getCenter(b_useCoordinates: Boolean = true): Point
		{
			var a_coordinates: Array = b_useCoordinates ? coordinates : getPoints();
			var total: int = a_coordinates.length;
			var x: Number = 0;
			var y: Number = 0;
			var f: Number;
			var j: int = total - 1;
			var p1: Point;
			var p2: Point;
			if (total == 1)
				return new Point(a_coordinates[0].x, a_coordinates[0].y)
			for (var i: int = 0; i < total; j = i++)
			{
				p1 = a_coordinates[i];
				p2 = a_coordinates[j];
				f = p1.x * p2.y - p2.x * p1.y;
				x += (p1.x + p2.x) * f;
				y += (p1.y + p2.y) * f;
			}
			f = getArea() * 6;
			return new Point(x / f, y / f);
		}

		/** Returns curve approximation using line segments in "coordinates" space */
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
			var segmentRenderer: CurveLineSegmentRenderer = new CurveLineSegmentRenderer();
			var b_closed: Boolean = (this is IClosableCurve) && IClosableCurve(this).isCurveClosed();
			var newSegmentRenderer: CurveLineSegmentRenderer = new CurveLineSegmentRenderer();
			master.container.drawHermitSpline(
					newSegmentRenderer,
					b_useCoordinates ? coordinates : getPoints(),
					b_closed, false, 0.005);
			return newSegmentRenderer.segments;
		}

		// event handlers
		// getters & setters
		public function get coordinates(): Array
		{
			return m_coordinates;
		}

		public function set coordinates(a: Array): void
		{
			m_coordinates = a;
			mb_pointsDirty = true;
		}

		public function get typeName(): String
		{
			return ms_typeName;
		}

		public function get namespaceURI(): String
		{
			return ms_namespace;
		}

		public function set featureId(s: String): void
		{
			ms_featureId = s;
		}

		public function get featureId(): String
		{
			return ms_featureId;
		}

		public function set internalFeatureId(s: String): void
		{
			ms_internalFeatureId = s;
		}

		public function get internalFeatureId(): String
		{
			return ms_internalFeatureId;
		}
	}
}
