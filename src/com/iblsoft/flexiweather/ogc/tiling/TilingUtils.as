package com.iblsoft.flexiweather.ogc.tiling
{
	import com.iblsoft.flexiweather.ogc.BBox;
	
	import flash.geom.Point;
	
	public class TilingUtils
	{
		private var ms_crs: String;
		private var m_extent: BBox;
		
		public function TilingUtils()
		{
		}
		
		public function onAreaChanged(s_crs: String, extent: BBox): void
		{
			ms_crs = s_crs
			m_extent = extent;
		}
		
		public function getTiledArea(viewBBox: BBox, zoomLevel: int): TiledArea
		{
			//find size (cols and rows)
//			var tilesInViewBBox: Point = getViewTilesInExtent(newZoomLevel, viewBBox);
			//find top left tile
			
			var maxColTiles: int = getColTiles(zoomLevel);
			var maxRowTiles: int = getRowTiles(zoomLevel);
			
			var tileBBox: Point = new Point(m_extent.width / maxColTiles, m_extent.height / maxRowTiles);
			var viewTiles: Point = new Point( Math.ceil(viewBBox.width / tileBBox.x), Math.ceil(viewBBox.height / tileBBox.y));
			
			var leftCol: int = Math.floor((viewBBox.xMin - m_extent.xMin) / tileBBox.x);
			var topRow: int = Math.floor((m_extent.yMax - viewBBox.yMax) / tileBBox.y);
			
			var area: TiledArea = new TiledArea(new TileIndex(zoomLevel, topRow, leftCol), new TileIndex(zoomLevel, topRow + viewTiles.y, leftCol + viewTiles.x));
			trace("getTiledArea viewBBox: " + viewBBox + " area: " + area);
			trace("getTiledArea viewTiles: " + viewTiles);
			return area;
			
		}
		public function getZoom(viewBBox: BBox, viewSize: Point): int
		{
			var minZoomLevel: int = 0;
			var maxZoomLevel: int = 17;
			
			var newZoomLevel: int = minZoomLevel;
			
			var scale: Point;
			var tilesInViewBBox: Point;
			var area: TiledArea;
			var tileWidth: int;
			var tileHeight: int;
			
			tileWidth = 256;
			tileHeight = 256;
			var zoomFound: Boolean = false;
			while (!zoomFound)
			{
//				tilesInViewBBox = getViewTilesInExtent(newZoomLevel, viewBBox);
				area = getTiledArea(viewBBox, newZoomLevel);
//				scale = new Point( viewSize.x / (tilesInViewBBox.x * tileWidth) ,  viewSize.y / (tilesInViewBBox.x * tileHeight));
				scale = new Point( viewSize.x / ((area.colTilesCount - 1) * tileWidth) ,  viewSize.y / ((area.rowTilesCount - 1) * tileHeight));
				
				if (scale.x <= 1 || scale.y <= 1)
				{
					zoomFound = true;
				} else {
					newZoomLevel++;
					
					if (newZoomLevel > maxZoomLevel)
						zoomFound = true;
				}
			}
			
			trace("Zoom found: " + newZoomLevel);
			return newZoomLevel;
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