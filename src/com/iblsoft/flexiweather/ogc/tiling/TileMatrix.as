package com.iblsoft.flexiweather.ogc.tiling
{
	import com.iblsoft.flexiweather.ogc.BBox;
	
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

		public function get extent(): BBox
		{

			var extentBBox: BBox = new BBox(topLeftCorner.x, topLeftCorner.y, topLeftCorner.x + matrixWidth * tileWidth * scaleDenominator, topLeftCorner.x + matrixHeight * tileHeight * scaleDenominator);
			return extentBBox;
		}
		public function TileMatrix()
		{
		}
	}
}
