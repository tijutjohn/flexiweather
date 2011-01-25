package com.iblsoft.flexiweather.ogc.tiling
{
	public class TileIndex
	{
		public var mi_tileZoom: uint;
		public var mi_tileRow: uint;
		public var mi_tileCol: uint;
	
		public function TileIndex(i_tileZoom: uint, i_tileRow: uint = 0, i_tileCol: uint = 0)
		{
			mi_tileZoom = i_tileZoom;
			changePosition(i_tileRow, i_tileCol);
		}
	
		public function changePosition(i_tileRow: uint, i_tileCol: uint): void
		{
			mi_tileRow = i_tileRow;
			mi_tileCol = i_tileCol;
		}
		public function toString(): String
		{
			return "" + mi_tileZoom + "/" + mi_tileRow + "/" + mi_tileCol; 
		}
	}
}