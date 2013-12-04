package com.iblsoft.flexiweather.ogc.managers
{
	import com.iblsoft.flexiweather.utils.Serializable;
	import com.iblsoft.flexiweather.utils.Storage;
	import flash.events.Event;
	import mx.collections.ArrayCollection;
	import com.iblsoft.flexiweather.ogc.configuration.MapConfiguration;

	public class MapConfigurationManager extends BaseConfigurationManager implements Serializable
	{
		public static const MAPS_CHANGED: String = 'maps changed';
		internal static var sm_instance: MapConfigurationManager;
		internal var ma_maps: ArrayCollection = new ArrayCollection();

		// getters & setters
		public function get maps(): ArrayCollection
		{
			return ma_maps;
		}

		public function MapConfigurationManager()
		{
			if (sm_instance != null)
				throw new Error("MapConfigurationManager can only be accessed through MapConfigurationManager.getInstance()");
		}

		public static function getInstance(): MapConfigurationManager
		{
			if (sm_instance == null)
				sm_instance = new MapConfigurationManager();
			return sm_instance;
		}

		public function serialize(storage: Storage): void
		{
			storage.serializePersistentArrayCollection("map", ma_maps, MapConfiguration);
		}

		public function getLayerByLabel(lbl: String): MapConfiguration
		{
			if (ma_maps && ma_maps.length > 0)
			{
				for each (var map: MapConfiguration in ma_maps)
				{
					if (map.label == lbl)
						return map;
				}
			}
			return null;
		}

		public function addMap(map: MapConfiguration): void
		{
			ma_maps.addItem(map);
			notify();
		}

		private function notify(): void
		{
			var event: Event = new Event(MAPS_CHANGED);
			dispatchEvent(event);
		}

		public function getMapsXMLList(oldXMLList: XML = null): XMLList
		{
			if (ma_maps && ma_maps.length > 0)
			{
				groups = [];
				submenuPos = 0;
				var mapsXMLList: XML;
				if (oldXMLList)
				{
					while (oldXMLList.children().length() > 0)
					{
						delete oldXMLList.children()[0];
					}
					mapsXMLList = oldXMLList;
				}
				else
				{
					mapsXMLList = <menuitem label='Maps' data='maps' type='folder'/>
							;
				}
				var groupParentXML: XML;
				for each (var map: MapConfiguration in ma_maps)
				{
					var lbl: String = map.label;
					lbl = fixLabel(lbl);
					var groupName: String = '';
					if (lbl && lbl.indexOf('/') > 0)
					{
						var lastPos: int = lbl.lastIndexOf('/');
						//there is group name
						groupName = lbl.substring(0, lastPos);
						lbl = lbl.substring(lastPos + 1, lbl.length);
					}
					var mapData: String = "maps." + map.mapConfiguration.toXMLString(); //+area.projection.crs+","+area.projection.bbox.xMin+","+area.projection.bbox.yMin+","+area.projection.bbox.xMax+","+area.projection.bbox.yMax;
					var mapXML: XML = <menuitem label={lbl} data={mapData} type='map'/>
					if (groupName && groupName.length > 0)
					{
						groupParentXML = createGroupSubfoldersAndGetParent(groupName, mapsXMLList);
						groupParentXML.appendChild(mapXML);
					}
					else
						mapsXMLList.appendChild(mapXML);
				}
//				var areaCustom: XML = <menuitem label='Custom...' data='custom.area' type='action'/>;
//				mapsXMLList.appendChild(areaCustom);
				
				latestMenuItemsList = mapsXMLList.children()
				return latestMenuItemsList;
			}
			latestMenuItemsList = null;
			return null;
		}
	}
}
