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
		
		public function TilingUtils()
		{
		}
		

		public function get minimumZoom():int
		{
			return _minimumZoom;
		}

		public function set minimumZoom(value:int):void
		{
			_minimumZoom = value;
		}

		public function get maximumZoom():int
		{
			return _maximumZoom;
		}

		public function set maximumZoom(value:int):void
		{
			_maximumZoom = value;
		}

		public function onAreaChanged(s_crs: String, extent: BBox): void
		{
			ms_crs = s_crs;
			m_extent = extent;
		}
		
		public function getTiledArea(viewBBox: BBox, zoomLevel: int): TiledArea
		{
			if(!m_extent)
				return null;
			var maxColTiles: int = getColTiles(zoomLevel);
			var maxRowTiles: int = getRowTiles(zoomLevel);
			
			var tileBBox: Point = new Point(m_extent.width / maxColTiles, m_extent.height / maxRowTiles);
			var viewTiles: Point = new Point((viewBBox.width / tileBBox.x), (viewBBox.height / tileBBox.y));
			
			var leftCol: int = Math.floor((viewBBox.xMin - m_extent.xMin) / tileBBox.x);
			var topRow: int = Math.floor((m_extent.yMax - viewBBox.yMax) / tileBBox.y);
//			trace("getTiledArea m_extent" + m_extent.width + ", " + m_extent.height)
//			trace("getTiledArea viewBBox:" + viewBBox.width + ", " + viewBBox.height)
//			trace("getTiledArea leftCol:" + leftCol + ", topRow: " + topRow)
//			var tileBBox: Point = new Point(m_extent.width / maxColTiles, m_extent.height / maxRowTiles);
//			var viewTiles: Point = new Point( Math.ceil(viewBBox.width / tileBBox.x), Math.ceil(viewBBox.height / tileBBox.y));
//			
//			var leftCol: int = Math.floor((viewBBox.xMin - m_extent.xMin) / tileBBox.x);
//			var topRow: int = Math.floor((m_extent.yMax - viewBBox.yMax) / tileBBox.y);
			
			var _maxTileID: int = 1 << (zoomLevel + 1) - 1;
			var topLeftIndex: TileIndex = new TileIndex(zoomLevel, Math.min(_maxTileID, Math.max(0,topRow)), Math.min(_maxTileID, Math.max(0,leftCol)));
			var bottomRightIndex: TileIndex = new TileIndex(zoomLevel, Math.min(_maxTileID, Math.ceil(topRow + viewTiles.y)),  Math.min(_maxTileID, Math.ceil(leftCol + viewTiles.x)));
			var area: TiledArea = new TiledArea(topLeftIndex, bottomRightIndex );
			//trace("getTiledArea viewBBox: " + viewBBox + " area: " + area);
			//trace("getTiledArea zoom: " + zoomLevel + " viewTiles: " + viewTiles);
			return area;
			
		}
		
		/**
		 * For now this method is deprecated, we have new equation for counting tile zoom level in InteractiveLayerQTTMS.findZoom 
		 * @param viewBBox
		 * @param viewSize
		 * @return 
		 * 
		 */		
		/*
		public function getZoom(viewBBox: BBox, viewSize: Point): int
		{
			if (viewSize.x == 0 || viewSize.y == 0 || !m_extent)
			{
				//can not get zoom for area with no size
				return -1;
			}
			var newZoomLevel: int = minimumZoom;
			var bestZoomLevel: int = minimumZoom;
			var bestDist: int = int.MAX_VALUE;
			var bestScale: Point;
			var bestArea: TiledArea;
			
			var scale: Point;
			var tilesInViewBBox: Point;
			var area: TiledArea;
			var tileWidth: int;
			var tileHeight: int;
			
			tileWidth = 256;
			tileHeight = 256;
			var zoomFound: Boolean = false;
			var arr: Array = [];
			
			
			while (!zoomFound)
			{
				area = getTiledArea(viewBBox, newZoomLevel);
//				scale = new Point( viewSize.x / ((area.colTilesCount - 1) * tileWidth) ,  viewSize.y / ((area.rowTilesCount - 1) * tileHeight));
				scale = new Point( viewSize.x / ((area.colTilesCount ) * tileWidth) ,  viewSize.y / ((area.rowTilesCount) * tileHeight));
				
				if ((viewSize.x <= (area.colTilesCount * 256)) && (viewSize.y <= (area.rowTilesCount * 256)))
				{
					
					
					var scaleOK: Boolean = false;
					if (checkColumnScale)
					{
						//trace("For zoom: " + newZoomLevel + " scale must be: " + scale + " view: " + viewSize + " tiledAreaSize: " + (area.colTilesCount * 256)+"," +(area.rowTilesCount * 256));
						
						var dist: Number = Math.sqrt((columnScaleMax - scale.x) * (columnScaleMax - scale.x)  + (rowScaleMax - scale.y) * (rowScaleMax - scale.y) );
						var dist2: Number = Math.abs(columnScaleMax - scale.x) + Math.abs(rowScaleMax - scale.y);
						
						if (dist < bestDist)
						{
							bestDist = dist;
							bestScale = scale;
							bestArea = area;
							bestZoomLevel = newZoomLevel;
						}
						arr.push({zoom: newZoomLevel, dist: dist, dist2: dist2, scale: scale});
					}
						
				}
				if (scaleOK)
				{
					zoomFound = true;
					trace("TilingUtils scale: " + scale.x + " , " + scale.y);
				} else {
					newZoomLevel++;
					
					if (newZoomLevel > maximumZoom)
						zoomFound = true;
				}
			}
			//trace("\nTilingUtils getZoom for viewBBox: " + viewBBox.toString() + " size: " + viewSize + " LEVEL FOUND: " + bestZoomLevel);
			return bestZoomLevel;
		}
		*/
		
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
		/*
		public function getViewTilesInExtent(zoomLevel: int, viewBBox: BBox): Point
		{
			var maxColTiles: int = getColTiles(zoomLevel);
			var maxRowTiles: int = getRowTiles(zoomLevel);
			
			var tileBBox: Point = new Point(m_extent.width / maxColTiles, m_extent.height / maxRowTiles);
			var viewTiles: Point = new Point( Math.ceil(viewBBox.width / tileBBox.x), Math.ceil(viewBBox.height / tileBBox.y));
			return viewTiles;
		}*/
		
		
		public function getTiles(zoomLevel: int): int
		{
			return getColTiles(zoomLevel) * getRowTiles(zoomLevel)	
		}
		public function getColTiles(zoomLevel: int): int
		{
			return Math.pow(2, zoomLevel);	
		}
		public function getRowTiles(zoomLevel: int): int
		{
			return Math.pow(2, zoomLevel);	
		}
		
		public function getTileIndexForPosition(x: Number, y: Number, zoomLevel: int): TileIndex
		{
			if (m_extent)
			{
				var xMin: Number = m_extent.xMin;
				var yMin: Number = m_extent.yMin;
				var yMax: Number = m_extent.yMax;
				
				var tileWidth: int = getTileWidth(zoomLevel);
				var tileHeight: int = getTileHeight(zoomLevel);
				
				var tileXPos: int = Math.floor( ( x - xMin ) / tileWidth );
//				var tileYPos: int = Math.floor( ( yPosition - yMin ) / tileHeight );
				var tileYPos: int = Math.floor( ( yMax - y ) / tileHeight );
				
				return new TileIndex( zoomLevel, tileXPos, tileYPos);
			} 
			return null;
		}
		
		public function getTileWidth(zoomLevel: int): int
		{
			if (m_extent)
			{
				var i_tilesInSerie: uint = 1 << zoomLevel;
				var f_tileWidth: Number = m_extent.width / i_tilesInSerie;
				return f_tileWidth;
			}
			
			return 0;
		}
		public function getTileHeight(zoomLevel: int): int
		{
			if (m_extent)
			{
				var i_tilesInSerie: uint = 1 << zoomLevel;
				var f_tileHeight: Number = m_extent.height / i_tilesInSerie;
				return f_tileHeight;
			}
			
			return 0;
		}

	}
}