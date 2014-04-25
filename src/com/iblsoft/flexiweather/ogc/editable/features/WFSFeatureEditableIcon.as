package com.iblsoft.flexiweather.ogc.editable.features
{
	import com.iblsoft.flexiweather.ogc.FeatureUpdateContext;
	import com.iblsoft.flexiweather.ogc.data.WFSEditableReflectionData;
	import com.iblsoft.flexiweather.ogc.editable.WFSFeatureEditable;
	import com.iblsoft.flexiweather.ogc.editable.data.IconFeatureType;
	import com.iblsoft.flexiweather.ogc.net.loaders.WFSIconLoader;
	import com.iblsoft.flexiweather.ogc.wfs.IWFSFeatureWithReflection;
	import com.iblsoft.flexiweather.proj.Coord;
	
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.geom.Point;
	
	public class WFSFeatureEditableIcon extends WFSFeatureEditable implements IWFSFeatureWithReflection
	{
		public var type: String;
		public var color: uint;
		private var ms_actIconLoaded: String = '';
		private var m_iconBitmap: Bitmap = new Bitmap();
		
		public function WFSFeatureEditableIcon(s_namespace:String, s_typeName:String, s_featureId:String)
		{
			super(s_namespace, s_typeName, s_featureId);
			color = 0x000000;
		}
		
		override public function update(changeFlag: FeatureUpdateContext): void
		{
			super.update(changeFlag);
			graphics.clear();
			
			var nIcon: String = resolveIconName();
			
			// http://wms.iblsoft.com/ria/helpers/gpaint-macro/render/SIGWX/tropical_storm?width=24&height=24
			if (nIcon != ms_actIconLoaded){
				ms_actIconLoaded = nIcon;
				var folderName: String = resolveIconFolder();
				WFSIconLoader.getInstance().getIcon(nIcon, this, onIconLoaded, folderName);
			}
		}
		
		private function onIconLoaded(mBitmap: Bitmap): void
		{
			if (mBitmap)
			{
				var nBitmapData: BitmapData = mBitmap.bitmapData;
				//				var pt: Point = getPoint(0);
				
				var iconSprite: IconSprite;
				var reflection: WFSEditableReflectionData;
				
				//create sprites for reflections
				var totalReflections: uint = ml_movablePoints.totalReflections;
				for (var i: int = 0; i < totalReflections; i++)
				{
					reflection = ml_movablePoints.getReflection(i) as WFSEditableReflectionData;
					if (!reflection.displaySprite)
					{
						iconSprite = new IconSprite(this); 
						reflection.displaySprite = iconSprite;
						addChild(reflection.displaySprite);
					} else {
						iconSprite = reflection.displaySprite as IconSprite;
					}
					
					var pt: Point = Point(reflection.points[0]);
					
					iconSprite.points = [pt];
					iconSprite.setBitmap(nBitmapData, pt, color);
					
				}
				if (pt)
				{
					update(FeatureUpdateContext.fullUpdate());
					master.container.labelLayout.update();
				}
				
				
			}
		}
		
		private function resolveIconFolder(): String
		{
			var folderName: String;
			
			switch (type)
			{
				case IconFeatureType.RAIN:
				case IconFeatureType.RAIN_STEADY:
				case IconFeatureType.RAIN_SHOWERS:
				case IconFeatureType.SNOW_STEADY:
				case IconFeatureType.SNOW_SHOWERS:
				case IconFeatureType.RASN_STEADY:
				case IconFeatureType.RASN_SHOWERS:
				case IconFeatureType.DRIZZLE:
				case IconFeatureType.PELLETS:
				case IconFeatureType.FOG:
				case IconFeatureType.HAZE:
				case IconFeatureType.SMOKE:
				case IconFeatureType.BLOWING_DUST:
					folderName = 'synop/weather';
					break;
				default:
					folderName = '';
					break;
			} 
			
			return folderName;
		}
		private function resolveIconName(): String
		{
			var retIconName: String = '';
//			var isSouthHemisphere: Boolean = false;
//			if (coordinates && coordinates.length > 0)
//			{
//				var coord: Coord = coordinates[0] as Coord;
//				var latLonCoord: Coord = coord.toLaLoCoord();
//				if (latLonCoord.y < 0)
//				{
//					isSouthHemisphere = true;
//				}
//			}
			
			switch (type)
			{
				case IconFeatureType.RAIN_STEADY:
					retIconName = IconFeatureType.ICON_NAME_RAIN_STEADY;
					break;
				case IconFeatureType.RAIN_SHOWERS:
					retIconName = IconFeatureType.ICON_NAME_RAIN_SHOWERS;
					break;
				case IconFeatureType.SNOW_STEADY:
					retIconName = IconFeatureType.ICON_NAME_SNOW_STEADY;
					break;
				case IconFeatureType.SNOW_SHOWERS:
					retIconName = IconFeatureType.ICON_NAME_SNOW_SHOWERS;
					break;
				case IconFeatureType.RASN_STEADY:
					retIconName = IconFeatureType.ICON_NAME_RASN_STEADY;
					break;
				case IconFeatureType.RASN_SHOWERS:
					retIconName = IconFeatureType.ICON_NAME_RASN_SHOWERS;
					break;
				case IconFeatureType.RAIN:
					retIconName = IconFeatureType.ICON_NAME_RAIN;
					break;
				case IconFeatureType.DRIZZLE:
					retIconName = IconFeatureType.ICON_NAME_DRIZZLE;
					break;
				case IconFeatureType.PELLETS:
					retIconName = IconFeatureType.ICON_NAME_PELLETS;
					break;
				case IconFeatureType.FOG:
					retIconName = IconFeatureType.ICON_NAME_FOG;
					break;
				case IconFeatureType.HAZE:
					retIconName = IconFeatureType.ICON_NAME_HAZE;
					break;
				case IconFeatureType.SMOKE:
					retIconName = IconFeatureType.ICON_NAME_SMOKE;
					break;
				case IconFeatureType.BLOWING_DUST:
					retIconName = IconFeatureType.ICON_NAME_BLOWING_DUST;
					break;
			} 
			
			return(retIconName);
		}
	}
}

