package com.iblsoft.flexiweather.ogc.editable.features
{
	import com.iblsoft.flexiweather.ogc.FeatureUpdateContext;
	import com.iblsoft.flexiweather.ogc.data.ReflectionData;
	import com.iblsoft.flexiweather.ogc.editable.WFSFeatureEditableWithBaseTimeAndValidity;
	import com.iblsoft.flexiweather.ogc.editable.data.FeatureDataPoint;
	import com.iblsoft.flexiweather.ogc.editable.data.FeatureDataReflection;
	import com.iblsoft.flexiweather.ogc.wfs.WFSFeatureEditableSprite;
	
	import flash.geom.Point;
	import flash.text.TextFieldAutoSize;
	import flash.text.TextFormat;
	
	import mx.core.UITextField;
	
	public class WFSFeatureEditableTropopause extends WFSFeatureEditableWithBaseTimeAndValidity
	{
		public static const TYPE_TROPOPAUSE: String = 'NotDefined';
		public static const TYPE_TROPOPAUSE_LOW: String = 'Low';
		public static const TYPE_TROPOPAUSE_HIGH: String = 'High';
		
		private var _type: String;

		public function get type():String
		{
			return _type;
		}

		public function set type(value:String):void
		{
			_type = value;
		}

		public var level: int;
		
		public function WFSFeatureEditableTropopause(s_namespace:String, s_typeName:String, s_featureId:String)
		{
			super(s_namespace, s_typeName, s_featureId);
			
		}
		
		override public function update(changeFlag: FeatureUpdateContext): void
		{
			super.update(changeFlag);
			var i_color: uint = getCurrentColor(0x000000);
			var s_color: String = '000000';
			
			var lvlString:String = level.toString();
			if (level < 10)
				lvlString = '00'+level;
			else if (level < 100)
				lvlString = '0'+level;
			
			var tropopauseSprite: TropopauseSprite;
			var reflection: FeatureDataReflection;
			
			//create sprites for reflections
			
			var blackColor: uint = getCurrentColor(0x000000);
			for (var i: int = 0; i < totalReflections; i++)
			{
				reflection = m_featureData.getReflectionAt(i);
				if (reflection)
				{
					var reflectionDelta: int = reflection.reflectionDelta;
					reflection.validate();
					
					tropopauseSprite = getDisplaySpriteForReflectionAt(reflectionDelta) as TropopauseSprite;
					tropopauseSprite.update(type, lvlString, i_color, s_color, blackColor);
					
					var fdpt: FeatureDataPoint = FeatureDataPoint(reflection.editablePoints[0]);
					if (fdpt)
					{
						tropopauseSprite.x = fdpt.x;
						tropopauseSprite.y = fdpt.y;
					}
				}
			}
			
			
		}	
		
		override public function getDisplaySpriteForReflection(id: int): WFSFeatureEditableSprite
		{
			return new TropopauseSprite(this); 
		}
		
		override public function toInsertGML(xmlInsert: XML): void
		{
			var gml: Namespace = new Namespace("http://www.opengis.net/gml");
			super.toInsertGML(xmlInsert);
			addInsertGMLProperty(xmlInsert, null, "type", type);
			addInsertGMLProperty(xmlInsert, null, "height", level);
		}

		override public function toUpdateGML(xmlUpdate: XML): void
		{
			super.toUpdateGML(xmlUpdate);
			addUpdateGMLProperty(xmlUpdate, null, "type", type);
			addUpdateGMLProperty(xmlUpdate, null, "height", level);
		}

		override public function fromGML(gml: XML): void
		{
			super.fromGML(gml);
			var ns: Namespace = new Namespace(ms_namespace);
			type = gml.ns::type[0];
			level = gml.ns::height[0];
		}
		
		public function getType(): String
		{
			return(type);
		}
	}
}

import com.iblsoft.flexiweather.ogc.editable.WFSFeatureEditable;
import com.iblsoft.flexiweather.ogc.editable.features.WFSFeatureEditableTropopause;
import com.iblsoft.flexiweather.ogc.wfs.WFSFeatureEditableSprite;

import flash.display.Sprite;
import flash.text.TextField;
import flash.text.TextFieldAutoSize;
import flash.text.TextFormat;

