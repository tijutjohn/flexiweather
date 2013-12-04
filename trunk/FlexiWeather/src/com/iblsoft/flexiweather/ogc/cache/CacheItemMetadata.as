package com.iblsoft.flexiweather.ogc.cache
{
	import com.iblsoft.flexiweather.ogc.BBox;
	import flash.net.URLRequest;

	public dynamic class CacheItemMetadata
	{
		private var _crs: String;
		private var _bbox: BBox;
		private var _url: URLRequest;
		/**
		 * time in which image is valid
		 */
		private var _validity: Date;
		/**
		 * Dimensions, which will be part of Cache key
		 */
		private var _dimensions: Array;
		private var _updateCycleAge: uint;

		public function CacheItemMetadata()
		{
			super();
		}

		public function get crs(): String
		{
			return _crs;
		}

		public function set crs(value: String): void
		{
			_crs = value;
		}

		public function get bbox(): BBox
		{
			return _bbox;
		}

		public function set bbox(value: BBox): void
		{
			_bbox = value;
		}

		public function get url(): URLRequest
		{
			return _url;
		}

		public function set url(value: URLRequest): void
		{
			_url = value;
		}

		public function get validity(): Date
		{
			return _validity;
		}

		public function set validity(value: Date): void
		{
			_validity = value;
		}

		public function get dimensions(): Array
		{
			return _dimensions;
		}

		public function set dimensions(value: Array): void
		{
			_dimensions = value;
		}

		public function get updateCycleAge(): uint
		{
			return _updateCycleAge;
		}

		public function set updateCycleAge(value: uint): void
		{
			_updateCycleAge = value;
		}
	}
}
