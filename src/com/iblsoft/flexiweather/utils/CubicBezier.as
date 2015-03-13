package com.iblsoft.flexiweather.utils
{
	import com.iblsoft.flexiweather.utils.wfs.FeatureSplitter;
	import com.iblsoft.flexiweather.widgets.InteractiveWidget;

	import flash.geom.Point;

	public class CubicBezier
	{
		public static function subdivideBezier(g: ICurveRenderer,
				p0_x: Number, p0_y: Number, p1_x: Number, p1_y: Number,
				s0_x: Number, s0_y: Number, s1_x: Number, s1_y: Number,
				h: Number, prec: Number): void
		{
			var pavg_x: Number = 0.5 * (p0_x + p1_x);
			var pavg_y: Number = 0.5 * (p0_y + p1_y);
			var smid_x: Number = 0.5 * (s0_x + s1_x);
			var smid_y: Number = 0.5 * (s0_y + s1_y);
			var factor: Number = 0.5 * h * h;
			var ofs_x: Number = factor * smid_x;
			var ofs_y: Number = factor * smid_y;
			if (ofs_x * ofs_x + ofs_y * ofs_y <= prec)
				return;
			var pmid_x: Number = pavg_x - ofs_x;
			var pmid_y: Number = pavg_y - ofs_y;
			subdivideBezier(g, p0_x, p0_y, pmid_x, pmid_y, s0_x, s0_y, smid_x, smid_y, 0.5 * h, prec);
			g.lineTo(pmid_x, pmid_y);
			/*
			g.lineTo(pmid_x + 4, pmid_y + 4);
			g.lineTo(pmid_x, pmid_y);
			g.lineTo(pmid_x - 4, pmid_y);
			g.lineTo(pmid_x, pmid_y);
			*/
			subdivideBezier(g, pmid_x, pmid_y, p1_x, p1_y, smid_x, smid_y, s1_x, s1_y, 0.5 * h, prec);
		}

		public static function expandBezier(g: ICurveRenderer,
				V0: Point, V1: Point, V2: Point, V3: Point, prec: Number): void
		{
			var sd0_x: Number = 6.0 * (V2.x - (V1.x + V1.x) + V0.x);
			var sd0_y: Number = 6.0 * (V2.y - (V1.y + V1.y) + V0.y);
			var sd1_x: Number = 6.0 * (V3.x - (V2.x + V2.x) + V1.x);
			var sd1_y: Number = 6.0 * (V3.y - (V2.y + V2.y) + V1.y);
			g.moveTo(V0.x, V0.y);
			subdivideBezier(g, V0.x, V0.y, V3.x, V3.y, sd0_x, sd0_y, sd1_x, sd1_y, 0.5, prec);
			g.lineTo(V3.x, V3.y);
		}

		/* pubic static function drawCurve
		 * 	Draws a single cubic Bézier curve
		 * 	@param:
		 * 		g: Graphics			 - Graphics on which to draw the curve
		 * 		p1: Point			 - First point in the curve
		 * 		p2: Point			 - Second point(control point) in the curve
		 * 		p3: Point			 - Third point(control point) in the curve
		 * 		p4: Point			 - Fourth point in the curve
		 * 		styling				 - Curve styling helper
		 * 	@return:
		*/
		public static function drawCurve(
				g: ICurveRenderer,
				p1: Point, p2: Point, p3: Point, p4: Point): void
		{
			var bezier: BezierSegment = new BezierSegment(p1, p2, p3, p4); // BezierSegment using the four points
			g.start(p1.x, p1.y);
			expandBezier(g, p1, p2, p3, p4, 0.5);
			g.finish(p4.x, p4.y);
		}

		/* public static function curveThroughPoints
		 * 	Draws a smooth curve through a series of points. For a closed curve, make the first and last points the same.
		 * 	@param:
		 * 		g: Graphics			 - Graphics on which to draw the curve
		 * 		p: Array				 - Array of Point instances
		 * 		z: Number			 - A factor(between 0 and 1) to reduce the size of curves by limiting the distance of control points from anchor points.
		 * 							 For example, z=.5 limits control points to half the distance of the closer adjacent anchor point.
		 * 							 I put the option here, but I recommend sticking with .5
		 * 		angleFactor: Number	 - Adjusts the size of curves depending on how acute the angle between points is. Curves are reduced as acuteness
		 * 							 increases, and this factor controls by how much.
		 * 							 1 = curves are reduced in direct proportion to acuteness
		 * 							 0 = curves are not reduced at all based on acuteness
		 * 							 in between = the reduction is basically a percentage of the full reduction
		 * 		moveTo: Bollean		 - Specifies whether to move to the first point in the curve rather than continuing drawing
		 * 							 from wherever drawing left off.
		 * 	@return:
		*/
		public static function curveThroughPoints(
				g: ICurveRenderer,
				points: Array /* of Points */,
				b_closed: Boolean = false,
				z: Number = .5,
				angleFactor: Number = .75,
				moveTo: Boolean = true): void
		{
			try
			{
				var p: Array = points.slice(); // Local copy of points array
				if (b_closed)
					p.push(p[0]);
				var duplicates: Array = new Array(); // Array to hold indices of duplicate points
				// Check to make sure array contains only Points
				for (var i: uint = 0; i < p.length; i++)
				{
					if (!(p[i] is Point))
						throw new Error("Array must contain Point objects");
					// Check for the same point twice in a row
					if (i > 0)
					{
						if (p[i].x == p[i - 1].x && p[i].y == p[i - 1].y)
							duplicates.push(i); // add index of duplicate to duplicates array
					}
				}
				// Loop through duplicates array and remove points from the points array
				for (var j: int = duplicates.length - 1; j >= 0; j--)
				{
					p.splice(duplicates[j], 1);
				}
				// Make sure z is between 0 and 1(too messy otherwise)
				if (z <= 0)
					z = .5;
				else if (z > 1)
					z = 1;
				// Make sure angleFactor is between 0 and 1
				if (angleFactor < 0)
					angleFactor = 0;
				else if (angleFactor > 1)
					angleFactor = 1;
				//
				// First calculate all the curve control points
				//
				// None of this junk will do any good if there are only two points
				if (p.length > 2)
				{
					// Generate control points
					var controlsPointsDesc: ControlPointsDescriptor = CubicBezier.generateControlPoints(
							p,
							b_closed,
							z,
							angleFactor,
							moveTo);
					//
					// Now draw the curve
					//
					var f_distanceFromStart: Number = 0;
					g.start(p[0].x, p[0].y);
					// If moveTo condition is false, this curve can connect to a previous curve on the same graphics.
					if (moveTo)
						g.moveTo(p[0].x, p[0].y);
					else
						g.lineTo(p[0].x, p[0].y);
					// If this isn't a closed line
					if (controlsPointsDesc.firstPt == 1)
					{
						// Draw a regular quadratic Bézier curve from the first to second points, using the first control point of the second point
						g.curveTo(controlsPointsDesc.controlPts[1][0].x, controlsPointsDesc.controlPts[1][0].y, p[1].x, p[1].y);
					}
					var straightLines: Boolean = true; // Change to true if you want to use lineTo for straight lines of 3 or more points rather than curves. You'll get straight lines but possible sharp corners!
					// Loop through points to draw cubic Bézier curves through the penultimate point, or through the last point if the line is closed.
					for (i = controlsPointsDesc.firstPt; i < controlsPointsDesc.lastPt - 1; i++)
					{
						// Determine if multiple points in a row are in a straight line
						var isStraight: Boolean =
								((i > 0 && Math.atan2(p[i].y - p[i - 1].y, p[i].x - p[i - 1].x)
								==
								Math.atan2(p[i + 1].y - p[i].y, p[i + 1].x - p[i].x))
								||
								(i < p.length - 2 && Math.atan2(p[i + 2].y - p[i + 1].y, p[i + 2].x - p[i + 1].x)
								==
								Math.atan2(p[i + 1].y - p[i].y, p[i + 1].x - p[i].x)));
						if (straightLines && isStraight)
							g.lineTo(p[i + 1].x, p[i + 1].y);
						else
							drawCurve(g, p[i], controlsPointsDesc.controlPts[i][1], controlsPointsDesc.controlPts[i + 1][0], p[i + 1]);
					}
					// If this isn't a closed line
					if (controlsPointsDesc.lastPt == p.length - 1)
					{
						// Curve to the last point using the second control point of the penultimate point.
						g.curveTo(controlsPointsDesc.controlPts[i][1].x, controlsPointsDesc.controlPts[i][1].y, p[i + 1].x, p[i + 1].y);
					}
						// just draw a line if only two points
				}
				else if (p.length == 2)
				{
					g.start(p[0].x, p[0].y);
					g.moveTo(p[0].x, p[0].y);
					g.lineTo(p[1].x, p[1].y);
				}
				g.finish(p[p.length - 1].x, p[p.length - 1].y);
			}
			// Catch error
			catch (e: Error)
			{
				trace(e.getStackTrace());
			}
		}

		/**
		 * Function returns all control points depending of inserted points
		 *
		 */
		public static function generateControlPoints(
				p: Array /* of Points */,
				b_closed: Boolean = false,
				z: Number = .5,
				angleFactor: Number = .75,
				moveTo: Boolean = true): ControlPointsDescriptor
		{
			// Create returning ControlPointsDescriptor
			var retObj: ControlPointsDescriptor = new ControlPointsDescriptor();
			// Ordinarily, curve calculations will start with the second point and go through the second - to - last point
			retObj.firstPt = 1;
			retObj.lastPt = p.length - 1;
			// Check if this is a closed line(the first and last points are the same)
			if (b_closed)
			{
				// Include first and last points in curve calculations
				retObj.firstPt = 0;
				retObj.lastPt = p.length;
			}
			retObj.controlPts = new Array(); // An array to store the two control points(of a cubic Bézier curve) for each point
			// Loop through all the points(except the first and last if not a closed line) to get curve control points for each.
			for (var i: uint = retObj.firstPt; i < retObj.lastPt; i++)
			{
				// The previous, current, and next points
				var p0: Point = (i - 1 < 0) ? p[p.length - 2] : p[i - 1]; // If the first point(of a closed line), use the second - to - last point as the previous point
				var p1: Point = p[i];
				var p2: Point = (i + 1 == p.length) ? p[1] : p[i + 1]; // If the last point(of a closed line), use the second point as the next point
				var a: Number = Point.distance(p0, p1); // Distance from previous point to current point
				if (a < 0.001)
					a = .001; // Correct for near - zero distances, a cheap way to prevent division by zero
				var b: Number = Point.distance(p1, p2); // Distance from current point to next point
				if (b < 0.001)
					b = .001;
				var c: Number = Point.distance(p0, p2); // Distance from previous point to next point
				if (c < 0.001)
					c = .001;
				var cos: Number = (b * b + a * a - c * c) / (2 * b * a);
				// Make sure above value is between - 1 and 1 so that Math.acos will work
				if (cos < -1)
					cos = -1;
				else if (cos > 1)
					cos = 1;
				var C: Number = Math.acos(cos); // Angle formed by the two sides of the triangle(described by the three points above) adjacent to the current point
				// Duplicate set of points. Start by giving previous and next points values RELATIVE to the current point.
				var aPt: Point = new Point(p0.x - p1.x, p0.y - p1.y);
				var bPt: Point = new Point(p1.x, p1.y);
				var cPt: Point = new Point(p2.x - p1.x, p2.y - p1.y);
				/*
				We'll be adding adding the vectors from the previous and next points to the current point,
				but we don't want differing magnitudes(i.e. line segment lengths) to affect the direction
				of the new vector. Therefore we make sure the segments we use, based on the duplicate points
				created above, are of equal length. The angle of the new vector will thus bisect angle C
				(defined above) and the perpendicular to this is nice for the line tangent to the curve.
				The curve control points will be along that tangent line.
				*/
				if (a > b)
					aPt.normalize(b); // Scale the segment to aPt(bPt to aPt) to the size of b(bPt to cPt) if b is shorter.
				else if (b > a)
					cPt.normalize(a); // Scale the segment to cPt(bPt to cPt) to the size of a(aPt to bPt) if a is shorter.
				// Offset aPt and cPt by the current point to get them back to their absolute position.
				aPt.offset(p1.x, p1.y);
				cPt.offset(p1.x, p1.y);
				// Get the sum of the two vectors, which is perpendicular to the line along which our curve control points will lie.
				var ax: Number = bPt.x - aPt.x; // x component of the segment from previous to current point
				var ay: Number = bPt.y - aPt.y;
				var bx: Number = bPt.x - cPt.x; // x component of the segment from next to current point
				var by: Number = bPt.y - cPt.y;
				var rx: Number = ax + bx; // sum of x components
				var ry: Number = ay + by;
				// Correct for three points in a line by finding the angle between just two of them
				if (rx == 0 && ry == 0)
				{
					rx = -bx; // Really not sure why this seems to have to be negative
					ry = by;
				}
				// Switch rx and ry when y or x difference is 0. This seems to prevent the angle from being perpendicular to what it should be.
				if (ay == 0 && by == 0)
				{
					rx = 0;
					ry = 1;
				}
				else if (ax == 0 && bx == 0)
				{
					rx = 1;
					ry = 0;
				}
				var r: Number = Math.sqrt(rx * rx + ry * ry); // length of the summed vector - not being used, but there it is anyway
				var theta: Number = Math.atan2(ry, rx); // angle of the new vector
				var controlDist: Number = Math.min(a, b) * z; // Distance of curve control points from current point: a fraction the length of the shorter adjacent triangle side
				var controlScaleFactor: Number = C / Math.PI; // Scale the distance based on the acuteness of the angle. Prevents big loops around long, sharp - angled triangles.
				controlDist *= ((1 - angleFactor) + angleFactor * controlScaleFactor); // Mess with this for some fine - tuning
				var controlAngle: Number = theta + Math.PI / 2; // The angle from the current point to control points: the new vector angle plus 90 degrees(tangent to the curve).
				var controlPoint2: Point = Point.polar(controlDist, controlAngle); // Control point 2, curving to the next point.
				var controlPoint1: Point = Point.polar(controlDist, controlAngle + Math.PI); // Control point 1, curving from the previous point(180 degrees away from control point 2).
				// Offset control points to put them in the correct absolute position
				controlPoint1.offset(p1.x, p1.y);
				controlPoint2.offset(p1.x, p1.y);
				/*
				Haven't quite worked out how this happens, but some control points will be reversed.
				In this case controlPoint2 will be farther from the next point than controlPoint1 is.
				Check for that and switch them if it's true.
				*/
				if (Point.distance(controlPoint2, p2) > Point.distance(controlPoint1, p2))
					retObj.controlPts[i] = new Array(controlPoint2, controlPoint1); // Add the two control points to the array in reverse order
				else
					retObj.controlPts[i] = new Array(controlPoint1, controlPoint2); // Otherwise add the two control points to the array in normal order
					// Uncomment to draw lines showing where the control points are.
				/*
				g.moveTo(p1.x, p1.y);
				g.lineTo(controlPoint2.x, controlPoint2.y);
				g.moveTo(p1.x, p1.y);
				g.lineTo(controlPoint1.x, controlPoint1.y);
				*/
			}
			return (retObj);
		}

		/**
		 *
		 */
		public static function subdivideBezierPoints(
				p0_x: Number, p0_y: Number, p1_x: Number, p1_y: Number,
				s0_x: Number, s0_y: Number, s1_x: Number, s1_y: Number,
				h: Number, prec: Number): Array
		{
			var pavg_x: Number = 0.5 * (p0_x + p1_x);
			var pavg_y: Number = 0.5 * (p0_y + p1_y);
			var smid_x: Number = 0.5 * (s0_x + s1_x);
			var smid_y: Number = 0.5 * (s0_y + s1_y);
			var factor: Number = 0.5 * h * h;
			var ofs_x: Number = factor * smid_x;
			var ofs_y: Number = factor * smid_y;
			var retArray: Array = new Array();
			if (ofs_x * ofs_x + ofs_y * ofs_y <= prec)
				return (retArray);
			var pmid_x: Number = pavg_x - ofs_x;
			var pmid_y: Number = pavg_y - ofs_y;
			retArray.concat(subdivideBezierPoints(p0_x, p0_y, pmid_x, pmid_y, s0_x, s0_y, smid_x, smid_y, 0.5 * h, prec));
			//g.lineTo(pmid_x, pmid_y);
			retArray.push(new Point(pmid_x, pmid_y));
			/*
			g.lineTo(pmid_x + 4, pmid_y + 4);
			g.lineTo(pmid_x, pmid_y);
			g.lineTo(pmid_x - 4, pmid_y);
			g.lineTo(pmid_x, pmid_y);
			*/
			retArray.concat(subdivideBezierPoints(pmid_x, pmid_y, p1_x, p1_y, smid_x, smid_y, s1_x, s1_y, 0.5 * h, prec));
			return (retArray);
		}

		/**
		 *
		 */
		public static function expandBezierPoints(
				V0: Point, V1: Point, V2: Point, V3: Point, prec: Number): Array
		{
			var sd0_x: Number = 6.0 * (V2.x - (V1.x + V1.x) + V0.x);
			var sd0_y: Number = 6.0 * (V2.y - (V1.y + V1.y) + V0.y);
			var sd1_x: Number = 6.0 * (V3.x - (V2.x + V2.x) + V1.x);
			var sd1_y: Number = 6.0 * (V3.y - (V2.y + V2.y) + V1.y);
			var retArray: Array = new Array();
			//g.moveTo(V0.x, V0.y);
			retArray.push(V0);
			retArray.concat(subdivideBezierPoints(V0.x, V0.y, V3.x, V3.y, sd0_x, sd0_y, sd1_x, sd1_y, 0.5, prec));
			//g.lineTo(V3.x, V3.y);
			retArray.push(V3);
			return (retArray);
		}

		/* public static function hermitCurveThroughPoints
		 * 	Draws a smooth curve through a series of points. For a closed curve, make the first and last points the same.
		 * 	@param:
		 * 		g: Graphics			 - Graphics on which to draw the curve
		 * 		p: Array				 - Array of Point instances
		 * 		z: Number			 - A factor(between 0 and 1) to reduce the size of curves by limiting the distance of control points from anchor points.
		 * 							 For example, z=.5 limits control points to half the distance of the closer adjacent anchor point.
		 * 							 I put the option here, but I recommend sticking with .5
		 * 		angleFactor: Number	 - Adjusts the size of curves depending on how acute the angle between points is. Curves are reduced as acuteness
		 * 							 increases, and this factor controls by how much.
		 * 							 1 = curves are reduced in direct proportion to acuteness
		 * 							 0 = curves are not reduced at all based on acuteness
		 * 							 in between = the reduction is basically a percentage of the full reduction
		 * 		moveTo: Bollean		 - Specifies whether to move to the first point in the curve rather than continuing drawing
		 * 							 from wherever drawing left off.
		 * 	@return:
		*/
		public static function hermitCurveThroughPoints(
				g: ICurveRenderer,
				points: Array /* of Points */,
				b_closed: Boolean = false,
				z: Number = .5,
				angleFactor: Number = .75,
				moveTo: Boolean = true): void
		{
			try
			{
				var p: Array = points.slice(); // Local copy of points array
				if (b_closed)
					p.push(p[0]);
				var duplicates: Array = new Array(); // Array to hold indices of duplicate points
				// Check to make sure array contains only Points
				for (var i: uint = 0; i < p.length; i++)
				{
					if (!(p[i] is Point))
						throw new Error("Array must contain Point objects");
					// Check for the same point twice in a row
					if (i > 0)
					{
						if (p[i].x == p[i - 1].x && p[i].y == p[i - 1].y)
							duplicates.push(i); // add index of duplicate to duplicates array
					}
				}
				// Loop through duplicates array and remove points from the points array
				for (var j: int = duplicates.length - 1; j >= 0; j--)
				{
					p.splice(duplicates[j], 1);
				}
				// Make sure z is between 0 and 1(too messy otherwise)
				if (z <= 0)
					z = .5;
				else if (z > 1)
					z = 1;
				// Make sure angleFactor is between 0 and 1
				if (angleFactor < 0)
					angleFactor = 0;
				else if (angleFactor > 1)
					angleFactor = 1;
				//
				// First calculate all the curve control points
				//
				// None of this junk will do any good if there are only two points
				if (p.length > 2)
				{
					// Generate control points
					var controlsPointsDesc: ControlPointsDescriptor = CubicBezier.generateControlPoints(
							p,
							b_closed,
							z,
							angleFactor,
							moveTo);
					//
					// Now draw the curve
					//
					var f_distanceFromStart: Number = 0;
					g.start(p[0].x, p[0].y);
					// If moveTo condition is false, this curve can connect to a previous curve on the same graphics.
					if (moveTo)
						g.moveTo(p[0].x, p[0].y);
					else
						g.lineTo(p[0].x, p[0].y);
					// If this isn't a closed line
					if (controlsPointsDesc.firstPt == 1)
					{
						// Draw a regular quadratic Bézier curve from the first to second points, using the first control point of the second point
						g.curveTo(controlsPointsDesc.controlPts[1][0].x, controlsPointsDesc.controlPts[1][0].y, p[1].x, p[1].y);
					}
					var straightLines: Boolean = true; // Change to true if you want to use lineTo for straight lines of 3 or more points rather than curves. You'll get straight lines but possible sharp corners!
					// Loop through points to draw cubic Bézier curves through the penultimate point, or through the last point if the line is closed.
					for (i = controlsPointsDesc.firstPt; i < controlsPointsDesc.lastPt - 1; i++)
					{
						// Determine if multiple points in a row are in a straight line
						var isStraight: Boolean =
								((i > 0 && Math.atan2(p[i].y - p[i - 1].y, p[i].x - p[i - 1].x)
								==
								Math.atan2(p[i + 1].y - p[i].y, p[i + 1].x - p[i].x))
								||
								(i < p.length - 2 && Math.atan2(p[i + 2].y - p[i + 1].y, p[i + 2].x - p[i + 1].x)
								==
								Math.atan2(p[i + 1].y - p[i].y, p[i + 1].x - p[i].x)));
						if (straightLines && isStraight)
							g.lineTo(p[i + 1].x, p[i + 1].y);
						else
							drawCurve(g, p[i], controlsPointsDesc.controlPts[i][1], controlsPointsDesc.controlPts[i + 1][0], p[i + 1]);
					}
					// If this isn't a closed line
					if (controlsPointsDesc.lastPt == p.length - 1)
					{
						// Curve to the last point using the second control point of the penultimate point.
						g.curveTo(controlsPointsDesc.controlPts[i][1].x, controlsPointsDesc.controlPts[i][1].y, p[i + 1].x, p[i + 1].y);
					}
						// just draw a line if only two points
				}
				else if (p.length == 2)
				{
					g.start(p[0].x, p[0].y);
					g.moveTo(p[0].x, p[0].y);
					g.lineTo(p[1].x, p[1].y);
				}
				g.finish(p[p.length - 1].x, p[p.length - 1].y);
			}
			// Catch error
			catch (e: Error)
			{
				trace(e.getStackTrace());
			}
		}

		/**
		 * Calculates and draw all needed parameters for hermit spline (distances, derivations, points)
		 *
		 * @return;
		 * Returns array of MPoints
		 *
		 */
		public static function drawHermitSpline(
				g: ICurveRenderer,
				_points: Array,
				_closed: Boolean = false,
				_drawHiddenHitMask: Boolean = false, // PREPARED PARAMETER FOR DRAWING HIT MASK AREA
				_distanceValidator: Function = null,
				_discontinuityValidator: Function = null,
				_step: Number = 0.01,
				_useSegmentation: Boolean = false): Array
		{
			var mPoints: Array = CubicBezier.calculateHermitSpline(_points, _closed, _distanceValidator, _discontinuityValidator);
			var actSegment: int = 0;
			g.start(mPoints[0].x, mPoints[0].y);
			g.moveTo(mPoints[0].x, mPoints[0].y);
			for (var i: int = 1; i < mPoints.length; i++)
			{
				g.lineTo(mPoints[i].x, mPoints[i].y);
				if ((actSegment != SPoint(mPoints[i]).segmentIndex) && (_useSegmentation))
				{
					g.finish(mPoints[i].x, mPoints[i].y);
					g.start(mPoints[i].x, mPoints[i].y);
					g.moveTo(mPoints[i].x, mPoints[i].y);
					actSegment = SPoint(mPoints[i]).segmentIndex;
				}
			}
			g.finish(mPoints[mPoints.length - 1].x, mPoints[mPoints.length - 1].y);
			return (mPoints);
		}

		/**
		 * Calculates all needed parameters for hermit spline (distances, derivations, points)
		 *
		 * @param _points - screen pixel positions
		 * @param _closed
		 * @param _step
		 * @return Returns array of MPoints
		 *
		 */
		public static function calculateHermitSpline(_points: Array, _closed: Boolean, distanceValidator: Function, discontinuityValidator: Function): Array
		{
			var retPoints: Array = new Array();
			var usePoints: Array = new Array();
			var p: Point;
			var nMPoint: MPoint;
			for (var i: int = 0; i < _points.length; i++)
			{
//				nMPoint = new MPoint(Point(_points[i]).clone());
				p = Point(_points[i]);
				if (p)
				{
					nMPoint = new MPoint(p.x, p.y);
					nMPoint.segmentIndex = i;
					usePoints.push(nMPoint);
				}
			}
			if (_closed)
			{
				p = Point(_points[0]);
				if (p)
				{
					nMPoint = new MPoint(p.x, p.y);
					nMPoint.segmentIndex = _points.length;
					usePoints.push(nMPoint);
				}
			}
			// CALCULATE DISTANCES
			if (_closed)
			{
				var nextIndex: int;
//				MPoint(usePoints[0]).dist = new Point(MPoint(usePoints[0]).point.x - MPoint(usePoints[usePoints.length - 2]).point.x, MPoint(usePoints[0]).point.y - MPoint(usePoints[usePoints.length - 2]).point.y).length;
				MPoint(usePoints[0]).dist = new Point(MPoint(usePoints[0]).x - MPoint(usePoints[usePoints.length - 2]).x, MPoint(usePoints[0]).y - MPoint(usePoints[usePoints.length - 2]).y).length;
				for (i = 1; i < usePoints.length - 1; i++)
				{
					nextIndex = (i + 1) % usePoints.length;
					MPoint(usePoints[i]).dist = new Point(MPoint(usePoints[nextIndex]).x - MPoint(usePoints[i % usePoints.length]).x, MPoint(usePoints[nextIndex]).y - MPoint(usePoints[i % usePoints.length]).y).length;
				}
				MPoint(usePoints[usePoints.length - 1]).dist = new Point(MPoint(usePoints[0]).x - MPoint(usePoints[usePoints.length - 2]).x, MPoint(usePoints[0]).y - MPoint(usePoints[usePoints.length - 2]).y).length;
			}
			else
			{
				//MPoint(usePoints[0]).dist = 0;
				for (i = 0; i < usePoints.length - 1; i++)
				{
					nextIndex = (i + 1); // % retPoints.length;
					MPoint(usePoints[i]).dist = new Point(MPoint(usePoints[nextIndex]).x - MPoint(usePoints[i]).x, MPoint(usePoints[nextIndex]).y - MPoint(usePoints[i]).y).length;
				}
			}

			//there are no visible points, return empty array
			if (usePoints.length == 0)
				return [];


			// CALCULATE DERIVATES
			for (i = 0; i < usePoints.length; i++)
			{
				MPoint(usePoints[i]).deriv = calcDerivateForPoint(i, usePoints, _closed);
			}
			//splineCanvas.graphics.moveTo(x0, y0);
			var point0: MPoint;
			var point1: MPoint;
			var drawPoint: Point;
			var x0: Number;
			var y0: Number;
			var tmpRetPoint: SPoint = new SPoint(MPoint(usePoints[0]).x, MPoint(usePoints[0]).y);
			retPoints.push(tmpRetPoint.clone());
			for (i = 0; i < usePoints.length; i++)
			{
				point0 = MPoint(usePoints[i]);
				if (i == (usePoints.length - 1))
				{
					//if (ukonciKrivku) {
					//	point1 = (Bod) zoznamBodov.elementAt(0);
					//} else {
					break;
						//}
				}
				else
					point1 = MPoint(usePoints[i + 1]);
				x0 = point0.x;
				y0 = point0.y;
				var tDist: Number = 0;

				calculateHermitSplineBisect(retPoints, "START", 0, 1, i, x0, y0, point0, point1, 0, distanceValidator, discontinuityValidator);

				trace("calculateHermitSplineBisect total: " + retPoints.length);

			}
//			tmpRetPoint = new SPoint(MPoint(usePoints[usePoints.length - 1]).x, MPoint(usePoints[usePoints.length - 1]).y);
//			retPoints.push(tmpRetPoint.clone());


			var str2: String = "";
			var leftX:  Number = 0;
			var rightX:  Number = 360;
			for each (var tmpRetPoint in retPoints)
			{
				if (tmpRetPoint)
				{
					str2 += tmpRetPoint.x + ", ";
				} else {
					str2 += "null, ";

				}
			}
			trace("Before: "+ str2);

			//filter points, which are inserted twice
			var bFilterDoublePoints: Boolean = true;

			if (bFilterDoublePoints)
			{
				i = 1;
				tmpRetPoint = retPoints[0] as SPoint;
				while (i < retPoints.length)
				{
					var sp: SPoint = retPoints[i] as SPoint;
					if (sp && tmpRetPoint && sp.equals(tmpRetPoint))
					{
						retPoints.splice(i,1);
					} else {
						i++;
						tmpRetPoint = sp;
					}
				}
			}
			return (retPoints);
		}


		public static function calculateHermitSplineBisect(points: Array, type: String, fromT: Number, toT: Number, segmentIndex: int, x0: Number, y0: Number, point0: MPoint, point1: MPoint, level: uint, distanceValidator: Function = null, discontinuityValidator: Function = null): void
		{
			var bTraceResults: Boolean = false;

			var drawPoint: Point;
			var drawPointMiddle: Point;
			var tmpRetPoint: SPoint;

			var testDist: Number = Point.distance(point0, point1);
			if (testDist > 1500)
			{
				trace("Check reflection problem");
				return;
			}

			if (level < 10)
			{

				var tHalf: Number = fromT + (toT - fromT)/2;

				//------------------------------------------------------------------------------------------------------------------
				//left part

				drawPointMiddle = hermiteCurveEvaluate(point0, point1, tHalf);

				var calculateParts: Boolean = true;
				var calculateLeftPart: Boolean = true;
				var calculateRightPart: Boolean = true;
				var leftPartDiscontinuation: Boolean = false;
				var rightPartDiscontinuation: Boolean = false;

				if (distanceValidator != null || discontinuityValidator != null)
				{
					var drawPoint0: Point = hermiteCurveEvaluate(point0, point1, fromT);
					var drawPointLast: Point = hermiteCurveEvaluate(point0, point1, toT);
					if (distanceValidator != null)
					{
						calculateLeftPart = !distanceValidator(drawPoint0, drawPointMiddle);
						calculateRightPart = !distanceValidator(drawPointMiddle, drawPointLast);
					}
					if (discontinuityValidator != null)
					{
						leftPartDiscontinuation = discontinuityValidator(drawPoint0, drawPointMiddle);
						rightPartDiscontinuation = discontinuityValidator(drawPointMiddle, drawPointLast);
					}
				}

				if (bTraceResults) trace("calculateHermitSplineBisect: [" + fromT + ", " + toT+"] level: " + level + " type: " + type);
				if (bTraceResults) trace("calculate left: " + calculateLeftPart + ", right: " + calculateRightPart+"] discontinuity LEFT: " + leftPartDiscontinuation + " RIGHT: " + rightPartDiscontinuation);

				var points2: Array;

				if (leftPartDiscontinuation)
				{
					if (bTraceResults) trace("LEFT discontinuation");
					points2 = calculateHermitSplineBisect2(drawPoint0, drawPointMiddle, fromT, tHalf, point0, point1, 0, discontinuityValidator);
					if (points2 && points2.length == 2)
					{
						var drawPointLeftDiscontinuationLeft: PPoint = points2[0] as PPoint;
						var drawPointLeftDiscontinuationRight: PPoint = points2[1] as PPoint;

						if (!distanceValidator(drawPoint0, drawPointLeftDiscontinuationLeft)) {

							var posLPDLeft0: Number = fromT;
							var posLPDLeft1: Number = drawPointLeftDiscontinuationLeft.position;

							if (bTraceResults) trace("\t\t after calculateHermitSplineBisect2 there needs to be more bisect drawPoint0, drawPointLeftDiscontinuationLeft ["+posLPDLeft0+","+posLPDLeft1+"]("+drawPoint0.x + " , " + drawPointLeftDiscontinuationLeft.x+")");

							calculateHermitSplineBisect(points, type, posLPDLeft0, posLPDLeft1, segmentIndex, x0, y0, point0, point1, level+1, distanceValidator, discontinuityValidator);
						} else {
//							if (bTraceResults) trace("\t\t after calculateHermitSplineBisect2 distance is OK - PUSH drawPointLeftDiscontinuationLeft (" + drawPointLeftDiscontinuationLeft.x+") into result array");
							if (bTraceResults) trace("after calculateHermitSplineBisect2 distance is OK: ["+fromT+","+drawPointLeftDiscontinuationLeft.position+"]  type: " + type + " => " + drawPointLeftDiscontinuationLeft);

						}

						if (bTraceResults) trace("\t\t after calculateHermitSplineBisect2 distance is OK - PUSH POINT drawPointLeftDiscontinuationLeft ["+drawPointLeftDiscontinuationLeft.position+"] (" + drawPointLeftDiscontinuationLeft.x+") into result array");
						if (bTraceResults) trace("\t\t after calculateHermitSplineBisect2 distance is OK - PUSH POINT null into result array");
						if (bTraceResults) trace("\t\t after calculateHermitSplineBisect2 distance is OK - PUSH POINT drawPointLeftDiscontinuationRight ["+drawPointLeftDiscontinuationRight.position+"] (" + drawPointLeftDiscontinuationRight.x+") into result array");
						points.push(drawPointLeftDiscontinuationLeft.toSPoint(segmentIndex));
						points.push(null);
						points.push(drawPointLeftDiscontinuationRight.toSPoint(segmentIndex));

						if (!distanceValidator(drawPointLeftDiscontinuationRight, drawPointMiddle)) {

							var posLPDRight0: Number = drawPointLeftDiscontinuationRight.position;
							var posLPDRight1: Number = tHalf;
							if (bTraceResults) trace("\t\t after Bisect2 there needs to be more bisect drawPointLeftDiscontinuationRight, drawPointMiddle ("+drawPointLeftDiscontinuationRight.x + " , " + drawPointMiddle.x+")");

							calculateHermitSplineBisect(points, type, posLPDRight0, posLPDRight1, segmentIndex, x0, y0, point0, point1, level+1, distanceValidator, discontinuityValidator);

						} else {
							if (bTraceResults) trace("\t\t after Bisect2 distance is OK - PUSH drawPointMiddle (" + drawPointMiddle.x+") into result array");

							tmpRetPoint = new SPoint(drawPointMiddle.x, drawPointMiddle.y);
							tmpRetPoint.segmentIndex = segmentIndex;
							points.push(tmpRetPoint);
							if (bTraceResults) trace("after Bisect2 distance [drawPointLeftDiscontinuationRight, drawPointMiddle] is OK: [" + drawPointLeftDiscontinuationRight.position + ", " + tHalf+"] type: " + type + " => PUSH POINT " +drawPointMiddle);
						}
					} else {
						if (bTraceResults) trace("\t\t calculateHermitSplineBisect2 return wrong value (or null)");
					}

				} else if (calculateLeftPart)
				{
					calculateHermitSplineBisect(points, "LEFT", fromT, tHalf, segmentIndex, x0, y0, point0, point1, level + 1, distanceValidator, discontinuityValidator);
				} else {
					tmpRetPoint = new SPoint(drawPoint0.x, drawPoint0.y);
					tmpRetPoint.segmentIndex = segmentIndex;
					points.push(tmpRetPoint);
					if (bTraceResults) trace("calculateHermitSplineBisect: [" + fromT + ", " + toT+"] LEFT pos:  " + fromT + " type: " + type + " PUSH POINT " + drawPoint0);
					//just debug
//					debugSPoints(points);
				}

				//------------------------------------------------------------------------------------------------------------------
				//right part
//				drawPointMiddle = hermiteCurveEvaluate(point0, point1, toT);

				if (rightPartDiscontinuation)
				{
					if (bTraceResults) trace("RIGHT discontinuation");
					points2 = calculateHermitSplineBisect2(drawPointMiddle, drawPointLast, tHalf, toT, point0, point1, 0, discontinuityValidator);
					if (points2 && points2.length == 2)
					{
						var drawPointRightDiscontinuationLeft: PPoint = points2[0] as PPoint;
						var drawPointRightDiscontinuationRight: PPoint = points2[1] as PPoint;

						if (!distanceValidator(drawPointMiddle, drawPointRightDiscontinuationLeft)) {

							if (bTraceResults) trace("\t\t after calculateHermitSplineBisect2 there needs to be more bisect [drawPointMiddle, drawPointRightDiscontinuationLeft] ("+drawPointMiddle.x + " , " + drawPointRightDiscontinuationLeft.x+")");

							var posRPDLeft0: Number = tHalf;
							var posRPDLeft1: Number = drawPointRightDiscontinuationLeft.position;
							calculateHermitSplineBisect(points, type, posRPDLeft0, posRPDLeft1, segmentIndex, x0, y0, point0, point1, level+1, distanceValidator, discontinuityValidator);

						} else {
							if (bTraceResults) trace("after calculateHermitSplineBisect2 distance [drawPointMiddle, drawPointRightDiscontinuationLeft] is OK: [" + tHalf + ", " +  drawPointRightDiscontinuationLeft.position+"]  type: " + type + " => " + drawPointRightDiscontinuationLeft.toString());
						}

						if (bTraceResults) trace("\t\t after calculateHermitSplineBisect2 distance is OK - PUSH POINT drawPointRightDiscontinuationLeft ["+drawPointRightDiscontinuationLeft.position+"] (" + drawPointRightDiscontinuationLeft.x+") into result array");
						if (bTraceResults) trace("\t\t after calculateHermitSplineBisect2 distance is OK - PUSH POINT null into result array");
						if (bTraceResults) trace("\t\t after calculateHermitSplineBisect2 distance is OK - PUSH POINT drawPointRightDiscontinuationRight ["+drawPointRightDiscontinuationRight.position+"] (" + drawPointRightDiscontinuationRight.x+") into result array");
						points.push(drawPointRightDiscontinuationLeft.toSPoint(segmentIndex));
						points.push(null);
						points.push(drawPointRightDiscontinuationRight.toSPoint(segmentIndex));

						if (!distanceValidator(drawPointRightDiscontinuationRight, drawPointLast)) {

							if (bTraceResults) trace("\t\t after Bisect2 there needs to be more bisect [drawPointRightDiscontinuationRight, drawPointLast] ("+drawPointRightDiscontinuationRight.x + " , " + drawPointLast.x+")");
							var posRPDRight0: Number = drawPointRightDiscontinuationRight.position;
							var posRPDRight1: Number = toT;
							calculateHermitSplineBisect(points, type, posRPDRight0, posRPDRight1, segmentIndex, x0, y0, point0, point1, level+1, distanceValidator, discontinuityValidator);

						} else {
							if (bTraceResults) trace("\t\t after Bisect2 distance is OK - PUSH drawPointLast (" + drawPointLast.x+") into result array");

							tmpRetPoint = new SPoint(drawPointLast.x, drawPointLast.y);
							tmpRetPoint.segmentIndex = segmentIndex;
							points.push(tmpRetPoint);
							if (bTraceResults) trace("after Bisect2 distance [drawPointRightDiscontinuationRight, drawPointLast] is OK: [" +  drawPointRightDiscontinuationRight.position + ", " + toT+"]  type: " + type + " PUSH POINT " + drawPointLast);
						}

					} else {
						if (bTraceResults) trace("\t\t calculateHermitSplineBisect2 return wrong value (or null)");
					}

				} else if (calculateRightPart)
				{
					calculateHermitSplineBisect(points, "RIGHT", tHalf, toT, segmentIndex, x0, y0, point0, point1, level + 1, distanceValidator, discontinuityValidator);
				} else {
					tmpRetPoint = new SPoint(drawPointLast.x, drawPointLast.y);
					tmpRetPoint.segmentIndex = segmentIndex;
					points.push(tmpRetPoint);
					if (bTraceResults) trace("calculateHermitSplineBisect: [" + fromT + ", " + toT+"] RIGHT pos:  " + toT + " type: " + type + " PUSH POINT " +drawPointLast);
				}
			} else {
				if (bTraceResults) trace("calculateHermitSplineBisect it's too deep: level: " + level);
			}

		}

		/**
		 *
		 * @param p1
		 * @param p2
		 * @param fromT
		 * @param toT
		 * @param point0
		 * @param point1
		 * @param level
		 * @param previousDistance
		 * @param discontinuityValidator
		 * @return
		 *
		 */
		public static function calculateHermitSplineBisect2(p1: Point, p2: Point, fromT: Number, toT: Number, point0: MPoint, point1: MPoint, previousDistance: Number = 0, discontinuityValidator: Function = null): Array
		{
			var debug: Function = function(str: String): void
			{
//				trace("Coord calculateHermitSplineBisect2: " + str);
			}

			var max: Number = 3;
			var isDiscontinuation: Boolean = discontinuityValidator(p1, p2);
			var currentDistance: Number = Point.distance(p1, p2);

			debug("\n calculateHermitSplineBisect2 currentDistance: " + currentDistance + " p1: " + p1 + " p2: " + p2);
			if (previousDistance != 0 && currentDistance > previousDistance)
			{
			}

			if (currentDistance < max && isDiscontinuation)
			{
				debug("\t\t bisect2GreatArc currentDistance < max and there were no sings change (" +p1 + ",  " + p2+") into result array");
				return [new PPoint(p1.x, p1.y, fromT), new PPoint(p2.x, p2.y, toT)];
			}
			if (!isDiscontinuation)
			{
				debug("\t\t bisect2GreatArc there were sings change return NULL into result array");
				return null;
			}


			var tHalf: Number = fromT + (toT - fromT)/2;
			var middlePoint: Point = hermiteCurveEvaluate(point0, point1, tHalf);

			if (middlePoint)
			{
				var points: Array;
				//LEFT SIDE
				debug("\t\t calculateHermitSplineBisect2 call calculateHermitSplineBisect2 for sp1, c (" + p1 + " , " + middlePoint+")");

				points = calculateHermitSplineBisect2(p1, middlePoint, fromT, tHalf, point0, point1, currentDistance, discontinuityValidator);
				if (points)
				{
					debug("\t\t calculateHermitSplineBisect2 after calculateHermitSplineBisect2 for sp1, c add " + points.length + " ito result array");
					return points;
				}

				//RIGHT SIDE
				debug("\t\t calculateHermitSplineBisect2 call calculateHermitSplineBisect2 for c, sp2 (" + middlePoint + " , " + p2+")");
				points = calculateHermitSplineBisect2(middlePoint, p2, tHalf, toT, point0, point1, currentDistance, discontinuityValidator);
				if (points)
				{
					debug("\t\t calculateHermitSplineBisect2 after calculateHermitSplineBisect2 for c, sp2 add " + points.length + " ito result array");
					return points;
				}
			}

			return null;
		}

		public static function debugSPoints(points: Array): void
		{
			var formatNumber: Function = function(nr: Number): String
			{
				return (int(nr * 10)/10).toString();
			}

			var str: String = "";
			for (var t: int = 0; t < points.length; t++)
			{
				str += formatNumber((points[t] as SPoint).x) + ", ";
			}
			trace(str);
		}

		/**
		*
		*/
		public static function calcDerivateForPoint(pointIndex: int, _mpoints: Array, _closed: Boolean = false): Point
		{
			var i_prev: int = pointIndex - 1;
			var i_next: int = pointIndex + 1;
			if (_closed)
			{
				if (pointIndex == 0)
					i_prev = _mpoints.length - 2;
				else if (pointIndex == (_mpoints.length - 1))
					i_next = 1;
			}
			else
			{
				if ((pointIndex == 0) || (pointIndex == (_mpoints.length - 1)))
					return (new Point(0, 0));
			}
			return (CubicBezier.calcDerivation(MPoint(_mpoints[i_prev]),
					MPoint(_mpoints[pointIndex]),
					MPoint(_mpoints[i_next]),
					MPoint(_mpoints[i_prev]).dist,
					MPoint(_mpoints[pointIndex]).dist,
					MPoint(_mpoints[i_next]).dist));
			//return(countSegmentDerivation(MPoint(mPoints[pointIndex - 1]).point, MPoint(mPoints[pointIndex + 1]).point, 0.2));
		}

		/**
		*
		*/
		public static function calcDerivation(p0: Point, p1: Point, p2: Point, knotDist0: Number, knotDist1: Number, knotDist2: Number): Point
		{
			var v1: Point = new Point(p2.x - p1.x, p2.y - p1.y);
			if (knotDist1 < 0.00000001)
				v1 = new Point(0, 0);
			else
			{
				v1.x /= 2 * knotDist1;
				v1.y /= 2 * knotDist1;
			}
			var v0: Point = new Point(p1.x - p0.x, p1.y - p0.y);
			if (knotDist0 < 0.00000001)
				v0 = new Point(0, 0);
			else
			{
				v0.x /= 2 * knotDist0;
				v0.y /= 2 * knotDist0;
			}
			return (new Point((v0.x + v1.x) * knotDist1, (v0.y + v1.y) * knotDist1));
		/*var P: Point = new Point(p2.x - p0.x, p2.y - p0.y);
		P.x = P.x / (knotDist2 - knotDist0);

		return(P);*/
		/*var v1: Point = p2.clone();

		v1.x = (v1.x - p0.x) / (knotDist2 - knotDist0);
		v1.y = (v1.y - p0.y) / (knotDist2 - knotDist0);

		return(v1);*/
		/*var c: Number = 0.2;
		var retPoint: Point = new Point(0, 0);

		retPoint.x = (0.5 * (1 - c) * (p2.x - p0.x));
		retPoint.y = (0.5 * (1 - c) * (p2.y - p0.y));

		return(retPoint);*/
		}

		public static function hermiteCurveEvaluate(p0: MPoint, p1: MPoint, t: Number): Point
		{
			// a3 = 2*(P0-P1) + d0 + d1;
			var a3: Point = p0.clone();
			a3.x -= p1.x;
			a3.y -= p1.y;
			a3.x += a3.x;
			a3.y += a3.y;
			a3.x += p0.deriv.x + p1.deriv.x;
			a3.y += p0.deriv.y + p1.deriv.y;
			//a3 -= P1;
			//a3 += a3;
			//a3 += d0;
			//a3 += d1;
			// a2 = 3*(P1-P0) - 2*d0 - d1;
			var a2: Point = p1.clone();
			a2.x -= p0.x;
			a2.y -= p0.y;
			a2.x *= 3;
			a2.y *= 3;
			a2.x -= p0.deriv.x * 2;
			a2.y -= p0.deriv.y * 2;
			a2.x -= p1.deriv.x;
			a2.y -= p1.deriv.y;
			//gpoint a2 = P1;
			//a2 -= P0;
			//a2 *= 3;
			//a2 -= d0*2;
			//a2 -= d1;
			// a1 = d0
			// a0 = P0
			// P = a3*a^3 + a2*a^2 + a1*a + a0
			var P: Point = a3.clone();
			P.x *= t;
			P.y *= t;
			P.x += a2.x;
			P.y += a2.y;
			P.x *= t;
			P.y *= t;
			P.x += p0.deriv.x;
			P.y += p0.deriv.y;
			P.x *= t;
			P.y *= t;
			P.x += p0.x;
			P.y += p0.y;
			//gpoint P = a3;
			//P *= t;
			//P += a2;
			//P *= t;
			//P += d0;
			//P *= t;
			//P += P0;
			return (P);
		}
	}
}
import flash.geom.Point;