import mx.core.UITextField;

class TropopauseSprite extends WFSFeatureEditableSprite {
	
	protected var mtf_tropopauseType: TextField = new TextField();
	protected var mtf_tropopauseValue: TextField = new TextField();
	
	
	public function TropopauseSprite(feature: WFSFeatureEditable): void
	{
		super(feature);
		
		//mtf_presureType.border = true;
		mtf_tropopauseType.autoSize = TextFieldAutoSize.LEFT;
		mtf_tropopauseValue.autoSize = TextFieldAutoSize.LEFT;
		addChild(mtf_tropopauseType);
		addChild(mtf_tropopauseValue);	
		
		
	}
	
	private function updateTextfield(txt: TextField, value: String, size: int, s_color: String = null): void
	{
		var html: String = '<FONT face="Verdana" size="'+size.toString()+'"';
		if (s_color)
			html += ' color="#'+s_color+ '">';
		else 
			html += '>';
		
		html += value +"</FONT>";

		txt.htmlText = html;
		
//		txt.text = value;
	}
	public function update(type: String, lvlString: String, i_color: uint, s_color: String, blackColor: uint): void
	{
		updateTextfield(mtf_tropopauseValue, lvlString, 12);
//		mtf_tropopauseValue.validateNow();
		
		var w: int = int(mtf_tropopauseValue.textWidth) + 3;
		var h: int = int(mtf_tropopauseValue.textHeight) + 2;
		var left: int = - int(mtf_tropopauseValue.textWidth/2);
		var top: int = - int(mtf_tropopauseValue.textHeight/2);
		
		mtf_tropopauseValue.x = left;
		mtf_tropopauseValue.y = top;
		
		
		mtf_tropopauseValue.visible = true;
		mtf_tropopauseType.visible = true;
		
		graphics.clear();
		graphics.beginFill(0xffffff);
		graphics.lineStyle(1, i_color);
		switch (type)
		{
			case WFSFeatureEditableTropopause.TYPE_TROPOPAUSE:
				graphics.drawRect(left, top, w, h);
				mtf_tropopauseType.visible = false;
				
				break;
			case WFSFeatureEditableTropopause.TYPE_TROPOPAUSE_LOW:
				
				//					mtf_tropopauseType.htmlText = '<FONT face="Verdana" size="12" color="#' + s_color + '">L</FONT>';
				updateTextfield(mtf_tropopauseType, "L", 12);
//				mtf_tropopauseType.validateNow();
				
				mtf_tropopauseType.y = (int(mtf_tropopauseValue.textHeight / 2)) - 1;
				graphics.moveTo(left, top);
				graphics.lineTo(left, top + h);
				//bottom triangle
				graphics.lineTo(left + w / 2 + 1, top + h + int(mtf_tropopauseType.textHeight) + 2);
				
				graphics.lineTo(left + w, top + h);
				graphics.lineTo(left + w, top);
				graphics.lineTo(left, top);
				
				break;
			case WFSFeatureEditableTropopause.TYPE_TROPOPAUSE_HIGH:
				
				updateTextfield(mtf_tropopauseType, "H", 12, s_color);
//				mtf_tropopauseType.validateNow();
				
				mtf_tropopauseType.y = - (int(mtf_tropopauseValue.textHeight / 2)) - mtf_tropopauseType.textHeight + 1;
				
				graphics.moveTo(left, top);
				graphics.lineTo(left, top + h);
				graphics.lineTo(left + w, top + h);
				graphics.lineTo(left + w, top);
				//top triangle
				graphics.lineTo(left + w / 2 + 1, top - int(mtf_tropopauseType.textHeight));
				graphics.lineTo(left, top);
				break;
		}
		graphics.endFill();
		mtf_tropopauseType.x = - (int(mtf_tropopauseType.textWidth / 2));
		
		i_color = blackColor;
		
		var format: TextFormat = mtf_tropopauseType.getTextFormat();
		format.color = i_color;
		mtf_tropopauseType.setTextFormat(format);
		
		format = mtf_tropopauseValue.getTextFormat();
		format.color = i_color;
		mtf_tropopauseValue.setTextFormat(format);
	}
}