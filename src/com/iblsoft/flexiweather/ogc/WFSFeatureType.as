package com.iblsoft.flexiweather.ogc
{
	import flash.events.Event;
	import flash.events.EventDispatcher;
	
	import mx.collections.ArrayCollection;
	
	public class WFSFeatureType extends EventDispatcher
	{
		internal var ms_name: String;
		internal var ms_title: String;
		internal  var ma_crsWithBBoxes: ArrayCollection = new ArrayCollection();
		
		protected var m_definition: SchemaParserDataItem;
		
		private var _items: ArrayCollection;
		
		[Bindable (event="itemsChanged")]
		public function get items(): ArrayCollection
		{
			return _items;
		}
		public function WFSFeatureType(xml: XML, wms: Namespace, version: Version)
		{
			if ((xml != null) && (wms != null)){
				ms_name = String(xml.wms::Name);
				ms_title = String(xml.wms::Title);
			}
			
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
		
		/**
		 * 
		 */
		public function setDefinition(definition: SchemaParserDataItem):void
		{
			m_definition = definition;
			
			_items = new ArrayCollection(getScalarItems());
			dispatchEvent(new Event('itemsChanged'));
		}
		
		/**
		 * 
		 */
		public function getScalarItems(): Array
		{
			if (m_definition){
				return(m_definition.getScalarItems());
			} else {
				return(null);
			}
		}
		
		/**
		 * 
		 */
		public function getScalarValues(responseXML: XMLList): Array
		{
			if (m_definition){
				return(m_definition.getScalarValues(responseXML));
			} else {
				return(null);
			}
		}
		
		/**
		 * 
		 */
		public function getFeature(resultXml: XML): WFSFeature
		{
			var ret: WFSFeature; // = new WFSFeature();
			
			if (m_definition){
				var t: Array = m_definition.getScalarValues(resultXml);
			}
			
			return(ret);
		}
	}
}