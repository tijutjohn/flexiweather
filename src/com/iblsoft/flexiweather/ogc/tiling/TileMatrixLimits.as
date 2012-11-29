package com.iblsoft.flexiweather.ogc.tiling
{

	public class TileMatrixLimits
	{
		public var tileMatrix: String;
		public var minTileRow: uint;
		public var maxTileRow: uint;
		public var minTileColumn: uint;
		public var maxTileColumn: uint;

		public function get rowTilesCount(): uint
		{
			return maxTileRow - minTileRow + 1;
		}
		public function get columnTilesCount(): uint
		{
			return maxTileColumn - minTileColumn + 1;
		}
		
		public function get tilesCount(): uint
		{
			return rowTilesCount * columnTilesCount;
		}
		
		public function TileMatrixLimits()
		{
		}
	}
}
