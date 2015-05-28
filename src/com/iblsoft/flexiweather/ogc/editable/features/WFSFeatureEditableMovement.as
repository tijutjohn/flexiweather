/***********************************************************************************************
 *
 *	Created:	24.03.2015
 *	Authors:	Franto Kormanak
 *
 *	Copyright (c) 2015, IBL Software Engineering spol. s r. o., <escrow@iblsoft.com>.
 *	All rights reserved. Unauthorised use, modification or redistribution is prohibited.
 *
 ***********************************************************************************************/

package com.iblsoft.flexiweather.ogc.editable.features
{
	import com.iblsoft.flexiweather.ogc.BBox;
	import com.iblsoft.flexiweather.ogc.FeatureUpdateContext;
	import com.iblsoft.flexiweather.ogc.data.ReflectionData;
	import com.iblsoft.flexiweather.ogc.editable.WFSFeatureEditableWithBaseTimeAndValidity;
	import com.iblsoft.flexiweather.ogc.editable.data.FeatureDataPoint;
	import com.iblsoft.flexiweather.ogc.editable.data.FeatureDataReflection;
	import com.iblsoft.flexiweather.ogc.wfs.IWFSFeatureWithReflection;
	import com.iblsoft.flexiweather.ogc.wfs.WFSFeatureEditableSprite;
	import com.iblsoft.flexiweather.plugins.IConsole;
	import com.iblsoft.flexiweather.proj.Coord;
	import com.iblsoft.flexiweather.proj.Projection;
	import com.iblsoft.flexiweather.widgets.InteractiveWidget;

	import flash.display.Graphics;
	import flash.events.Event;
	import flash.geom.Point;
	import flash.text.TextFieldAutoSize;
	import flash.utils.Dictionary;

	import mx.collections.ArrayCollection;
	import mx.core.UITextField;

	public class WFSFeatureEditableMovement extends WFSFeatureEditableWithBaseTimeAndValidity implements IWFSFeatureWithReflection
	{
		public var type: String;

		public static var debugConsole: IConsole;

		public function get directionValue():Object
		{
			return _directionValue;
		}

		public function set directionValue(value:Object):void
		{
			_directionValue = value;
			dispatchEvent(new Event("directionChanged"));
		}

		[Bindable (event="directionChanged")]
		public function get direction(): int
		{
			var test: int = getDirectionFromValue(directionValue, type);
			return test;
		}
		private var _directionValue: Object;
		public var speed: int;
		public static var angles: Dictionary;

		public function WFSFeatureEditableMovement(s_namespace: String, s_typeName: String, s_featureId: String)
		{
			super(s_namespace, s_typeName, s_featureId);

			type = MovementMode.COMPASS_POINTS_8;
			speed = 80;
			directionValue = {value: "N"};
			mb_isSinglePointFeature = true;
		}

		public static function getDataProviderForMovementMode(mode: String): ArrayCollection
		{
			var arr: Array;
			switch (mode)
			{
				case MovementMode.COMPASS_POINTS_8:
					arr = [{value: "N"}, {value: "NE"}, {value: "E"}, {value: "SE"}, {value: "S"}, {value: "SW"}, {value: "W"}, {value: "NW"}];
					break;
				case MovementMode.COMPASS_POINTS_16:
					arr = [{value: "N"}, {value: "NNE"}, {value: "NE"}, {value: "ENE"}, {value: "E"}, {value: "SSE"}, {value: "SE"}, {value: "ESE"}, {value: "S"}, {value: "SSW"}, {value: "SW"}, {value: "WSW"}, {value: "W"}, {value: "NNW"}, {value: "NW"}, {value: "WNW"}];
					break;
			}
			return new ArrayCollection(arr);
		}

		public static function initAngles(): void
		{
			if (!angles)
			{
				angles = new Dictionary();
				var directions: Array = ["N", "NNE", "NE", "ENE", "E", "ESE", "SE","SSE", "S", "SSW", "SW", "WSW", "W", "WNW", "NW", "NNW"];
				var angle: Number = 0;
				for each (var direction: String in directions)
				{
					angles[direction] = {direction: direction, angle: angle};
					angle += 360/16;
				}
			}
		}

		public static function getAngleForDirection(direction: Object): Number
		{
			if (direction is Object && direction.hasOwnProperty("value"))
			{
				initAngles();
				return angles[direction.value as String].angle as Number;
			}

			return (direction as Number);
		}
		public static function getItemWithSimilarDirection(ac: ArrayCollection, directionValue: Object): Object
		{
			if (directionValue)
			{
				var currAngle: Number = -1;
				var direction: String;
				var item: Object;
				var currDirectionString: String;
				if (directionValue is Object && directionValue.hasOwnProperty("value"))
				{
					initAngles();

					direction = directionValue.value;
					currAngle = angles[direction].angle;
					for each (item in ac)
					{
						currDirectionString = item.value as String;
						if (currDirectionString == direction)
							return item;
					}

				}

				if (directionValue is Number || currAngle > -1) {
					if (directionValue is Number)
						currAngle = directionValue as Number;

					var minDistance: Number = 360;
					var foundItem: Object;
					for each (item in ac)
					{
						currDirectionString = item.value as String;
						var angle: Number = angles[currDirectionString].angle;

						var dist: Number = Math.abs(currAngle - angle);
						if (dist < minDistance)
						{
							minDistance = dist;
							foundItem = item;
						}
					}
				}
				if (foundItem)
					return foundItem;
			}

			if (ac.length > 0)
				return ac.getItemAt(0);

			return null;
		}

		public static function getDirectionFromValue(directionValue: Object, movementType: String): int
		{
			if (movementType == MovementMode.DEGREES)
			{
				return Math.round(directionValue as Number);
			}

			initAngles();
			var directionName: String = directionValue.value as String;
			return Math.round((angles[directionName] as Object).angle);
		}

		private function groundVectorToScreen(projection: Projection, lalo: Coord, angle: Number): Point
		{
			var piConst: Number = Math.PI / 180;
			var p: Point = new Point(Math.sin(angle * piConst), Math.cos(angle * piConst));

			var arr: Array = derivativeLaloToXY(projection, lalo);
			var dl: Coord = arr[0] as Coord;
			var dp: Coord = arr[1] as Coord;

			var px: Number = dl.x * p.x + dp.x * p.y;
			var py: Number = dl.y * p.x + dp.y * p.y;

			var p2: Point = new Point(px,py);
			p2.normalize(1);

			return p2;
		}

		/**
		 * Derivate LaLo coordinate
		 * @param projection
		 * @param lalo
		 * @return
		 *
		 */
		private function derivativeLaloToXY(projection: Projection, lalo: Coord): Array
		{
			var piConst: Number = Math.PI / 180;
			var diff_h: Number = 0.001;
			var cor: Number = Math.cos(lalo.y * piConst);
			if (cor < 1e-5) cor = 1e-5;

			var laloDiff1: Coord = new Coord(lalo.crs, lalo.x + diff_h, lalo.y);
			var laloDiff2: Coord = new Coord(lalo.crs, lalo.x - diff_h, lalo.y);

			var xy1: Coord = projection.laLoCoordToPrjCoord(laloDiff1);
			var xy2: Coord = projection.laLoCoordToPrjCoord(laloDiff2);

			var dl: Coord =  new Coord(projection.crs, (xy1.x - xy2.x) *(0.5/diff_h) / cor, (xy1.y - xy2.y) *(0.5/diff_h) / cor);

			var laloDiff3: Coord = new Coord(lalo.crs, lalo.x, lalo.y + diff_h);
			var laloDiff4: Coord = new Coord(lalo.crs, lalo.x, lalo.y - diff_h);

			var xy3: Coord = projection.laLoCoordToPrjCoord(laloDiff3);
			var xy4: Coord = projection.laLoCoordToPrjCoord(laloDiff4);

			var dp: Coord =  new Coord(projection.crs, (xy3.x - xy4.x) *(0.5/diff_h), (xy3.y - xy4.y) *(0.5/diff_h));

			return [dl, dp];
		}

		override public function update(changeFlag: FeatureUpdateContext): void
		{
			super.update(changeFlag);
			graphics.clear();
			var i_color: uint = 0;
			var i_colorSign: uint = 0;
			var i_colorCross: uint = 0;
			if (useMonochrome)
			{
				i_color = monochromeColor;
				i_colorSign = monochromeColor;
				i_colorCross = monochromeColor;
			}
			else if (master.useMonochrome)
			{
				i_color = master.monochromeColor;
				i_colorSign = master.monochromeColor;
				i_colorCross = master.monochromeColor;
			}
			var s_colorSign: String = i_colorSign.toString(16);
			while (s_colorSign.length < 6)
			{
				s_colorSign = '0' + s_colorSign;
			}
			var s_color: String = i_color.toString(16);
			while (s_color.length < 6)
			{
				s_color = '0' + s_color;
			}
			var movementSprite: MovementSprite;
			var reflection: FeatureDataReflection;
			var displaySprite: WFSFeatureEditableSprite;
			//create sprites for reflections

			var reflectionIDs: Array = m_featureData.reflectionsIDs;
			var iw: InteractiveWidget = master.container;
			var projection: Projection = iw.getCRSProjection();

			//new solution
			var c0: Coord = coordinates[0] as Coord;
			//coordinates is always in same projections as they were created, so we need to convert it to current project
			c0 = c0.convertToProjection(projection);

			var laloCoord: Coord = c0.toLaLoCoord();
			var arrowDirection: Point = groundVectorToScreen(projection, laloCoord, direction);

			var bbox: BBox = iw.getViewBBox();
			var pixDistanceX: Number = bbox.width / iw.areaWidth;

			var movementLineLengthPx: int = 45;
			var labelDistancePx: int = 60;
			var pResult: Coord = new Coord(iw.crs, c0.x + arrowDirection.x * pixDistanceX * movementLineLengthPx,
				c0.y + arrowDirection.y * pixDistanceX * movementLineLengthPx);

			for (var i: int = 0; i < totalReflections; i++)
			{
				reflection = m_featureData.getReflectionAt(reflectionIDs[i]);
				if (reflection)
				{
					reflection.validate();
					displaySprite = getDisplaySpriteForReflectionAt(reflection.reflectionDelta);
					var reflectionDelta: int = reflection.reflectionDelta;

					movementSprite = displaySprite as MovementSprite;

					if (totalReflectionEditablePoints(0) > 0)
					{
						var pt: Point = Point(reflection.editablePoints[0]);
						if (pt)
						{
							movementSprite.pixDistanceX = pixDistanceX;
							movementSprite.updateText(s_color, speed);
//							var pLabel: Coord = new Coord(iw.crs, c0.x + arrowDirection.x * pixDistanceX * labelDistancePx,
//								c0.y + arrowDirection.y * pixDistanceX * labelDistancePx);

							var arrowCoordInReflections: Array = iw.mapCoordInCRSToViewReflectionsForDeltas(c0, [reflectionDelta, reflectionDelta-1, reflectionDelta+1]);
							var arrowCoordInReflection: Point = getClosestPoint(arrowCoordInReflections, reflection.editablePoints[0], projection );
							var arrowPoint: Point = arrowCoordInReflection.subtract(pt);

							var arrowCoordInReflections2: Array = iw.mapCoordInCRSToViewReflectionsForDeltas(pResult, [reflectionDelta, reflectionDelta-1, reflectionDelta+1]);
							var arrowCoordInReflection2: Point = getClosestPoint(arrowCoordInReflections2, reflection.editablePoints[0], projection );
							var arrowPoint2: Point = arrowCoordInReflection2.subtract(pt);

							movementSprite.update(s_colorSign, s_color, i_colorCross, type, arrowPoint2, arrowPoint, speed);
							movementSprite.x = pt.x;
							movementSprite.y = pt.y;
						}
//						else
//						{
//							renderFallbackGraphics(i_color);
//							return;
//						}
					}
				}
			}
		}

		private function getClosestPoint(coordsObjects: Array, point: Point, projection: Projection): Point
		{
			var iw: InteractiveWidget = master.container;
			var minDistance: Number = Number.MAX_VALUE;
			var foundPoint: Point;
			for each (var currCoordObject: Object in coordsObjects)
			{
				var currCoord: Coord = new Coord(projection.crs, currCoordObject.point.x, currCoordObject.point.y);
				var currPoint: Point = iw.coordToPoint(currCoord);
				var dist: Number = Point.distance(point, currPoint);
				if (dist < minDistance)
				{
					minDistance = dist;
					foundPoint = currPoint;
				}
			}

			return foundPoint;
		}

		override public function getDisplaySpriteForReflection(id: int): WFSFeatureEditableSprite
		{
			return new MovementSprite(this);
		}

		override public function toInsertGML(xmlInsert: XML): void
		{
			var gml: Namespace = new Namespace("http://www.opengis.net/gml");
			super.toInsertGML(xmlInsert);
//			addInsertGMLProperty(xmlInsert, null, "mode", type);
			addInsertGMLProperty(xmlInsert, null, "direction", anglesToRad(direction));
			addInsertGMLProperty(xmlInsert, null, "speed", knotsToMeterPerSeconds(speed));
		}

		private function anglesToRad(angle: Number): Number
		{
			return angle * Math.PI / 180;
		}
		private function radToAngles(rad: Number): Number
		{
			return rad * 180 / Math.PI;
		}
		private function knotsToMeterPerSeconds(speed: Number): Number
		{
			return speed * 0.514444444;
		}
		private function meterPerSecondsToKnots(speed: Number): Number
		{
			return speed / 0.514444444;
		}

		override public function toUpdateGML(xmlUpdate: XML): void
		{
			super.toUpdateGML(xmlUpdate);
//			addUpdateGMLProperty(xmlUpdate, null, "mode", type);
			addUpdateGMLProperty(xmlUpdate, null, "direction", anglesToRad(direction));
			addUpdateGMLProperty(xmlUpdate, null, "speed", knotsToMeterPerSeconds(speed));
		}

		override public function fromGML(gml: XML): void
		{
			super.fromGML(gml);
			var ns: Namespace = new Namespace(ms_namespace);
//			type = gml.ns::mode[0];
			var test1: XML = (gml.ns::direction[0] as XML);
			var test2: XML = (gml.ns::speed[0] as XML);
			var directionGML: Number =test1.valueOf();
			var speedGML: Number = test2.valueOf();

			type = MovementMode.DEGREES;
			directionValue = radToAngles(directionGML);
			speed = meterPerSecondsToKnots(speedGML);
		}

		protected function debug(str: String): void
		{
			if (debugConsole)
				debugConsole.print(str, 'Info', 'WFSFeatureEditableMovement');
			trace("WFSFeatureEditableMovement: " + str);
		}
	}
}
import com.iblsoft.flexiweather.ogc.BBox;
import com.iblsoft.flexiweather.ogc.editable.WFSFeatureEditable;
import com.iblsoft.flexiweather.ogc.editable.formatters.WindSpeedFormatter;
import com.iblsoft.flexiweather.ogc.wfs.WFSFeatureEditableSprite;
import com.iblsoft.flexiweather.proj.Coord;

