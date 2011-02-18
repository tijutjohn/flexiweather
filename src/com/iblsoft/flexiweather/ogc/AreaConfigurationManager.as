package com.iblsoft.flexiweather.ogc
{
	import com.iblsoft.flexiweather.utils.Serializable;
	import com.iblsoft.flexiweather.utils.Storage;
	import com.iblsoft.flexiweather.widgets.InteractiveLayerMap;
	
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.utils.Dictionary;
	
	import mx.collections.ArrayCollection;

	public class AreaConfigurationManager extends EventDispatcher implements Serializable
	{
		public static const AREAS_CHANGED: String = 'areas changed';
		public static const AREAS_THUMBNAILS_CACHE: Dictionary = new Dictionary();
		public static const AREAS_THUMBNAILS_CACHE2: Dictionary = new Dictionary();
		
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
		
		public static function getAreaThumbnail(s_key: String, cacheID: int): Bitmap
		{
			var bd: BitmapData
			if (cacheID == 1) {
				if(s_key in AREAS_THUMBNAILS_CACHE) {
					bd = AREAS_THUMBNAILS_CACHE[s_key].image;
//					trace("getAreaThumbnail: " + s_key + " AREAS_THUMBNAILS_CACHE[s_key].image: " + AREAS_THUMBNAILS_CACHE[s_key].image);
				}
			} else {
				if (cacheID == 2)
				{
					if(s_key in AREAS_THUMBNAILS_CACHE2) {
						bd = AREAS_THUMBNAILS_CACHE2[s_key].image;
//						trace("getAreaThumbnail: " + s_key + " AREAS_THUMBNAILS_CACHE[s_key].image: " + AREAS_THUMBNAILS_CACHE2[s_key].image);
					}
				}
				
			}
			if (bd)
				return new Bitmap(bd);
				
//			if (s_key)
//				trace("getAreaThumbnail null" );
			return null;
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
//				trace("addAreaThumbnail: " + s_key + " size" + img.width + " , " + img.height + " AREAS_THUMBNAILS_CACHE[s_key]: " + AREAS_THUMBNAILS_CACHE[s_key]);
			} else {
				if (cacheID == 2)
				{	
					AREAS_THUMBNAILS_CACHE2[s_key] = {
						image: bd
					};
//					trace("addAreaThumbnail2: " + s_key + " size" + img.width + " , " + img.height + " AREAS_THUMBNAILS_CACHE2[s_key]: " + AREAS_THUMBNAILS_CACHE2[s_key]);
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
			if(i >= 0) {
				ma_areas.removeItemAt(i);
				notify();
			}
		}
		
		private function notify(): void
		{
			var event: Event = new Event(AREAS_CHANGED);
			dispatchEvent(event);
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
					if (area.isDefaultArea)
						return area;
				} 
			}
			return null;
		}
		
		private var submenuPos: int = 0;
		public function getAreaXMLList(layerComposer: InteractiveLayerMap = null, oldXMLList: XML = null): XML
		{
			if (ma_areas && ma_areas.length > 0)
			{
				areaGroups = [];
				submenuPos = 0;
				var areasXMLList: XML;
				if (oldXMLList)
				{
					while (oldXMLList.children().length() > 0)
					{
						delete oldXMLList.children()[0];
					}	
					areasXMLList = oldXMLList;
				} else {
					areasXMLList = <menuitem label='Areas' data='area' type='folder'/>;
				}
				var groupParentXML: XML;
				
				for each (var area: AreaConfiguration in ma_areas)
				{
					var lbl: String =  area.label;
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
					{
						compatibleWithLayers = layerComposer.isCompatibleWithCRS(area.projection.crs);
					}
					var areaData: String = "area."+area.projection.crs+","+area.projection.bbox.xMin+","+area.projection.bbox.yMin+","+area.projection.bbox.xMax+","+area.projection.bbox.yMax;
					var areaXML: XML = <menuitem label={lbl} data={areaData} icon={area.icon} compatibleWithLayers={compatibleWithLayers} type='area'/>
					
					if (groupName && groupName.length > 0)
					{
						groupParentXML = createGroupSubfoldersAndGetParent(groupName, areasXMLList);
						groupParentXML.appendChild(areaXML);	
						
					} else {
						areasXMLList.appendChild(areaXML);
					}
				}
				
				var areaCustom: XML = <menuitem label='Custom...' data='custom.area' type='action'/>;
				areasXMLList.appendChild(areaCustom);
				
				return areasXMLList;
			}
			return null;
		}
		
		/**
		 * Creates folders and subfolders for custom areas 
		 * @param groupName - full group name... it can consists subfolders. Use / for subolders. E.g Continents/States
		 * @param areasXMLList - root menu item
		 * @return 
		 * 
		 */		
		private function createGroupSubfoldersAndGetParent(groupName: String, areasXMLList: XML): XML
		{
			var groupParentXML: XML;
			var currGroupParentXML: XML = areasXMLList;
			var groupObject: Object;
			var parentGroupObject: Object;
			var groupsArr: Array;
			
			//check if there is more levels (split by "/")
			groupsArr = groupName.split('/');
			var level: int = 0;
			var position: int;
			
			var currJoinedGroupName: String = ''
			for each (var currGroupName: String in groupsArr)
			{
				if (level == 0)
				{
					currJoinedGroupName = currGroupName;
				} else {
					currJoinedGroupName += '/'+currGroupName
				}
				if (!areaGroups[currJoinedGroupName])
				{
					groupParentXML = <menuitem label={currGroupName}/>;
					
					groupObject = new Object();
					groupObject.parent = groupParentXML;
					groupObject.submenuPos = 0;
					
					areaGroups[currJoinedGroupName] = groupObject;
					
					if (level == 0)
					{
						position = submenuPos;
					} else {
						position = parentGroupObject.submenuPos;
					}
					
					var len:int = currGroupParentXML.elements().length();
					if (len == 0 )
						currGroupParentXML.appendChild(groupParentXML);
					else {
						if (position > 0)
							currGroupParentXML.insertChildAfter(currGroupParentXML.elements()[position - 1], groupParentXML);
						else
							currGroupParentXML.insertChildBefore(currGroupParentXML.elements()[position], groupParentXML);
					}
					if (level == 0)
					{
						submenuPos++;
					} else {
						parentGroupObject.submenuPos++;
					}
					
					
				} else {
					groupObject = areaGroups[currJoinedGroupName];
					groupParentXML = groupObject.parent as XML;
				}
				
				parentGroupObject = groupObject;
				currGroupParentXML = groupParentXML;
				level++;
			}
			
			return groupParentXML;
		}
		// getters & setters
		public function get areas(): ArrayCollection
		{ return ma_areas; }
	}
}