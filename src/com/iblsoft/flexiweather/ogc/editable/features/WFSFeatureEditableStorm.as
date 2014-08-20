package com.iblsoft.flexiweather.ogc.editable.features
{
	import com.iblsoft.flexiweather.ogc.FeatureUpdateContext;
	import com.iblsoft.flexiweather.ogc.InteractiveLayerFeatureBase;
	import com.iblsoft.flexiweather.ogc.InteractiveLayerWFS;
	import com.iblsoft.flexiweather.ogc.data.ReflectionData;
	import com.iblsoft.flexiweather.ogc.editable.WFSFeatureEditableWithBaseTimeAndValidityAndAnnotation;
	import com.iblsoft.flexiweather.ogc.editable.annotations.StormAnnotation;
	import com.iblsoft.flexiweather.ogc.editable.data.FeatureDataPoint;
	import com.iblsoft.flexiweather.ogc.editable.data.FeatureDataReflection;
	import com.iblsoft.flexiweather.ogc.net.loaders.WFSIconLoader;
	import com.iblsoft.flexiweather.ogc.wfs.IWFSFeatureWithAnnotation;
	import com.iblsoft.flexiweather.ogc.wfs.IWFSFeatureWithReflection;
	import com.iblsoft.flexiweather.ogc.wfs.WFSFeatureEditableSprite;
	import com.iblsoft.flexiweather.proj.Coord;
	import com.iblsoft.flexiweather.utils.AnnotationBox;
	
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.DisplayObject;
	import flash.geom.Point;

	public class WFSFeatureEditableStorm extends WFSFeatureEditableWithBaseTimeAndValidityAndAnnotation implements IWFSFeatureWithAnnotation, IWFSFeatureWithReflection
	{
		public function get sprite(): StormSprite
		{
			if (totalReflections > 0)
			{
				var reflection: FeatureDataReflection = m_featureData.getReflectionAt(0);
				return getDisplaySpriteForReflectionAt(reflection.reflectionDelta) as StormSprite;
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
		
		public var type: String;
		public var label: String;
//		public var intensity: String;
		public var speed: int;
		public var pressure: int;
		
		private var ms_actIconLoaded: String = '';
		private var m_iconBitmap: Bitmap = new Bitmap();
		
		public function WFSFeatureEditableStorm(s_namespace:String, s_typeName:String, s_featureId:String)
		{
			super(s_namespace, s_typeName, s_featureId);
			
			mb_isSinglePointFeature = true;
			mb_isIconFeature = true;
		}
	
		public override function cleanup(): void
		{
			if (master && master.container && master.container.labelLayout)
			{
				master.container.labelLayout.removeObject(this);
				
				var stormAnnotation: StormAnnotation;
				var reflection: FeatureDataReflection;
				var displaySprite: WFSFeatureEditableSprite;
				
				for (var i: int = 0; i < totalReflections; i++)
				{
					reflection = m_featureData.getReflectionAt(i);
					var reflectionDelta: int = reflection.reflectionDelta;
					stormAnnotation = getAnnotationForReflectionAt(reflectionDelta) as StormAnnotation;
					displaySprite = getDisplaySpriteForReflectionAt(reflectionDelta);
					
					master.container.labelLayout.removeObject(displaySprite);
					master.container.labelLayout.removeObject(stormAnnotation);
				}
			}
			
			super.cleanup();
		}
		
		private var _spritesAddedToLabelLayout: Boolean;
		
		override public function update(changeFlag: FeatureUpdateContext): void
		{
			super.update(changeFlag);
			graphics.clear();
			
			var nIcon: String = resolveIconName();
		
			// http://wms.iblsoft.com/ria/helpers/gpaint-macro/render/SIGWX/tropical_storm?width=24&height=24
			if (nIcon != ms_actIconLoaded){
				ms_actIconLoaded = nIcon;
				WFSIconLoader.getInstance().getIcon(nIcon, this, onIconLoaded, 'SIGWX');
			}
			
		}	
		
		override public function getDisplaySpriteForReflection(id: int): WFSFeatureEditableSprite
		{
			return new StormSprite(this);
		}
		
		override public function createAnnotation(): AnnotationBox
		{
			return new StormAnnotation(0);
		}
		
		
		
		
		/**
		 * 
		 */
		private function onIconLoaded(mBitmap: Bitmap): void
		{
			if (mBitmap)
			{
				m_loadedIconBitmapData = mBitmap.bitmapData;
				
				var stormSprite: StormSprite;
				var reflection: FeatureDataReflection;
				var displaySprite: WFSFeatureEditableSprite;
				
				//create sprites for reflections
				
				for (var i: int = 0; i < totalReflections; i++)
				{
					reflection = m_featureData.getReflectionAt(i);
					var reflectionDelta: int = reflection.reflectionDelta;
					
					displaySprite = getDisplaySpriteForReflectionAt(reflectionDelta);
					stormSprite = displaySprite as StormSprite;
					
					var pt: Point = Point(reflection.editablePoints[0]);
					
					stormSprite.points = [pt];
					stormSprite.setBitmap(m_loadedIconBitmapData, pt);
					
				}
				if (pt)
				{
					update(FeatureUpdateContext.fullUpdate());
					master.container.labelLayout.update();
				}
				
				
			}
		}
		
		/**
		 * 
		 */
		private function resolveIconName(): String
		{
			var retIconName: String = '';
			var isSouthHemisphere: Boolean = false;
			if (coordinates && coordinates.length > 0)
			{
				var coord: Coord = coordinates[0] as Coord;
				var latLonCoord: Coord = coord.toLaLoCoord();
				if (latLonCoord.y < 0)
				{
					isSouthHemisphere = true;
				}
			}
			switch (type)
			{
				case StormAnnotation.TYPE_DEPRESSION:
				case StormAnnotation.TYPE_TROPIC_DEPRESSION:
					retIconName = 'tropical_depression';
					break;
				case StormAnnotation.TYPE_TROPIC_STORM:
				case StormAnnotation.TYPE_SEVERE_STORM:
					if (isSouthHemisphere)
						retIconName = 'tropical_storm_south_hemisphere';
					else
						retIconName = 'tropical_storm';
				
					break;
				
				case StormAnnotation.TYPE_TYPHOON:
					
					if (isSouthHemisphere)
						retIconName = 'hurricane_typhoon_south_hemisphere';
					else
						retIconName = 'hurricane_typhoon';
					break;
					
				case StormAnnotation.TYPE_DUST_SAND_STORM:
					retIconName = 'sandstorm';
					break;
			} 
			
			return(retIconName);
		}
		
		override public function toInsertGML(xmlInsert: XML): void
		{
			var gml: Namespace = new Namespace("http://www.opengis.net/gml");
			super.toInsertGML(xmlInsert);
			addInsertGMLProperty(xmlInsert, null, "type", type);
			addInsertGMLProperty(xmlInsert, null, "phenomenonName", label);
		}

		override public function toUpdateGML(xmlUpdate: XML): void
		{
			super.toUpdateGML(xmlUpdate);
			addUpdateGMLProperty(xmlUpdate, null, "type", type);
			addUpdateGMLProperty(xmlUpdate, null, "phenomenonName", label);
		}

		override public function fromGML(gml: XML): void
		{
			super.fromGML(gml);
			var ns: Namespace = new Namespace(ms_namespace);
			type = gml.ns::type[0];
			label = gml.ns::phenomenonName[0];
		}
		
		public function getType(): String
		{
			return(type);
		}
	}
}
import com.iblsoft.flexiweather.ogc.editable.WFSFeatureEditable;
import com.iblsoft.flexiweather.ogc.editable.WFSFeatureEditableWithBaseTimeAndValidityAndAnnotation;
import com.iblsoft.flexiweather.ogc.editable.annotations.StormAnnotation;
import com.iblsoft.flexiweather.ogc.editable.data.FeatureDataPoint;
import com.iblsoft.flexiweather.ogc.editable.features.WFSFeatureEditableStorm;
import com.iblsoft.flexiweather.ogc.wfs.IWFSIconSprite;
import com.iblsoft.flexiweather.ogc.wfs.WFSFeatureEditableSprite;
import com.iblsoft.flexiweather.ogc.wfs.WFSFeatureEditableSpriteWithAnnotation;
import com.iblsoft.flexiweather.utils.AnnotationBox;
import com.iblsoft.flexiweather.utils.ColorUtils;
import com.iblsoft.flexiweather.utils.anticollision.AnticollisionLayout;
import com.iblsoft.flexiweather.utils.geometry.LineSegment;

import flash.display.Bitmap;
import flash.display.BitmapData;
import flash.display.Sprite;
import flash.geom.Point;

class StormSprite extends WFSFeatureEditableSpriteWithAnnotation implements IWFSIconSprite 
{

	private var mn_iconsWidth: Number = 24;
	private var m_iconBitmap: Bitmap = new Bitmap();
	private var m_iconBitmapOrig: Bitmap = new Bitmap();
	
	override public function set visible(value:Boolean):void
	{
		if (super.visible != value)
		{
			super.visible = value;
			
			if (!value)
			{
				trace("StormSprite hiding");
			} else {
				trace("StormSprite showing");
			}
			if (annotation)
			{
				annotation.visible = value;
			}
		}
	}
	
	public function StormSprite(feature: WFSFeatureEditable)
	{
		super(feature)
			
		var baseBitmapData: BitmapData = new BitmapData(mn_iconsWidth, mn_iconsWidth, true, 0xFFFFFF);
		m_iconBitmap.bitmapData = baseBitmapData;
		
		addChild(m_iconBitmap);

	}
	
	public function setBitmap(nBitmapData: BitmapData, pt: Point, blackColor: uint = 0): void
	{
		
		var nBitmapData: BitmapData = nBitmapData.clone();
		m_iconBitmapOrig = new Bitmap(nBitmapData.clone());
		
		m_iconBitmap.bitmapData = nBitmapData;
		
		if (pt)
		{
			m_iconBitmap.x = pt.x - nBitmapData.width / 2;
			m_iconBitmap.y = pt.y - nBitmapData.height / 2;
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
		var storm: WFSFeatureEditableStorm = feature as WFSFeatureEditableStorm;
		
		this.annotation = annotation;
		
		if (m_iconBitmap)
		{
			m_iconBitmap.x = pt.x - m_iconBitmap.width / 2;
			m_iconBitmap.y = pt.y - m_iconBitmap.height / 2;
			ColorUtils.updateSymbolColor(blackColor, m_iconBitmap, m_iconBitmapOrig);
		}		
		
		annotation.color = blackColor;
		(annotation as StormAnnotation).stormData = storm;
		annotation.update();
//		annotation.visible = true;
		annotation.x = m_iconBitmap.x + m_iconBitmap.width / 2 - annotation.width / 2.0;
		annotation.y = m_iconBitmap.y - annotation.height - 3;
		
		trace("StormSprite update 1: " + annotation.x + " , " + annotation.y + " visible: " + annotation.visible)
		trace("StormSprite update 2: " + x + " , " + y)
		labelLayout.updateObjectReferenceLocation(annotation);
	}
}