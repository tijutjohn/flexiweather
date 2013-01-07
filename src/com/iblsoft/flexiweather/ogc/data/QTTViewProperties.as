package com.iblsoft.flexiweather.ogc.data
{
	import com.iblsoft.flexiweather.ogc.BBox;
	import com.iblsoft.flexiweather.ogc.ILayerConfiguration;
	import com.iblsoft.flexiweather.ogc.IWMSLayerConfiguration;
	import com.iblsoft.flexiweather.ogc.cache.WMSTileCache;
	import com.iblsoft.flexiweather.ogc.tiling.QTTTileViewProperties;
	import com.iblsoft.flexiweather.ogc.tiling.TileIndex;
	import com.iblsoft.flexiweather.ogc.tiling.TileIndicesMapper;
	import com.iblsoft.flexiweather.ogc.tiling.TiledArea;
	
	import flash.events.EventDispatcher;
	import flash.net.URLRequest;

	public class QTTViewProperties extends EventDispatcher implements IViewProperties
	{
		private static var _uid: int = 0;
		
		private var _id: int;
		
		public var name: String;
		public var crs: String;
		public var zoom: Number;
		
		protected var m_cfg: ILayerConfiguration;
		
		public var tiledAreas: Array;
		
		private var _validity: Date;
		public function get validity():Date
		{
			return _validity;
		}
		public function setValidityTime(validity: Date): void
		{
			_validity = validity;
		}
		
		private var ma_specialCacheStrings: Array;
		public function get specialCacheStrings():Array
		{
			return ma_specialCacheStrings;
		}
		public function setSpecialCacheStrings(arr: Array): void
		{
			ma_specialCacheStrings = arr;
		}
		
		private var _tileIndicesMapper: TileIndicesMapper;
		public function get tileIndicesMapper(): TileIndicesMapper
		{
			return _tileIndicesMapper;
		}
		
		
		private var ma_qttTiles: Array;
		
		public function QTTViewProperties()
		{
			super();
			
			_uid++;
			
			_id = _uid;
			
			_tileIndicesMapper = new TileIndicesMapper();
			ma_qttTiles = [];
		}
		
		public function destroy(): void
		{
			m_cfg = null;
			_validity = null;
			ma_specialCacheStrings = null;
			_tileIndicesMapper.destroy();
			_tileIndicesMapper = null;
			
			for each (var qttTile: QTTTileViewProperties in ma_qttTiles)
			{
				qttTile.destroy();
			}
			ma_qttTiles = null;
			for each (var obj: Object in tiledAreas)
			{
				(obj.tiledArea as TiledArea).destroy();
				obj.tiledArea = null;
				obj.viewPart  = null;
			}
			tiledAreas = null;
			_viewBBox = null;
		}
		
		public function clearTileProperties(qttTileViewProperties: QTTTileViewProperties): void
		{
			ma_qttTiles = [];
		}
		public function addTileProperties(qttTileViewProperties: QTTTileViewProperties): void
		{
			ma_qttTiles.push(qttTileViewProperties);
		}
		
		private var _viewBBox: BBox;
		public function getViewBBox(): BBox
		{
			return _viewBBox
		}
		public function setViewBBox(bbox: BBox): void
		{
			_viewBBox = bbox;
		}
		
		public function setConfiguration(cfg: ILayerConfiguration): void
		{
			m_cfg = cfg;
		}
		
		/**
		 * Return true is viewProperties is same 
		 *  
		 * @param viewProperties
		 * @return 
		 * 
		 */		
		public function equals(viewProperties: QTTViewProperties): Boolean
		{
			//FIXME neet to implement QTTViewProperties equals function
			if (validity)
			{
				if (!viewProperties.validity)
					return false;
				if (validity.time != viewProperties.validity.time)
					return false;
			}
			return true;
		}
		
		public function isPreloaded(cache: WMSTileCache): Boolean
		{
			var isCached: Boolean = true;
			for each (var qttTile: QTTTileViewProperties in ma_qttTiles)
			{
				var isTileCached: Boolean = cache.getCacheItem(qttTile) != null;
				if (!isTileCached)
					return false;
			}
			
			//all parts are cached, so all WMS view properties are cached
			return true;
		}
		
		public function clone():IViewProperties
		{
			var viewProperties: QTTViewProperties = new QTTViewProperties();
			//FIXME implement QTTViewProperties clone() function
			
			return viewProperties
			
		}
		
		override public function toString(): String
		{
			var str: String = "QTTViewProperties["+_id+"]";
			if (ma_qttTiles)
				str += "  tiles: " + ma_qttTiles.length;
			
			return str;
		}
	
	}
}