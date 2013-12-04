package com.iblsoft.flexiweather.ogc.tiling
{
	import com.iblsoft.flexiweather.ogc.BBox;
	
	import flash.geom.Point;

	public class TilingUtils
	{
		/** these variables are static to be able to fast test different methods to find best zoom for BBox */
		public static var checkColumnScale: Boolean = true;
		public static var checkRowScale: Boolean = false;
		public static var columnScaleMax: Number = 1;
		public static var rowScaleMax: Number = 1;
		private var ms_crs: String;
		private var m_extent: BBox;
		private var _minimumZoom: int = 1;
		private var _maximumZoom: int = 10;

		private var _tiledLayer: InteractiveLayerTiled;
		
		public function TilingUtils(tiledLayer: InteractiveLayerTiled)
		{
			_tiledLayer = tiledLayer;
		}

		public function onAreaChanged(s_crs: String, extent: BBox): void
		{
			ms_crs = s_crs;
			m_extent = extent;
		}

		public function getTiledArea(viewBBox: BBox, zoomLevel: String, tileSize: int): TiledArea
		{
			if (!m_extent)
				return null;
			
			var limits: TileMatrixLimits = _tiledLayer.getTileMatrixLimitsForCRSAndZoom(ms_crs, zoomLevel);
			
			var maxColTiles: int = limits.columnTilesCount; //getColTiles(zoomLevel, tileSize);
			var maxRowTiles: int = limits.rowTilesCount; //getRowTiles(zoomLevel, tileSize);
			var _maxRowTileID: int = limits.maxTileRow;  //getMaxTileID(zoomLevel, tileSize);
			var _maxColumnTileID: int = limits.maxTileColumn; // getMaxTileID(zoomLevel, tileSize);
			
			var tilesInExtent: Point = new Point(m_extent.width / maxColTiles, m_extent.height / maxRowTiles);
			
			var leftColPosition: int = Math.max(0, Math.floor((viewBBox.xMin - m_extent.xMin) / tilesInExtent.x));
			var rightColPosition: int = Math.max(0, Math.floor((viewBBox.xMin + viewBBox.width - m_extent.xMin) / tilesInExtent.x));
			
			var topRowPosition: int = Math.floor((m_extent.yMax - viewBBox.yMax) / tilesInExtent.y);
			var bottomRowPosition: int = Math.floor((m_extent.yMax - viewBBox.yMax + viewBBox.height) / tilesInExtent.y);
			
			var topLeftIndex: TileIndex = new TileIndex(zoomLevel, Math.min(_maxRowTileID, Math.max(0, topRowPosition)), Math.min(_maxColumnTileID, Math.max(0, leftColPosition)), tileSize);
			var bottomRightIndex: TileIndex = new TileIndex(zoomLevel, Math.min(_maxRowTileID, bottomRowPosition), Math.min(_maxColumnTileID, rightColPosition), tileSize);
		
//			trace("TilingUtils getTiledArea viewBBox: " + viewBBox.toBBOXString());
//			trace("TilingUtils getTiledArea tilesInExtent: " + tilesInExtent + " topLeft: " + topLeftIndex + " bottomRight: " + bottomRightIndex);
			var area: TiledArea = new TiledArea(topLeftIndex, bottomRightIndex, tileSize);
			return area;
		}

		private function debugZoomLevels(arr: Array): void
		{
			return;
			if (arr)
			{
				arr.sortOn('dist', Array.NUMERIC);
				for each (var zoomObj: Object in arr)
				{
					if (zoomObj)
						trace("zoom : " + zoomObj.zoom + " dist: " + zoomObj.dist + " dist2: " + zoomObj.dist2);
				}
			}
		}

		public function getTileSize(zoomLevel: int, tileSize: int = 256): int
		{
			var max256ID: int = (1 << (zoomLevel + 1) - 1) - 1;
			if (tileSize != 256)
			{
				var totalSize: int = (max256ID + 1) * 256;
				if (totalSize >= tileSize && (totalSize % tileSize) == 0)
					return tileSize;
			}
			return 256;
		}

//		public function getMaxTileID(zoomLevel: int, tileSize: int = 256): int
//		{
//			var max256ID: int = (1 << (zoomLevel + 1) - 1) - 1;
//			if (tileSize != 256)
//			{
//				var totalSize: int = (max256ID + 1) * 256;
//				if (totalSize >= tileSize && (totalSize % tileSize) == 0)
//					return (totalSize / tileSize) - 1;
//			}
//			return max256ID;
//		}

//		public function getTiles(zoomLevel: int): int
//		{
//			return getColTiles(zoomLevel) * getRowTiles(zoomLevel)
//		}
//		public function getColTiles(zoomLevel: int, tileSize: int = 256): int
//		{
//			return getMaxTileID(zoomLevel, tileSize) + 1;
//		}
//
//		public function getRowTiles(zoomLevel: int, tileSize: int = 256): int
//		{
//			return getMaxTileID(zoomLevel, tileSize) + 1;
//		}

		public function getTileIndexForPosition(x: Number, y: Number, zoomLevel: String): TileIndex
		{
			if (m_extent)
			{
				var xMin: Number = m_extent.xMin;
				var yMin: Number = m_extent.yMin;
				var yMax: Number = m_extent.yMax;
				//TODO fix this after InteractiveLayerTiled is implemented
				var tileWidth: int = 256; //= getTileWidth(zoomLevel);
				var tileHeight: int = 256; //getTileHeight(zoomLevel);
				var tileXPos: int = Math.floor((x - xMin) / tileWidth);
				var tileYPos: int = Math.floor((yMax - y) / tileHeight);
				return new TileIndex(zoomLevel, tileXPos, tileYPos);
			}
			return null;
		}

//		public function getTileWidth(zoomLevel: String): int
//		{
//			if (m_extent)
//			{
//				var i_tilesInSerie: uint = 1 << zoomLevel;
//				var f_tileWidth: Number = m_extent.width / i_tilesInSerie;
//				return f_tileWidth;
//			}
//			return 0;
//		}
//
//		public function getTileHeight(zoomLevel: String): int
//		{
//			if (m_extent)
//			{
//				var i_tilesInSerie: uint = 1 << zoomLevel;
//				var f_tileHeight: Number = m_extent.height / i_tilesInSerie;
//				return f_tileHeight;
//			}
//			return 0;
//		}

		public function get minimumZoom(): int
		{
			return _minimumZoom;
		}

		public function set minimumZoom(value: int): void
		{
			_minimumZoom = value;
		}

		public function get maximumZoom(): int
		{
			return _maximumZoom;
		}

		public function set maximumZoom(value: int): void
		{
			_maximumZoom = value;
		}
	}
}
