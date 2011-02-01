package com.iblsoft.flexiweather.ogc.cache
{
	import com.iblsoft.flexiweather.ogc.tiling.TileIndex;
	
	public class TileArea
	{
		public var tile: Object;
		public var x: int;
		public var y: int;
		public var sx: Number;
		public var sy: Number;	
		public var width: int;	
		public var height: int;	
		
		public function updateTilePosition(newX: int, newY: int): Boolean
		{
			var tileIndex: TileIndex = tile.tileIndex;
			
			if (x != newX || y !=  newY)
			{
				trace("WRONG TILE POSITION: tile: zoom: " + tileIndex.mi_tileZoom + " [" + tileIndex.mi_tileCol + "," + tileIndex.mi_tileRow + "]  [" + x + "," + y + "] new [" + newX + "," + newY + "]");
				x = newX;
				y = newY;
				return true;
			} else {
				trace("CORRECT TILE POSITION: tile: zoom: " + tileIndex.mi_tileZoom + " [" + tileIndex.mi_tileCol + "," + tileIndex.mi_tileRow + "]  [" + x + "," + y + "] new [" + newX + "," + newY + "]");
				
			}
			return false;
		}
		
		public function clone(): TileArea
		{
			var tileArea: TileArea = new TileArea();
			tileArea.x = x;
			tileArea.y = y;
			tileArea.sx = sx;
			tileArea.sy = sy;
			tileArea.width = width;
			tileArea.height = height;
			tileArea.tile = tile;
			
			return tileArea;
		}

	}
}