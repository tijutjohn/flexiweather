package com.iblsoft.flexiweather.widgets
{
	import flash.events.MouseEvent;
	import flash.ui.Mouse;
	
	import spark.components.Image;
	
	[Event(name="click", type="flash.events.MouseEvent")]
	public class InteractiveLayerLegendImage extends Image
	{
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
			
		
	}
}