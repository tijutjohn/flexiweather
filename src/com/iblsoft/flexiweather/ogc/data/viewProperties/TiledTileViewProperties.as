package com.iblsoft.flexiweather.ogc.data.viewProperties
{
	import com.iblsoft.flexiweather.ogc.configuration.layers.interfaces.ILayerConfiguration;
	
	import flash.display.Bitmap;
	import flash.net.URLRequest;
	import com.iblsoft.flexiweather.ogc.tiling.TileIndex;
	
	public class TiledTileViewProperties implements IViewProperties
	{
		// loaded bitmap for this tileIndex
		public var bitmap: Bitmap;
		
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
		
		public function TiledTileViewProperties(qttViewProperties: TiledViewProperties)
		{
			m_qttViewProperties = qttViewProperties;
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
		
		public function setConfiguration(cfg:ILayerConfiguration):void
		{
		}
		
		public function clone():IViewProperties
		{
			var qttTile: TiledTileViewProperties = new TiledTileViewProperties(qttViewProperties);
			trace("QTTTileViewProperties clone: " + qttViewProperties.specialCacheStrings[0]);
			qttTile.tileIndex = tileIndex;
			qttTile.updateCycleAge = updateCycleAge;
			qttTile.url = url;
			
			return qttTile;
		}
		
	}
}