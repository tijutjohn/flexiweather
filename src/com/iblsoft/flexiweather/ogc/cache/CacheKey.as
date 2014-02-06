package com.iblsoft.flexiweather.ogc.cache
{
	import com.iblsoft.flexiweather.ogc.BBox;
	import flash.net.URLRequest;

	public class CacheKey
	{
		private var ms_key: String;

		public function get key(): String
		{
			return ms_key;
		}

		public function set key(value: String): void
		{
			ms_key = value;
		}
		public var url: URLRequest;
		public var crs: String;
		public var bbox: BBox;
		public var validity: Date;

		public function CacheKey(s_crs: String, bbox: BBox, url: URLRequest, validity: Date = null)
		{
			crs = s_crs;
			bbox = bbox;
			this.url = url;
			this.validity = validity;
		}

		protected function sortKeysArray(var1: Object, var2: Object): int
		{
			if (var1.name < var2.name)
				return -1;
			if (var1.name > var2.name)
				return 1;
			return 0;
		}
		
		protected function sortCacheKeyString(): void
		{
			if (ms_key)
			{
				var arr: Array = ms_key.split('|');
				if (arr.length > 2)
				{
					var newString: String = arr.shift() + "|" + arr.shift();
					if (arr.length > 0)
					{
						arr.sort();
						ms_key = newString + "|" + arr.join('|');
					}
				}
			}
		}

		protected function getURLParameterName(str: String): String
		{
			var arr: Array = str.split('=');
			arr.pop();
			return arr.join('=');
		}
		
		protected function getURLParameterValue(str: String): String
		{
			var arr: Array = str.split('=');
			var value: String = arr.pop();
			return value;
		}
		
		public function destroy(): void
		{
			url = null;
			crs = null;
			bbox = null;
			validity = null;
			ms_key = null;
		}

		public function toString(): String
		{
			return ms_key;
		}
	}
}
