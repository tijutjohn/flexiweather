package com.iblsoft.flexiweather.widgets
{
	import flash.display.Bitmap;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.ui.Mouse;
	
	import spark.components.Image;
	
	[Event(name="click", type="flash.events.MouseEvent")]
	public class InteractiveLayerLegendImage extends Image
	{
		public static var _uid: int = 0;
		public var legendID: int = 0;
		
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
			
			legendID = _uid++;
			addEventListener(Event.ADDED_TO_STAGE, onAddedToStage);
			addEventListener(Event.REMOVED_FROM_STAGE, onRemovedFromStage);
			addEventListener(MouseEvent.CLICK, onMouseClick);
		}
		
		private function onAddedToStage(event: Event): void
		{
			trace("LegendImage ["+legendID+"] onAddedToStage");
		}
		private function onRemovedFromStage(event: Event): void
		{
			trace("LegendImage ["+legendID+"] onRemovedFromStage");
		}
		
		private function onMouseClick(event: MouseEvent): void
		{
			trace("legend click");
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
		
		override public function toString(): String
		{
			return "InteractiveLayerLegendImage: " + legendID;
		}
			
		
	}
}