package com.iblsoft.flexiweather.ogc.kml.controls
{
	import flash.display.Sprite;
	import flash.filters.GlowFilter;
	import flash.text.TextField;
	import flash.text.TextFieldAutoSize;
	import flash.text.TextFormat;
	
	
	public class KMLLabel extends Sprite
	{
		public static var allowLabelGlow: Boolean = true;
		public static var glow: GlowFilter;
		
		public var reflection: uint;
		
		override public function set visible(value:Boolean):void
		{
			super.visible = value;
//			if (reflection == 0)
//				trace("KMLLabel["+_id+"].visible = " + value);
		}
		override public function set x(value:Number):void
		{
			super.x = value;
//			if (reflection == 0)
//				trace("KMLLabel["+_id+"].x = " + value);
		}
		override public function set y(value:Number):void
		{
			super.y = value;
//			if (reflection == 0)
//				trace("KMLLabel["+_id+"].y = " + value);
		}
		
		private var _color: uint;
		private var _scale: Number;
		
		private var _txt: TextField;
		
		private var _text: String;
		public function get text():String
		{
			return _text;
		}

		public function set text(value:String):void
		{
			_text = value;
			updateLabel();
		}
		
		private static var uid: int =  0;
		private var  _id: int;
		public function KMLLabel()
		{
			super();
			
			_id = ++uid;
//			trace("new KMLLabel["+_id+"]");
			mouseChildren = false;
			mouseEnabled = false;
			
			_scale = 1;
			_color = 0xffffff;
			
			createLabel();
		}
		
		public function cleanup(): void
		{
			removeChild(_txt);
			_txt = null;
		}
		
		private function updateLabel(): void
		{
			if (!_txt)
				createLabel();
			
			var labelText: String = _text;
			if (!labelText)
			{
				labelText = '';
			}
			
			_txt.autoSize = TextFieldAutoSize.LEFT;
			_txt.text = labelText;
			updateTextFormat();	
			
		}


		private function createLabel(): void
		{
			if (!glow)
			{
				glow = new GlowFilter(0,1,4,4);
			}
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
				format.size = int (14 * _scale)
				format.bold = true;
				_txt.setTextFormat(format);
			}
			
		}
	}
}