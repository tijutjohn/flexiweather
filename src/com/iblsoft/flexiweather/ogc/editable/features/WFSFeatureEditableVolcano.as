package com.iblsoft.flexiweather.ogc.editable.features
{
	import com.iblsoft.flexiweather.ogc.FeatureUpdateContext;
	import com.iblsoft.flexiweather.ogc.GMLUtils;
	import com.iblsoft.flexiweather.ogc.InteractiveLayerWFS;
	import com.iblsoft.flexiweather.ogc.data.ReflectionData;
	import com.iblsoft.flexiweather.ogc.editable.WFSFeatureEditableClosableCurveWithBaseTimeAndValidity;
	import com.iblsoft.flexiweather.ogc.editable.WFSFeatureEditableWithBaseTimeAndValidity;
	import com.iblsoft.flexiweather.ogc.editable.data.FeatureDataPoint;
	import com.iblsoft.flexiweather.ogc.editable.data.FeatureDataReflection;
	import com.iblsoft.flexiweather.ogc.editable.data.MoveablePoint;
	import com.iblsoft.flexiweather.ogc.net.loaders.WFSIconLoader;
	import com.iblsoft.flexiweather.ogc.wfs.IWFSFeatureWithReflection;
	import com.iblsoft.flexiweather.ogc.wfs.WFSFeatureEditableSprite;
	import com.iblsoft.flexiweather.proj.Coord;
	import com.iblsoft.flexiweather.proj.Projection;
	import com.iblsoft.flexiweather.utils.CubicBezier;
	import com.iblsoft.flexiweather.utils.GraphicsCurveRenderer;
	import com.iblsoft.flexiweather.utils.ISO8601Parser;
	import com.iblsoft.flexiweather.utils.NumberUtils;
	import com.iblsoft.flexiweather.widgets.InteractiveWidget;

	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.geom.ColorTransform;
	import flash.geom.Matrix;
	import flash.geom.Point;
	import flash.utils.setTimeout;

	import mx.collections.ArrayCollection;
	import mx.core.FlexGlobals;
	import mx.core.UITextField;
	import mx.graphics.ImageSnapshot;

	/**
	 * For front styles see for example http://en.wikipedia.org/wiki/Weather_front
	 **/
	public class WFSFeatureEditableVolcano extends WFSFeatureEditableWithBaseTimeAndValidity
		implements IWFSFeatureWithReflection
	{
//		public var values: Object = {
//			anotation: "test"
//		}

		private var mf_iconsWidth: Number = 48;

		private var ms_actIconLoaded: String = '';

		public var values: Object;
		public var volcano:Object;

		//TODO add better depedency on InteractiveWidget
//		public var iw:InteractiveWidget;
//		public var iw:InteractiveWidget = (FlexGlobals.topLevelApplication as IBrowsingWeather).mainView.iw;

//		public static const smf_pxToPt: Number = 0.35277777910232544;

		public function WFSFeatureEditableVolcano(s_namespace: String, s_typeName: String, s_featureId: String)
		{
			super(s_namespace, s_typeName, s_featureId);

			justSelectable = true;
			mb_isSinglePointFeature = true;

			volcano = { number: 1, name: "blank", la: 0, lo: 0, coordinate: new Coord(Projection.CRS_EPSG_GEOGRAPHIC, 0,0), elev: 0, anotation: "none" };
			values = { smooth: false, size: 1.0, style: "Solid", color: 0x000000 };
		}

		override public function update(changeFlag: FeatureUpdateContext): void
		{
			if(m_coordinates.length != 1
				|| Coord(m_coordinates[0]).equalsCoord(volcano.coordinate)) {
				m_coordinates = [volcano.coordinate];
			}

			super.update(changeFlag);



			if (master)
			{
				// create volcano icon
				var pt: Point = master.container.coordToPoint(volcano.coordinate);

				var s_iconName: String = 'volcanic_eruption';

				// http://wms.iblsoft.com/ria/helpers/gpaint-macro/render/SIGWX/volcanic_eruption?width=24&height=24
				if (s_iconName != ms_actIconLoaded){
					ms_actIconLoaded = s_iconName;
					WFSIconLoader.getInstance().getIcon(s_iconName, this, onIconLoaded, 'SIGWX', mf_iconsWidth, mf_iconsWidth);
				}


				var volcanicAshSprite: VolcanoSprite;
				var reflection: FeatureDataReflection;

				//create sprites for reflections

				var blackColor: uint = getCurrentColor(0x000000);
				var reflectionIDs: Array = m_featureData.reflectionsIDs;

				for (var i: int = 0; i < totalReflections; i++)
				{
					var reflectionDelta: int = reflectionIDs[i];

					reflection = m_featureData.getReflectionAt(reflectionDelta);

					var displaySprite: WFSFeatureEditableSprite = getDisplaySpriteForReflectionAt(reflectionDelta);
					volcanicAshSprite = displaySprite as VolcanoSprite;

					volcanicAshSprite.update(blackColor);

//					var fdpt: FeatureDataPoint = FeatureDataPoint(reflection.editablePoints[0]);
					var fdpt: Point = Point(reflection.editablePoints[0]);
					if (fdpt)
					{
						volcanicAshSprite.x = fdpt.x;
						volcanicAshSprite.y = fdpt.y;
					}
				}

			} else {
				setTimeout(update, 1000);
			}
		}

		public function onIconLoaded(mBitmap: Bitmap): void
		{
			if (master && mBitmap){

				var volcanicAshSprite: VolcanoSprite;
				var reflection: FeatureDataReflection;

				//create sprites for reflections

				var blackColor: uint = getCurrentColor(0x000000);
				var reflectionIDs: Array = m_featureData.reflectionsIDs;

				for (var i: int = 0; i < totalReflections; i++)
				{
					var reflectionDelta: int = reflectionIDs[i];

					reflection = m_featureData.getReflectionAt(reflectionDelta);

					var displaySprite: WFSFeatureEditableSprite = getDisplaySpriteForReflectionAt(reflectionDelta);
					volcanicAshSprite = displaySprite as VolcanoSprite;

					volcanicAshSprite.setBitmap(mBitmap.bitmapData);
				}

				update(FeatureUpdateContext.fullUpdate());
				master.container.labelLayout.update();
			} else {
				setTimeout(onIconLoaded, 1000, mBitmap);
			}
		}

		override protected function addMoveablePointListeners(mp:MoveablePoint):void
		{
			//do not do anything, volcano can not be dragged out
		}
		override protected function removeMoveablePointListeners(mp:MoveablePoint):void
		{
			//do not do anything, volcano can not be dragged out
		}

		override public function getDisplaySpriteForReflection(id: int): WFSFeatureEditableSprite
		{
			return new VolcanoSprite(this, mf_iconsWidth, mf_iconsWidth);
		}

		override public function toString(): String
		{
			return "WFSFeatureEditablVolcano: ";
		}

		override public function toInsertGML(xmlInsert: XML): void
		{
//			var gml: Namespace = new Namespace("http://www.opengis.net/gml");
//			super.toInsertGML(xmlInsert);
//			addInsertGMLProperty(xmlInsert, null, "baseTime", ISO8601Parser.dateToString(m_baseTime));
//			addInsertGMLProperty(xmlInsert, null, "validity", ISO8601Parser.dateToString(m_validity));

			var crs: String = master.container.getCRS();
			var projection: Projection = master.container.getCRSProjection();
			var coord: Coord = new Coord("CRS:84", volcano.lo, volcano.la);
			var volcanoCoord: Coord = coord.convertToProjection(projection);

			var gml: Namespace = new Namespace("http://www.opengis.net/gml");
			addInsertGMLProperty(xmlInsert, null, "baseTime", ISO8601Parser.dateToString(m_baseTime));
			addInsertGMLProperty(xmlInsert, null, "validity", ISO8601Parser.dateToString(m_validity));
			xmlInsert.appendChild(<gml:location xmlns:gml="http://www.opengis.net/gml"><gml:Point><gml:pos srsName={crs}>{volcanoCoord.x} {volcanoCoord.y}</gml:pos></gml:Point></gml:location>);
			addInsertGMLProperty(xmlInsert, null, "phenomenonName", volcano.name);

//			addInsertGMLProperty(xmlInsert, null, "anotation", values.anotation);
		}

		override public function toUpdateGML(xmlUpdate: XML): void
		{
//			super.toUpdateGML(xmlUpdate);

			var crs: String = master.container.getCRS();
			var projection: Projection = master.container.getCRSProjection();
			var coord: Coord = new Coord("CRS:84", volcano.lo, volcano.la);
			var volcanoCoord: Coord = coord.convertToProjection(projection);

			var gml: Namespace = new Namespace("http://www.opengis.net/gml");
			addInsertGMLProperty(xmlUpdate, null, "baseTime", ISO8601Parser.dateToString(m_baseTime));
			addInsertGMLProperty(xmlUpdate, null, "validity", ISO8601Parser.dateToString(m_validity));
			xmlUpdate.appendChild(<gml:location xmlns:gml="http://www.opengis.net/gml"><gml:Point><gml:pos srsName={crs}>{volcanoCoord.x} {volcanoCoord.y}</gml:pos></gml:Point></gml:location>);
			addInsertGMLProperty(xmlUpdate, null, "phenomenonName", volcano.name);
		}

		override public function fromGML(gml: XML): void
		{

			super.fromGML(gml);
//			var ns: Namespace = new Namespace(ms_namespace);
//			values.anotation = gml.ns::anotation[0];

			var ns: Namespace = new Namespace(ms_namespace);
			var nsGML: Namespace = new Namespace("http://www.opengis.net/gml");

			m_baseTime = ISO8601Parser.stringToDate(gml.ns::baseTime);
			m_validity = ISO8601Parser.stringToDate(gml.ns::validity);

			// change color based on time or height
			values = {
				smooth: false,
				size: 1.0,
				style: "Solid",
				color: 0x000000
			};

			var xmlLocation: XML = gml.nsGML::location[0];
			var xmlPoint: XML = xmlLocation.nsGML::Point[0];
			for each(var node: XML in xmlPoint.children()) {
				var s_coords: String = String(node);
				var a_bits: Array = s_coords.split(/\s/);
				var s_srs: String = node.@srsName;
			}

			var c: Coord = new Coord(s_srs, a_bits[0], a_bits[1]);
			var cooPoint:Point = master.container.coordToPoint(c);

			volcano = {
					number: 1,
					name: gml.ns::phenomenonName[0].toString(),
					la: a_bits[1],
					lo: a_bits[0],
					coordinate: c,
					point: cooPoint,
					elev: 0,
					anotation: "none"
			};

		}
	}
}

