package com.iblsoft.flexiweather.ogc.editable.features
{
	import com.iblsoft.flexiweather.ogc.FeatureUpdateContext;
	import com.iblsoft.flexiweather.ogc.data.ReflectionData;
	import com.iblsoft.flexiweather.ogc.data.WFSEditableReflectionData;
	import com.iblsoft.flexiweather.ogc.editable.WFSFeatureEditableWithBaseTimeAndValidity;
	import com.iblsoft.flexiweather.ogc.wfs.IWFSFeatureWithReflection;
	import flash.geom.Point;
	import flash.text.TextFieldAutoSize;
	import mx.core.UITextField;

	public class WFSFeatureEditablePressureCentre extends WFSFeatureEditableWithBaseTimeAndValidity implements IWFSFeatureWithReflection
	{
		public var type: String;
		public var pressure: int;
		private var _pressureSprites: Array = [];

		public function WFSFeatureEditablePressureCentre(s_namespace: String, s_typeName: String, s_featureId: String)
		{
			super(s_namespace, s_typeName, s_featureId);
			type = PressureCentreType.LOW;
			pressure = 1000;
		}

		override public function update(changeFlag: FeatureUpdateContext): void
		{
			super.update(changeFlag);
			graphics.clear();
			var i_color: uint = 0;
			var i_colorSign: uint = 0;
			var i_colorCross: uint = 0;
			if (type == PressureCentreType.HIGH)
				i_colorSign = 0xC00000;
			else if (type == PressureCentreType.LOW)
				i_colorSign = 0x0000C0;
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
			var pressureInfoSprite: PressureInfoSprite;
			var reflection: WFSEditableReflectionData;
			//create sprites for reflections
			var totalReflections: uint = ml_movablePoints.totalReflections;
			for (var i: int = 0; i < totalReflections; i++)
			{
				reflection = ml_movablePoints.getReflection(i) as WFSEditableReflectionData;
				if (!reflection.displaySprite)
				{
					pressureInfoSprite = new PressureInfoSprite();
					reflection.displaySprite = pressureInfoSprite;
					addChild(reflection.displaySprite);
				}
				else
					pressureInfoSprite = reflection.displaySprite as PressureInfoSprite;
				var pt: Point = Point(reflection.points[0]);
				if ((type == PressureCentreType.HIGH) || (type == PressureCentreType.LOW))
				{
					pressureInfoSprite.update(s_colorSign, s_color, i_colorCross, type, pressure);
					pressureInfoSprite.x = Point(reflection.points[0]).x;
					pressureInfoSprite.y = Point(reflection.points[0]).y;
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
import flash.display.Sprite;
import flash.text.TextFieldAutoSize;
import mx.core.UITextField;

class PressureInfoSprite extends Sprite
{
	protected var mtf_presureType: UITextField = new UITextField();
	protected var mtf_presureValue: UITextField = new UITextField();

	public function PressureInfoSprite(): void
	{
		//mtf_presureType.border = true;
		mtf_presureType.autoSize = TextFieldAutoSize.LEFT;
		mtf_presureValue.autoSize = TextFieldAutoSize.LEFT;
		addChild(mtf_presureType);
		addChild(mtf_presureValue);
	}

	public function update(s_colorSign: String, s_color: String, i_colorCross: uint, type: String, pressure: int): void
	{
		graphics.lineStyle(1, i_colorCross);
		graphics.moveTo(-3, -3);
		graphics.lineTo(3, 3);
		graphics.moveTo(-3, 3);
		graphics.lineTo(3, -3);
		mtf_presureType.htmlText = '<FONT face="Verdana" size="20" color="#' + s_colorSign + '">' + type.charAt(0).toUpperCase() + '</FONT>';
		mtf_presureType.x = -(int(mtf_presureType.width / 2));
		mtf_presureType.y = -(int(mtf_presureType.height)) - 3;
		mtf_presureValue.htmlText = '<FONT face="Verdana" size="12" color="#' + s_color + '">' + pressure + '</FONT>';
		mtf_presureValue.x = -(int(mtf_presureValue.width / 2));
		mtf_presureValue.y = 5;
	}
}
