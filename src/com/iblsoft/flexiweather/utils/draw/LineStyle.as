package com.iblsoft.flexiweather.utils.draw
{
	public class LineStyle
	{
		public var thickness: int;
		public var color: uint;
		public var alpha: Number;
		public var pixelHinting: Boolean;
		public var scaleMode: String;
		public var caps: String;
		public var joints: String;
		public var miterLimit: int;
		
		public function LineStyle(thickness: int, color: uint, alpha: Number, pixelHinting: Boolean = false, scaleMode: String = 'normal', caps: String = null, joints: String = null, miterLimit: Number = 3)
		{
			this.thickness = thickness;
			this.color = color;
			this.alpha = alpha;
			this.pixelHinting = pixelHinting;
			this.scaleMode = scaleMode;
			this.caps = caps;
			this.joints = joints;
			this.miterLimit = miterLimit;
		}
	}
}