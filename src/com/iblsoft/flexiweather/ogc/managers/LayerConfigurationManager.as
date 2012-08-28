package com.iblsoft.flexiweather.ogc.managers
{
	import com.iblsoft.flexiweather.net.loaders.AbstractURLLoader;
	import com.iblsoft.flexiweather.net.loaders.UniURLLoader;
	import com.iblsoft.flexiweather.utils.Serializable;
	import com.iblsoft.flexiweather.utils.Storage;
	import com.iblsoft.flexiweather.widgets.InteractiveWidget;
	
	import flash.events.Event;
	
	import mx.collections.ArrayCollection;
	import mx.collections.Sort;
	
	import spark.collections.SortField;
	import com.iblsoft.flexiweather.ogc.BBox;
	import com.iblsoft.flexiweather.ogc.ILayerConfiguration;
	import com.iblsoft.flexiweather.ogc.InteractiveLayerWMS;
	import com.iblsoft.flexiweather.ogc.LayerConfiguration;
	import com.iblsoft.flexiweather.ogc.WMSLayer;

	public class LayerConfigurationManager extends BaseConfigurationManager implements Serializable
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
			storage.serializePersistentArrayCollection("layer", ma_layers, LayerConfiguration);
		}
		
		public function getLayerConfigurationByLabel(lbl: String): ILayerConfiguration
		{
			if (ma_layers && ma_layers.length > 0)
			{
				for each (var layer: ILayerConfiguration in ma_layers)
				{
					if (layer.label == lbl)
						return layer;
				}
			}
			return null;
		}
		
		public function editLayer(l: ILayerConfiguration): void
		{
			notify();
		}
		public function addLayer(l: ILayerConfiguration): void
		{
			ma_layers.addItem(l);
			notify();
		}
		
		public function removeLayer(l: ILayerConfiguration): void
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
		
		private function checkIfLayerIsCompatibleWithCrs(configurations: Array, crs: String = null): Boolean
		{
			if (!crs)
				return true;
				
			if (configurations && configurations.length > 0)
			{
				for each (var layer: WMSLayer in configurations)
				{
					if (layer.isCompatibleWithCRS(crs))
						return true;
				}
			}
			
			return false;
		}
		public function getMenuLayersXMLList(currentCRS: String = null, oldXMLList: XML = null): XMLList
		{
			if (ma_layers && ma_layers.length > 0)
			{
				groups = [];
				submenuPos = 0;
				var layersXMLList: XML;
				if (oldXMLList)
				{
					while (oldXMLList.children().length() > 0)
					{
						delete oldXMLList.children()[0];
					}	
					layersXMLList = oldXMLList;
				} else {
					layersXMLList = <menuitem label='Layers' data='layer' type='folder'/>;
				}
				var groupParentXML: XML;
				
				var iw: InteractiveWidget = new InteractiveWidget();
				iw.width = 150;
				iw.height = 100;
				
				var lWMS: InteractiveLayerWMS;
				var bbox: BBox;
				var compatibleWithCRS: Boolean = true;
				var layerType: String = 'layer';
				
				var sort: Sort = new Sort();
				var labelField: SortField = new SortField('label');
				sort.fields = [labelField];
				sort.compareFunction = sortArray;
				ma_layers.sort = sort;
				ma_layers.refresh();
				
				for each (var layerConfig: LayerConfiguration in ma_layers)
				{
					var lbl: String = layerConfig.label;
					var folderName: String = '';
					
					compatibleWithCRS =  layerConfig.isCompatibleWithCRS(currentCRS);
					
//					if (currentCRS)
//					{
//						if (!compatibleWithCRS)
//						{
//							trace("Layer : " + lbl + " is not compatible with " + currentCRS);
//						}
//					}
					
					if (lbl && lbl.indexOf('/') > 0)
					{
						var lastPos: int = lbl.lastIndexOf('/');
						
						folderName = lbl.substring(0, lastPos);
						lbl = lbl.substring(lastPos+1, lbl.length);
					}
					
						
					var icon: String = layerConfig.getPreviewURL();
					if (!icon)
					{
						//just to test problem with icon is null -> remove next line when fixed
						layerConfig.getPreviewURL();
					}
					
					if (icon)
					{
						icon = AbstractURLLoader.fromBaseURL(icon);
					}
					var layerData: String = "layer."+layerConfig.label;
					var layerXML: XML = <menuitem label={lbl} data={layerData} icon={icon} compatibleWithCRS={compatibleWithCRS} type={layerType}/>
					
					if (folderName && folderName.length > 0)
					{
						groupParentXML = createGroupSubfoldersAndGetParent(folderName, layersXMLList);
						groupParentXML.appendChild(layerXML);	
						
					} else {
						layersXMLList.appendChild(layerXML);
					}
				}
				var layerCustom: XML = <menuitem label="Add custom layer..." data="map.add-layer-custom" type="action"/>
				layersXMLList.appendChild(layerCustom);
				
				return layersXMLList.children();
			}
			return null;
		}
		
		
		// getters & setters
		public function get layers(): ArrayCollection
		{ return ma_layers; }
	}
}