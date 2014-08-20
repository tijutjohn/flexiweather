package com.iblsoft.flexiweather.ogc.wfs
{
	import flash.display.BitmapData;
	import flash.geom.Point;
	
	public interface IWFSIconSprite
	{
		function setBitmap(nBitmapData: BitmapData, pt: Point, blackColor: uint = 0): void
	}
}