import com.iblsoft.flexiweather.ogc.editable.WFSFeatureEditable;
import com.iblsoft.flexiweather.ogc.wfs.WFSFeatureEditableSprite;
import com.iblsoft.flexiweather.utils.ColorUtils;

import flash.display.Bitmap;
import flash.display.BitmapData;
import flash.display.Graphics;
import flash.display.Sprite;
import flash.geom.Point;

class VolcanoSprite extends WFSFeatureEditableSprite {

	private var m_iconBitmap: Bitmap = new Bitmap();
	private var m_iconBitmapOrig: Bitmap = new Bitmap();

	private var sprite1:Sprite;
	private var sprite2:Sprite;

	private var graphicsLine:Graphics;
	private var graphicsIcon:Graphics;

	public function VolcanoSprite(feature: WFSFeatureEditable, wIcon: Number, hIcon: Number)
	{
		super(feature);

		sprite1 = new Sprite();
		sprite2 = new Sprite();

		addChild(sprite1);
		addChild(sprite2);

		graphicsLine = sprite1.graphics;
		graphicsIcon = sprite2.graphics;

		var baseBitmapData: BitmapData = new BitmapData(wIcon, hIcon, true, 0xFFFFFF);
		m_iconBitmap.bitmapData = baseBitmapData;
		addChild(m_iconBitmap);

	}

	public function setBitmap(nBitmapData: BitmapData): void
	{

		m_iconBitmap.bitmapData = nBitmapData.clone();
		m_iconBitmapOrig = new Bitmap(nBitmapData.clone());

	}

	public function update(blackColor: uint): void
	{
		graphicsLine.clear();
		graphicsIcon.clear();

		if (m_iconBitmap)
		{
			m_iconBitmap.x = - m_iconBitmap.width / 2 - 1;
			m_iconBitmap.y = - m_iconBitmap.height / 2 - 20;
			ColorUtils.updateSymbolColor(blackColor, m_iconBitmap, m_iconBitmapOrig);
		}

		graphicsIcon.lineStyle(0, 0, 0); // volcano border
		graphicsIcon.beginFill(0xFFFFFF);
		graphicsIcon.drawRect(m_iconBitmap.x - 2, m_iconBitmap.y - 2, m_iconBitmap.width + 4, m_iconBitmap.height + 4);
		graphicsIcon.endFill();


	}
}

