package com.iblsoft.flexiweather.ogc.kml.features
{
	import flash.display.Sprite;
	import flash.text.TextField;
	import flash.text.TextFieldAutoSize;
	import flash.text.TextFormat;
	
	public class KMLLabel extends Sprite
	{
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
		
		
		public function KMLLabel()
		{
			super();
			mouseChildren = false;
			mouseEnabled = false;
			createLabel();
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
			
//			var format: TextFormat = _txt.getTextFormat();
			_txt.autoSize = TextFieldAutoSize.LEFT;
			_txt.text = labelText;
			
			
		}


		private function createLabel(): void
		{
			_txt = new TextField();	
			_txt.selectable = false;
			addChild(_txt);
		}
	}
}