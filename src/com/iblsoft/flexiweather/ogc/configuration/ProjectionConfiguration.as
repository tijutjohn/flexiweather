package com.iblsoft.flexiweather.ogc.configuration
{
	import com.iblsoft.flexiweather.utils.Serializable;
	import com.iblsoft.flexiweather.utils.Storage;
	import com.iblsoft.flexiweather.ogc.BBox;
	import com.iblsoft.flexiweather.ogc.CRSWithBBox;

	public class ProjectionConfiguration extends CRSWithBBox implements Serializable
	{
		public var title: String;

		public function get fullTitle(): String
		{
			return title + " (" + crs + ")";
		}
		private var _wrapsHorizontally: Boolean;

		public function get wrapsHorizontally(): Boolean
		{
			return _wrapsHorizontally;
		}

		public function set wrapsHorizontally(value: Boolean): void
		{
			_wrapsHorizontally = value;
		}
		private var _proj4String: String;

		public function get proj4String(): String
		{
			return _proj4String;
		}

		public function set proj4String(value: String): void
		{
			_proj4String = value;
		}

		public function ProjectionConfiguration(s_crs: String = '', bbox: BBox = null, proj4String: String = '', wrapsHorizontally: Boolean = false)
		{
			super(s_crs, bbox);
			_proj4String = proj4String;
			_wrapsHorizontally = wrapsHorizontally;
			parseTitle();
		}

		private function parseTitle(): void
		{
			title = '';
			//min _proj4 string length > 8 (+title=xx
			if (_proj4String && _proj4String.length > 8)
			{
				var proj4Arr: Array = _proj4String.split('+');
				if (proj4Arr && proj4Arr.length > 0)
				{
					for each (var item: String in proj4Arr)
					{
						if (item.indexOf('title=') == 0)
						{
							title = item.substring(6, item.length);
							return;
						}
					}
				}
			}
		}

		override public function serialize(storage: Storage): void
		{
			super.serialize(storage);
			proj4String = storage.serializeString("proj4-string", proj4String, null);
			wrapsHorizontally = storage.serializeBool("wraps-horizontally", wrapsHorizontally, false);
			if (storage.isLoading())
				parseTitle();
		}

		override public function clone(): Object
		{
			var projection: ProjectionConfiguration = new ProjectionConfiguration(crs, bbox.clone(), proj4String);
			return projection;
		}
	}
}
