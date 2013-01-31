package com.iblsoft.flexiweather.ogc.tiling
{

	public class TileIndex
	{
		public var mi_tileSize: int;
		public var mi_tileZoom: String;
		public var mi_tileRow: int;
		public var mi_tileCol: int;

		public function TileIndex(i_tileZoom: String = null, i_tileRow: int = 0, i_tileCol: int = 0, i_tileSize: int = 256)
		{
//			if (i_tileZoom == null)
//			{
//				trace("TileIndex.TileIndex(): Stop tileZoom not set");
//			}
			mi_tileSize = i_tileSize;
			mi_tileZoom = i_tileZoom;
			mi_tileRow = i_tileRow;
			mi_tileCol = i_tileCol;
		}

		public static function createTileIndexFromString(str: String): TileIndex
		{
			var tileIndex: TileIndex = new TileIndex();
			var arr: Array = str.split('|');
			str = arr[1] as String;
			arr = str.split('/');
			tileIndex.mi_tileZoom = arr[0];
			tileIndex.mi_tileCol = arr[1];
			tileIndex.mi_tileRow = arr[2];
			return tileIndex;
		}

		public function toString(): String
		{
//			return "" + mi_tileZoom + "/" + mi_tileRow + "/" + mi_tileCol; 
			return "" + mi_tileZoom + "/" + mi_tileCol + "/" + mi_tileRow;
		}
	}
}
