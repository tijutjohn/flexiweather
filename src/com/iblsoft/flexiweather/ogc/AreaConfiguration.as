package com.iblsoft.flexiweather.ogc
{
	import com.iblsoft.flexiweather.utils.Serializable;
	import com.iblsoft.flexiweather.utils.Storage;

	public class AreaConfiguration implements Serializable
	{
		public var crsWithBBox: CRSWithBBox;
		
		internal var ms_default_area: Boolean;
		internal var ms_name: String;
		internal var ms_group_name: String;

		
		public function AreaConfiguration()
		{
		}

		public function serialize(storage: Storage): void
		{
			if(storage.isLoading())
			{
				crsWithBBox = new CRSWithBBox('');
				crsWithBBox.bbox = new BBox(0,0,0,0);
			}
			
			ms_name = storage.serializeString(
					"name", ms_name, null);
			ms_group_name = storage.serializeString(
					"group-name", ms_group_name, null);
			ms_default_area = storage.serializeBool(
					"default", ms_default_area, false);
					
			crsWithBBox.crs = storage.serializeString("crs", crsWithBBox.crs, null);
			
			crsWithBBox.bbox.mf_xMin = storage.serializeInt("min-x", crsWithBBox.bbox.mf_xMin, 0);
			crsWithBBox.bbox.mf_xMax = storage.serializeInt("max-x", crsWithBBox.bbox.mf_xMax, 0);
			crsWithBBox.bbox.mf_yMin = storage.serializeInt("min-y", crsWithBBox.bbox.mf_yMin, 0);
			crsWithBBox.bbox.mf_yMax = storage.serializeInt("max-y", crsWithBBox.bbox.mf_yMax, 0);
		}
		
		public function get label(): String
		{ return ms_name; }
		
	}
}