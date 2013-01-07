package com.iblsoft.flexiweather.ogc.tiling
{
	import flash.net.URLRequest;

	public class QTTTileRequest
	{
//		public var tileIndex: TileIndex;
//		public var crs: String;
//		public var associatedData: Object;
		
		/**
		 * Optional parameter. Job name for backroundJobManager 
		 */		
		private var _jobName: String;
		private var _qttTileViewProperties: QTTTileViewProperties;
		
		public function get jobName():String
		{
			return _jobName;
		}

		public function get qttTileViewProperties():QTTTileViewProperties
		{
			return _qttTileViewProperties;
		}
		
		public function QTTTileRequest(qttTileViewProperties: QTTTileViewProperties, jobName: String)
		{
			_qttTileViewProperties = qttTileViewProperties;
			_jobName = jobName;
		}



	}
}