package com.iblsoft.flexiweather.utils.wfs
{
	import com.iblsoft.flexiweather.ogc.BBox;
	import com.iblsoft.flexiweather.proj.Coord;
	import com.iblsoft.flexiweather.proj.Projection;
	import com.iblsoft.flexiweather.widgets.InteractiveWidget;
	
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.utils.Dictionary;

	public class FeatureSplitter
	{
		private var m_iw: InteractiveWidget;
		private var m_crs84Projection: Projection;

		public function FeatureSplitter(iw: InteractiveWidget)
		{
			m_iw = iw;
			m_crs84Projection = Projection.getByCRS('CRS:84');
		}

		public function destroy(): void
		{
			m_crs84Projection = null;
			m_iw = null;
		}

		public function splitPointLineToArrayOfPointPolyLines(crs: String, currPoint: Point, nextPoint: Point): Array
		{
			return [];
		}

		private function getNextPoint(currPoint: Point, nextPoint: Point): Point
		{
			var nextPointReflections: Array;
			var distance: Number;
			var nearestPoint: Point;
			var minDistance: Number = Number.MAX_VALUE;
			nextPointReflections = m_iw.mapCoordInCRSToViewReflections(nextPoint);
			nearestPoint = nextPoint;
			minDistance = Number.MAX_VALUE;
			//find nearest point
			for each (var p2ReflectedObj: Object in nextPointReflections)
			{
				var p2Reflected: Point = p2ReflectedObj.point as Point;
				distance = Math.abs(p2Reflected.x - currPoint.x);
				if (distance < minDistance)
				{
					minDistance = distance;
					nearestPoint = p2Reflected;
				}
			}
			return nearestPoint;
		}

		public function splitCoordHermitSplineToArrayOfPointPolyLines(coords: Array, bClosed: Boolean, bPolygon: Boolean = false): Array
		{
			// let's draw Hermit Spline in CRS:84
//			return [];
			return splitCoordPolyLineToArrayOfPointPolyLines(coords, bClosed, bPolygon);
		}
		private var m_projectionWidth: Number;
		private var m_projectionWidthHalf: Number;

		public function splitCoordPolyLineToArrayOfPointPolyLines(coords: Array, bClosed: Boolean, bPolygon: Boolean = false, bClipping: Boolean = true): Array
		{
			if (coords.length == 0)
				return [];
			
			var total: int = coords.length;
			var projection: Projection = m_iw.getCRSProjection()
			m_projectionWidth = projection.extentBBox.width;
			m_projectionWidthHalf = m_projectionWidth / 2;
			
			var _points: Array = convertCoordsToPoints(coords, projection, bClosed);
			var points: Array = _points;
//			var points: Array = createPoints(_points);
			var resultArr: Array = createScreenPoints(points, projection, bPolygon, bClipping);
			
			return resultArr;
		
		}

		/**
		 * Use this method for converting coordinates to screen points in same way as  splitCoordPolyLineToArrayOfPointPolyLines method but without clipping
		 * 
		 * @param coords
		 * @param bClosed
		 * @param bPolygon
		 * @return 
		 * 
		 */		
		public function convertCoordinatesToScreenPointsWithoutClipping(coords: Array, bClosed: Boolean, bPolygon: Boolean = false): Array
		{
			var projection: Projection = m_iw.getCRSProjection();
			m_projectionWidth = projection.extentBBox.width;
			m_projectionWidthHalf = m_projectionWidth / 2;
			
			var _points: Array = convertCoordsToPoints(coords, projection, bClosed);
			var points: Array = createPoints(_points);
			var resultArr: Array = createScreenPoints(points, projection, bPolygon, false);
			
			return resultArr;
		}
		
		private function createScreenPoints(points: Array, projection: Projection, bPolygon: Boolean = false, bClipping: Boolean = true): Array
		{
			var resultArr: Array = [];
			var polygons: Array;
			var polygon: Array;
			var i: int;
			
			if (projection.wrapsHorizontally)
			{
				for (i = 0; i < 5; i++)
				{
					var i_delta: int = (i & 1 ? 1 : -1) * ((i + 1) >> 1); // generates sequence 0, 1, -1, 2, -2, ..., 5, -5
					polygons = convertToScreenPoints(shiftCoords(points, i_delta), bPolygon, bClipping);
					for each (polygon in polygons)
					{
						resultArr.push(polygon);
					}
				}
			} else {
				// projection does not wrap around
				polygons = convertToScreenPoints(points, bPolygon, bClipping);
				for each (polygon in polygons)
				{
					resultArr.push(polygon);
				}
			}
			return resultArr;
		}
		
		private function createPoints(_points: Array): Array
		{
			var points: Array = [];
			
			var currPoint: Point = _points[0] as Point;
			var nextPoint: Point;
			var currPos: int = 1;
			var nearestPoint: Point;
			points.push(currPoint);
			var total: int = _points.length;
			while (currPos < total)
			{
				nextPoint = _points[currPos] as Point;
				nextPoint = getNextPoint(currPoint, nextPoint);
				points.push(nextPoint);
				currPoint = nextPoint;
				currPos++;
			}
			return points;
		}
		
		private function convertCoordsToPoints(coords: Array, projection: Projection, bClosed: Boolean): Array
		{
			var i: int;
			var c1: Coord;
			var c2: Coord;
			var p1: Point;
			var p2: Point;
			var total: int = coords.length;
			var _points: Array = [];
			for (i = 0; i < total; i++)
			{
				c1 = coords[i] as Coord;
				c2 = c1.convertToProjection(projection);
				p1 = new Point(c2.x, c2.y);
				_points.push(p1);
			}
			if (bClosed)
			{
				c1 = coords[0] as Coord;
				c2 = c1.convertToProjection(projection);
				p1 = new Point(c2.x, c2.y);
				_points.push(p1);
			}
			
			return _points;
		}
		/**
		 * Convert arrray of coordinates to screen points
		 * @param coords - coords in lat lon. Array consist points as Point.
		 * @param shiftSize
		 * @return
		 */
		private function convertToScreenPoints(coords: Array, bPolygon: Boolean = false, bClipping: Boolean = true): Array
		{
			var arr: Array = [];
			var total: int = coords.length;
			var crs: String = m_iw.getCRS();
			var i: int;
			
			var padding: int = 0;
			var viewPolygon: Array = [new Point(padding, padding), new Point(m_iw.width - padding, padding), new Point(m_iw.width - padding, m_iw.height - padding), new Point(padding, m_iw.height - padding)];
			var polygon: Array = [];
			
			for (i = 0; i < total; i++)
			{
				var p: Point = coords[i] as Point;
				var screenPoint: Point = m_iw.coordToPoint(new Coord(crs, p.x, p.y));
				polygon.push(screenPoint);
			}
			
			if (bPolygon)
			{
				if (bClipping)
				{
					//polygon clipping
					var clippedPolygon: Array = polygonClipppingSutherlandHodgman(polygon, viewPolygon);
					arr.push(clippedPolygon);
				} else {
					arr.push(polygon);
				}
			} else {

				if (bClipping)
				{
					//line clipping
					var viewRect: Rectangle = new Rectangle(padding, padding, m_iw.width - 2 * padding, m_iw.height - 2 * padding);
					var lastPoint: Point;
					var polyline: Array = [];
					
					for (i = 1; i < total; i++)
					{
						var p1: Point = polygon[i - 1] as Point;
						var p2: Point = polygon[i] as Point;
						
						var line: Array = lineClippingCohenSutherland(p1, p2, viewRect);
						
						if (line)
						{
							if (!lastPoint)
							{
								polyline.push(line[0] as Point);
								polyline.push(line[1] as Point);
							} else {
								if ((line[0] as Point).equals(lastPoint))
								{
									//same point, so it's same polyline
									polyline.push(line[1] as Point);
								} else {
									
									//completly new line, previous last point is different
									arr.push(polyline);
									polyline = [];
									polyline.push(line[0] as Point);
									polyline.push(line[1] as Point);
								}
							}
							lastPoint = line[1] as Point;
						} else {
							
							if (lastPoint)
							{
								polyline.push(lastPoint);
								lastPoint = null;
								
								arr.push(polyline);
								polyline = [];
							}
						}
					}
					arr.push(polyline);
				} else {
					arr.push(polygon);
				}
			}

			return arr;
		}

		private function intersection(s: Point, e: Point, cp1: Point, cp2: Point): Point
		{
//			var dc = [ cp1[0] - cp2[0], cp1[1] - cp2[1] ],
//				dp = [ s[0] - e[0], s[1] - e[1] ],
//				n1 = cp1[0] * cp2[1] - cp1[1] * cp2[0],
//				n2 = s[0] * e[1] - s[1] * e[0], 
//				n3 = 1.0 / (dc[0] * dp[1] - dc[1] * dp[0]);
//			return [(n1*dp[0] - n2*dc[0]) * n3, (n1*dp[1] - n2*dc[1]) * n3];
			
			var dc: Point = new Point( cp1.x - cp2.x, cp1.y - cp2.y);
			var dp: Point = new Point( s.x - e.x, s.y - e.y );
			
			var n1: Number = cp1.x * cp2.y - cp1.y * cp2.x;
			var n2: Number = s.x * e.y - s.y * e.x;
			var n3: Number = 1 / (dc.x * dp.y - dc.y * dp.x);
				
			return new Point((n1*dp.x - n2*dc.x) * n3, (n1*dp.y - n2*dc.y) * n3);
		}
		private function inside(p: Point, cp1: Point, cp2: Point): Boolean 
		{
//			return (cp2[0]-cp1[0])*(p[1]-cp1[1]) > (cp2[1]-cp1[1])*(p[0]-cp1[0]);
			return (cp2.x-cp1.x)*(p.y-cp1.y) > (cp2.y-cp1.y)*(p.x-cp1.x);
		}
		
		public static const INSIDE: int = 0; // 0000
		public static const LEFT: int = 1;   // 0001
		public static const RIGHT: int = 2;  // 0010
		public static const BOTTOM: int = 4; // 0100
		public static const TOP: int = 8;    // 1000
		
		private function computeOutCode(p: Point, view: Rectangle): int
		{
			var code: int;
			
			code = INSIDE;          // initialised as being inside of clip window
			
			if (p.x < view.left)           // to the left of clip window
				code |= LEFT;
			else if (p.x > view.right)      // to the right of clip window
				code |= RIGHT;
			if (p.y < view.top)           // below the clip window
				code |= BOTTOM;
			else if (p.y > view.bottom)      // above the clip window
				code |= TOP;
			
			return code;
		}
		
		/**
		 * Implementation of Cohen Sutherland algorithm for line clipping
		 *  
		 * @param p1 - line start point
		 * @param p2 - line end point
		 * @param view - clipping view (mostly widget view)
		 * @return - Array of 2 points of clipped line or null if line is outside of view
		 * 
		 */		
		public function lineClippingCohenSutherland(p1: Point, p2: Point, view: Rectangle): Array
		{
			// compute outcodes for P0, P1, and whatever point lies outside the clip rectangle
			var outcode0: int = computeOutCode(p1, view);
			var outcode1: int = computeOutCode(p2, view);
			var accept: Boolean = false;
			
			var x0: Number = p1.x;
			var y0: Number = p1.y;
			var x1: Number = p2.x;
			var y1: Number = p2.y;
			
			var xmin: Number = view.left;
			var xmax: Number = view.right;
			var ymin: Number = view.top;
			var ymax: Number = view.bottom;
			
			while (true) {
				if (!(outcode0 | outcode1)) { // Bitwise OR is 0. Trivially accept and get out of loop
					accept = true;
					break;
				} else if (outcode0 & outcode1) { // Bitwise AND is not 0. Trivially reject and get out of loop
					break;
				} else {
					// failed both tests, so calculate the line segment to clip
					// from an outside point to an intersection with clip edge
					var x: Number;
					var y: Number;
					
					// At least one endpoint is outside the clip rectangle; pick it.
					var outcodeOut: int = outcode0 ? outcode0 : outcode1;
					
					// Now find the intersection point;
					// use formulas y = y0 + slope * (x - x0), x = x0 + (1 / slope) * (y - y0)
					if (outcodeOut & TOP) {           // point is above the clip rectangle
						x = x0 + (x1 - x0) * (ymax - y0) / (y1 - y0);
						y = ymax;
					} else if (outcodeOut & BOTTOM) { // point is below the clip rectangle
						x = x0 + (x1 - x0) * (ymin - y0) / (y1 - y0);
						y = ymin;
					} else if (outcodeOut & RIGHT) {  // point is to the right of clip rectangle
						y = y0 + (y1 - y0) * (xmax - x0) / (x1 - x0);
						x = xmax;
					} else if (outcodeOut & LEFT) {   // point is to the left of clip rectangle
						y = y0 + (y1 - y0) * (xmin - x0) / (x1 - x0);
						x = xmin;
					}
					
					// Now we move outside point to intersection point to clip
					// and get ready for next pass.
					if (outcodeOut == outcode0) {
						x0 = x;
						y0 = y;
						outcode0 = computeOutCode(new Point(x0, y0), view);
					} else {
						x1 = x;
						y1 = y;
						outcode1 = computeOutCode(new Point(x1, y1), view);
					}
				}
			}
			if (accept) {
				// Following functions are left for implementation by user based on
				// their platform (OpenGL/graphics.h etc.)
//				DrawRectangle(xmin, ymin, xmax, ymax);
				return [new Point(x0, y0), new Point(x1, y1)];
			}
			
			return null;
		}
		
		public function polygonClipppingSutherlandHodgman(subjectPolygon: Array, clipPolygon: Array): Array 
		{
			var cp1: Point;
			var cp2: Point;
			var s: Point;
			var e: Point;
			
			var inputList: Array;
			var outputList: Array = subjectPolygon;
			cp1 = clipPolygon[clipPolygon.length-1];
			
			for each (cp2 in clipPolygon) 
			{
				inputList = outputList;
				
				outputList = [];
				s = inputList[inputList.length - 1]; //last on the input list
				for each (e in inputList) 
				{
					if (inside(e, cp1, cp2)) 
					{
						if (!inside(s, cp1, cp2)) 
						{
							outputList.push(intersection(s, e, cp1, cp2));
						}
						outputList.push(e);
					}
					else if (inside(s, cp1, cp2)) {
						outputList.push(intersection(s, e, cp1, cp2));
					}
					s = e;
				}
				cp1 = cp2;
			}
			
			
//			var outputList = subjectPolygon;
//			cp1 = clipPolygon[clipPolygon.length-1];
//			for (j in clipPolygon) {
//				var cp2 = clipPolygon[j];
//				var inputList = outputList;
//				outputList = [];
//				s = inputList[inputList.length - 1]; //last on the input list
//				for (i in inputList) {
//					var e = inputList[i];
//					if (inside(e)) {
//						if (!inside(s)) {
//							outputList.push(intersection());
//						}
//						outputList.push(e);
//					}
//					else if (inside(s)) {
//						outputList.push(intersection());
//					}
//					s = e;
//				}
//				cp1 = cp2;
//			}
			
//			trace("polygonClipppingSutherlandHodgman: subjectPolygon: " + subjectPolygon.length + " outputList: " + outputList.length);
			if (outputList.length)// > 0 && subjectPolygon.length != outputList.length)
			{
				
				
				var str: String = '';
				var p: Point;
				var clipped: Boolean = false

//				var firstPoint: Point = outputList[0] as Point;
//				var lastPoint: Point = outputList[outputList.length - 1] as Point;
//				if (firstPoint.x != lastPoint.x || firstPoint.y != lastPoint.y)
//				{
//					outputList.push(firstPoint);
//				}
				
				str = '';
				for each (p in outputList)
				{
					if (p.x > -1000 && p.x < 2700)
						str += "["+int(p.x)+","+int(p.y)+"], ";
				}
				if (str.length != 0)
					clipped = true;
				
//				if (clipped)
//				{
//					trace("\nClipped: " + str);
//					trace("outputList: " + str);
//					str = '';
//					for each (p in subjectPolygon)
//					{
//						if (p.x > -1000 && p.x < 2700)
//							str += "["+int(p.x)+","+int(p.y)+"], ";
//					}
//					trace("subjectPolygon: " + str);
//					str = '';
//					for each (p in clipPolygon)
//					{
//						if (p.x > -1000 && p.x < 2700)
//							str += "["+int(p.x)+","+int(p.y)+"], ";
//					}
//					trace("clipPolygon: " + str);
//				
//				}
			}
			return outputList;
		}
		
		
		
		/**
		 * Shift coordinates in array of projection extent width multiplies "shiftSize"
		 * @param coords
		 * @param shiftSize
		 * @return
		 *
		 */
		private function shiftCoords(coords: Array, shiftSize: Number): Array
		{
			var arr: Array = [];
			var total: int = coords.length;
			for (var i: int = 0; i < total; i++)
			{
				var p: Point = coords[i] as Point;
				arr.push(new Point(p.x + shiftSize * m_projectionWidth, p.y));
			}
			return arr;
		}

		/**
		 * Compute lines points from coordinates
		 *
		 * changeDirection = 1 -> if 2nd Coord need to be shifted by whole projection width, shift it to the right
		 * changeDirection = -1 -> if 2nd Coord need to be shifted by whole projection width, shift it to the left
		 */
		public function computeLinePointsFromCoords(crs: String, _p1x: Number, _p1y: Number, _p2x: Number, _p2y: Number, changeDirection: int = 1, draw: Boolean = false): Array
		{
			var ax: Number = _p1x;
			var ay: Number = _p1y;
			var bx: Number = _p2x;
			var by: Number = _p2y;
			var pointsChanged: Boolean;
			if (_p2x <= _p1x)
			{
				ax = _p2x;
				ay = _p2y;
				bx = _p1x;
				by = _p1y;
				pointsChanged = true;
			}
			var dist: Number = bx - ax;
			var coord1: Coord;
			var coord2: Coord;
			var directionChanged: Boolean = false;
			//TODO: finish this... it must support any projection, not just CRS: 84
			if (dist < m_projectionWidthHalf)
			{
				//drawing from A to B
				coord1 = new Coord(crs, ax, ay);
				coord2 = new Coord(crs, bx, by);
			}
			else
			{
				coord1 = new Coord(crs, ax + m_projectionWidth * changeDirection, ay);
				coord2 = new Coord(crs, bx, by);
				directionChanged = true;
			}
			return [coord1, coord2, directionChanged];
//			var currentViewBBox: BBox = m_iw.getViewBBox();
//			var extendedBBox: BBox = m_iw.getExtentBBox();
//			var parts: Array = m_iw.mapBBoxToProjectionExtentParts(currentViewBBox);
		/*
		var p1: Point = m_iw.coordToPoint(coord1);
		var p2: Point = m_iw.coordToPoint(coord2);

		if (dist > m_projectionWidthHalf)
		{
			coord1 = new Coord(crs, -180,0);
			coord2 = new Coord(crs, 180,0);
			var pL: Point = m_iw.coordToPoint(coord1);
			var pR: Point = m_iw.coordToPoint(coord2);
			var projectionWidthInPixels: Number = Math.abs(pR.x - pL.x);

			p1.x += projectionWidthInPixels;
		}

		if (!pointsChanged)
			return [p1,p2, directionChanged];

		return [p2,p1, directionChanged];
		*/
		}

		private function pointsAreSame(p1: Point, p2: Point): Boolean
		{
			var diffX: int = Math.abs(int(p1.x) - int(p2.x));
			var diffY: int = Math.abs(int(p1.y) - int(p2.y));
			if (diffX <= 1 && diffY <= 1)
				return true;
			return false;
		}

		private function movePointsToCorrectReflection(lastPoint: Point, p1: Point, p2: Point, crs84WidthInPixels: int): void
		{
			var crs84HalfWidthInPixels: int = crs84WidthInPixels / 2;
			var posX: int = p1.x;
			if ((lastPoint.x + crs84HalfWidthInPixels) < p1.x)
			{
				//need to move points to the left
				while (Math.abs(lastPoint.x - posX) > crs84HalfWidthInPixels)
				{
					p1.x -= crs84WidthInPixels;
					p2.x -= crs84WidthInPixels;
					posX = p1.x;
				}
			}
			else if ((p1.x + crs84HalfWidthInPixels) < lastPoint.x)
			{
				//need to move points to the left
				while (Math.abs(lastPoint.x - posX) > crs84HalfWidthInPixels)
				{
					p1.x += crs84WidthInPixels;
					p2.x += crs84WidthInPixels;
					posX = p1.x;
				}
			}
		}

		private function movePointsToScreen(p1: Point, p2: Point, crs84WidthInPixels: int): void
		{
			var moveCount: int = getReflectionsCountForMovingPointToScreen(p1, crs84WidthInPixels);
			if (moveCount)
			{
				var movePx: int = crs84WidthInPixels * moveCount;
				p1.x -= movePx;
				p2.x -= movePx;
			}
		}

		private function getReflectionsCountForMovingPointToScreen(p1: Point, crs84WidthInPixels: int): int
		{
			var totalRight: int = m_iw.width;
			var currX: int = p1.x;
			var cnt: int = 0;
			while (currX > totalRight)
			{
				currX -= crs84WidthInPixels;
				cnt++;
			}
			return cnt;
		}
	/**
	 * Get projection width in screen pixels
	 *
	 * @param projection
	 * @return
	 *
	 */
	/*
	private function getProjectionWidthInPixels(projection: Projection): Number
	{
		var coord1:Coord = new Coord("CRS:84", -180,0);
		var coord2:Coord = new Coord("CRS:84", 180,0);

		coord1 = convertToProjection(coord1, projection);
		coord2 = convertToProjection(coord2, projection);

		var pL: Point = m_iw.coordToPoint(coord1);
		var pR: Point = m_iw.coordToPoint(coord2);
		var projectionWidthInPixels: int = Math.abs(pR.x - pL.x);

		return projectionWidthInPixels;
	}
	*/
	}
}
