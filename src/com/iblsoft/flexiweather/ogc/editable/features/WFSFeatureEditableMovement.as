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
	import com.iblsoft.flexiweather.ogc.FeatureUpdateContext;
	import com.iblsoft.flexiweather.ogc.data.ReflectionData;
	import com.iblsoft.flexiweather.ogc.editable.WFSFeatureEditableWithBaseTimeAndValidity;
	import com.iblsoft.flexiweather.ogc.editable.data.FeatureDataPoint;
	import com.iblsoft.flexiweather.ogc.editable.data.FeatureDataReflection;
	import com.iblsoft.flexiweather.ogc.wfs.IWFSFeatureWithReflection;
	import com.iblsoft.flexiweather.ogc.wfs.WFSFeatureEditableSprite;
	import com.iblsoft.flexiweather.proj.Coord;
	import com.iblsoft.flexiweather.proj.Projection;
	import com.iblsoft.flexiweather.widgets.InteractiveWidget;

	import flash.events.Event;
	import flash.geom.Point;
	import flash.text.TextFieldAutoSize;
	import flash.utils.Dictionary;

	import mx.collections.ArrayCollection;
	import mx.core.UITextField;

	public class WFSFeatureEditableMovement extends WFSFeatureEditableWithBaseTimeAndValidity implements IWFSFeatureWithReflection
	{
		public var type: String;


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
			var test: int = getDirectionFromValue();
			return test;
		}
		private var _directionValue: Object;
		public var speed: int;
		private var _angles: Dictionary;

		public function WFSFeatureEditableMovement(s_namespace: String, s_typeName: String, s_featureId: String)
		{
			super(s_namespace, s_typeName, s_featureId);
			type = MovementMode.COMPASS_POINTS_8;
			speed = 80;
			directionValue = {value: "N"};
			mb_isSinglePointFeature = true;
			_angles = new Dictionary();
			initAngles();
		}

		public function getDataProvideForMovementMode(mode: String): ArrayCollection
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

		private function initAngles(): void
		{
			var directions: Array = ["N", "NNE", "NE", "ENE", "E", "ESE", "SE","SSE", "S", "SSW", "SW", "WSW", "W", "WNW", "NW", "NNW"];
			var angle: Number = 0;
			for each (var direction: String in directions)
			{
				_angles[direction] = {direction: direction, angle: angle};
				angle += 360/16;
			}
		}

		public function getAngleForDirection(direction: Object): Number
		{
			if (direction is Object && direction.hasOwnProperty("value"))
				return _angles[direction.value as String].angle as Number;

			return (direction as Number);
		}
		public function getItemWithSimilarDirection(ac: ArrayCollection): Object
		{
			if (directionValue)
			{
				var currAngle: Number = -1;
				var direction: String;
				var item: Object;
				var currDirectionString: String;
				if (directionValue is Object && directionValue.hasOwnProperty("value")) {
					direction = directionValue.value;
					currAngle = _angles[direction].angle;
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
						var angle: Number = _angles[currDirectionString].angle;

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

		private function getDirectionFromValue(): int
		{
			if (type == MovementMode.DEGREES)
			{
				return Math.round(directionValue as Number);
			}

			var directionName: String = directionValue.value as String;
			return Math.round((_angles[directionName] as Object).angle);
		}
		override public function update(changeFlag: FeatureUpdateContext): void
		{
			super.update(changeFlag);
			graphics.clear();
			var i_color: uint = 0;
			var i_colorSign: uint = 0;
			var i_colorCross: uint = 0;
//			if (type == PressureCentreType.HIGH)
//				i_colorSign = 0xC00000;
//			else if (type == PressureCentreType.LOW)
//				i_colorSign = 0x0000C0;
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
			var pixelDistance: Number = iw.getPixelDistance();

//			var laloCoord: Coord = (coordinates[0] as Coord).toLaLoCoord();
			var laloCoord: Coord = (coordinates[0] as Coord)

			var c0: Coord = laloCoord
			var c1: Coord = new Coord(laloCoord.crs, laloCoord.x + 1, laloCoord.y + 1);

			var p0: Point = iw.coordToPoint(c0);
			var p1: Point = iw.coordToPoint(c1);
			var pixelsForDegree: Number = p1.x - p0.x;
			var pixelsForDegree2: Number = p1.y - p0.y;
			var pixelsForDegree3: Number = Point.distance(p0, p1);

			var radius: Number = 50 / pixelsForDegree3;
			var radius2: Number = 30 / pixelsForDegree3;
			var radiusLabel: Number = 55 / pixelsForDegree3;
			var piConst: Number = Math.PI / 180;

//			var dir: Number = direction;// - 90;
			var dir: Number = (90 + (360 - direction)) % 360;// - 90;
			var dir2: Number = (dir + 180) % 360
			var arrowCoord: Coord = new Coord(laloCoord.crs, laloCoord.x + radius * Math.cos(dir * piConst), laloCoord.y + radius * Math.sin(dir * piConst)).convertToProjection(projection);
			var arrowCoord2: Coord = new Coord(laloCoord.crs, laloCoord.x + radius2 * Math.cos(dir2 * piConst), laloCoord.y + radius2 * Math.sin(dir2 * piConst)).convertToProjection(projection);
			var labelCoord: Coord = new Coord(laloCoord.crs, laloCoord.x + radiusLabel * Math.cos(dir * piConst), laloCoord.y + radiusLabel * Math.sin(dir * piConst)).convertToProjection(projection);


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
							var arrowCoordInReflections: Array = iw.mapCoordInCRSToViewReflectionsForDeltas(arrowCoord, [reflectionDelta]);
							var arrowCoordInReflection: Coord = new Coord(projection.crs, arrowCoordInReflections[0].point.x, arrowCoordInReflections[0].point.y);
							var arrowPoint: Point = iw.coordToPoint(arrowCoordInReflection).subtract(pt);

							var arrowCoordInReflections2: Array = iw.mapCoordInCRSToViewReflectionsForDeltas(arrowCoord2, [reflectionDelta]);
							var arrowCoordInReflection2: Coord = new Coord(projection.crs, arrowCoordInReflections2[0].point.x, arrowCoordInReflections2[0].point.y);
							var arrowPoint2: Point = iw.coordToPoint(arrowCoordInReflection2).subtract(pt);

							var labelCoordInReflections: Array = iw.mapCoordInCRSToViewReflectionsForDeltas(labelCoord, [reflectionDelta]);
							var labelCoordInReflection: Coord = new Coord(projection.crs, labelCoordInReflections[0].point.x, labelCoordInReflections[0].point.y);
							var labelPoint: Point = iw.coordToPoint(labelCoordInReflection).subtract(pt);


							movementSprite.update(s_colorSign, s_color, i_colorCross, type, arrowPoint, arrowPoint2, labelPoint, speed);
							movementSprite.x = pt.x;
							movementSprite.y = pt.y;
						}
						else
						{
							renderFallbackGraphics(i_color);
							return;
						}
					}
				}
			}
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
	}
}
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
	protected var mtf_presureType: UITextField = new UITextField();
	protected var mtf_presureValue: UITextField = new UITextField();

	private var m_windFormatter: WindSpeedFormatter;

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
//		graphics.beginFill(i_colorCross,1);

