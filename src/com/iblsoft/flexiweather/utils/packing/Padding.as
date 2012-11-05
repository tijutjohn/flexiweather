package com.iblsoft.flexiweather.utils.packing
{
	import flash.geom.Rectangle;

	public class Padding
	{
		public var left: int = 0;
		public var right: int = 0;
		public var top: int = 0;
		public var bottom: int = 0;

		public function Padding()
		{
		}

		public function updateRectangleSizeWithPadding(rect: Rectangle): void
		{
			rect.width += left + right;
			rect.height += top + bottom;
		}
	}
}
