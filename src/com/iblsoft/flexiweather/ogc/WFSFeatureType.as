package com.iblsoft.flexiweather.ogc
{
	import mx.collections.ArrayCollection;
	
	public class WFSFeatureType
	{
		internal var ms_name: String;
		internal var ms_title: String;
		internal  var ma_crsWithBBoxes: ArrayCollection = new ArrayCollection();
		
		public function WFSFeatureType(xml: XML, wms: Namespace, version: Version)
		{
			ms_name = String(xml.wms::Name);
			ms_title = String(xml.wms::Title);
			
			//TODO parse SRS, Operations and LatLongBoundingBox for <FeatureType>
		}
		
		public function equals(other: WFSFeatureType): Boolean
		{
			if(other == null)
				return false;
			if(ms_name != other.ms_name)
				return false;
			if(ms_title != other.ms_title)
				return false;
				
			//TODO check ma_crsWithBBoxes (this code is from WMSLayerBase)
			/*
			if(ma_crsWithBBoxes.length != other.ma_crsWithBBoxes.length)
				return false;
			for(var i: int = 0; i < ma_crsWithBBoxes.length; ++i) {
				var cb: CRSWithBBox = ma_crsWithBBoxes[i] as CRSWithBBox; 
				if(!cb.equals(other.ma_crsWithBBoxes[i] as CRSWithBBox))
					return false;
			}*/
			return true;
		}
		
		public function get name(): String
		{ return ms_name; }

		public function get title(): String
		{ return ms_title; }

	}
}