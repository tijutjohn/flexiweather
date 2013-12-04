package com.iblsoft.flexiweather.utils
{
	import flash.display.DisplayObject;
	import flash.filters.BitmapFilter;
	import flash.filters.ColorMatrixFilter;
	import mx.collections.ArrayCollection;

	public class BitmapFilterUtils
	{
		public static function createGrayscale(f_alpha: Number = 1): ColorMatrixFilter
		{
			return new ColorMatrixFilter([
					0.3, 0.59, 0.11, 0, 0,
					0.3, 0.59, 0.11, 0, 0,
					0.3, 0.59, 0.11, 0, 0,
					0, 0, 0, f_alpha, 0
					]);
		}

		public static function createHighlight(f_alpha: Number = 1): ColorMatrixFilter
		{
			return new ColorMatrixFilter([
					1.1, 0, 0, 0, 0,
					0, 1.1, 0, 0, 0,
					0, 0, 1.1, 0, 0,
					0, 0, 0, f_alpha, 0
					]);
		}

		public static function addFilterTo(o: DisplayObject, f: BitmapFilter): void
		{
			if (o.filters == null)
				o.filters = [f];
			else
			{
				var a: Array = ArrayUtils.dupArray(o.filters);
				a.push(f);
				o.filters = a;
			}
		}

		public static function removeFilterFrom(o: DisplayObject, f: BitmapFilter): void
		{
			if (o.filters == null)
				return;
			var a: ArrayCollection = new ArrayCollection(o.filters);
			var i: int = a.getItemIndex(f);
			if (i >= 0)
				a.removeItemAt(i);
			if (a.length == 0)
				o.filters = null;
			else
				o.filters = a.toArray();
		}
	}
}
