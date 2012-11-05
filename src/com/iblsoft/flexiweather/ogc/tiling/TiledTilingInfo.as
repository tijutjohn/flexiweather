package com.iblsoft.flexiweather.ogc.tiling
{
	import com.iblsoft.flexiweather.utils.Serializable;
	import com.iblsoft.flexiweather.utils.Storage;
	import com.iblsoft.flexiweather.ogc.CRSWithBBox;

	/**
	 * QuadTree tiling info. There is stored urlPattern, crs, bbox and minimum and maximum zoom
	 * @author fkormanak
	 *
	 */
	public class TiledTilingInfo implements Serializable
	{
		private var _urlPattern: String;

		private var _crsWithBBox: CRSWithBBox;

		private var _minimumZoomLevel: uint = 0;

		public var maximumZoomLevel: uint = 12;

		public var tileSize: uint;

		public function get minimumZoomLevel(): uint
		{
			return _minimumZoomLevel;
		}

		public function set minimumZoomLevel(value: uint): void
		{
			_minimumZoomLevel = value;
		}

		public function get urlPattern(): String
		{
			return _urlPattern;
		}

		public function set urlPattern(value: String): void
		{
//			if (value != '&TILEZOOM=%ZOOM%&TILECOL=%COL%&TILEROW=%ROW%')
//			{
//				trace("check TiledTilingInfo urlPattern: " + value);
//			}
			_urlPattern = value;
		}

		public function get crsWithBBox(): CRSWithBBox
		{
			return _crsWithBBox;
		}

		public function TiledTilingInfo(_urlPattern: String = '', crsWithBBox: CRSWithBBox = null, tileSize: uint = 256)
		{
			urlPattern = _urlPattern;
			_crsWithBBox = crsWithBBox;
			this.tileSize = tileSize;
		}

		public function destroy(): void
		{
			if (_crsWithBBox)
				_crsWithBBox.destroy();
			_crsWithBBox = null;
		}

		public function updateCRSWithBBox(value: CRSWithBBox): void
		{
			_crsWithBBox = value;
		}

		public function serialize(storage: Storage): void
		{
			urlPattern = storage.serializeString("url-pattern", urlPattern);
			if (storage.isLoading())
				_crsWithBBox = new CRSWithBBox();
			_crsWithBBox.serialize(storage);
			minimumZoomLevel = storage.serializeUInt("minimum-zoom-level", minimumZoomLevel, 1);
			maximumZoomLevel = storage.serializeUInt("maximum-zoom-level", maximumZoomLevel, 12);
			tileSize = storage.serializeUInt("tile-size", tileSize, 0);
		}
	}
}
