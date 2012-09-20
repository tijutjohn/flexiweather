package com.iblsoft.flexiweather.utils
{
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.geom.ColorTransform;

	public class ColorUtils
	{
		public function ColorUtils()
		{
		}
		
		public static function updateSymbolColor(clr: uint, bmp: Bitmap, originalSymbolBitmap: Bitmap): void
		{
			if (bmp && originalSymbolBitmap)
			{
				var bd: BitmapData = bmp.bitmapData;
				
				var clrTransform: ColorTransform = new ColorTransform();
				clrTransform.color = clr;
				clrTransform.redMultiplier = 1;
				clrTransform.blueMultiplier = 1;
				clrTransform.greenMultiplier = 1;
				
				bd.draw(originalSymbolBitmap, null, clrTransform);
			}	
		}

	}
}