package com.iblsoft.flexiweather.ogc.cache
{
	import com.iblsoft.flexiweather.ogc.tiling.TileIndex;
	
	import flash.utils.Dictionary;
	
	public class TileAreaCache
	{
		private var _cache: Dictionary = new Dictionary();
		private var _length: int = 0;
		public function get length(): int
		{
			return _length;
		}
		
		private var _baseTileObject: TileArea
		
		public function addTile(tile: TileArea): void
		{
			var key: String = tile.tile.tileIndex.toString(); 
			_cache[key] = tile;
			if (_length == 0)
			{
				_baseTileObject = tile;
			}
			_length++;
			trace("AreaCache addTile key: " + key + " length: " + _length);
		}
		
		public function getTile(tileIndex: TileIndex): TileArea
		{
			var tileObject: TileArea = _cache[tileIndex.toString()];
			if (!tileObject && _length > 0)
			{
				tileObject = createTileFromCache(tileIndex);
			}
			if (!tileObject)
			{
				trace("AreaCache NO TILE");
			}
			if (tileObject)
				return tileObject.clone();
				
			return null;
		}
		
		public function createTileFromCache(tileIndex: TileIndex): TileArea
		{
			//get first tile object from cache
			if (_length > 0 && _baseTileObject)
			{
				trace("AREA CACHE: createTileFromCache: " + tileIndex);
				var _baseTileIndex: TileIndex = _baseTileObject.tile.tileIndex;
				
				var tileObject: TileArea = new TileArea();
				tileObject.tile = {tileIndex: tileIndex};
				tileObject.sx = _baseTileObject.sx;
				tileObject.sy = _baseTileObject.sy;
				tileObject.width = _baseTileObject.width;
				tileObject.height = _baseTileObject.height;
				
				var newX: int = _baseTileObject.x + (tileIndex.mi_tileCol - _baseTileIndex.mi_tileCol) * _baseTileObject.width;
				var newY: int = _baseTileObject.y + (tileIndex.mi_tileRow - _baseTileIndex.mi_tileRow) * _baseTileObject.height;
					
				tileObject.x = newX;
				tileObject.y = newY;
				
				addTile(tileObject);
				
				return tileObject;
			}
			return null;
		}
		
		public function clearCache(): void
		{
			trace("\n\nCLEAR AREA CACHE\n\n");
			_cache = new Dictionary();
			_baseTileObject = null;
			_length = 0;
		}

	}
}