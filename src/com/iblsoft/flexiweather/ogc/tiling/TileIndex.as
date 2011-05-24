package com.iblsoft.flexiweather.ogc.tiling
{
	public class TileIndex
	{
		public var mi_tileZoom: uint;
		public var mi_tileRow: uint;
		public var mi_tileCol: uint;
	
		public function TileIndex(i_tileZoom: uint = 0, i_tileRow: uint = 0, i_tileCol: uint = 0)
		{
			mi_tileZoom = i_tileZoom;
			changePosition(i_tileRow, i_tileCol);
		}
	
		public function changePosition(i_tileRow: uint, i_tileCol: uint): void
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