import com.iblsoft.flexiweather.ogc.editable.WFSFeatureEditable;
import com.iblsoft.flexiweather.ogc.editable.features.WFSFeatureEditableIcon;
import com.iblsoft.flexiweather.ogc.wfs.WFSFeatureEditableSprite;
import com.iblsoft.flexiweather.utils.ColorUtils;

import flash.display.Bitmap;
import flash.display.BitmapData;
import flash.geom.Point;

class IconSprite extends WFSFeatureEditableSprite 
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
				trace("IconSprite hiding");
			} else {
				trace("IconSprite showing");
			}
		}
	}
	
	public function IconSprite(feature: WFSFeatureEditable)
	{
		super(feature)
		
		var baseBitmapData: BitmapData = new BitmapData(mn_iconsWidth, mn_iconsWidth, true, 0xFFFFFF);
		m_iconBitmap.bitmapData = baseBitmapData;
		
		addChild(m_iconBitmap);
		
	}
	
	public function setBitmap(nBitmapData: BitmapData, pt: Point, blackColor: uint): void
	{
		
		var nBitmapData: BitmapData = nBitmapData.clone();
		m_iconBitmapOrig = new Bitmap(nBitmapData.clone());
		
		m_iconBitmap.bitmapData = nBitmapData;
		
		update(blackColor, pt);
		
		
	}
	public function update(blackColor: uint, pt: Point): void
	{
		if (m_iconBitmap)
		{
			m_iconBitmap.x = pt.x - m_iconBitmap.width / 2;
			m_iconBitmap.y = pt.y - m_iconBitmap.height / 2;
			ColorUtils.updateSymbolColor(blackColor, m_iconBitmap, m_iconBitmapOrig);
		}		
	}
}