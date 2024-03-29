package com.iblsoft.flexiweather.ogc.editable.features
{
	import com.iblsoft.flexiweather.ogc.FeatureUpdateContext;
	import com.iblsoft.flexiweather.ogc.InteractiveLayerFeatureBase;
	import com.iblsoft.flexiweather.ogc.InteractiveLayerWFS;
	import com.iblsoft.flexiweather.ogc.data.ReflectionData;
	import com.iblsoft.flexiweather.ogc.editable.WFSFeatureEditableWithBaseTimeAndValidity;
	import com.iblsoft.flexiweather.ogc.editable.WFSFeatureEditableWithBaseTimeAndValidityAndAnnotation;
	import com.iblsoft.flexiweather.ogc.editable.annotations.RadiationAnnotation;
	import com.iblsoft.flexiweather.ogc.editable.data.FeatureDataPoint;
	import com.iblsoft.flexiweather.ogc.editable.data.FeatureDataReflection;
	import com.iblsoft.flexiweather.ogc.net.loaders.WFSIconLoader;
	import com.iblsoft.flexiweather.ogc.wfs.IWFSFeatureWithAnnotation;
	import com.iblsoft.flexiweather.ogc.wfs.IWFSFeatureWithReflection;
	import com.iblsoft.flexiweather.ogc.wfs.WFSFeatureEditableSprite;
	import com.iblsoft.flexiweather.utils.AnnotationBox;
	import com.iblsoft.flexiweather.utils.ISO8601Parser;

	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.DisplayObject;
	import flash.geom.ColorTransform;
	import flash.geom.Point;
	import flash.geom.Rectangle;

	public class WFSFeatureEditableRadiation extends WFSFeatureEditableWithBaseTimeAndValidityAndAnnotation implements IWFSFeatureWithAnnotation, IWFSFeatureWithReflection
	{
		private var ms_actIconLoaded: String = '';

		public var label: String;
		public var type: String;
		public var date: Date;

		public function get sprite(): RadiationSprite
		{
			if (totalReflections > 0)
			{
				var reflection: FeatureDataReflection = m_featureData.getReflectionAt(m_featureData.reflectionsIDs[0]);
				if (reflection)
					return getDisplaySpriteForReflectionAt(reflection.reflectionDelta) as RadiationSprite;
			}
			return null;
		}

		override public function get getAnticollisionObject(): DisplayObject
		{
			return annotation;
		}
		override public function get getAnticollisionObstacle():DisplayObject
		{
			return sprite;
		}

		public function WFSFeatureEditableRadiation(s_namespace:String, s_typeName:String, s_featureId:String)
		{
			super(s_namespace, s_typeName, s_featureId);
			mb_isSinglePointFeature = true;
			mb_isIconFeature = true;
		}

		private var _spritesAddedToLabelLayout: Boolean;

		public override function cleanup(): void
		{
			if (master && master.container && master.container.labelLayout)
			{
				master.container.labelLayout.removeObject(this);

				var radiationSprite: RadiationSprite;
				var reflection: FeatureDataReflection;

				//create sprites for reflections

				var blackColor: uint = getCurrentColor(0x000000);
				var reflectionIDs: Array = m_featureData.reflectionsIDs;

				for (var i: int = 0; i < totalReflections; i++)
				{
					var reflectionDelta: int = reflectionIDs[i];

					reflection = m_featureData.getReflectionAt(reflectionDelta);
					radiationSprite = getDisplaySpriteForReflectionAt(reflectionDelta) as RadiationSprite;

					removeFromLabelLayout(radiationSprite.annotation, radiationSprite, master.container.labelLayout);
				}
			}

			ms_actIconLoaded = '';

			super.cleanup();
		}

		override public function update(changeFlag: FeatureUpdateContext): void
		{
			super.update(changeFlag);



			var s_iconName: String = 'radioactive_materials';

			// http://wms.iblsoft.com/ria/helpers/gpaint-macro/render/SIGWX/tropical_storm?width=24&height=24
			if (s_iconName != ms_actIconLoaded){
				ms_actIconLoaded = s_iconName;
				WFSIconLoader.getInstance().getIcon(s_iconName, this, onIconLoaded, 'SIGWX');
			}
		}

		override public function getDisplaySpriteForReflection(id: int): WFSFeatureEditableSprite
		{
			return new RadiationSprite(this);
		}

		override public function createAnnotation(): AnnotationBox
		{
			return new RadiationAnnotation(0);
		}

		public function onIconLoaded(mBitmap: Bitmap): void
		{
			if (mBitmap){
				m_loadedIconBitmapData = mBitmap.bitmapData.clone();

				//var pt: Point = getPoint(0);

				var radiationSprite: RadiationSprite;
				var reflection: FeatureDataReflection;

				//create sprites for reflections

				var blackColor: uint = getCurrentColor(0x000000);
				var reflectionIDs: Array = m_featureData.reflectionsIDs;

				for (var i: int = 0; i < totalReflections; i++)
				{
					var reflectionDelta: int = reflectionIDs[i];

					reflection = m_featureData.getReflectionAt(reflectionDelta);
					radiationSprite = getDisplaySpriteForReflectionAt(reflectionDelta)  as RadiationSprite;

					var pt: Point = Point(reflection.editablePoints[0]);
					if (pt)
					{
						radiationSprite.setBitmap(m_loadedIconBitmapData, pt);
					}
				}

				if (pt)
				{
					update(FeatureUpdateContext.fullUpdate());
					master.container.labelLayout.invalidateLayout();
				}


			}
		}

		override public function toInsertGML(xmlInsert: XML): void
		{
			date.seconds = 0;
			date.milliseconds = 0;

			var gml: Namespace = new Namespace("http://www.opengis.net/gml");
			super.toInsertGML(xmlInsert);
			addInsertGMLProperty(xmlInsert, null, "type", type);
			addInsertGMLProperty(xmlInsert, null, "phenomenonName", label);
//			addInsertGMLProperty(xmlInsert, null, "eventTime", ISO8601Parser.dateToString(getUTCDate(date)));
			addInsertGMLProperty(xmlInsert, null, "eventTime", ISO8601Parser.dateToString((date)));
		}

		override public function toUpdateGML(xmlUpdate: XML): void
		{
			date.seconds = 0;
			date.milliseconds = 0;

			super.toUpdateGML(xmlUpdate);
			addUpdateGMLProperty(xmlUpdate, null, "type", type);
			addUpdateGMLProperty(xmlUpdate, null, "phenomenonName", label);
			addUpdateGMLProperty(xmlUpdate, null, "eventTime", ISO8601Parser.dateToString((date)));
		}

		override public function fromGML(gml: XML): void
		{
			super.fromGML(gml);
			var ns: Namespace = new Namespace(ms_namespace);
			type = gml.ns::type[0];
			label = gml.ns::phenomenonName[0];
			date = ISO8601Parser.stringToDate(gml.ns::eventTime[0]);
		}

		public function getType(): String
		{
			return type;
		}
	}
}
import com.iblsoft.flexiweather.ogc.editable.WFSFeatureEditable;
import com.iblsoft.flexiweather.ogc.editable.WFSFeatureEditableWithBaseTimeAndValidityAndAnnotation;
import com.iblsoft.flexiweather.ogc.editable.annotations.RadiationAnnotation;
import com.iblsoft.flexiweather.ogc.editable.data.FeatureDataPoint;
import com.iblsoft.flexiweather.ogc.editable.features.WFSFeatureEditableRadiation;
import com.iblsoft.flexiweather.ogc.net.loaders.WMSFeatureInfoLoader;
import com.iblsoft.flexiweather.ogc.wfs.IWFSIconSprite;
import com.iblsoft.flexiweather.ogc.wfs.WFSFeatureEditableSpriteWithAnnotation;
import com.iblsoft.flexiweather.utils.AnnotationBox;
import com.iblsoft.flexiweather.utils.ColorUtils;
import com.iblsoft.flexiweather.utils.anticollision.AnticollisionLayout;
import com.iblsoft.flexiweather.utils.anticollision.AnticollisionLayoutObject;
import com.iblsoft.flexiweather.utils.geometry.LineSegment;
import com.iblsoft.flexiweather.widgets.InteractiveLayer;