class BezierSegment
{
	protected var p1: Point;
	protected var p2: Point;
	protected var p3: Point;
	protected var p4: Point;

	public function BezierSegment(p1: Point, p2: Point, p3: Point, p4: Point)
	{
		this.p1 = p1;
		this.p2 = p2;
		this.p3 = p3;
		this.p4 = p4;
	}

	public function getValue(t: Number): Point
	{
		var f_oneMinusT: Number = 1 - t;
		var f_tToThePowerOf3: Number = t * t * t;
		var x: Number = p1.x * (f_oneMinusT) * (f_oneMinusT) * (f_oneMinusT) +
				p2.x * 3 * (f_oneMinusT) * (f_oneMinusT) * t +
				p3.x * 3 * (f_oneMinusT) * t * t +
				p4.x * f_tToThePowerOf3;
		var y: Number = p1.y * (f_oneMinusT) * (f_oneMinusT) * (f_oneMinusT) +
				p2.y * 3 * (f_oneMinusT) * (f_oneMinusT) * t +
				p3.y * 3 * (f_oneMinusT) * t * t +
				p4.y * f_tToThePowerOf3;
		return new Point(x, y);
	}
}

class ControlPointsDescriptor
{
	public var firstPt: uint;
	public var lastPt: uint;
	public var controlPts: Array;

