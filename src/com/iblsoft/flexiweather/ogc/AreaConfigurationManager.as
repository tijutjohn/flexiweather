package com.iblsoft.flexiweather.ogc
{
	import com.iblsoft.flexiweather.utils.Serializable;
	import com.iblsoft.flexiweather.utils.Storage;
	
	import mx.collections.ArrayCollection;

	public class AreaConfigurationManager implements Serializable
	{
		internal static var sm_instance: AreaConfigurationManager;

		internal var ma_areas: ArrayCollection = new ArrayCollection();
		
		public function AreaConfigurationManager()
		{
            if (sm_instance != null)
                throw new Error(
                		"AreaConfigurationManager can only be accessed through "
                		+ "AreaConfigurationManager.getInstance()");
		}
		
		public static function getInstance(): AreaConfigurationManager
		{
			if(sm_instance == null) {
				sm_instance = new AreaConfigurationManager();
			}			
			return sm_instance;
		}
		
		public function serialize(storage: Storage): void
		{
			storage.serializeNonpersistentArrayCollection("area", ma_areas, AreaConfiguration);
		}
		
		public function addArea(l: AreaConfiguration): void
		{
			ma_areas.addItem(l);
		}
		
		public function removeArea(l: AreaConfiguration): void
		{
			var i: int = ma_areas.getItemIndex(l);
			if(i >= 0) {
				ma_areas.removeItemAt(i);
			}
		}
		
		private var areaGroups:Array = [];
		
		public function getDefaultArea(): AreaConfiguration
		{
			if (ma_areas && ma_areas.length > 0)
			{
				var areasXMLList: XML = <menuitem label='Areas' data='area'/>;
				var groupParentXML: XML;
				
				for each (var area: AreaConfiguration in ma_areas)
				{
					if (area.ms_default_area && area.ms_default_area == true)
						return area;
				} 
			}
			return null;
		}
		
		public function getAreaXMLList(): XML
		{
			if (ma_areas && ma_areas.length > 0)
			{
				var areasXMLList: XML = <menuitem label='Areas' data='area'/>;
				var groupParentXML: XML;
				
				for each (var area: AreaConfiguration in ma_areas)
				{
					var groupName: String = area.ms_group_name;
					var areaData: String = "area."+area.crsWithBBox.crs+","+area.crsWithBBox.bbox.xMin+","+area.crsWithBBox.bbox.yMin+","+area.crsWithBBox.bbox.xMax+","+area.crsWithBBox.bbox.yMax;
					var areaXML: XML = <menuitem label={area.label} data={areaData} icon={area.icon}/>
					
					if (groupName && groupName.length > 0)
					{
						if (!areaGroups[groupName])
						{
							groupParentXML = <menuitem label={groupName}/>;
							areaGroups[groupName] = groupParentXML;
							areasXMLList.appendChild(groupParentXML);
						} else {
							groupParentXML = areaGroups[groupName];
						}
							
						groupParentXML.appendChild(areaXML);	
						
					} else {
						areasXMLList.appendChild(areaXML);
					}
				}
				
				return areasXMLList;
			}
			return null;
		}
		// getters & setters
		public function get areas(): ArrayCollection
		{ return ma_areas; }
	}
}