import flash.display.Bitmap;
import flash.display.BitmapData;
import flash.display.Sprite;
import flash.geom.Point;

import mx.utils.ColorUtil;

class RadiationSprite extends WFSFeatureEditableSpriteWithAnnotation implements IWFSIconSprite
{

	private var m_iconBitmap: Bitmap = new Bitmap();
	private var m_originalSymbolBitmap: Bitmap;

	private var mf_iconsWidth: Number = 24;

	override public function set visible(value:Boolean):void
	{
//		if (super.visible != value)
//		{
			super.visible = value;
			trace(this + " : visible: " + value);
			if (annotation)
			{
				annotation.visible = value;
			} else {
				trace(this + " HIDE");
			}
//		} else {
//			if (annotation)
//				trace(this + " visibility not changed: " + super.visible + "  annotation["+annotation+"].visible: " + annotation.visible);
//			else
//				trace(this + " visibility not changed: " + super.visible);
//		}
	}
	override public function set x(value:Number):void
	{
		super.x = value;
	}
	override public function set y(value:Number):void
	{
		super.y = value;
	}
	public function RadiationSprite(feature: WFSFeatureEditable)
	{
		super(feature);


		var baseBitmapData: BitmapData = new BitmapData(mf_iconsWidth, mf_iconsWidth, true, 0xFFFFFF);
		m_iconBitmap.bitmapData = baseBitmapData;
		addChild(m_iconBitmap);
	}

