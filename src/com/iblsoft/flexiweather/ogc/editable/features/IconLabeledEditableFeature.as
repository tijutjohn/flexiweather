package com.iblsoft.flexiweather.ogc.editable.features
{
	import com.iblsoft.flexiweather.ogc.FeatureUpdateContext;
	import flash.display.Bitmap;
	import flash.geom.Point;

	public class IconLabeledEditableFeature extends LabeledEditableFeature
	{
		private var _bitmap: Bitmap;

		public function get bitmap(): Bitmap
		{
			return _bitmap;
		}

		public function set bitmap(value: Bitmap): void
		{
			_bitmap = value;
			bitmapAdded();
		}

		public function IconLabeledEditableFeature(s_namespace: String, s_typeName: String, s_featureId: String)
		{
			super(s_namespace, s_typeName, s_featureId);
		}

		private function bitmapAdded(): void
		{
			if (_bitmap.parent != this)
				addChild(_bitmap);
		}

		override public function update(changeFlag: FeatureUpdateContext): void
		{
			super.update(changeFlag);
			var a_points: Array = getPoints();
			if (a_points.length > 0)
			{
				var pt: Point = a_points[0] as Point;
				var gap: int = 5;
				updateIconPosition(pt.x - _bitmap.width / 2, pt.y - _bitmap.height / 2);
				updateLabelPosition(_bitmap.x + _bitmap.width + gap, _bitmap.y + _bitmap.height / 2 - textfield.textHeight / 2);
			}
		}

		protected function updateIconPosition(x: Number, y: Number): void
		{
			_bitmap.x = x;
			_bitmap.y = y;
		}
	}
}
