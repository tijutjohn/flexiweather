package com.iblsoft.flexiweather.ogc.data.viewProperties
{
	import com.iblsoft.flexiweather.ogc.BBox;
	import com.iblsoft.flexiweather.ogc.configuration.layers.interfaces.ILayerConfiguration;
	import com.iblsoft.flexiweather.ogc.tiling.TileIndex;
	
	import flash.display.Bitmap;
	import flash.net.URLRequest;

	public class TiledTileViewProperties implements IViewProperties
	{
		// loaded bitmap for this tileIndex
		public var bitmap: Bitmap;
		public var bitmapIsOk: Boolean;
		public var cacheKey: String;
		
		public var tileIndex: TileIndex;
		public var updateCycleAge: uint;
		private var m_qttViewProperties: TiledViewProperties;

		public function get qttViewProperties(): TiledViewProperties
		{
			return m_qttViewProperties;
		}
		private var m_url: URLRequest;

		public function get url(): URLRequest
		{
			return m_url
		}

		public function set url(value: URLRequest): void
		{
			m_url = value;
		}
		
		/**
		 * This properties are also in parent TiledViewPropertie 
		 */		
		public var crs: String;
		public var tiledAreas: Array;
		
		private var _validity: Date;
		private var ma_specialCacheStrings: Array;
		private var _viewBBox: BBox;
		
		public function get validity(): Date
		{
			return _validity;
		}
		
		
		public function get specialCacheStrings(): Array
		{
			return ma_specialCacheStrings;
		}
		

		public function TiledTileViewProperties(qttViewProperties: TiledViewProperties)
		{
			m_qttViewProperties = qttViewProperties;
		}
		
		public function setValidityTime(validity: Date): void
		{
			_validity = validity;
		}
		
		public function setSpecialCacheStrings(arr: Array): void
		{
			ma_specialCacheStrings = arr;
		}
		
		
		public function getViewBBox(): BBox
		{
			return _viewBBox
		}
		
		public function setViewBBox(bbox: BBox): void
		{
			_viewBBox = bbox;
		}

		public function destroy(): void
		{
			if (bitmap)
			{
				if (bitmap.bitmapData)
				{
					bitmap.bitmapData.dispose();
					bitmap = null;
				}
				tileIndex = null;
				m_qttViewProperties = null;
				m_url = null;
			}
		}

		public function setConfiguration(cfg: ILayerConfiguration): void
		{
		}

		public function clone(): IViewProperties
		{
			var qttTile: TiledTileViewProperties = new TiledTileViewProperties(qttViewProperties);
			qttTile.tileIndex = tileIndex;
			qttTile.updateCycleAge = updateCycleAge;
			qttTile.url = url;
			qttTile.crs = crs;
			qttTile.setSpecialCacheStrings(specialCacheStrings);
			qttTile.setValidityTime(validity);
			qttTile.setViewBBox(getViewBBox());
			qttTile.tiledAreas = tiledAreas;
			return qttTile;
		}
	}
}