	public function setBitmap(nBitmapData: BitmapData, pt: Point, blackColor: uint = 0): void
	{
		m_iconBitmap.bitmapData = nBitmapData;
		m_originalSymbolBitmap = new Bitmap(nBitmapData.clone());

		if (pt)
		{
			m_iconBitmap.x = pt.x - 12;
			m_iconBitmap.y = pt.y - 12;
		}
	}

	override public function getLineSegmentApproximationOfBounds(): Array
	{
		var a: Array = [];

		if (m_iconBitmap)
		{
			var iconX: int = m_iconBitmap.x + m_iconBitmap.width / 2;
			var iconY: int = m_iconBitmap.y + m_iconBitmap.height / 2;

			a.push(new LineSegment(iconX, iconY, iconX+0.5, iconY));
		} else
			a.push(new LineSegment(x, y, x+0.5, y+0.5));

		return a;
	}

	override public function update(feature: WFSFeatureEditableWithBaseTimeAndValidityAndAnnotation, annotation: AnnotationBox, blackColor: uint, labelLayout: AnticollisionLayout, pt: Point): void
	{
		var radiation: WFSFeatureEditableRadiation = feature as WFSFeatureEditableRadiation;

		this.annotation = annotation;

		graphics.clear();

		if (m_iconBitmap)
		{
			m_iconBitmap.x = pt.x - m_iconBitmap.width / 2;
			m_iconBitmap.y = pt.y - m_iconBitmap.height / 2;
			ColorUtils.updateSymbolColor(blackColor, m_iconBitmap, m_originalSymbolBitmap);
		}

		annotation.color = blackColor;
		(annotation as RadiationAnnotation).radiationData = radiation;
		annotation.update();
//		annotation.visible = true;
		annotation.x = pt.x - annotation.width / 2.0;
		annotation.y = pt.y - m_iconBitmap.height/2 - annotation.height - 3;

//		trace("RadiationSprite update 1: " + annotation.x + " , " + annotation.y + " visible: " + annotation.visible)
//		trace("RadiationSprite update 2: " + x + " , " + y)

		labelLayout.updateObjectReferenceLocation(annotation);

	}

	override public function toString(): String
	{
		return "RadiationSprite["+id+"]";
	}
}