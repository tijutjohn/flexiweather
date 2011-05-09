package com.iblsoft.flexiweather.utils
{
	import flash.display.Sprite;
	
	public class AnnotationBox extends Sprite
	{
		public var measuredWidth: Number = 0;
		public var measuredHeight: Number = 0;
		
		public function AnnotationBox()
		{
			super();
			mouseEnabled = false;
			mouseChildren = false;
		}
		
		public function update(): void
		{
			meassureContent();
			graphics.clear();
			graphics.beginFill(0xFFFFFF, 1);
			graphics.lineStyle(1, 0, 1);
			graphics.drawRect(0, 0, measuredWidth, measuredHeight);
			graphics.endFill();
			updateContent();
		}
		
		public function meassureContent(): void
		{
		}
		
		public function updateContent(): void
		{
		}
	}
}