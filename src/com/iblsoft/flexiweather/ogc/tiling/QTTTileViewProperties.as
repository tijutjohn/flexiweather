package com.iblsoft.flexiweather.ogc.tiling
{
	import com.iblsoft.flexiweather.ogc.ILayerConfiguration;
	import com.iblsoft.flexiweather.ogc.data.IViewProperties;
	import com.iblsoft.flexiweather.ogc.data.QTTViewProperties;
	
	import flash.display.Bitmap;
	import flash.net.URLRequest;
	
	public class QTTTileViewProperties implements IViewProperties
	{
		// loaded bitmap for this tileIndex
		public var bitmap: Bitmap;
		
		public var tileIndex: TileIndex;
		public var updateCycleAge: uint;
		
		private var m_qttViewProperties: QTTViewProperties;
		public function get qttViewProperties(): QTTViewProperties
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
		
		public function QTTTileViewProperties(qttViewProperties: QTTViewProperties)
		{
			m_qttViewProperties = qttViewProperties;
		}
		
		public function setConfiguration(cfg:ILayerConfiguration):void
		{
		}
		
		public function clone():IViewProperties
		{
			var qttTile: QTTTileViewProperties = new QTTTileViewProperties(qttViewProperties);
			trace("QTTTileViewProperties clone: " + qttViewProperties.specialCacheStrings[0]);
			qttTile.tileIndex = tileIndex;
			qttTile.updateCycleAge = updateCycleAge;
			qttTile.url = url;
			
			return qttTile;
		}
		
	}
}