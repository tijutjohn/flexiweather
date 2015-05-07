package com.iblsoft.flexiweather.ogc.editable.features.curves
{
	import com.iblsoft.flexiweather.ogc.editable.data.jetstream.WindBarb;
	import com.iblsoft.flexiweather.utils.Hemisphere;

	import flash.display.Bitmap;
	import flash.display.LineScaleMode;
	import flash.display.Sprite;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.text.AntiAliasType;
	import flash.text.TextField;
	import flash.text.TextFormat;

	import mx.controls.Label;

	public class WFSFeatureEditableJetStreamWindBarb extends Sprite
	{
		protected var m_points: Array;
		protected var m_myPointIndex: uint;
		protected var m_windBarbDef: WindBarb;

		//on which hemisphere is windbard (one of Hemisphere constansts)
		protected var m_hemisphere: String;

		private var _m_canBeDrawed: Boolean = true;
		public function get m_canBeDrawed():Boolean
		{
			return _m_canBeDrawed;
		}

		public function set m_canBeDrawed(value:Boolean):void
		{
			if (!value)
			{
				debug("windbard can not be drawed");
			}
			_m_canBeDrawed = value;
		}

		protected var m_textfield: TextField = new TextField();
		protected var m_textfieldSprite: Sprite = new Sprite();

		[Embed(source="/assets/fonts/DroidSans.ttf",
				fontFamily="labelFont",
				embedAsCFF="false",
				fontWeight="normal")]
		public var labelFontFaceNormal: String;
		[Embed(source="/assets/fonts/DroidSans-Bold.ttf",
				fontFamily="labelFont",
				embedAsCFF="false",
				fontWeight="bold")]
		public var labelFontFaceBold: String;


		/**
		 *
		 */
		public function WFSFeatureEditableJetStreamWindBarb(points: Array, myPointIndex: uint, windBarbDef: WindBarb, i_color: uint, s_hemisphere: String)
		{
			super();

			m_points = points;
			m_myPointIndex = myPointIndex;
			m_windBarbDef = windBarbDef;
			m_hemisphere = s_hemisphere;

			var nFormat: TextFormat = new TextFormat();
			nFormat.leading = -1;
			nFormat.font = 'labelFont';
			nFormat.color = i_color;
			nFormat.size = 12;

			m_textfield.defaultTextFormat = nFormat;
			m_textfield.setTextFormat(nFormat);
			m_textfield.multiline = true;
			m_textfield.embedFonts = true;
			m_textfield.antiAliasType = AntiAliasType.ADVANCED;
			//m_textfield.border = true;
			//m_textfield.autoSize = TextFieldAutoSize.CENTER;


			addChild(m_textfieldSprite);
			m_textfieldSprite.addChild(m_textfield);

			update(m_points, m_myPointIndex, m_windBarbDef, i_color);
		}



		/**
		 * Count and draw windbarb
		 *
		 * @param points  Points of jetstreat
		 * @param myPointIndex Index in jetstream points from where will be windbarb drawns
		 * @param windBarbDef Windbard definition
		 * @param i_color Color
		 *
		 */
		public function update(points: Array, myPointIndex: uint, windBarbDef: WindBarb, i_color: uint): void
		{
			m_myPointIndex = myPointIndex;
			m_points = points;
			m_windBarbDef = windBarbDef;

			var m_pt: Point = Point(m_points[m_myPointIndex]);

			debug("update at : " + myPointIndex + " pt: " + m_pt);
			graphics.clear();

			var triangleA: Number = 8;
			var triangleB: Number = 10;
			var lineStep: Number = 5;

			var windPower: Number = m_windBarbDef.windSpeed;

			var numTriangles: int = int(windPower / 50);
			var numLines: int = int((windPower - (numTriangles * 50)) / 10);
			var numHalfLines: int = int((windPower - ((numTriangles * 50) + (numLines * 10))) / 5);

			var totalLength: Number = (numTriangles * triangleA) + ((numLines + numHalfLines) * lineStep);

			// ADD ONE SPACE BETWEEN TRIANGLE(S) AND LINES
			if ((numTriangles > 0) && ((numLines > 0) || (numHalfLines > 0))){
				totalLength += lineStep;
			}

			// COMPUTE NEEDED SIGN POINTS
			var signPoints: Array = new Array();
			var pTangent: Point;
			var tDist: Number = 0;
			var aDist: Number = 0;
			var totalDist: Number = 0;
			var dirVector: Point;
			var offsetVector: Point;
			var addOffset: Number;
			var p1: Point;
			var i: int;

			// FIND HALF LENGTH BEFORE CENTER POINT (CENTER POINT IS m_myPointIndex)
			var sPointIndex: int = m_myPointIndex;
			var tBeforeDist: Number = 0;
			var enoughSpaceBefore: Boolean = false;

			var currPoint: Point;
			var previousPoint: Point;
			var nextPoint: Point;

			for (i = m_myPointIndex; i > 0; i--)
			{
				currPoint = m_points[i];
				previousPoint = m_points[i -1];

				if (!currPoint || !previousPoint)
					continue;

				tDist = Point.distance(currPoint, previousPoint);

				if ((tBeforeDist + tDist) < (totalLength / 2)){
					tBeforeDist = tBeforeDist + tDist;
				} else {
					addOffset = (totalLength / 2) - tBeforeDist;
					if (addOffset > (tDist / 2)){
						sPointIndex = i - 1;
					} else {
						sPointIndex = i;
					}

					enoughSpaceBefore = true;

					break;
				}
			}

			//TODO problem s tym, ze sa windbarby stracaju, ze prejde len 1 prechod vo FOR i loope (pri mensich, prejde 3 prechody atd)...
			if (!enoughSpaceBefore){
				m_canBeDrawed = false;
				m_textfield.visible = m_textfieldSprite.visible = false;
			} else {
				//for (i = m_myPointIndex; i < (m_points.length - 1); i++){
				for (i = sPointIndex; i < (m_points.length - 1); i++)
				{
					currPoint = m_points[i];
					nextPoint = m_points[i + 1];

					if (!currPoint || !nextPoint)
						continue;

					tDist = Point.distance(nextPoint, currPoint);

					if ((aDist + tDist) >= 1)
					{
						// NEED TO FIND POINT BETWEEN
						dirVector = nextPoint.subtract(currPoint);
						dirVector.normalize(1);

						pTangent = makeNormal(dirVector);

						addOffset = (1 - aDist);
						offsetVector = dirVector.clone();
						offsetVector.x = offsetVector.x * addOffset;
						offsetVector.y = offsetVector.y * addOffset;

						p1 = Point(currPoint).add(offsetVector);
//						p1 = Point(currPoint).add(dirVector);

						signPoints.push({pt: p1.clone(), tg: pTangent.clone()});
						totalDist += addOffset;

						tDist = tDist - addOffset;
						while((tDist >= 1) && (totalDist < totalLength)){
							addOffset = addOffset + 1;

							offsetVector = dirVector.clone();
							offsetVector.x = offsetVector.x * addOffset;
							offsetVector.y = offsetVector.y * addOffset;

//							p1 = Point(currPoint).add(dirVector);
							p1 = Point(currPoint).add(offsetVector);

							signPoints.push({pt: p1.clone(), tg: pTangent.clone()});

							totalDist += 1;

							tDist = tDist - 1;
						}

						aDist = Point.distance(nextPoint, currPoint) - addOffset;
						totalDist += aDist;
						//i = i - 1
					} else {
						aDist = aDist + tDist;

						totalDist += tDist;
					}

					if (totalDist >= totalLength){
						break;
					}
				}

				var txt: String = '';
				for each (var obj: Object in signPoints)
				{
					txt += int(obj.pt.x) + "," + int(obj.pt.y)+" | ";
				}

				graphics.clear();


				if (signPoints.length < totalLength){
					// NOT ENOUGH POINTS TO SHOW WIND SIGN

					m_canBeDrawed = false;
					m_textfield.visible = m_textfieldSprite.visible = false;
				} else {
					m_canBeDrawed = true;

					var actPointIndex: uint = 0;
					var offsetAfterTriangles: uint = (numTriangles > 0) ? lineStep : 0;
					var spPt: Point;

					var drawString: String;
					var px: Number;
					var py: Number;

					while(numTriangles > 0){
						// DRAW TRIANGLE
						graphics.lineStyle(1, i_color, 1, false, LineScaleMode.NONE);
						graphics.beginFill(i_color, 1);

						drawString = '';
						spPt = signPoints[actPointIndex].pt;
						graphics.moveTo(spPt.x, spPt.y);

						drawString = updateDrawString(drawString,"M",spPt.x,spPt.y);

						for (i = 1; i < triangleA; i++){
							px = signPoints[actPointIndex + i].pt.x;
							py = signPoints[actPointIndex + i].pt.y;
							graphics.lineTo(px, py);
							drawString = updateDrawString(drawString,"L",px,py);
						}

						px = spPt.x + (signPoints[actPointIndex + (int(triangleA / 2))].tg.x * triangleB);
						py = spPt.y + (signPoints[actPointIndex + (int(triangleA / 2))].tg.y * triangleB);

						graphics.lineTo(px, py);
						drawString = updateDrawString(drawString,"L",px,py);
						graphics.lineTo(spPt.x, spPt.y);
						drawString = updateDrawString(drawString,"L",spPt.x,spPt.y);
						graphics.endFill();

						actPointIndex += triangleA;
						numTriangles--;
					}

					actPointIndex += offsetAfterTriangles;

					var bNormal: Point;
					while(numLines > 0)
					{
						drawString = '';

						spPt = signPoints[actPointIndex].pt;
						// DRAW LINE
						graphics.lineStyle(1, i_color, 1, false, LineScaleMode.NONE);
						graphics.moveTo(spPt.x, spPt.y);

						drawString = updateDrawString(drawString,"M",spPt.x,spPt.y);

						bNormal = makeNormal(signPoints[actPointIndex - triangleA].tg);
						//splineCanvas.graphics.lineTo(signPoints[actPointIndex].pt.x + (bNormal.x * triangleA) + (signPoints[actPointIndex - (int(triangleA / 2))].tg.x * triangleB), signPoints[actPointIndex].pt.y + (bNormal.y * triangleA) + (signPoints[actPointIndex - (int(triangleA / 2))].tg.y * triangleB));

						px = signPoints[actPointIndex - triangleA].pt.x + (signPoints[actPointIndex - triangleA].tg.x * triangleB);
						py = signPoints[actPointIndex - triangleA].pt.y + (signPoints[actPointIndex - triangleA].tg.y * triangleB);

						graphics.lineTo(px, py);

						drawString = updateDrawString(drawString,"L",px,py);

						actPointIndex += lineStep;
						numLines--;
					}

					while(numHalfLines > 0){
						// DRAW HALF LINE
						graphics.lineStyle(1, i_color, 1, false, LineScaleMode.NONE);
						graphics.moveTo(signPoints[actPointIndex].pt.x, signPoints[actPointIndex].pt.y);

						drawString = updateDrawString(drawString,"M",signPoints[actPointIndex].pt.x,signPoints[actPointIndex].pt.y);

						bNormal = makeNormal(signPoints[actPointIndex - triangleA].tg);
						//splineCanvas.graphics.lineTo(signPoints[actPointIndex].pt.x + ((bNormal.x * triangleA) + (signPoints[actPointIndex - (int(triangleA / 2))].tg.x * triangleB)) / 2, signPoints[actPointIndex].pt.y + ((bNormal.y * triangleA) + (signPoints[actPointIndex - (int(triangleA / 2))].tg.y * triangleB)) / 2);

						px = signPoints[actPointIndex - Math.round(triangleA / 2)].pt.x + (signPoints[actPointIndex - triangleA].tg.x * (triangleB / 2));
						py = signPoints[actPointIndex - Math.round(triangleA / 2)].pt.y + (signPoints[actPointIndex - triangleA].tg.y * (triangleB / 2));

						graphics.lineTo(px, py);

						drawString = updateDrawString(drawString,"L",px,py);

						actPointIndex += lineStep;
						numHalfLines--;
					}

					// UPDATE TEXT INFO
					var nText: String = '';
					if (m_windBarbDef.flightLevel == 0){
						nText = '';
					} else {
						var fLevel: String = String(m_windBarbDef.flightLevel);

						while(fLevel.length < 3){
							fLevel = '0' + fLevel;
						}

						nText = '<P align="center"><B>FL' + fLevel;
						if (m_windBarbDef.below > 0){
							var tBelow: String = String(m_windBarbDef.below);
							while(tBelow.length < 3){tBelow = '0' + tBelow;}

							var tAbove: String = String(m_windBarbDef.above);
							while(tAbove.length < 3){tAbove = '0' + tAbove;}

							nText += '\n' + tBelow + '/' + tAbove;
						}

						nText += '</B></P>';
					}

					var nFormat: TextFormat = m_textfield.getTextFormat();
					nFormat.color = i_color;
					m_textfield.setTextFormat(nFormat);
					m_textfield.htmlText = nText;
//					m_textfield.text = nText;

					m_textfield.width = m_textfield.textWidth + 8;
					m_textfield.height = m_textfield.textHeight + 8;

					//
					var fPoint: Point = signPoints[0].pt;
					var fPointNormal: Point = makeNormal(signPoints[0].tg);
					var lPoint: Point = signPoints[signPoints.length - 1].pt;

					var mPoint: Point = lPoint.subtract(fPoint);
					var mPointNormal: Point = makeNormal(mPoint);
					mPointNormal.normalize(1);
					var cPoint: Point = fPoint.add(new Point(mPoint.x / 2, mPoint.y / 2));
					var degree: Number = Math.atan2(mPoint.y, mPoint.x) * 180 / Math.PI;

					if (m_hemisphere == Hemisphere.SOUTHERN_HEMISPHERE)
						m_textfield.y = -1 * m_textfield.textHeight;
					else
						m_textfield.y = 0;

					mPoint.normalize(1);

					m_textfieldSprite.x = cPoint.x - (mPointNormal.x * 4) - (mPoint.x * ((m_textfield.textWidth + 8) / 2));
					m_textfieldSprite.y = cPoint.y - (mPointNormal.y * 4) - (mPoint.y * ((m_textfield.textWidth + 8) / 2));
					m_textfieldSprite.rotation = degree;

					m_textfield.visible = m_textfieldSprite.visible = true;
				}
			}

			var bounds: Rectangle = getBounds(this.stage);

			//FIXME remove franto tests from Windbard drawing
//			drawPoints(points);
		}

		private function drawPoints(points: Array): void
		{
			var cnt: int = 0;
			graphics.lineStyle(3, 0);
			for each (var p: Point in points)
			{
				if (cnt == 0)
				{
					graphics.moveTo(p.x, p.y);
				} else {
					graphics.lineTo(p.x, p.y);
				}
				cnt++;
			}
		}

		private function updateDrawString(drawString: String, type: String, x: int, y: int): String
		{
			drawString += type + " " + x + "," + y + " | ";

			return drawString;
		}
		/**
		*
		*/
		protected function makeNormal(point: Point): Point
		{
			if (m_hemisphere == Hemisphere.SOUTHERN_HEMISPHERE) {
				// southern hemisphere
				return(new Point(-point.y, point.x));
			} else {
				// northern hemisphere
				return(new Point(point.y, -point.x));
			}

		}

		/**
		 *
		 */
		public function get canBeDrawed(): Boolean
		{
			return(m_canBeDrawed);
		}

		private function debug(str: String, type: String = "Info", tag: String = " WFSFeatureEditableJetStreamWindBarb"): void
		{
			trace(this + "| " + type + "| " + str);
		}
	}
}