import flash.display.Graphics;
import flash.display.Sprite;
import flash.geom.Point;
import flash.text.TextFieldAutoSize;

import mx.core.UITextField;

class MovementSprite extends WFSFeatureEditableSprite
{
	public var pixDistanceX: Number;

	protected var mtf_presureType: UITextField = new UITextField();
	protected var mtf_presureValue: UITextField = new UITextField();

	private var m_windFormatter: WindSpeedFormatter;

	public function get textWidth(): Number
	{
		if (mtf_presureValue)
			return mtf_presureValue.textWidth;
		return 0;
	}
	public function get textHeight(): Number
	{
		if (mtf_presureValue)
			return mtf_presureValue.textHeight;
		return 0;
	}
	public function MovementSprite(feature: WFSFeatureEditable)
	{
		super(feature);

		//mtf_presureType.border = true;
		mtf_presureType.autoSize = TextFieldAutoSize.LEFT;
		mtf_presureValue.autoSize = TextFieldAutoSize.LEFT;
		addChild(mtf_presureType);
		addChild(mtf_presureValue);

		m_windFormatter = new WindSpeedFormatter();
	}

	private function drawArrow(x: Number, y: Number, prevX: Number, prevY: Number, i_colorCross: uint): void
	{
		//			if (isNaN(mi_lastOneMoreX))
		if (isNaN(prevX))
			return;

		var ptDiffX: int;
		var ptDiffY: int;
		var ptDiff2X: int;
		var ptDiff2Y: int;
		var ptPerpX: int;
		var ptPerpY: int;

		var pt: Point = new Point(x,y);
		var ptPrev: Point =  new Point(prevX, prevY);


		var ptDiff: Point = pt.subtract(ptPrev);
		ptDiff.normalize(15);
		ptDiffX = ptDiff.x;
		ptDiffY = ptDiff.y;
		var ptDiff2: Point = new Point(ptDiffX, ptDiffY);
		ptDiff2.normalize(8);
		ptDiff2X = ptDiff2.x;
		ptDiff2Y = ptDiff2.y;
		var ptPerp: Point = new Point(ptDiffY, -ptDiffX);
		ptPerp.normalize(5);
		ptPerpX = ptPerp.x;
		ptPerpY = ptPerp.y;

		graphics.clear();

		graphics.lineStyle(2,i_colorCross, 1 );
		graphics.moveTo(prevX, prevY);
		graphics.lineTo(x - ptDiff2X, y - ptDiff2Y);
		graphics.lineTo(x + ptPerpX - ptDiffX, y + ptPerpY - ptDiffY);
		graphics.moveTo(x - ptDiff2X, y - ptDiff2Y);
		graphics.lineTo(x - ptPerpX - ptDiffX, y - ptPerpY - ptDiffY);

		/*
		trace("\nMovement draw");
		trace("graphics.moveTo("+prevX +", "+prevY +");");
		trace("graphics.lineTo("+(x - ptDiff2X) +", "+(y - ptDiff2Y) +");");
		trace("graphics.lineTo("+(x + ptPerpX - ptDiffX) +", "+(y + ptPerpY - ptDiffY) +");");

		trace("graphics.moveTo("+(x - ptDiff2X) +", "+(y - ptDiff2Y) +");");
		trace("graphics.lineTo("+(x - ptPerpX - ptDiffX) +", "+(y - ptPerpY - ptDiffY) +");");
		*/

	}

