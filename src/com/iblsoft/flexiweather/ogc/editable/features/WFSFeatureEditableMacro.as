package com.iblsoft.flexiweather.ogc.editable.features
{
	import com.iblsoft.flexiweather.ogc.FeatureUpdateContext;
	import com.iblsoft.flexiweather.ogc.editable.WFSFeatureEditable;
	import com.iblsoft.flexiweather.ogc.editable.WFSFeatureEditableWithBaseTimeAndValidity;
	import com.iblsoft.flexiweather.ogc.editable.data.FeatureDataPoint;
	import com.iblsoft.flexiweather.ogc.editable.data.FeatureDataReflection;
	import com.iblsoft.flexiweather.ogc.editable.data.IconFeatureType;
	import com.iblsoft.flexiweather.ogc.net.loaders.WFSIconLoader;
	import com.iblsoft.flexiweather.ogc.wfs.IWFSFeatureWithReflection;
	import com.iblsoft.flexiweather.ogc.wfs.WFSFeatureEditableSprite;
	import com.iblsoft.flexiweather.proj.Coord;
	import com.iblsoft.flexiweather.utils.NumberUtils;
	
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.geom.Point;
	
	public class WFSFeatureEditableMacro extends WFSFeatureEditableWithBaseTimeAndValidity implements IWFSFeatureWithReflection
	{
		public var type: String;
		public var color: uint;
		private var ms_actIconLoaded: String = '';
		private var m_iconBitmap: Bitmap = new Bitmap();
		private var ma_types: Array;
		
		public function WFSFeatureEditableMacro(s_namespace:String, s_typeName:String, s_featureId:String)
		{
			super(s_namespace, s_typeName, s_featureId);
			color = 0x000000;
			
			mb_isSinglePointFeature = true;
			mb_isIconFeature = true;
			ma_types = [];
			initializeTypes();
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
			} else {
				
				
				var iconSprite: IconSprite;
				var reflection: FeatureDataReflection;
				var displaySprite: WFSFeatureEditableSprite;
				//create sprites for reflections
				
				var reflectionIDs: Array = m_featureData.reflectionsIDs;
				
				for (var i: int = 0; i < totalReflections; i++)
				{
					reflection = m_featureData.getReflectionAt(reflectionIDs[i]);
					if (reflection)
					{
						reflection.validate();
						displaySprite = getDisplaySpriteForReflectionAt(reflection.reflectionDelta);
						iconSprite = displaySprite as IconSprite;
						
						var pt: Point = Point(reflection.editablePoints[0]);
						if (pt)
						{
							if (!iconSprite.bitmapLoaded)
								iconSprite.setBitmap(m_loadedIconBitmapData, pt, color);
							
							iconSprite.update(color, pt);
						}
					}
				}
				
			}
		}
		
		override public function getDisplaySpriteForReflection(id:int):WFSFeatureEditableSprite
		{
			return new IconSprite(this);
		}
		
		private function onIconLoaded(mBitmap: Bitmap): void
		{
			if (mBitmap)
			{
				m_loadedIconBitmapData = mBitmap.bitmapData;

				var iconSprite: IconSprite;
				var reflection: FeatureDataReflection;
				var displaySprite: WFSFeatureEditableSprite;
				//create sprites for reflections
				
				var reflectionIDs: Array = m_featureData.reflectionsIDs;
				
				for (var i: int = 0; i < totalReflections; i++)
				{
					reflection = m_featureData.getReflectionAt(reflectionIDs[i]);
					if (reflection)
					{
						reflection.validate();
						displaySprite = getDisplaySpriteForReflectionAt(reflection.reflectionDelta);
						iconSprite = displaySprite as IconSprite;
						
						var pt: Point = Point(reflection.editablePoints[0]);
						
						iconSprite.points = [pt];
						iconSprite.setBitmap(m_loadedIconBitmapData, pt, color);
					}
					
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
		private function resolveTypeFromIconPath(path: String): String
		{
			var arr: Array = path.split('/');
			var iconName: String = arr[arr.length - 1];
			
			var retType: String = '';
			
			for each (var obj: IconTypeData in ma_types)
			{
				if (obj.icon == iconName)
				{
					retType = obj.type;
					break;
				}
			}
			
			return(retType);
		}
		
		private function initializeTypes(): void
		{
			ma_types.push( new IconTypeData( IconFeatureType.RAIN_STEADY, IconFeatureType.ICON_NAME_RAIN_STEADY ) );
			ma_types.push( new IconTypeData( IconFeatureType.RAIN_SHOWERS, IconFeatureType.ICON_NAME_RAIN_SHOWERS ) );
			ma_types.push( new IconTypeData( IconFeatureType.SNOW_STEADY, IconFeatureType.ICON_NAME_SNOW_STEADY ) );
			ma_types.push( new IconTypeData( IconFeatureType.SNOW_SHOWERS, IconFeatureType.ICON_NAME_SNOW_SHOWERS ) );
			ma_types.push( new IconTypeData( IconFeatureType.RASN_STEADY, IconFeatureType.ICON_NAME_RASN_STEADY ) );
			ma_types.push( new IconTypeData( IconFeatureType.RASN_SHOWERS, IconFeatureType.ICON_NAME_RASN_SHOWERS ) );
			ma_types.push( new IconTypeData( IconFeatureType.RAIN, IconFeatureType.ICON_NAME_RAIN_STEADY ) );
			ma_types.push( new IconTypeData( IconFeatureType.DRIZZLE, IconFeatureType.ICON_NAME_DRIZZLE ) );
			ma_types.push( new IconTypeData( IconFeatureType.PELLETS, IconFeatureType.ICON_NAME_PELLETS ) );
			ma_types.push( new IconTypeData( IconFeatureType.FOG, IconFeatureType.ICON_NAME_FOG ) );
			ma_types.push( new IconTypeData( IconFeatureType.HAZE, IconFeatureType.ICON_NAME_HAZE ) );
			ma_types.push( new IconTypeData( IconFeatureType.SMOKE, IconFeatureType.ICON_NAME_SMOKE ) );
			ma_types.push( new IconTypeData( IconFeatureType.BLOWING_DUST, IconFeatureType.ICON_NAME_BLOWING_DUST ) );
		}
		private function resolveIconName(): String
		{
			var retIconName: String = '';
			
			for each (var obj: IconTypeData in ma_types)
			{
				if (obj.type == type)
				{
					retIconName = obj.icon;
					break;
				}
			}
			
			return(retIconName);
		}
		
		override public function toInsertGML(xmlInsert: XML): void
		{
			super.toInsertGML(xmlInsert);
			
			addInsertGMLProperty(xmlInsert, null, "iconPath", "doc:global/macros/" + resolveIconFolder() + "/" + resolveIconName());
			
			var clrString: String = NumberUtils.encodeHTMLColorWithAlpha(color, 1);
			var scale: int = 1;
			var rotation: int = 0;
			
			xmlInsert.appendChild(
				<style xmlns={ms_namespace}>
					<color>{clrString}</color>
					<scale>{scale}</scale>
				</style>
				);
			xmlInsert.appendChild(
				<rotation>{rotation}</rotation>
				);
		}
		
		override public function toUpdateGML(xmlUpdate: XML): void
		{
			super.toUpdateGML(xmlUpdate);
			
			addUpdateGMLProperty(xmlUpdate, null, "iconPath", "doc:global/macros/" + resolveIconFolder() + "/" + resolveIconName());
			addUpdateGMLProperty(xmlUpdate, null, "style/color", NumberUtils.encodeHTMLColorWithAlpha(color, 1));
		}
		
		override public function fromGML(gml: XML): void
		{
			super.fromGML(gml);
			
			var ns: Namespace = new Namespace(ms_namespace);
			
			var iconPath: String = gml.ns::iconPath[0].toString();
			
			type = resolveTypeFromIconPath( iconPath );
			
			if (gml.ns::style)
			{
				var style: XMLList = gml.ns::style;
				if (style.ns::color)
				{
					var macroColor: XMLList = style.ns::color;
					var clr1: String = macroColor[0].text().toString();
					
					color = NumberUtils.decodeHTMLColor(String(clr1), color);
				}
			}
		}
	}
}

import com.iblsoft.flexiweather.ogc.editable.WFSFeatureEditable;
import com.iblsoft.flexiweather.ogc.editable.features.WFSFeatureEditableMacro;
import com.iblsoft.flexiweather.ogc.wfs.IWFSIconSprite;
import com.iblsoft.flexiweather.ogc.wfs.WFSFeatureEditableSprite;
import com.iblsoft.flexiweather.utils.ColorUtils;

import flash.display.Bitmap;
import flash.display.BitmapData;
import flash.geom.Point;

class IconTypeData
{
	public var type: String;
	public var icon: String;
	
	public function IconTypeData(sType: String, sIcon: String)
	{
		type = sType;
		icon = sIcon;
	}
}

class IconSprite extends WFSFeatureEditableSprite implements IWFSIconSprite
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
	
	public function setBitmap(nBitmapData: BitmapData, pt: Point, blackColor: uint = 0): void
	{
		mb_bitmapLoaded = true;
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
