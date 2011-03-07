package com.iblsoft.flexiweather.ogc
{
	import com.iblsoft.flexiweather.utils.Serializable;
	import com.iblsoft.flexiweather.utils.Storage;

	public class ProjectionConfiguration extends CRSWithBBox implements Serializable
	{
		private var _proj4String: String;
		public var title: String;
		
		public function get fullTitle(): String
		{	return title + " ("+crs+")";	}
		
		public function get proj4String(): String
		{	return _proj4String;	}
		
		public function set proj4String(value: String): void
		{	_proj4String = value;	}
		
		public function ProjectionConfiguration(s_crs:String = '', bbox:BBox = null, proj4String: String = '')
		{
			super(s_crs, bbox);
			
			_proj4String = proj4String;
			
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
		
		public function serialize(storage:Storage):void
		{
			proj4String = storage.serializeString("proj4-string", proj4String, null);
			var _crs: String = storage.serializeString("crs", crs, null);
			
			var xMin: int = storage.serializeInt("min-x", bbox.xMin, 0);
			var yMin: int = storage.serializeInt("min-y", bbox.yMin, 0);
			var xMax: int = storage.serializeInt("max-x", bbox.xMax, 0);
			var yMax: int = storage.serializeInt("max-y", bbox.yMax, 0);
			
			var newBBox: BBox = new BBox(xMin, yMin, xMax, yMax);
//			bbox = newBBox;
			
			setCRSAndBBox(_crs, newBBox);
			
			
//			bbox.mf_xMin = storage.serializeInt("min-x", bbox.mf_xMin, 0);
//			bbox.mf_xMax = storage.serializeInt("max-x", bbox.mf_xMax, 0);
//			bbox.mf_yMin = storage.serializeInt("min-y", bbox.mf_yMin, 0);
//			bbox.mf_yMax = storage.serializeInt("max-y", bbox.mf_yMax, 0);
			
			parseTitle();
		}
		
		override public function clone(): Object
		{
			var projection: ProjectionConfiguration = new ProjectionConfiguration(crs, bbox.clone(), proj4String);
			return projection;
		}
		
	}
}