//		graphics.moveTo(x - ptDiff2X, y - ptDiff2Y);
		graphics.moveTo(prevX, prevY);
		graphics.lineTo(x - ptDiff2X, y - ptDiff2Y);
		graphics.lineTo(x + ptPerpX - ptDiffX, y + ptPerpY - ptDiffY);
		graphics.moveTo(x - ptDiff2X, y - ptDiff2Y);
		graphics.lineTo(x - ptPerpX - ptDiffX, y - ptPerpY - ptDiffY);

//		trace("\nMovement draw");
//		trace("graphics.moveTo("+prevX +", "+prevY +");");
//		trace("graphics.lineTo("+(x - ptDiff2X) +", "+(y - ptDiff2Y) +");");
//		trace("graphics.lineTo("+(x + ptPerpX - ptDiffX) +", "+(y + ptPerpY - ptDiffY) +");");
//		trace("graphics.moveTo("+(x - ptDiff2X) +", "+(y - ptDiff2Y) +");");
//		trace("graphics.lineTo("+(x - ptPerpX - ptDiffX) +", "+(y - ptPerpY - ptDiffY) +");");

//		graphics.lineTo(x - ptDiff2X, y - ptDiff2Y);

//		graphics.endFill();

	}

	public function update(s_colorSign: String, s_color: String, i_colorCross: uint, type: String, toPoint: Point, toPoint2: Point, labelPoint: Point,speed: int): void
	{
//		direction -= 90
		drawArrow(toPoint.x, toPoint.y, toPoint2.x, toPoint2.y, i_colorCross);
//		mtf_presureType.htmlText = '<FONT face="Verdana" size="20" color="#' + s_colorSign + '">' + type.charAt(0).toUpperCase() + '</FONT>';
//		mtf_presureType.x = -(int(mtf_presureType.width / 2));
//		mtf_presureType.y = -(int(mtf_presureType.height)) - 3;
		mtf_presureValue.htmlText = '<FONT face="Verdana" size="12" color="#' + s_color + '">' + m_windFormatter.format(speed) + '</FONT>';
		mtf_presureValue.x = labelPoint.x -(int(mtf_presureValue.width / 2));
		mtf_presureValue.y = labelPoint.y -(int(mtf_presureValue.height / 2));;
	}
}