	public function updateText( s_color: String, speed: int): void
	{
		mtf_presureValue.htmlText = '<FONT face="Verdana" size="12" color="#' + s_color + '">' + m_windFormatter.format(speed) + '</FONT>';
	}

	private function countLabelPosition(toPoint: Point, toPoint2: Point): Point
	{
		//find angle between points
		var deltaX: Number = toPoint.x - toPoint2.x;
		var deltaY: Number = toPoint.y - toPoint2.y;
		var angle: Number = Math.atan2(deltaY, deltaX);
//		var angleInDegrees: Number = angle * 180 / Math.PI;

		var movementLineLengthPx: int = 45;
		var labelDistancePx: int = 60;

		var cos: Number = Math.cos(angle);
		var sin: Number = Math.sin(angle);

		var lx: Number = toPoint2.x + movementLineLengthPx * cos + (cos - 1)/2*(textWidth + 3);
		var ly: Number = toPoint2.y + movementLineLengthPx * sin + (sin - 1)/2 *(textHeight + 3);
		var labelPoint2: Point = new Point(lx, ly);
		return labelPoint2;
	}

	public function update(s_colorSign: String, s_color: String, i_colorCross: uint, type: String, toPoint: Point, toPoint2: Point,speed: int): void
	{
//		if (toPoint2.x != 0 || toPoint2.y != 0)
//		{
//			trace("Check wrong position");
//		}
		updateText(s_color, speed);
		var labelPoint: Point = countLabelPosition(toPoint, toPoint2);

		drawArrow(toPoint.x, toPoint.y, toPoint2.x, toPoint2.y, i_colorCross);
		mtf_presureValue.x = labelPoint.x;
		mtf_presureValue.y = labelPoint.y;
	}
}
