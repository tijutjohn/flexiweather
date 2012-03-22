package com.iblsoft.flexiweather.utils
{
	import flash.display.DisplayObject;
	import flash.geom.Point;

	public class AnticollisionLayoutObject
	{
		private var _object: DisplayObject;
		public var managedChild: Boolean;
		public var displacementMode: uint;
		private var m_referenceLocation: Point;
		
		public var objectsToAnchor: Array;
		public var anchorColor: uint = 0;
		public var anchorAlpha: Number = 1;
		public var drawAnchorArrow: Boolean = true;
		public var manageVisibilityWithAnchors: Boolean
		public var visible: Boolean;
		
		public function AnticollisionLayoutObject(object: DisplayObject,
												  b_managedChild: Boolean,
												  i_displacementMode: uint)
		{
			_object = object;
			managedChild = b_managedChild;
			displacementMode = i_displacementMode;
			m_referenceLocation = new Point(_object.x, _object.y)
			
			manageVisibilityWithAnchors = false;
		}
		

		public function get object():DisplayObject
		{
			return _object;
		}

		public function set object(value:DisplayObject):void
		{
			_object = value;
		}

		public function get referenceLocation():Point
		{
			return m_referenceLocation;
		}
		
		public function set referenceLocation(value:Point):void
		{
			m_referenceLocation.x = value.x;
			m_referenceLocation.y = value.y;
			
			//		trace("LayoutObject m_referenceLocation " + value);
		}
	}
}