package com.iblsoft.flexiweather.ogc.tiling
{

	public class TileMatrixSetLimits
	{
		private var _tileMatrixLimits: Array;

		public function TileMatrixSetLimits()
		{
			_tileMatrixLimits = [];
		}

		public function addTileMatrixLimits(limit: TileMatrixLimits): void
		{
			_tileMatrixLimits.push(limit);
		}
	}
}
