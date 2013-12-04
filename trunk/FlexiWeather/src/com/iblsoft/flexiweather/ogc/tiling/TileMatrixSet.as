package com.iblsoft.flexiweather.ogc.tiling
{

	public class TileMatrixSet
	{
		public var id: String;
		public var supportedCRS: String;
		public var tileMatrices: Array;

		public function TileMatrixSet()
		{
			tileMatrices = new Array();
		}

		public function addTileMatrix(matrix: TileMatrix): void
		{
			tileMatrices.push(matrix);
		}
		
		public function toString(): String
		{
			return "TileMatrixSet: " + id + " crs: " + supportedCRS + " matrices: " + tileMatrices.length;
		}
	}
}
