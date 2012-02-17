package com.iblsoft.flexiweather.ogc.kml
{
	import com.iblsoft.flexiweather.ogc.FeatureBase;
	
	/**
	 * Main class for KML feature
	 *  
	 * @author fkormanak
	 * 
	 */	
	public class KMLFeature extends FeatureBase
	{
		public function KMLFeature(s_namespace:String, s_typeName:String, s_featureId:String)
		{
			super(s_namespace, s_typeName, s_featureId);
		}
	}
}