package com.iblsoft.flexiweather.ogc
{
	import com.iblsoft.flexiweather.ogc.editable.IClosableCurve;
	import com.iblsoft.flexiweather.proj.Coord;
	import com.iblsoft.flexiweather.utils.CubicBezier;
	import com.iblsoft.flexiweather.utils.CurveLineSegment;
	import com.iblsoft.flexiweather.utils.CurveLineSegmentRenderer;
	import com.iblsoft.flexiweather.widgets.InteractiveWidget;
	
	import flash.display.Sprite;
	import flash.geom.Point;
	
	import mx.collections.ArrayCollection;
	
	public class FeatureBase extends Sprite
	{
		protected var m_master: InteractiveLayerFeatureBase;
		
		protected var ms_namespace: String;
		protected var ms_typeName: String;
		protected var ms_featureId: String;
		protected var ms_internalFeatureId: String;
		
		protected var m_coordinates: ArrayCollection = new ArrayCollection();
		protected var m_points: ArrayCollection = new ArrayCollection();
		protected var mb_pointsDirty: Boolean = false;
		
		public function FeatureBase(s_namespace: String, s_typeName: String, s_featureId: String)
		{
			super();
			
			ms_namespace = s_namespace;
			ms_typeName = s_typeName;
			ms_featureId = s_featureId;
			mouseEnabled = false;
			mouseChildren = false;
			doubleClickEnabled = false;
		}
		
		/** Called after the feature is added to master, before first call to update(). */
		public function setMaster(master: InteractiveLayerFeatureBase): void
		{
			m_master = master;
		}
		
		/** Called after the feature is added to master or after any change (e.g. area change). */
		public function update(): void
		{
			if(mb_pointsDirty) {
				mb_pointsDirty = false;
				m_points = new ArrayCollection();
				if(m_coordinates.length) {
					var iw: InteractiveWidget = m_master.container;
					for(var i: uint = 0; i < m_coordinates.length; ++i) {
						var c: Coord = m_coordinates[i];
						var pt: Point = iw.coordToPoint(c);
						m_points.addItem(pt);
					}
				}
			}
		}
		
		/** Called internally before the feature is removed from the master. */ 
		public function cleanup(): void
		{
			m_master = null;
			m_coordinates.removeAll();
			m_points.removeAll();
		}
		
		
		public function get master(): InteractiveLayerFeatureBase
		{ return m_master; }
		
		public function getPoints(): ArrayCollection
		{ return m_points; }
		
		public function getPoint(i_pointIndex: uint): Point
		{
			if (m_points && m_points.length > i_pointIndex)
				return m_points[i_pointIndex];
			
			return null;
		}
		
		public function invalidatePoints(): void
		{ mb_pointsDirty = true; }
		
		// helpers methods
		
		private function getArea(b_useCoordinates: Boolean = true): Number
		{
			var area: Number=0;
			var a_coordinates: Array = b_useCoordinates ? coordinates : getPoints().toArray(); 
			var total: int = a_coordinates.length;
			var j: int = total - 1;
			var p1: Point;
			var p2: Point;
			
			for (var i: int =0;i < total; j=i++) {
				p1= a_coordinates[i]; 
				p2 = a_coordinates[j];
				area += p1.x*p2.y;
				area -= p1.y*p2.x;
			}
			area /= 2;
			return area;
		}
			
		public function getCenter(b_useCoordinates: Boolean = true): Point
		{
			var a_coordinates: Array = b_useCoordinates ? coordinates : getPoints().toArray(); 
			var total: int = a_coordinates.length;
			var x: Number = 0; 
			var y: Number = 0; 
			var f: Number; 
			var j: int = total - 1;
			var p1: Point;
			var p2: Point;
			
			for (var i:int=0;i<total;j=i++) 
			{
				p1 = a_coordinates[i]; 
				p2 = a_coordinates[j];
				f=p1.x*p2.y-p2.x*p1.y;
				x+=(p1.x+p2.x)*f;
				y+=(p1.y+p2.y)*f;
			}
			
			f = getArea()*6;
			return new Point(x/f,y/f);
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
			var a_coordinates: Array = b_useCoordinates ? coordinates : getPoints().toArray(); 
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
				b_useCoordinates ? coordinates : getPoints().toArray(),
				b_closed, false, 0.005, true);
			
			/*CubicBezier.curveThroughPoints(
			segmentRenderer,
			b_useCoordinates ? coordinates : getPoints().toArray(),
			b_closed);*/
			
			//return segmentRenderer.segments;
			
			return newSegmentRenderer.segments;
		}
		
		
		// event handlers
		
		// getters & setters
		public function get coordinates(): Array
		{ return m_coordinates.toArray(); }  		
		
		public function set coordinates(a: Array): void
		{
			m_coordinates = new ArrayCollection(a);
			mb_pointsDirty = true;
		}  		
		
		public function get typeName(): String
		{ return ms_typeName; }
		
		public function get namespaceURI(): String
		{ return ms_namespace; }
		
		public function set featureId(s: String): void
		{ ms_featureId = s; }
		
		public function get featureId(): String
		{ return ms_featureId; }
		
		public function set internalFeatureId(s: String): void
		{ ms_internalFeatureId = s; }
		
		public function get internalFeatureId(): String
		{ return ms_internalFeatureId; }
	}
}