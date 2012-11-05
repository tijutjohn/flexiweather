package com.iblsoft.flexiweather.ogc.wfs
{
	import com.iblsoft.flexiweather.proj.Coord;
	import com.iblsoft.flexiweather.utils.ArrayUtils;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import mx.collections.ArrayCollection;
	import com.iblsoft.flexiweather.ogc.SchemaParserDataItem;
	import com.iblsoft.flexiweather.ogc.Version;

	public class WFSFeatureType extends EventDispatcher
	{
		internal var ms_name: String;
		internal var ms_title: String;
		internal var ma_crsWithBBoxes: ArrayCollection = new ArrayCollection();
		protected var m_definition: SchemaParserDataItem;
		protected var m_definition_items: ArrayCollection;
		private var _stringItems: ArrayCollection;

		[Bindable(event = "stringItemsChanged")]
		public function get stringItems(): ArrayCollection
		{
			return _stringItems;
		}
		private var _items: ArrayCollection;

		[Bindable(event = "itemsChanged")]
		public function get items(): ArrayCollection
		{
			return _items;
		}

		public function WFSFeatureType(xml: XML, wms: Namespace, version: Version)
		{
			if ((xml != null) && (wms != null))
			{
				ms_name = String(xml.wms::Name);
				ms_title = String(xml.wms::Title);
				dispatchEvent(new Event('featureTypeChanged'));
			}
			//TODO parse SRS, Operations and LatLongBoundingBox for <FeatureType>
		}

		public function equals(other: WFSFeatureType): Boolean
		{
			if (other == null)
				return false;
			if (ms_name != other.ms_name)
				return false;
			if (ms_title != other.ms_title)
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

		[Bindable(event = "featureTypeChanged")]
		public function get name(): String
		{
			return ms_name;
		}

		[Bindable(event = "featureTypeChanged")]
		public function get title(): String
		{
			return ms_title;
		}

		/**
		 *
		 */
		public function setDefinition(definition: SchemaParserDataItem): void
		{
			m_definition = definition;
			var tmpDefinitionItems: Array = [];
			ArrayUtils.unionArrays(tmpDefinitionItems, m_definition.childrenParameters);
			m_definition_items = new ArrayCollection();
			_items = new ArrayCollection();
			//_items = new ArrayCollection(getScalarItems());
			var nItem: SchemaParserDataItem;
			for each (var defItem: SchemaParserDataItem in tmpDefinitionItems)
			{
				nItem = defItem.clone();
				nItem.parentItem = null;
				ArrayUtils.unionArrays(_items.source, nItem.getScalarItems());
			}
			dispatchEvent(new Event('itemsChanged'));
			_stringItems = getScalarItems([SchemaParserDataItem.TYPE_STRING]);
			dispatchEvent(new Event('stringItemsChanged'));
		}

		/**
		 *
		 */
		public function getScalarItems(typeFilter: Array = null): ArrayCollection
		{
			if (typeFilter)
			{
				var retItems: ArrayCollection = new ArrayCollection();
				var tmpDefinitionItems: Array = [];
				ArrayUtils.unionArrays(tmpDefinitionItems, m_definition.childrenParameters);
				var nItem: SchemaParserDataItem;
				for each (var defItem: SchemaParserDataItem in tmpDefinitionItems)
				{
					nItem = defItem.clone();
					nItem.parentItem = null;
					ArrayUtils.unionArrays(retItems.source, nItem.getScalarItems(typeFilter));
				}
				return (retItems);
			}
			else
				return (_items);
		/*if (m_definition){
return(m_definition.getScalarItems());
} else {
return(null);
}*/
		}

		/**
		 *
		 */
		public function getScalarValues(responseXML: XMLList): Array
		{
			if (m_definition)
				return (m_definition.getScalarValues(responseXML));
			else
				return (null);
		}

		/**
		 *
		 */
		public function getFeature(resultXml: XML): WFSFeature
		{
			var retFeature: WFSFeature = new WFSFeature(ms_title); // = new WFSFeature();
			var wfs: Namespace = new Namespace('http://www.opengis.net/wfs');
			var gml: Namespace = new Namespace('http://www.opengis.net/gml');
			var ibl: Namespace = new Namespace('http://www.iblsoft.com/wfs');
			var location: XML = resultXml.gml::location[0];
			if (location)
			{
				var point: XML = location.gml::Point[0];
				if (point)
				{
					var coordXML: XML = point.gml::coordinates[0];
					if (coordXML)
					{
						var coordString: String = coordXML.text();
						var coordArr: Array = coordString.split(',');
						retFeature.location = new Coord('EPSG:4326', coordArr[0], coordArr[1]);
					}
					else
					{
						trace('there is location with Point without coordinates: ' + point.toXMLString());
//						Alert.show('there is location with Point without coordinates: ' + point.toXMLString(), 'Location problem', Alert.OK);
					}
				}
				else
				{
					trace('there is location without: ' + location.toXMLString());
//					Alert.show('there is location without: ' + location.toXMLString(), 'Location problem', Alert.OK);
				}
			}
			if (m_definition)
				retFeature.values = new ArrayCollection(m_definition.getScalarValues(resultXml));
			return (retFeature);
		}
	}
}
