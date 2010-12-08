package com.iblsoft.flexiweather.ogc
{
	import com.iblsoft.flexiweather.utils.Serializable;
	import com.iblsoft.flexiweather.utils.Storage;
	
	import mx.collections.ArrayCollection;

	public class ProjectionConfigurationManager implements Serializable
	{
		internal static var sm_instance: ProjectionConfigurationManager;

		internal var ma_projections: ArrayCollection = new ArrayCollection();
		
		public function ProjectionConfigurationManager()
		{
            if (sm_instance != null)
                throw new Error(
                		"ProjectionConfigurationManager can only be accessed through "
                		+ "ProjectionConfigurationManager.getInstance()");
		}
		
		public static function getInstance(): ProjectionConfigurationManager
		{
			if(sm_instance == null) {
				sm_instance = new ProjectionConfigurationManager();
			}			
			return sm_instance;
		}
		
		public function serialize(storage: Storage): void
		{
			storage.serializeNonpersistentArrayCollection("projection", ma_projections, CRSWithBBox);
			trace("pr: " + ma_projections);
		}
		
		public function addProjection(l: CRSWithBBox): void
		{
			ma_projections.addItem(l);
		}
		
		public function removeProjection(l: CRSWithBBox): void
		{
			var i: int = ma_projections.getItemIndex(l);
			if(i >= 0) {
				ma_projections.removeItemAt(i);
			}
		}
		/*
		private var areaGroups:Array = [];
		
		public function getProjectionXMLList(): XML
		{
			if (ma_projections && ma_projections.length > 0)
			{
				var areasXMLList: XML = <menuitem label='Areas' data='area'/>;
				var groupParentXML: XML;
				
				for each (var area: CRSWithBBox in ma_projections)
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
				
				var areaCustom: XML = <menuitem label='Custom...' data='custom.area'/>;
				areasXMLList.appendChild(areaCustom);
				
				return areasXMLList;
			}
			return null;
		}*/
		// getters & setters
		public function get projections(): ArrayCollection
		{ return ma_projections; }
	}
}