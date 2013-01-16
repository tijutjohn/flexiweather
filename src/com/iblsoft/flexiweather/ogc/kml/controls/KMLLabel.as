package com.iblsoft.flexiweather.ogc.kml.controls
{
	import com.iblsoft.flexiweather.ogc.kml.features.KMLFeature;
	import com.iblsoft.flexiweather.utils.anticollision.AnticollisionLayoutObject;
	import com.iblsoft.flexiweather.utils.anticollision.IAnticollisionLayoutObject;
	
	import flash.display.Sprite;
	import flash.filters.GlowFilter;
	import flash.text.TextField;
	import flash.text.TextFieldAutoSize;
	import flash.text.TextFormat;

	public class KMLLabel extends Sprite implements IAnticollisionLayoutObject
	{
		public static var labelFont: String = 'defaultFontMX';
		public static var allowLabelGlow: Boolean = true;
		public static var glow: GlowFilter;
		public var tempPosition: Number;
		public var reflection: uint;
		private var _anticollisionLayoutObject: AnticollisionLayoutObject;

		/**
		 * Reference to KML feature label belongs to 
		 */		
		public var kmlFeature: KMLFeature;
		
		public function set anticollisionLayoutObject(object: AnticollisionLayoutObject): void
		{
			_anticollisionLayoutObject = object;
		}

		public function get anticollisionLayoutObject(): AnticollisionLayoutObject
		{
			return _anticollisionLayoutObject;
		}

		override public function set visible(value: Boolean): void
		{
			super.visible = value;
			
//			trace(this + " visible: " + value);
//			if (reflection == 0)
//				trace("KMLLabel["+_id+"].visible = " + value);
		}

		override public function set x(value: Number): void
		{
			super.x = value;
		}

		override public function set y(value: Number): void
		{
			super.y = value;
		}
		private var _color: uint;
		private var _scale: Number;
		private var _txt: TextField;
		private var _text: String;

		public function get textfield(): TextField
		{
			return _txt;
		}

		public function get text(): String
		{
			return _text;
		}

		public function set text(value: String): void
		{
			_text = value;
			updateLabel();
		}
		private static var uid: int = 0;
		private var _id: int;

		public function get id(): int
		{
			return _id;
		}

		public function KMLLabel(feature: KMLFeature)
		{
			super();
			_id = ++uid;
			
			kmlFeature = feature;
			
			mouseChildren = false;
			mouseEnabled = false;
			_scale = 1;
			_color = 0xffffff;
			createLabel();
		}

		public function cleanup(): void
		{
			if (_txt)
			{
				removeChild(_txt);
				_txt = null;
			}
		}

		public function invalidate(): void
		{
			_text = '';
			if (_txt)
				_txt.text = '';
			updateTextFormat();
		}

		private function updateLabel(): void
		{
			if (!_txt)
				createLabel();
			var labelText: String = _text;
			if (!labelText)
				labelText = '';
			_txt.autoSize = TextFieldAutoSize.LEFT;
			_txt.text = labelText;
			updateTextFormat();
		}

		private function createLabel(): void
		{
			if (!glow)
				glow = new GlowFilter(0, 1, 4, 4);
			_txt = new TextField();
			_txt.selectable = false;
			updateTextFormat();
			addChild(_txt);
			_txt.filters = [glow];
		}

		public function updateLabelProperties(color: uint, colorAlpha: Number, scale: Number = 1): void
		{
			if (isNaN(scale))
				scale = 1;
			alpha = colorAlpha;
			_color = color;
			_scale = scale;
			updateLabel();
		}

		private function updateTextFormat(): void
		{
			if (_txt)
			{
				_txt.border = false;
				var format: TextFormat = _txt.getTextFormat();
				format.color = _color;
				format.size = int(20 * _scale)
				format.bold = true;
				format.font = labelFont;
				_txt.embedFonts = true;
				_txt.setTextFormat(format);
			}
		}
		
		override public function toString(): String
		{
			return "KMLLabel ["+_id+"/"+text+"]: ";
		}
	}
}
