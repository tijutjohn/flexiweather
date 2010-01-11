package com.iblsoft.flexiweather.ogc
{
	import com.iblsoft.flexiweather.proj.Projection;
	
	import mx.collections.ArrayCollection;
	
	public class WMSLayerBase
	{
		internal var m_parent: WMSLayerGroup;
		
		internal var ms_name: String;
		internal var ms_title: String;
		internal  var ma_crsWithBBoxes: ArrayCollection = new ArrayCollection();

		public function WMSLayerBase(parent: WMSLayerGroup, xml: XML, wms: Namespace, version: Version)
		{
			ms_name = String(xml.wms::Name);
			ms_title = String(xml.wms::Title);
			
			// parse bounding box extents
			if(version.isLessThan(1, 3, 0)) {
				var s_srs: String;
				var srsBBox: BBox = null;
				var a_detectedSRSs: Array = [];
				// <BoundingBox SRS=... minx=...
				for each(var bbox: XML in xml.wms::BoundingBox) {
					s_srs = String(bbox.@SRS);
					ma_crsWithBBoxes.addItem(new CRSWithBBox(s_srs, BBox.fromXML_WMS(bbox)));
					a_detectedSRSs.push(s_srs);
				}
				// <LatLonBoundingBox minx=...
				if(xml.wms::LatLonBoundingBox.length() != 0) {
					srsBBox = BBox.fromXML_WMS(xml.wms::LatLonBoundingBox[0]);
					if(a_detectedSRSs.indexOf(Projection.CRS_EPSG_GEOGRAPHIC) < 0) {
						ma_crsWithBBoxes.addItem(new CRSWithBBox(Projection.CRS_EPSG_GEOGRAPHIC, srsBBox));
						a_detectedSRSs.push(Projection.CRS_EPSG_GEOGRAPHIC);
					}
					if(a_detectedSRSs.indexOf(Projection.CRS_EPSG_GEOGRAPHIC) < 0) {
						ma_crsWithBBoxes.addItem(new CRSWithBBox(Projection.CRS_GEOGRAPHIC, srsBBox));
						a_detectedSRSs.push(Projection.CRS_GEOGRAPHIC);
					}
				} 
				// <SRS>
				for each(var srs: XML in xml.wms::SRS) {
					s_srs = String(srs);
					if(a_detectedSRSs.indexOf(s_srs) < 0) {
						ma_crsWithBBoxes.addItem(new CRSWithBBox(s_srs));
					}
				}
			}
			else {
				var s_crs: String;
				var crsBBox: BBox = null;
				var a_detectedCRSs: Array = [];
				// <BoundingBox CRS=... minx=...
				for each(bbox in xml.wms::BoundingBox) {
					s_crs = String(bbox.@CRS);
					ma_crsWithBBoxes.addItem(new CRSWithBBox(s_crs, BBox.fromXML_WMS(bbox)));
					a_detectedCRSs.push(s_crs);
				}
				// <EX_GeographicBoundingBox minx=...
				if(xml.wms::EX_GeographicBoundingBox.length() != 0) {
					crsBBox = BBox.fromXML_WMS(xml.wms::EX_GeographicBoundingBox[0]);
					if(a_detectedCRSs.indexOf(Projection.CRS_EPSG_GEOGRAPHIC) < 0) {
						ma_crsWithBBoxes.addItem(new CRSWithBBox(Projection.CRS_EPSG_GEOGRAPHIC, crsBBox));
						a_detectedCRSs.push(Projection.CRS_EPSG_GEOGRAPHIC);
					}
					if(a_detectedCRSs.indexOf(Projection.CRS_EPSG_GEOGRAPHIC) < 0) {
						ma_crsWithBBoxes.addItem(new CRSWithBBox(Projection.CRS_GEOGRAPHIC, crsBBox));
						a_detectedCRSs.push(Projection.CRS_GEOGRAPHIC);
					}
				} 
				// <CRS>
				for each(var crs: XML in xml.wms::CRS) {
					s_crs = String(crs);
					if(a_detectedCRSs.indexOf(s_crs) < 0) {
						ma_crsWithBBoxes.addItem(new CRSWithBBox(s_crs));
					}
				}
			}
		}

		public function equals(other: WMSLayer): Boolean
		{
			if(other == null)
				return false;
			if(ms_name != other.ms_name)
				return false;
			if(ms_title != other.ms_title)
				return false;
			if(ma_crsWithBBoxes.length != other.ma_crsWithBBoxes.length)
				return false;
			for(var i: int = 0; i < ma_crsWithBBoxes.length; ++i) {
				var cb: CRSWithBBox = ma_crsWithBBoxes[i] as CRSWithBBox; 
				if(!cb.equals(other.ma_crsWithBBoxes[i] as CRSWithBBox))
					return false;
			}
			return true;
		}

		public function enumerateAllCRSs(a_out: ArrayCollection): void
		{
			for each(var crsBBox: CRSWithBBox in ma_crsWithBBoxes) {
				if(!a_out.contains(crsBBox.crs))
					a_out.addItem(crsBBox.crs);
			}
			parent.enumerateAllCRSs(a_out);
		} 

		public function getBBoxForCRS(s_crs: String): BBox
		{
			for each(var crsBBox: CRSWithBBox in ma_crsWithBBoxes) {
				if(Projection.equalCRSs(s_crs, crsBBox.crs)) {
					if(crsBBox.bbox != null)
						return crsBBox.bbox;
				}
			}
			if(parent == null)
				return null;
			return parent.getBBoxForCRS(s_crs);
		}

		public function get parent(): WMSLayerGroup
		{ return m_parent; }

		public function get name(): String
		{ return ms_name; }

		public function get title(): String
		{ return ms_title; }

		public function get crsWithBBoxes(): ArrayCollection
		{ return ma_crsWithBBoxes; }
		
		public function get label(): String
		{
			if(ms_title == null || ms_title.length == 0) {
				if(ms_name == null || ms_name.length == 0)
					return "[unnamed layer]";
				return ms_name;
			}
			if(ms_name == null || ms_name.length == 0)
				return ms_title;
			return ms_title + " (" + ms_name + ")";
		} 
	}
}