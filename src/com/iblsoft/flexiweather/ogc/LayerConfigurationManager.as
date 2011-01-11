package com.iblsoft.flexiweather.ogc
{
	import com.iblsoft.flexiweather.utils.Serializable;
	import com.iblsoft.flexiweather.utils.Storage;
	
	import flash.events.Event;
	import flash.events.EventDispatcher;
	
	import mx.collections.ArrayCollection;

	public class LayerConfigurationManager extends EventDispatcher implements Serializable
	{
		public static const LAYERS_CHANGED: String = 'layers changed';
	
		internal static var sm_instance: LayerConfigurationManager;

		internal var ma_layers: ArrayCollection = new ArrayCollection();
		
		public function LayerConfigurationManager()
		{
            if (sm_instance != null)
                throw new Error(
                		"LayerConfigurationManager can only be accessed through "
                		+ "LayerConfigurationManager.getInstance()");
		}
		
		public static function getInstance(): LayerConfigurationManager
		{
			if(sm_instance == null) {
				sm_instance = new LayerConfigurationManager();
			}			
			return sm_instance;
		}
		
		public function serialize(storage: Storage): void
		{
			storage.serializeNonpersistentArrayCollection("layer", ma_layers, WMSLayerConfiguration);
		}
		
		public function editLayer(l: WMSLayerConfiguration): void
		{
			notify();
		}
		public function addLayer(l: WMSLayerConfiguration): void
		{
			ma_layers.addItem(l);
			notify();
		}
		
		public function removeLayer(l: WMSLayerConfiguration): void
		{
			var i: int = ma_layers.getItemIndex(l);
			if(i >= 0) {
				ma_layers.removeItemAt(i);
				notify();
			}
		}
		
		private function notify(): void
		{
			var event: Event = new Event(LAYERS_CHANGED);
			dispatchEvent(event);
		}
		
		private var layerGroups:Array = [];
		private var submenuPos: int = 0;
		public function getMenuLayersXMLList(): XML
		{
			if (ma_layers && ma_layers.length > 0)
			{
				layerGroups = [];
				submenuPos = 0;
				var layersXMLList: XML = <menuitem label='Layers' data='layer'/>;
				var groupParentXML: XML;
				
				for each (var layer: WMSLayerConfiguration in ma_layers)
				{
					var folderName: String = layer.folderName;
					var layerData: String = ""//"layer."+layer.projection.crs+","+layer.projection.bbox.xMin+","+layer.projection.bbox.yMin+","+layer.projection.bbox.xMax+","+layer.projection.bbox.yMax;
					var icon: String =  '';
					var layerXML: XML = <menuitem label={layer.label} data={layerData} icon={icon}/>
					
					if (folderName && folderName.length > 0)
					{
						groupParentXML = createGroupSubfoldersAndGetParent(folderName, layersXMLList);
						groupParentXML.appendChild(layerXML);	
						
					} else {
						layersXMLList.appendChild(layerXML);
					}
				}
				
				var layerCustom: XML = <menuitem label='Custom...' data='custom.layer'/>;
				layersXMLList.appendChild(layerCustom);
				
				return layersXMLList;
			}
			return null;
		}
		
		/**
		 * Creates folders and subfolders for custom layers 
		 * @param folderName - full group name... it can consists subfolders. Use / for subolders. E.g Continents/States
		 * @param layersXMLList - root menu item
		 * @return 
		 * 
		 */		
		private function createGroupSubfoldersAndGetParent(folderName: String, layersXMLList: XML): XML
		{
			var groupParentXML: XML;
			var currGroupParentXML: XML = layersXMLList;
			var groupObject: Object;
			var parentGroupObject: Object;
			var groupsArr: Array;
			
			//check if there is more levels (split by "/")
			groupsArr = folderName.split('/');
			if (groupsArr.length > 1)
			{
				if (groupsArr[0] == 'test')
					trace('test');
			}
			var level: int = 0;
			var position: int;
			
			var currJoinedfolderName: String = ''
			for each (var currfolderName: String in groupsArr)
			{
				if (level == 0)
				{
					currJoinedfolderName = currfolderName;
				} else {
					currJoinedfolderName += '/'+currfolderName
				}
				if (!layerGroups[currJoinedfolderName])
				{
					groupParentXML = <menuitem label={currfolderName}/>;
					
					groupObject = new Object();
					groupObject.parent = groupParentXML;
					groupObject.submenuPos = 0;
					
					layerGroups[currJoinedfolderName] = groupObject;
					
					if (level == 0)
					{
						position = submenuPos;
					} else {
						position = parentGroupObject.submenuPos;
					}
					
//					if (currfolderName == 'States')
//					{
//						trace('stop');
//					}
					var len:int = currGroupParentXML.elements().length();
					if (len == 0 )
						currGroupParentXML.appendChild(groupParentXML);
					else {
//						trace("pos " + position + " len: " + len);
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
					groupObject = layerGroups[currJoinedfolderName];
					groupParentXML = groupObject.parent as XML;
				}
				
				parentGroupObject = groupObject;
				currGroupParentXML = groupParentXML;
				level++;
			}
			
			return groupParentXML;
		}
		
		// getters & setters
		public function get layers(): ArrayCollection
		{ return ma_layers; }
	}
}