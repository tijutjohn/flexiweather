package com.iblsoft.flexiweather.ogc.tiling
{
	import flash.net.URLRequest;

	public class QTTTileRequest
	{
		public var tileIndex: TileIndex;
		public var crs: String;
		public var associatedData: Object;
		
		/**
		 * Optional parameter. Job name for backroundJobManager 
		 */		
		public var jobName: String;
		
		/**
		 * Optional parameter. Request is done in InteractiveLayerQTTMS, but tileProvider can make its own request. 
		 */		
		public var request: URLRequest;
		
		public function QTTTileRequest()
		{
		}
	}
}