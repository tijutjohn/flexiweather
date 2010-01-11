package com.iblsoft.flexiweather.proj
{
	public class Projection
	{
		public static const CRS_GEOGRAPHIC: String = "CRS:84";
		public static const CRS_EPSG_GEOGRAPHIC: String = "EPSG:4326";
		
		public static function equalCRSs(s_crs1: String, s_crs2: String): Boolean
		{
			if(s_crs1 == CRS_EPSG_GEOGRAPHIC || s_crs1 == CRS_GEOGRAPHIC) {
				if(s_crs2 == CRS_EPSG_GEOGRAPHIC || s_crs2 == CRS_GEOGRAPHIC)
					return true;
			}
			return s_crs1 == s_crs2;
		}
		
	}
}