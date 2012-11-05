package com.iblsoft.flexiweather.ogc.tiling
{
	import flash.net.URLRequest;
	import com.iblsoft.flexiweather.ogc.data.viewProperties.TiledTileViewProperties;

	public class TiledTileRequest
	{
//		public var tileIndex: TileIndex;
//		public var crs: String;
//		public var associatedData: Object;
		/**
		 * Optional parameter. Job name for backroundJobManager
		 */
		private var _jobName: String;
		private var _qttTileViewProperties: TiledTileViewProperties;

		public function get jobName(): String
		{
			return _jobName;
		}

		public function get qttTileViewProperties(): TiledTileViewProperties
		{
			return _qttTileViewProperties;
		}

		public function TiledTileRequest(qttTileViewProperties: TiledTileViewProperties, jobName: String)
		{
			_qttTileViewProperties = qttTileViewProperties;
			_jobName = jobName;
		}
	}
}
