package com.iblsoft.flexiweather.ogc.kml.controls
{
	import com.iblsoft.flexiweather.ogc.kml.controls.skins.KMLInfoWindowBottomCenterSkin;
	import com.iblsoft.flexiweather.ogc.kml.controls.skins.KMLInfoWindowTopCenterSkin;
	import com.iblsoft.flexiweather.ogc.kml.features.KMLFeature;
	import com.iblsoft.flexiweather.ogc.kml.managers.KMLPopupManager;
	import com.iblsoft.flexiweather.utils.HTMLUtils;
	
	import flash.events.Event;
	import flash.geom.Rectangle;
	
	import mx.core.IVisualElement;
	import mx.managers.PopUpManager;
	
	import spark.components.TextArea;
	import spark.components.TitleWindow;

	public class KMLInfoWindowBase extends TitleWindow
	{
		override public function set y(value:Number):void
		{
			super.y = value;
			trace("KMLInfoWindow y = "+ value);
		}
		override public function get width():Number
		{
			return super.width;
		}
		override public function set width(value:Number):void
		{
			super.width = value;
			trace("Change width of kml info window");
		}
		public var textArea: TextArea;
		private var _feature: KMLFeature;

		private var _waitForSize: Boolean;
		
		[Bindable]
		public var contentBottom: int = 50;
		[Bindable]
		public var contentTop: int = 50;
		
		[Bindable]
		public var arrowTop: int = 50;
		[Bindable]
		public var arrowBottom: int = 0;
		[Bindable]
		public var arrowLeft: int = 0;
		[Bindable]
		public var arrowRight: int = 0;
		
		override public function set visible(value: Boolean): void
		{
			super.visible = value;
		}

		[Bindable]
		public function get feature(): KMLFeature
		{
			return _feature;
		}

		public function set feature(value: KMLFeature): void
		{
			_feature = value;
			invalidateProperties();
		}

		[Bindable(event = "refresh")]
		public function get borderPath(): String
		{
			return createBorderPath();
		}

		[Bindable(event = "refresh")]
		public function get arrowPath(): String
		{
			return createArrowPath();
		}

		[Bindable(event = "refresh")]
		public function get arrowBorderPath(): String
		{
			return createArrowBorderPath();
		}

		[Bindable(event = "refresh")]
		public function get arrowWidth(): int
		{
			return 50;
		}

		[Bindable(event = "refresh")]
		public function get arrowHeight(): int
		{
			return 50;
		}

		[Bindable(event = "refresh")]
		public function get arrowX(): int
		{
			var position: Number;
			
			switch(_arrowPosition)
			{
				case KMLInfoWindowArrowPosition.BOTTOM_LEFT:
				case KMLInfoWindowArrowPosition.TOP_LEFT:
					position = 0;
					break;
				case KMLInfoWindowArrowPosition.BOTTOM_CENTER:
				case KMLInfoWindowArrowPosition.TOP_CENTER:
					position = width / 2 - arrowWidth / 2;
					break;
				case KMLInfoWindowArrowPosition.BOTTOM_RIGHT:
				case KMLInfoWindowArrowPosition.TOP_RIGHT:
					position = width - arrowWidth;
//					trace("arrowX3: " + position + " w: " + width);
					break;
			}
			return position;
		}

		[Bindable(event = "refresh")]
		public function get arrowY(): int
		{
			var position: Number;
			
			switch(_arrowPosition)
			{
				case KMLInfoWindowArrowPosition.TOP_LEFT:
				case KMLInfoWindowArrowPosition.TOP_CENTER:
				case KMLInfoWindowArrowPosition.TOP_RIGHT:
					position = 0;
					break;
				case KMLInfoWindowArrowPosition.BOTTOM_LEFT:
				case KMLInfoWindowArrowPosition.BOTTOM_CENTER:
				case KMLInfoWindowArrowPosition.BOTTOM_RIGHT:
					position = height - arrowHeight
					break;
			}
//			trace("arrowY: " + position);
			return position;
		}

		/**
		 * X coordinate of arrow pointer
		 */
		[Bindable(event = "refresh")]
		public function get arrowPointerX(): int
		{
			return getArrowPointerXPosition(_arrowPosition);
		}
		
		/**
		 * X coordinate of arrow pointer
		 */
		[Bindable(event = "refresh")]
		public function get arrowPointerY(): int
		{
			return getArrowPointerYPosition(_arrowPosition);	
		}

		private var _arrowPosition: String;
		private var _arrowPositionChanged: Boolean;
		
		[Bindable(event = "refresh")]
		public function get arrowPosition():String
		{
			return _arrowPosition;
		}
		
		public function set arrowPosition(value:String):void
		{
			if (_arrowPosition != value)
			{
				_arrowPosition = value;
				_arrowPositionChanged = true;
				invalidateProperties();
			}
		}
		
		public function KMLInfoWindowBase()
		{
			super();
			
			arrowPosition = KMLInfoWindowArrowPosition.BOTTOM_CENTER;
			setStyle('skinClass', KMLInfoWindowBottomCenterSkin);
		}

		override protected function partAdded(partName:String, instance:Object):void
		{
			super.partAdded(partName, instance);
			
			if (instance == contentGroup)
			{
				
			}
		}
		
		override protected function measure():void
		{
			var oldMeasuredWidth: Number = measuredWidth;
			
			super.measure();
			
			//WORKAROUND
			if (!isNaN(oldMeasuredWidth) && (oldMeasuredWidth + 1 == measuredWidth))
			{
				measuredWidth = oldMeasuredWidth;	
			}
			
		}

		
		override protected function commitProperties(): void
		{
			if (!_arrowPositionChanged)
			{
				switch(_arrowPosition)
				{
					case KMLInfoWindowArrowPosition.TOP_LEFT:
					case KMLInfoWindowArrowPosition.TOP_CENTER:
					case KMLInfoWindowArrowPosition.TOP_RIGHT:
						trace("test reinvalidation");
						break;
				}
			}
			super.commitProperties();
			
			var reinvalidatePropertiesForNewSkin: Boolean = false;
			
			if (_arrowPositionChanged)
			{
				trace("KMLInfo _arrowPositionChanged _arrowPosition: " + _arrowPosition + " h: " + height);
				switch(_arrowPosition)
				{
					case KMLInfoWindowArrowPosition.TOP_LEFT:
					case KMLInfoWindowArrowPosition.TOP_CENTER:
					case KMLInfoWindowArrowPosition.TOP_RIGHT:
						setStyle('skinClass', KMLInfoWindowTopCenterSkin);
						reinvalidatePropertiesForNewSkin = true;
						break;
					default:
					case KMLInfoWindowArrowPosition.BOTTOM_LEFT:
					case KMLInfoWindowArrowPosition.BOTTOM_CENTER:
					case KMLInfoWindowArrowPosition.BOTTOM_RIGHT:
						setStyle('skinClass', KMLInfoWindowBottomCenterSkin);
						reinvalidatePropertiesForNewSkin = true;
						break;
				}
				_arrowPositionChanged = false;
				notify();
			}
			if (_feature)
				updateHTMLText(_feature.description);
			
			if (reinvalidatePropertiesForNewSkin)
				validateProperties();
		}

		private function updateHTMLText(txt: String): void
		{
			textArea.textFlow = HTMLUtils.createHTMLTextFlow(txt);
		}
		
		public function getBoundsForPosition(x: Number, y: Number, direction: String): Rectangle
		{
			var arrX: Number = getArrowPointerXPosition(direction);
			var arrY: Number = getArrowPointerYPosition(direction);
			
			var bounds: Rectangle = new Rectangle(x - arrX, y - arrY, width, height);
			
//			trace("getBoundsForPosition ["+x+","+y+"] direction: " + direction + " => " + bounds + " arr: ["+arrX+","+arrY+"]");
			return bounds;
		}

		private function createBorderPath(): String
		{
			var path: String;
			if (contentGroup == null || (contentGroup.width == 0 && contentGroup.height == 0))
			{
				_waitForSize = true;
				callLater(createBorderPath);
				return null;
			}
			
//			var arrLeft: Number = arrowX - arrowWidth / 2;
//			var arrRight: Number = arrLeft + arrowWidth;
//			var arrRightParth: Number = width - arrRight;
			var wArrowHalf: Number = width/2 - arrowWidth/2;
			var wArrowHalf2: Number = width/2 + arrowWidth/2;
			
			var w: Number = contentGroup.width // + 2;
			var h: Number = contentGroup.height;
			
			var borderForTops: String = " V " + h + " H 0 V 0";
			var borderForBottoms: String = "M 0 " + h + " V 0 H " + w + " V " + h;
			switch(_arrowPosition)
			{
				case KMLInfoWindowArrowPosition.TOP_LEFT:
					path = "M 0 0 M " + arrowWidth + " 0 L " + w + " 0" + borderForTops;
					break;
				case KMLInfoWindowArrowPosition.TOP_CENTER:
					path = "M 0 0 L " + wArrowHalf + " 0 M " + wArrowHalf2 + " 0 L " + w + " 0" + borderForTops;
					break;
				case KMLInfoWindowArrowPosition.TOP_RIGHT:
					path = "M 0 0 H " + (w - arrowWidth) + " M " + w + " 0" + borderForTops;
					break;
				
				
				case KMLInfoWindowArrowPosition.BOTTOM_LEFT:
					path = borderForBottoms + " H " + arrowWidth// + " M " + wArrowHalf + " " + h + " L 0 " + h + " Z";
					break;
				case KMLInfoWindowArrowPosition.BOTTOM_RIGHT:
					path = borderForBottoms + " M " + (w - arrowWidth) + " " + h + " H 0";
					break;
				default:
				case KMLInfoWindowArrowPosition.BOTTOM_CENTER:
					path = borderForBottoms + " L " + wArrowHalf2 + " " + h + " M " + wArrowHalf + " " + h + " L 0 " + h + " Z";
					break;
			}
			
//			trace("createBorderPath _arrowPosition: " + _arrowPosition + " path: " + path);
			
			if (_waitForSize)
			{
				_waitForSize = false;
				notify();
			}
			return path;
		}

		private function createArrowPath(): String
		{
			var path: String;
//			var arrWHalf: int = arrowWidth / 2;
			path = createArrowBorderPath() + " Z";
			
//			trace("createArrowPath _arrowPosition: " + _arrowPosition + " path: " + path);
			return path;
		}

		
		private function createArrowBorderPath(): String
		{
			/*
			 
			
			
			Move				M/m	x y			M 10 20 - Move line to 10, 20.
			Line				L/l	x y			L 50 30 - Line to 50, 30.
			HorizontaL line		H/h	x			H 40 = HorizontaL line to 40.
			VerticaL line		V/v	y			V 100 - VerticaL line to 100.
			QuadraticBezier		Q/q	controlX controlY x y	Q 110 45 90 30 - Curve to 90, 30 with the controL point at 110, 45.
			CubicBezier			C/c	control1X control1Y control2X control2Y x y	C 45 50 20 30 10 20 - Curve to 10, 20 with the first controL point at 45, 50 and the second controL point at 20, 30.
			Close path			Z/z	n/a	Closes off the path.
			
			*/
			
			var path: String;
			var arrWHalf: int = arrowWidth / 2;
			
			switch(_arrowPosition)
			{
				case KMLInfoWindowArrowPosition.TOP_LEFT:
					path = "M 0 " + arrowHeight + " L 0 0 L " + arrowWidth + " " + arrowHeight;
					break;
				case KMLInfoWindowArrowPosition.TOP_CENTER:
					path = "M 0 " + arrowHeight + " L " +  arrWHalf + " 0 L " +  arrowWidth+ " " + arrowHeight;
					break;
				case KMLInfoWindowArrowPosition.TOP_RIGHT:
					path = "M 0 " + arrowHeight + " L " + arrowWidth +" 0 L " + arrowWidth + " " + arrowHeight;
					break;
				
				
				case KMLInfoWindowArrowPosition.BOTTOM_LEFT:
					path = "M 0 0 L 0 " + arrowHeight + " L " + arrowWidth + " 0";
					break;
				case KMLInfoWindowArrowPosition.BOTTOM_RIGHT:
					path = "M 0 0 L " + arrowWidth + " " + arrowHeight + " L " + arrowWidth + " 0";
					break;
				default:
				case KMLInfoWindowArrowPosition.BOTTOM_CENTER:
					path = "M 0 0 L " + arrWHalf + " " + (arrowHeight) + " L " + arrowWidth + " 0"
					break;
			}
			
			
//			trace("createArrowBorderPath _arrowPosition: " + _arrowPosition + " path: " + path);
			return path;
		}

		
		private function getArrowPointerXPosition(direction: String): Number
		{
			var arrWHalf: int = arrowWidth / 2;
			var arrPointer: int;
			
			switch(direction)
			{
				case KMLInfoWindowArrowPosition.TOP_LEFT:
				case KMLInfoWindowArrowPosition.BOTTOM_LEFT:
					arrPointer = 0
					break;
				case KMLInfoWindowArrowPosition.TOP_RIGHT:
				case KMLInfoWindowArrowPosition.BOTTOM_RIGHT:
					arrPointer = width;
					break;
				default:
				case KMLInfoWindowArrowPosition.TOP_CENTER:
				case KMLInfoWindowArrowPosition.BOTTOM_CENTER:
					arrPointer = width/2//  - arrWHalf;
					break;
			}
			
			return arrPointer;
		}
		
		private function getArrowPointerYPosition(direction: String): Number
		{
			var arrWHalf: int = arrowWidth / 2;
			var arrPointer: int;
			
			switch(direction)
			{
				case KMLInfoWindowArrowPosition.TOP_CENTER:
				case KMLInfoWindowArrowPosition.TOP_LEFT:
				case KMLInfoWindowArrowPosition.TOP_RIGHT:
					arrPointer = 0
					break;
				default:
				case KMLInfoWindowArrowPosition.BOTTOM_LEFT:
				case KMLInfoWindowArrowPosition.BOTTOM_RIGHT:
				case KMLInfoWindowArrowPosition.BOTTOM_CENTER:
					arrPointer = arrowHeight;
					if (contentGroup)
						arrPointer += contentGroup.height;
					break;
			}
			
			return arrPointer;
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
