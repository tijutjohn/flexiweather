package com.iblsoft.flexiweather.utils.anticollision
{
	import flash.display.DisplayObject;
	import flash.geom.Point;

	public class AnticollisionLayoutObject
	{
		public var name: String;
		public var object: DisplayObject;
//		private var _object: DisplayObject;
//		public function get object():DisplayObject
//		{
//			return _object;
//		}
//		
//		public function set object(value:DisplayObject):void
//		{
//			_object = value;
//		}
		
		public var managedChild: Boolean;
		public var displacementMode: String;
		private var m_referenceLocation: Point;
		
		public var reflectionID: int;
		public var objectsToAnchor: Array;
		public var anchorColor: uint = 0;
		public var anchorAlpha: Number = 1;
		public var drawAnchorArrow: Boolean = true;
		public var manageVisibilityWithAnchors: Boolean
		private var _visible: Boolean;
		

		public function get visible():Boolean
		{
			return _visible;
		}

		public function set visible(value:Boolean):void
		{
			_visible = value;
		}

		public function toString(): String
		{
			return "ALO ["+name+"] " + object + " visible: " + visible;
		}
		public function AnticollisionLayoutObject(object: DisplayObject,
												  b_managedChild: Boolean,
												  i_displacementMode: String)
		{
			managedChild = b_managedChild;
			displacementMode = i_displacementMode;
//			_object = object;
//			m_referenceLocation = new Point(_object.x, _object.y)
			this.object = object;
			m_referenceLocation = new Point(object.x, object.y)
			
			manageVisibilityWithAnchors = false;
		}
		

		

		public function get referenceLocation():Point
		{
			return m_referenceLocation;
		}
		
		public function set referenceLocation(value:Point):void
		{
//			if (value.x == 0  && value.y == 0)
//			{
//				trace("referenceLocation is set to 0");
//			}
			m_referenceLocation.x = value.x;
			m_referenceLocation.y = value.y;
			
//			trace("LayoutObject m_referenceLocation " + value);
		}
	}
}