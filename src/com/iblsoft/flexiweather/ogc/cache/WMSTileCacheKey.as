package com.iblsoft.flexiweather.ogc.cache
{
	import com.iblsoft.flexiweather.ogc.BBox;
	import com.iblsoft.flexiweather.ogc.tiling.TileIndex;
	import com.iblsoft.flexiweather.utils.ISO8601Parser;
	import flash.net.URLRequest;

	public class WMSTileCacheKey extends CacheKey
	{
		public var m_tileIndex: TileIndex;
		public var m_validity: Date;

		public function WMSTileCacheKey(s_crs: String, bbox: BBox, tileIndex: TileIndex, url: URLRequest, validity: Date, specialStrings: Array = null)
		{
			super(s_crs, bbox, url, validity);
			key = s_crs;
			m_tileIndex = tileIndex;
			m_validity = validity;
			if (bbox != null)
				key += "|" + bbox.toBBOXString();
			if (tileIndex != null)
				key += "|" + tileIndex.toString();
			if (m_validity != null)
			{
				var timeStr: String = ISO8601Parser.dateToString(m_validity);
				key += "|validity:" + timeStr;
			}
			var a: Array = []
//			if(url.url != null) {
//				key += url.url;
//			} 
			if (specialStrings && specialStrings.length > 0)
			{
				var specialStringInside: Boolean = true;
				for each (var str: String in specialStrings)
				{
					key += "|" + str;
				}
			}
			sortCacheKeyString();
		}

		private function getURLParameterName(str: String): String
		{
			var arr: Array = str.split('=');
			arr.pop();
			return arr.join('=');
		}

		private function getURLParameterValue(str: String): String
		{
			var arr: Array = str.split('=');
			var value: String = arr.pop();
			return value;
		}

		override public function destroy(): void
		{
			super.destroy();
			m_tileIndex = null;
			m_validity = null;
		}
	}
}
