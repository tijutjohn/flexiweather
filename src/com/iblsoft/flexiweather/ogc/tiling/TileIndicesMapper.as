package com.iblsoft.flexiweather.ogc.tiling
{
	import com.iblsoft.flexiweather.ogc.BBox;
	import flash.utils.Dictionary;

	public class TileIndicesMapper
	{
		private var _tileIndices: Dictionary = new Dictionary();

		public function TileIndicesMapper()
		{
		}

		public function destroy(): void
		{
			for each (var obj: Object in _tileIndices)
			{
				obj.tileIndex = null;
				obj.viewPart = null;
			}
			for (var id: String in _tileIndices)
			{
				delete _tileIndices[id];
			}
			_tileIndices = null;
		}

		private function getMapperKey(tileIndex: TileIndex): String
		{
			return tileIndex.mi_tileCol + "_" + tileIndex.mi_tileRow + "_" + tileIndex.mi_tileZoom;
		}

		private function getMapperItem(tileIndex: TileIndex): Object
		{
			return _tileIndices[getMapperKey(tileIndex)];
		}

		public function removeAll(): void
		{
			destroy();
			_tileIndices = new Dictionary();
		}

		public function getTileIndexViewPart(tileIndex: TileIndex): BBox
		{
			var object: Object = getMapperItem(tileIndex);
			if (object)
				return object.viewPart;
			return null;
		}

		public function setTileIndexViewPart(tileIndex: TileIndex, viewPart: BBox): void
		{
			addTileIndex(tileIndex, viewPart);
		}

		public function addTileIndex(tileIndex: TileIndex, viewPart: BBox): void
		{
			_tileIndices[getMapperKey(tileIndex)] = {tileIndex: tileIndex, viewPart: viewPart};
		}

		public function removeTileIndex(tileIndex: TileIndex, viewPart: BBox): void
		{
			delete _tileIndices[getMapperKey(tileIndex)]
		}

		public function tileIndexInside(tileIndex: TileIndex): Boolean
		{
			return getMapperItem(tileIndex) != null;
		}
	}
}
