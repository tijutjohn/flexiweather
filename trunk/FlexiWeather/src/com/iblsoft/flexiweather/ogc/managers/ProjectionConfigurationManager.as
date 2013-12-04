package com.iblsoft.flexiweather.ogc.managers
{
	import com.iblsoft.flexiweather.ogc.BBox;
	import com.iblsoft.flexiweather.ogc.configuration.ProjectionConfiguration;
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
			{
				throw new Error(
						"ProjectionConfigurationManager can only be accessed through "
						+ "ProjectionConfigurationManager.getInstance()");
			}
		}

		public static function getInstance(): ProjectionConfigurationManager
		{
			if (sm_instance == null)
				sm_instance = new ProjectionConfigurationManager();
			return sm_instance;
		}

		public function serialize(storage: Storage): void
		{
			storage.serializeNonpersistentArrayCollection("projection", ma_projections, ProjectionConfiguration);
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
			//check if this is valid projection
			var proj: Projection = Projection.getByCRS(projection.crs);
			if (!proj || (proj && !Projection.isValidProjection(proj)))
			{
				//not valid projection, do not add it to parsed projections
				return;
			}
			if (!projection.bbox || (projection.bbox && (projection.bbox.width == 0 || projection.bbox.width == 0)))
			{
				return;
			}
			ma_parsedProjectionsDictionary[projection.crs] = projection;
			addProj4Projection(projection);
		}

		private function addProj4Projection(projection: ProjectionConfiguration): void
		{
			if (projection && projection.crs && projection.proj4String)
				Projection.addCRSByProj4(projection.crs, projection.proj4String, projection.bbox, projection.wrapsHorizontally);
		}

		public function getMaxExtentForProjection(projection: ProjectionConfiguration): BBox
		{
			return getMaxExtentForCRS(projection.crs);
		}

		public function getProjectionForCRS(crs: String): ProjectionConfiguration
		{
			var allProjs: ArrayCollection = getAllProjections;
			for each (var proj: ProjectionConfiguration in allProjs)
			{
				if (proj.crs == crs)
					return proj;
			}
			return null;
		}
		
		public function getMaxExtentForCRS(crs: String): BBox
		{
			var allProjs: ArrayCollection = getAllProjections;
			for each (var proj: ProjectionConfiguration in allProjs)
			{
				if (proj.crs == crs)
					return proj.bbox;
			}
			return null;
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
//			ArrayUtils.unionArrays(ma_areas.source, ma_parsedAreas.source, compareProjections);
		}

		public function addProjection(projection: ProjectionConfiguration): void
		{
			ma_projections.addItem(projection);
			addProj4Projection(projection);
		}

		public function removeProjection(projection: ProjectionConfiguration): void
		{
			var i: int = ma_projections.getItemIndex(projection);
			if (i >= 0)
				ma_projections.removeItemAt(i);
		}

		// getters & setters
		public function get projections(): ArrayCollection
		{
			return ma_projections;
		}

		public function get parsedProjections(): ArrayCollection
		{
			return ma_parsedProjections;
		}

		public function get getAllProjections(): ArrayCollection
		{
			var projections: ArrayCollection = projections;
			var projections2: ArrayCollection = parsedProjections;
			ArrayUtils.unionArrays(projections.source, projections2.source, compareProjections);
			return projections;
		}

		public function compareProjections(proj1: ProjectionConfiguration, proj2: ProjectionConfiguration): Boolean
		{
			return (proj1.crs == proj2.crs);
		}
	}
}
