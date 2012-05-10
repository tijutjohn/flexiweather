package com.iblsoft.flexiweather.utils.wfs
{
	import com.iblsoft.flexiweather.ogc.BBox;
	import com.iblsoft.flexiweather.proj.Coord;
	import com.iblsoft.flexiweather.proj.Projection;
	import com.iblsoft.flexiweather.widgets.InteractiveWidget;
	
	import flash.geom.Point;

	public class FeatureSplitter
	{
		private var m_iw: InteractiveWidget;
		private var m_crs84Projection: Projection;
		
		public function FeatureSplitter(iw: InteractiveWidget)
		{
			m_iw = iw;
			
			m_crs84Projection = Projection.getByCRS('CRS:84');
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

		public function splitCoordHermitSplineToArrayOfPointPolyLines(coords: Array, b_closed: Boolean): Array
		{
			// let's draw Hermit Spline in CRS:84
			return [];
		}
		
		
		private var m_projectionWidth: Number;
		private var m_projectionWidthHalf: Number;
		
		public function splitCoordPolyLineToArrayOfPointPolyLines(coords: Array, b_closed: Boolean): Array
		{
			var total: int = coords.length;
			
			var projection: Projection = m_iw.getCRSProjection(); //Projection.getByCRS((coords[0] as Coord).crs);
			
			m_projectionWidth = projection.extentBBox.width// getProjectionWidthInPixels(projection);
			m_projectionWidthHalf = m_projectionWidth / 2;
			
			var points: Array = [];
			
			/**
			 * moveDirection = 0 => do not do any change
			 * moveDirection = 1 => move 1 projection width to the right
			 * moveDirection = -1 => move 1 projection width to the left
			 */
			var moveDirection: int = 0;
			var moveCount: int;
			var lastPoint: Point;
			var lastCoord: Coord;
			var i: int;
			var p1: Point;
			var p2: Point;
			var c1: Coord;
			var c2: Coord;
			var crs: String = projection.crs;
			
			var currentViewBBox: BBox = m_iw.getViewBBox();
			var extendedBBox: BBox = m_iw.getExtentBBox();
			var parts: Array = m_iw.mapBBoxToProjectionExtentParts(currentViewBBox);
			
			var _points: Array = [];
			for (i = 0; i < total; i++)
			{
				c1 = coords[i] as Coord;
				c2 = c1.convertToProjection(projection);
				p1 = new Point(c2.x, c2.y);
				_points.push(p1);
			}
			
			if (b_closed)
			{
				c1 = coords[0] as Coord;
				c2 = c1.convertToProjection(projection);
				p1 = new Point(c2.x, c2.y);
				_points.push(p1);
			}
//			for (i = 0; i < total; i++)
//			{
//				p1 = coords[i] as Point;
//				_points.push(p1);
//			}
			
			var currPoint: Point = _points[0] as Point;
			var nextPoint: Point;
			var currPos: int = 1;
			var nearestPoint: Point;
			
			points.push(currPoint);
			
			total = _points.length;
			
			
			while (currPos < total)
			{
				nextPoint = _points[currPos] as Point;
//				splitPointLineToArrayOfPointPolyLines(crs, currPoint, nextPoint);
				
				nextPoint = getNextPoint(currPoint, nextPoint);
				
				points.push(nextPoint);
				
				currPoint = nextPoint;
				currPos++;
				
				
//				c1 = convertToProjection(c1, projection);
//				c2 = convertToProjection(c2, projection);
				
				/*
				var ps: Array = computeLinePointsFromCoords(c1.x, c1.y, c2.x, c2.y);
				
				var p1: Point = ps[0] as Point;
				var p2: Point = ps[1] as Point;
				var directionChanged: Boolean = ps[2] as Boolean;

				if (i == 0)
				{
					movePointsToScreen(p1,p2, projectionWidthInPixels);
					points.push(p1);
					points.push(p2);
				} else {
					
					var same: Boolean;
					if (Math.abs(lastPoint.x - p2.x) > projectionHalfWidthInPixels)
					{
						movePointsToCorrectReflection(lastPoint, p2, p1, projectionWidthInPixels);
					}
					same = pointsAreSame(lastPoint, p1);
					if (same)
					{
						points.push(p2);
					} else {
						trace("problem => lastPoint is not same as new first point");
					}
				}
				
				lastPoint = p2.clone();
				lastCoord = c2.cloneCoord();
				*/
			}
			
//			var resultArr: Array = [];
			var resultArr: Array = [convertToScreenPoints(points)];
			resultArr.push(convertToScreenPoints(shiftCoords(points, 1)));
			resultArr.push(convertToScreenPoints(shiftCoords(points, -1)));
			
			return resultArr;
		}
		
		/*
		private function distanceTo(p1: Point, p2: Point): Number
		{
			var r: Number = 6371; // km
			
			//be sure coords are in LatLong
			var dLat: Number = toRad(c.y - y);
			var dLon: Number = toRad(c.x - x);
			var lat1: Number = toRad(y);
			var lat2: Number = toRad(c.y);
			
			var a: Number = Math.sin(dLat/2) * Math.sin(dLat/2) +
				Math.sin(dLon/2) * Math.sin(dLon/2) * Math.cos(lat1) * Math.cos(lat2); 
			var c2: Number = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1-a)); 
			var d: Number = r * c2;
			
			return d;
		}
		*/
		
		/**
		 * Convert arrray of coordinates to screen points 
		 * @param coords
		 * @param shiftSize
		 * @return 
		 * 
		 */		
		private function convertToScreenPoints(coords: Array): Array
		{
			var arr: Array = [];
			
			var total: int = coords.length;
			var crs: String =  m_iw.getCRS();
			for (var i: int = 0; i < total; i++)
			{
				var p: Point = coords[i] as Point;
				arr.push(m_iw.coordToPoint(new Coord(crs, p.x, p.y)));
			}
			return arr;
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
				trace("drawing from A to B");
				coord1 = new Coord(crs, ax, ay);	
				coord2 = new Coord(crs, bx, by);
			} else {
				trace("drawing from B to A");
				coord1 = new Coord(crs, ax + m_projectionWidth * changeDirection, ay);	
				coord2 = new Coord(crs, bx, by);
				directionChanged = true;
			}
			
			return [coord1, coord2, directionChanged];
			
//			var currentViewBBox: BBox = m_iw.getViewBBox();
//			var extendedBBox: BBox = m_iw.getExtentBBox();
//			var parts: Array = m_iw.mapBBoxToProjectionExtentParts(currentViewBBox);
			
			//				for each(var partBBoxToUpdate: BBox in parts) {
			//					trace("visible parts: " + partBBoxToUpdate.toBBOXString());					
			//				}
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
			{
				return true;
			}
			return false;
		}
		private function movePointsToCorrectReflection(lastPoint: Point, p1: Point, p2: Point, crs84WidthInPixels: int): void
		{
			var crs84HalfWidthInPixels: int = crs84WidthInPixels / 2;
			
			trace("\n\tmovePointsToCorrectReflection");
			trace("\t\t p1: " + p1 + " p2: " + p2 + " lastPoint: " + lastPoint);
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
			} else if ((p1.x + crs84HalfWidthInPixels) < lastPoint.x) {
				
				//need to move points to the left
				while (Math.abs(lastPoint.x - posX) > crs84HalfWidthInPixels)
				{
					p1.x += crs84WidthInPixels;
					p2.x += crs84WidthInPixels;
					
					posX = p1.x;
				}
			}
			
			trace("\t\t END p1: " + p1 + " p2: " + p2 + " lastPoint: " + lastPoint);
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