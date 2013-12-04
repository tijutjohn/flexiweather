package com.iblsoft.flexiweather.ogc.tiling
{

	public class TileMatrixSetLink
	{
		public var tileMatrixSet: TileMatrixSet;
		public var tileMatrixSetLimitsArray: TileMatrixSetLimits;

		public function TileMatrixSetLink()
		{
		}
		
		public function toString(): String
		{
			return "TileMatrixSetLink tileMatrixSet: " + tileMatrixSet + " tileMatrixSetLimitsArray: " + tileMatrixSetLimitsArray;
		}
	}
}
