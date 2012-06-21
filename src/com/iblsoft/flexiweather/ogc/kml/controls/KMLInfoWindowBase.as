package com.iblsoft.flexiweather.ogc.kml.controls
{
	import com.iblsoft.flexiweather.ogc.kml.features.KMLFeature;
	import com.iblsoft.flexiweather.ogc.kml.managers.KMLPopupManager;
	import com.iblsoft.flexiweather.utils.HTMLUtils;
	
	import flash.events.Event;
	
	import mx.managers.PopUpManager;
	
	import spark.components.TextArea;
	import spark.components.TitleWindow;
	
	public class KMLInfoWindowBase extends TitleWindow
	{
		public var textArea: TextArea;
		
		private var _feature: KMLFeature;
		
		override public function set y(value:Number):void
		{
			super.y = value;
			trace("KMLInfoWindow y: " + value);
		}
		override public function set visible(value:Boolean):void
		{
			super.visible = value;
			trace("KMLInfoWindow visible: " + value);
		}
		
		[Bindable]
		public function get feature():KMLFeature
		{
			return _feature;
		}

		public function set feature(value:KMLFeature):void
		{
			_feature = value;
			invalidateProperties();
		}

		[Bindable (event="refresh")]
		public function get borderPath(): String
		{
			return createBorderPath();
		}
		[Bindable (event="refresh")]
		public function get arrowPath(): String
		{
			return createArrowPath();
		}
		[Bindable (event="refresh")]
		public function get arrowBorderPath(): String
		{
			return createArrowBorderPath();
		}
		[Bindable (event="refresh")]
		public function get arrowWidth(): int
		{
			return 50;
		}
		
		[Bindable (event="refresh")]
		public function get arrowHeight(): int
		{
			return 50;
		}
		
		[Bindable (event="refresh")]
		public function get arrowX(): int
		{
			return width / 2;
		}
		
		[Bindable (event="refresh")]
		public function get arrowY(): int
		{
			return height;
		}
		
		/**
		 * X coordinate of arrow pointer 
		 */		
		[Bindable (event="refresh")]
		public function get arrowPointerX(): int
		{
			var arrWHalf: int = arrowWidth / 2;
			var arrPointer: int = - arrowWidth - arrWHalf;
			if (contentGroup)
				arrPointer += contentGroup.width / 2;
			return arrPointer;
		}
		
		public function KMLInfoWindowBase()
		{
			super();
		}
		
		override protected function commitProperties():void
		{
			super.commitProperties();
		
			if (_feature)
			{
				updateHTMLText(_feature.description);				
			}
		}
		
		private function updateHTMLText(txt: String): void
		{
			textArea.textFlow = HTMLUtils.createHTMLTextFlow(txt);
		}
		
		private var _waitForSize: Boolean;
		private function createBorderPath(): String
		{
			trace("KIW cbt ["+id+"] size ["+width+","+height+"]");
			if (!contentGroup || (contentGroup.width == 00 && contentGroup.height == 0))
			{
				_waitForSize = true;
				callLater(createBorderPath);
				return "";
			}
			var arrLeft: int = arrowX - arrowWidth / 2;
			var arrRight: int = arrLeft + arrowWidth;
			var arrRightParth: int = width - arrRight;
			
			var w: int = contentGroup.width// + 2;
			var h: int = contentGroup.height - 2;
			var path: String = "m 0 0 l " + w + " 0 l 0 " + h + " l " + (-1 * arrRightParth)+ " 0 m " + (-1 * arrowWidth) + " 0 l " + (-1 * arrLeft) +" 0 l 0 " + (-1 * h);
			
			trace("KIW border path ["+id+"] => " + path);
			if (_waitForSize)
			{
				_waitForSize = false;
				notify();
			}
			return path;
		}
		private function createArrowPath(): String
		{
			
			var arrWHalf: int = arrowWidth / 2;
			var path: String = "m 0 0 l " + (-1 * arrowWidth) + " " + arrowHeight + " l " + (2 * arrowWidth) + " " + (-1 * arrowHeight) + " l " + (-1 * arrowWidth)+ " 0";
			return path;
		}
		private function createArrowBorderPath(): String
		{
			var arrWHalf: int = arrowWidth / 2;
			var path: String = "m 0 0 l " + (-1 * arrowWidth) + " " + arrowHeight + " l " + (2 * arrowWidth) + " " + (-1 * arrowHeight);
			return path;
		}
		
		private function notify(): void
		{
			dispatchEvent(new Event("refresh"));
		}
		
		protected function close(): void
		{
			KMLPopupManager.getInstance().removePopUp(this);
		}
	}
}