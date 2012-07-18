package com.iblsoft.flexiweather.ogc.kml.controls
{
	import com.iblsoft.flexiweather.ogc.kml.features.KMLFeature;
	import com.iblsoft.flexiweather.utils.anticollision.AnticollisionLayoutObject;
	import com.iblsoft.flexiweather.utils.anticollision.IAnticollisionLayoutObject;
	
	import flash.display.Sprite;

	public class KMLSprite extends Sprite implements IAnticollisionLayoutObject
	{
		public var reflection: uint;
		private var _kmlLabel: KMLLabel;
		
		private var _feature: KMLFeature;
		
		private var _anticollisionLayoutObject: AnticollisionLayoutObject;

		public function get kmlLabel():KMLLabel
		{
			return _kmlLabel;
		}

		public function set kmlLabel(value:KMLLabel):void
		{
			_kmlLabel = value;
		}

		override public function set visible(value:Boolean):void
		{
			super.visible = value;
//			trace("KMLSprite.visible = " + value);
		}
		
		override public function set x(value:Number):void
		{
			super.x = value;
//			if (reflection == 0)
//				trace("KMLSprite.x = " + value);
			_feature.notifyPositionChange();
		}
		override public function set y(value:Number):void
		{
			super.y = value;
//			if (reflection == 0)
//				trace("KMLSprite.y = " + value);
			_feature.notifyPositionChange();
		}
		public function KMLSprite(feature: KMLFeature, forReflection: uint = 0)
		{
			super();
			reflection = forReflection;
			_feature = feature
		}
		
		public function set anticollisionLayoutObject(object:AnticollisionLayoutObject):void
		{
			_anticollisionLayoutObject = object;			
		}
		
		public function get anticollisionLayoutObject():AnticollisionLayoutObject
		{
			return _anticollisionLayoutObject;
		}
		
	}
}