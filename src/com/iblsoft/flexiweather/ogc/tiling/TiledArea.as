package com.iblsoft.flexiweather.ogc.tiling
{
	public class TiledArea
	{
		public var topLeftTileIndex: TileIndex;
		public var bottomRightTileIndex: TileIndex;
		
		public function TiledArea(topLeftTileIndex: TileIndex, bottomRightTileIndex: TileIndex)
		{
			this.topLeftTileIndex = topLeftTileIndex;
			this.bottomRightTileIndex = bottomRightTileIndex;
		}
		
		public function get topRow(): int
		{
			return topLeftTileIndex.mi_tileRow;
		}
		public function get bottomRow(): int
		{
			return bottomRightTileIndex.mi_tileRow;
		}
		
		public function get leftCol(): int
		{
			return topLeftTileIndex.mi_tileCol;
		}
		
		public function get rightCol(): int
		{
			return bottomRightTileIndex.mi_tileCol;
		}
		
		public function get colTilesCount(): int
		{
			return bottomRightTileIndex.mi_tileCol - topLeftTileIndex.mi_tileCol + 1;
		}
		public function get rowTilesCount(): int
		{
			return bottomRightTileIndex.mi_tileRow - topLeftTileIndex.mi_tileRow + 1;
		}
		
		public function toString(): String
		{
			return 'TiledArea (' + topLeftTileIndex + ", " + bottomRightTileIndex + ") size: " + colTilesCount + " , " + rowTilesCount;
		}

	}
}