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
		
		public static function uintToHex(color: uint): String
		{
			var clrString: String = color.toString(16);
			if (clrString == "0")
				clrString = "000000";
			else if (clrString.length == 2)
				clrString += "0000";
			else if (clrString.length == 4)
				clrString += "00";
			
			var hexColor:String = "#" + clrString;
			return hexColor;
		}
		public static function hexToUint(hexString: String): uint
		{
//			var color1:String= "#00FF00";
			var uintColor: uint;
			var r: RegExp = new RegExp(/#/g);		
			
			uintColor=uint(String(hexString).replace(r,"0x"));
			
			return uintColor;
		}
	}
}