	public function ControlPointsDescriptor()
	{
	}
}

class MPoint extends Point
{
//	public var point: Point = new Point();
	public var deriv: Point = new Point();
	public var dist: Number = 0;
	public var segmentIndex: int = 0;

	public function MPoint(x: Number = 0, y: Number = 0, _deriv: Point = null)
	{
		super(x, y);
//		if (_point != null){
//			point = _point.clone();
//		}
		if (_deriv != null)
			deriv = _deriv.clone();
	}
}

class SPoint extends Point
{
	public var segmentIndex: int = 0;

	public function SPoint(x: Number = 0, y: Number = 0)
	{
		super(x, y);
	}

	/**
	 *
	 */
	override public function clone(): Point
	{
		var ret: SPoint = new SPoint(this.x, this.y);
		ret.segmentIndex = this.segmentIndex;
		return (ret);
	}
}


class PPoint extends Point
{
	public var position: Number;

	public function PPoint(x: Number = 0, y: Number = 0, position: Number = 0)
	{
		super(x, y);
		this.position = position;
	}

	public function toSPoint(segmentIndex: int): SPoint
	{
		var sPoint: SPoint = new SPoint(x, y);
		sPoint.segmentIndex = segmentIndex;
		return sPoint;
	}

	/**
	 *
	 */
	override public function clone(): Point
	{
		var ret: PPoint = new PPoint(this.x, this.y, this.position);
		return (ret);
	}
}