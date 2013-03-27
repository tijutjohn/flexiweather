package com.iblsoft.flexiweather.widgets
{
	import flash.display.Bitmap;
	import flash.events.MouseEvent;
	import flash.ui.Mouse;
	
	import spark.components.Image;
	
	[Event(name="click", type="flash.events.MouseEvent")]
	public class InteractiveLayerLegendImage extends Image
	{
		public var title: String;
		public var originalWidth: int;
		public var originalHeight: int;
		
		override public function set enabled(value: Boolean): void
		{
			super.enabled = value;	
		}
		
		override public function set mouseEnabled(value:Boolean):void
		{
			super.mouseEnabled = value;	
		}
		
		public function get isScaled(): Boolean
		{
			if (originalWidth != width || originalHeight != height)
				return true;
			
			return false;
		}
		public function InteractiveLayerLegendImage()
		{
			super();
			addEventListener(MouseEvent.CLICK, onMouseClick);
		}
		
		private function onMouseClick(event: MouseEvent): void
		{
		}
		
		public function clone(): InteractiveLayerLegendImage
		{
			var source: Bitmap = this.source as Bitmap;
			
			if (source)
			{
				var image: InteractiveLayerLegendImage = new InteractiveLayerLegendImage();
				image.source = new Bitmap(source.bitmapData.clone());
				image.originalWidth = originalWidth;
				image.originalHeight = originalHeight;
				image.title = title;
				return image;
			}
			return this;
		}
			
		
	}
}