package com.iblsoft.flexiweather.ogc.managers
{
	import com.iblsoft.flexiweather.ogc.BBox;
	import com.iblsoft.flexiweather.ogc.configuration.AreaConfiguration;
	import com.iblsoft.flexiweather.ogc.configuration.ProjectionConfiguration;
	import com.iblsoft.flexiweather.utils.LoggingUtils;
	import com.iblsoft.flexiweather.utils.Serializable;
	import com.iblsoft.flexiweather.utils.Storage;
	import com.iblsoft.flexiweather.widgets.InteractiveLayerMap;
	
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.events.Event;
	import flash.utils.Dictionary;
	
	import mx.collections.ArrayCollection;
	import mx.collections.Sort;
	
	import spark.collections.SortField;

	public class AreaConfigurationManager extends BaseConfigurationManager implements Serializable
	{
		public static const AREAS_CHANGED: String = 'areas changed';
		public static const AREAS_THUMBNAILS_CACHE: Dictionary = new Dictionary();
		public static const AREAS_THUMBNAILS_CACHE2: Dictionary = new Dictionary();
		private static var sm_instance: AreaConfigurationManager;
		private var ma_areas: ArrayCollection = new ArrayCollection();

		public function AreaConfigurationManager()
		{
			if (sm_instance != null)
			{
				throw new Error(
						"AreaConfigurationManager can only be accessed through "
						+ "AreaConfigurationManager.getInstance()");
			}
			ma_areas = new ArrayCollection();
		}

		public static function getInstance(): AreaConfigurationManager
		{
			if (sm_instance == null)
				sm_instance = new AreaConfigurationManager();
			return sm_instance;
		}

		public static function getAreaThumbnail(s_key: String, cacheID: int): Bitmap
		{
			var bd: BitmapData
			if (cacheID == 1)
			{
				if (s_key in AREAS_THUMBNAILS_CACHE)
				{
					bd = AREAS_THUMBNAILS_CACHE[s_key].image;
				}
			}
			else
			{
				if (cacheID == 2)
				{
					if (s_key in AREAS_THUMBNAILS_CACHE2)
					{
						bd = AREAS_THUMBNAILS_CACHE2[s_key].image;
					}
				}
			}
			if (bd)
				return new Bitmap(bd);
			return null;
		}

		public static function resetCachedAreaThumbnail(s_key: String, cacheID: int): void
		{
			var img: BitmapData;
			if (cacheID == 1)
			{
				if (AREAS_THUMBNAILS_CACHE[s_key])
				{
					img = AREAS_THUMBNAILS_CACHE[s_key]['image'] as BitmapData;
					delete AREAS_THUMBNAILS_CACHE[s_key];
				}
			} else if (cacheID == 2) {
				if (AREAS_THUMBNAILS_CACHE2[s_key])
				{
					img = AREAS_THUMBNAILS_CACHE2[s_key]['image'] as BitmapData;
					delete AREAS_THUMBNAILS_CACHE2[s_key];
				}
			}
			
			if (img)
				img.dispose();
			
		}
		
		public static function addAreaThumbnail(img: Bitmap, s_key: String, cacheID: int): void
		{
			if (img.width == 0 || img.height == 0)
				return;
			var bd: BitmapData = img.bitmapData.clone();
			if (cacheID == 1)
			{
				AREAS_THUMBNAILS_CACHE[s_key] = {
							image: bd
						};
			}
			else
			{
				if (cacheID == 2)
				{
					AREAS_THUMBNAILS_CACHE2[s_key] = {
								image: bd
							};
				}
			}
		}

		public function setAllAreas(areas: ArrayCollection): void
		{
			ma_areas.removeAll();
			ma_areas.addAll(areas);
		}

		public function serializeForConfiguration(storage: Storage): void
		{
			var defaultArea: AreaConfiguration;
			if (storage.isStoring())
			{
				defaultArea = getDefaultArea();
				if (defaultArea)
					storage.serialize('area', defaultArea);
			} else {
				defaultArea = new AreaConfiguration();
				storage.serialize('area', defaultArea);
				defaultArea.name = "CustomArea " + defaultArea.projection.crs;
				if (defaultArea.isDefaultArea)
				{
					_defaultArea = defaultArea;
				}
			}
			
		}
		public function serialize(storage: Storage): void
		{
			storage.serializeNonpersistentArrayCollection("area", ma_areas, AreaConfiguration);
		}

		public function editArea(area: AreaConfiguration): void
		{
			area.update();
			notify();
		}

		public function addArea(area: AreaConfiguration): void
		{
			ma_areas.addItem(area);
			notify();
		}

		public function removeArea(area: AreaConfiguration): void
		{
			var i: int = ma_areas.getItemIndex(area);
			if (i >= 0)
			{
				ma_areas.removeItemAt(i);
				notify();
			}
		}

		private function notify(): void
		{
			var event: Event = new Event(AREAS_CHANGED);
			dispatchEvent(event);
		}

		public function makeDefaultArea(bbox: BBox, crs: String): void
		{
			var projConfig: ProjectionConfiguration = ProjectionConfigurationManager.getInstance().getProjectionForCRS(crs);
			if (projConfig)
			{
				var newProjectionConfiguration: ProjectionConfiguration = new ProjectionConfiguration(crs, bbox, projConfig.proj4String);
					
				if (!_defaultArea)
				{
					_defaultArea = new AreaConfiguration();
					trace("There were no previous default area!");
				}
				_defaultArea.projection = newProjectionConfiguration;
			} else {
				trace("makeDefaultArea can not find projConfig for projetion: " + crs);
			}
				
				
		}
		
		private var _defaultArea: AreaConfiguration;
		
		public function getDefaultArea(): AreaConfiguration
		{
			if (_defaultArea)
				return _defaultArea;
			
//			if (ma_areas && ma_areas.length > 0)
//			{
//				var areasXMLList: XML = <menuitem label='Areas' data='area'/>
//						;
//				var groupParentXML: XML;
//				for each (var area: AreaConfiguration in ma_areas)
//				{
//					if (area.isDefaultArea)
//						return area;
//				}
//			}
			return null;
		}

		public function getAreaXMLList(layerComposer: InteractiveLayerMap = null, oldXMLList: XML = null): XMLList
		{
			if (ma_areas && ma_areas.length > 0)
			{
				groups = [];
				submenuPos = 0;
				var areasXMLList: XML;
				if (oldXMLList)
				{
					while (oldXMLList.children().length() > 0)
					{
						delete oldXMLList.children()[0];
					}
					areasXMLList = oldXMLList;
				}
				else
				{
					areasXMLList = <menuitem label='Areas' data='area' type='folder'/>
							;
				}
				var groupParentXML: XML;
				//sort array first
				var sort: Sort = new Sort();
				var labelField: SortField = new SortField('label');
				sort.fields = [labelField];
				sort.compareFunction = sortArray;
				ma_areas.sort = sort;
				ma_areas.refresh();
				for each (var area: AreaConfiguration in ma_areas)
				{
					var lbl: String = area.label;
					lbl = fixLabel(lbl);
					var groupName: String = '';
					if (lbl.indexOf('/') > 0)
					{
						var lastPos: int = lbl.lastIndexOf('/');
						//there is group name
						groupName = lbl.substring(0, lastPos);
						lbl = lbl.substring(lastPos + 1, lbl.length);
					}
					var compatibleWithLayers: Boolean = true;
					if (layerComposer)
						compatibleWithLayers = layerComposer.isCompatibleWithCRS(area.projection.crs);
					var areaData: String = "area." + area.projection.crs + "," + area.projection.bbox.xMin + "," + area.projection.bbox.yMin + "," + area.projection.bbox.xMax + "," + area.projection.bbox.yMax;
					var areaXML: XML = <menuitem label={lbl} data={areaData} icon={area.icon} compatibleWithLayers={compatibleWithLayers} type='area'/>
					if (groupName && groupName.length > 0)
					{
						groupParentXML = createGroupSubfoldersAndGetParent(groupName, areasXMLList);
						groupParentXML.appendChild(areaXML);
					}
					else
						areasXMLList.appendChild(areaXML);
				}

				var areaCustom: XML = <menuitem label="Restore to default area" data="map.restore-default-area" type="action"/>
				areasXMLList.appendChild(areaCustom);

				areasXMLList.appendChild(getCustomArea());
				latestMenuItemsList = areasXMLList.children() 
				return latestMenuItemsList;
			}
			latestMenuItemsList = getNoAreasXMLList()
			return latestMenuItemsList;
		}

		public function getNoAreasXMLList(): XMLList
		{
			var areasXMLList: XML;
			areasXMLList = <menuitem label='Areas' data='area' type='folder'/>
					;
			areasXMLList.appendChild(getCustomArea());
			return areasXMLList.children();
		}

		private function getCustomArea(): XML
		{
			var areaCustom: XML = <menuitem label='Add custom area...' data='custom.area' type='action'/>
					;
			return areaCustom;
		}

		// getters & setters
		public function get areas(): ArrayCollection
		{
			return ma_areas;
		}
	}
}
