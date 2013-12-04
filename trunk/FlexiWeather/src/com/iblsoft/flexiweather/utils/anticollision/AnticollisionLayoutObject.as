package com.iblsoft.flexiweather.utils.anticollision
{
	import com.iblsoft.flexiweather.ogc.kml.controls.KMLLabel;
	import com.iblsoft.flexiweather.ogc.kml.events.KMLFeatureEvent;
	import com.iblsoft.flexiweather.ogc.kml.features.KMLFeature;
	import com.iblsoft.flexiweather.widgets.InteractiveLayer;
	
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
		public var layer: InteractiveLayer;
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

		public function get referenceLocation(): Point
		{
			return m_referenceLocation;
		}
		
		public function set referenceLocation(value: Point): void
		{
			m_referenceLocation.x = value.x;
			m_referenceLocation.y = value.y;
		}
		
		public function get visible(): Boolean
		{
			return _visible;
		}

		public function set visible(value: Boolean): void
		{
			if (_visible != value || object.visible != value)
			{
				_visible = value;
				//set object visibility to save value
				object.visible = value;
//				trace(this + " VISIBLE CHANGED");
			}
		}

		public function toString(): String
		{
			return "ALO [" + name + "] " + object + " visible: " + visible;
		}

		public function AnticollisionLayoutObject(object: DisplayObject, l_layer: InteractiveLayer, b_managedChild: Boolean, i_displacementMode: String)
		{
			managedChild = b_managedChild;
			displacementMode = i_displacementMode;
			layer = l_layer;
//			_object = object;
//			m_referenceLocation = new Point(_object.x, _object.y)
			this.object = object;
			m_referenceLocation = new Point(object.x, object.y)
			manageVisibilityWithAnchors = false;
			
			if (object is KMLLabel)
			{
				var kmlFeature: KMLFeature = (object as KMLLabel).kmlFeature;
				kmlFeature.addEventListener(KMLFeatureEvent.KML_FEATURE_VISIBILITY_CHANGE, onKMLFeatureVisibilityChange);
			}
		}
			
		private function onKMLFeatureVisibilityChange(event: KMLFeatureEvent): void
		{
			var kmlFeature: KMLFeature = event.target as KMLFeature;
			visible = kmlFeature.visible;
		}

		public function destroy(): void
		{
			if (object is KMLLabel)
			{
				var kmlFeature: KMLFeature = (object as KMLLabel).kmlFeature;
				kmlFeature.removeEventListener(KMLFeatureEvent.KML_FEATURE_VISIBILITY_CHANGE, onKMLFeatureVisibilityChange);
			}
			
		}
		
	}
}
