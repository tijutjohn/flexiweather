package com.iblsoft.flexiweather.ogc.tiling
{
	public class TileIndex
	{
		public var mi_tileZoom: int;
		public var mi_tileRow: int;
		public var mi_tileCol: int;
	
		public function TileIndex(i_tileZoom: int = 0, i_tileRow: int = 0, i_tileCol: int = 0)
		{
			if (i_tileZoom <= 0)
			{
				i_tileZoom = 2;
				trace("Strop tileZoom is negative");
			}
			
			var _maxTilePos: int = i_tileZoom * i_tileZoom - 1;
			if (i_tileRow > _maxTilePos || i_tileCol > _maxTilePos || i_tileCol < 0 || i_tileRow < 0)
			{
				trace("stop, wrong tile for zoom: " + i_tileZoom);
			}
			mi_tileZoom = i_tileZoom;
			changePosition(i_tileRow, i_tileCol);
		}
	
		public function changePosition(i_tileRow: int, i_tileCol: int): void
		{
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