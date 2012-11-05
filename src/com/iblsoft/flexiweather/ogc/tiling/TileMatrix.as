package com.iblsoft.flexiweather.ogc.tiling
{
	import flash.geom.Point;

	public class TileMatrix
	{
		public var id: String;
		public var scaleDenominator: Number;
		public var topLeftCorner: Point;
		public var tileWidth: int;
		public var tileHeight: int;
		public var matrixWidth: int;
		public var matrixHeight: int;

		public function TileMatrix()
		{
		}
	}
}
