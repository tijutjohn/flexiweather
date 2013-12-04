package com.iblsoft.flexiweather.utils
{
	import com.iblsoft.flexiweather.utils.anticollision.AnticollisionLayoutObject;
	import com.iblsoft.flexiweather.utils.anticollision.IAnticollisionLayoutObject;
	
	import flash.display.Sprite;
	import flash.text.TextField;
	import flash.text.TextFormat;

	public class AnnotationBox extends Sprite implements IAnticollisionLayoutObject
	{
		public var measuredWidth: Number = 0;
		public var measuredHeight: Number = 0;
		private var _color: uint;

		private var _anticollisionLayoutObject: AnticollisionLayoutObject;
		
		public function AnnotationBox()
		{
			super();
			mouseEnabled = false;
			mouseChildren = false;
		}

		public function set anticollisionLayoutObject(object: AnticollisionLayoutObject): void
		{
			_anticollisionLayoutObject = object;
		}
		
		public function get anticollisionLayoutObject(): AnticollisionLayoutObject
		{
			return _anticollisionLayoutObject;
		}
		
		public function get color(): uint
		{
			return _color;
		}

		public function set color(value: uint): void
		{
			_color = value;
		}

		protected function updateLabelColor(lbl: TextField, clr: uint): void
		{
			var format: TextFormat = lbl.getTextFormat();
			format.color = clr;
			lbl.setTextFormat(format);
		}

		public function update(): void
		{
			measureContent();
			graphics.clear();
			graphics.beginFill(0xFFFFFF, 1);
			graphics.lineStyle(1, color, 1);
			graphics.drawRect(0, 0, measuredWidth, measuredHeight);
			graphics.endFill();
			updateContent();
		}

		public function measureContent(): void
		{
		}

		public function updateContent(): void
		{
		}
	}
}
