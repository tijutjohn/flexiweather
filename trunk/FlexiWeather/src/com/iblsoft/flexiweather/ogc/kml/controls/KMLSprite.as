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

		public function get kmlLabel(): KMLLabel
		{
			return _kmlLabel;
		}

		public function set kmlLabel(value: KMLLabel): void
		{
			_kmlLabel = value;
		}

		override public function set visible(value: Boolean): void
		{
			super.visible = value;
		}

		override public function set x(value: Number): void
		{
			super.x = value;
			_feature.notifyPositionChange();
		}

		override public function set y(value: Number): void
		{
			super.y = value;
			_feature.notifyPositionChange();
		}
		private static var uid: int = 0;
		private var _id: int;

		public function get id(): int
		{
			return _id;
		}

		public function KMLSprite(feature: KMLFeature, forReflection: uint = 0)
		{
			super();
			reflection = forReflection;
			_feature = feature
			_id = ++uid;
		}

		public function cleanup(): void
		{
			_kmlLabel = null;
			_feature = null
			_anticollisionLayoutObject = null;
		}

		public function set anticollisionLayoutObject(object: AnticollisionLayoutObject): void
		{
			_anticollisionLayoutObject = object;
		}

		public function get anticollisionLayoutObject(): AnticollisionLayoutObject
		{
			return _anticollisionLayoutObject;
		}
	}
}
