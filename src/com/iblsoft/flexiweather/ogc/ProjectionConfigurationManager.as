package com.iblsoft.flexiweather.ogc
{
	import com.iblsoft.flexiweather.proj.Projection;
	import com.iblsoft.flexiweather.utils.ArrayUtils;
	import com.iblsoft.flexiweather.utils.Serializable;
	import com.iblsoft.flexiweather.utils.Storage;
	
	import flash.utils.Dictionary;
	
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
			storage.serializeNonpersistentArrayCollection("projection", ma_projections, ProjectionConfiguration);
			trace("pr: " + ma_projections);
		}
		
		private var ma_parsedProjectionsDictionary: Dictionary = new Dictionary();
		private var ma_parsedProjections: ArrayCollection = new ArrayCollection();
		
		public function removeParsedProjections(): void
		{
			ma_parsedProjections.removeAll();
//			ma_parsedProjectionsDictionary = new Dictionary();
		}
		
		public function addParsedProjectionByCRS(projection: ProjectionConfiguration): void
		{
//			trace("ProjectionConfigurationManager addParsedAreaByCRS: " + crs.crs);
			ma_parsedProjectionsDictionary[projection.crs] = projection;
			addProj4Projection(projection);
			
		}
		private function addProj4Projection(projection: ProjectionConfiguration): void
		{
			if (projection && projection.crs && projection.proj4String)
		 		Projection.addCRSByProj4(projection.crs, projection.proj4String);
		}
		public function initializeProj4Projections(): void
		{
			 var allProjs: ArrayCollection = getAllProjections;
			 for each (var proj: ProjectionConfiguration in allProjs)
			 {
			 	addProj4Projection(proj);
			 }
		}
		public function initializeParsedProjections(): void
		{
			//FIXME check if every projection has proj4 string (mainly projection parsed from GetCapabilities)
			ma_parsedProjections.removeAll();
			
			for each (var projection: ProjectionConfiguration in ma_parsedProjectionsDictionary)
			{
				ma_parsedProjections.addItem(projection);
				addProj4Projection(projection);
			}
			trace("ProjectionConfigurationManager initializeParsedAreas items: " + ma_parsedProjections.length);
			
//			trace("getAreaXMLList ma_areas1: " + ma_areas.length);
//			ArrayUtils.unionArrays(ma_areas.source, ma_parsedAreas.source, compareProjections);
//			trace("getAreaXMLList ma_areas2: " + ma_areas.length);
		}
		
		public function addProjection(projection: ProjectionConfiguration): void
		{
			ma_projections.addItem(projection);
			addProj4Projection(projection);
		}
		
		public function removeProjection(projection: ProjectionConfiguration): void
		{
			var i: int = ma_projections.getItemIndex(projection);
			if(i >= 0) {
				ma_projections.removeItemAt(i);
			}
		}
		
		// getters & setters
		public function get projections(): ArrayCollection
		{ return ma_projections; }
		
		public function get parsedProjections(): ArrayCollection
		{ return ma_parsedProjections; }
		
		public function get getAllProjections(): ArrayCollection
		{ 
			var projections: ArrayCollection = projections; 
			var projections2: ArrayCollection = parsedProjections; 
			ArrayUtils.unionArrays(projections.source, projections2.source,  compareProjections);
			
			return projections;
		}
		
		public function compareProjections(proj1: ProjectionConfiguration, proj2: ProjectionConfiguration): Boolean
		{
			return (proj1.crs == proj2.crs);
		}
	}
}