package com.iblsoft.flexiweather.ogc.managers
{
	import com.iblsoft.flexiweather.net.loaders.AbstractURLLoader;
	import com.iblsoft.flexiweather.net.loaders.UniURLLoader;
	import com.iblsoft.flexiweather.ogc.BBox;
	import com.iblsoft.flexiweather.ogc.InteractiveLayerWMS;
	import com.iblsoft.flexiweather.ogc.WMSLayer;
	import com.iblsoft.flexiweather.ogc.configuration.layers.LayerConfiguration;
	import com.iblsoft.flexiweather.ogc.configuration.layers.interfaces.ILayerConfiguration;
	import com.iblsoft.flexiweather.plugins.IConsole;
	import com.iblsoft.flexiweather.utils.Serializable;
	import com.iblsoft.flexiweather.utils.Storage;
	import com.iblsoft.flexiweather.widgets.InteractiveWidget;

	import flash.events.Event;

	import mx.collections.ArrayCollection;
	import mx.collections.Sort;
	import mx.controls.Alert;

	import spark.collections.SortField;

	public class LayerConfigurationManager extends BaseConfigurationManager implements Serializable
	{
		public static var debugConsole: IConsole;

		public static const LAYERS_CONFIGURATIONS_CHANGED: String = 'layersConfigurationChanged';
		public static var sm_instance: LayerConfigurationManager;
		private var ma_layersConfigurations: ArrayCollection = new ArrayCollection();

		public function LayerConfigurationManager()
		{
			if (sm_instance != null)
			{
				throw new Error(
						"LayerConfigurationManager can only be accessed through "
						+ "LayerConfigurationManager.getInstance()");
			}
		}

		public static function getInstance(): LayerConfigurationManager
		{
			if (sm_instance == null)
				sm_instance = new LayerConfigurationManager();
			return sm_instance;
		}

		public function serialize(storage: Storage): void
		{
			storage.serializePersistentArrayCollection("layer", ma_layersConfigurations, LayerConfiguration);
		}

		public function getLayerConfigurationByLabel(lbl: String): ILayerConfiguration
		{
			if (ma_layersConfigurations && ma_layersConfigurations.length > 0)
			{
				for each (var layerConfiguration: ILayerConfiguration in ma_layersConfigurations)
				{
					if (layerConfiguration.label == lbl)
						return layerConfiguration;
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
			ma_layersConfigurations.addItem(l);
			notify();
		}

		public function removeLayer(l: ILayerConfiguration): void
		{
			var i: int = ma_layersConfigurations.getItemIndex(l);
			if (i >= 0)
			{
				ma_layersConfigurations.removeItemAt(i);
				notify();
			}
		}

		private function notify(): void
		{
			var event: Event = new Event(LAYERS_CONFIGURATIONS_CHANGED);
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
			if (ma_layersConfigurations && ma_layersConfigurations.length > 0)
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
				}
				else
				{
					layersXMLList = <menuitem label='Layers' data='layer' type='folder'/>
				}
				var groupParentXML: XML;
				var iw: InteractiveWidget = new InteractiveWidget(true);
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
				ma_layersConfigurations.sort = sort;
				ma_layersConfigurations.refresh();

				var maxLayers: int = ma_layersConfigurations.length;
				debug ("\n getMenuLayersXMLList	CRS: " + currentCRS + " maxLayers: " + maxLayers);
//				maxLayers = Math.min(50, maxLayers);
				for (var i: int = 0; i < maxLayers; i++)
				{
					var layerConfig: LayerConfiguration = ma_layersConfigurations[i] as LayerConfiguration;

					var lbl: String = layerConfig.label;
					var folderName: String = '';
					compatibleWithCRS = layerConfig.isCompatibleWithCRS(currentCRS);
					if (lbl && lbl.indexOf('/') > 0)
					{
						var lastPos: int = lbl.lastIndexOf('/');
						folderName = lbl.substring(0, lastPos);
						lbl = lbl.substring(lastPos + 1, lbl.length);
					}

//					debug ("\nlayerConfiguration: " + lbl + " previewURL: " + layerConfig.previewURL);
					var layerData: String = "layer." + layerConfig.label;
					var layerXML: XML;
					var icon: String = null;
					try {
						icon = layerConfig.getPreviewURL();
						if (icon)
						{
							icon = AbstractURLLoader.fromBaseURL(icon);
							layerXML = <menuitem label={lbl} data={layerData} icon={icon} compatibleWithCRS={compatibleWithCRS} type={layerType}/>
						}
					} catch (e:Error)
					{
						debug("problem with getting icon for layerConfig: " + layerConfig + " lbl: " + lbl + " previewURL: " + layerConfig.previewURL);
//						throw new Error("problem with getting icon for layerConfig: " + layerConfig + " lbl: " + lbl + " previewURL: " + layerConfig.previewURL);
					}

					if (!icon)
						layerXML = <menuitem label={lbl} data={layerData} compatibleWithCRS={compatibleWithCRS} type={layerType}/>

					if (folderName && folderName.length > 0)
					{
						groupParentXML = createGroupSubfoldersAndGetParent(folderName, layersXMLList);
						groupParentXML.appendChild(layerXML);
					}
					else
						layersXMLList.appendChild(layerXML);
				}
				var layerCustom: XML = <menuitem label="Add custom layer..." data="map.add-layer-custom" type="action"/>
				layersXMLList.appendChild(layerCustom);

				latestMenuItemsList = layersXMLList.children();

				debug("latestMenuItemsList: " + latestMenuItemsList.toXMLString());
				return latestMenuItemsList;
			}
			latestMenuItemsList = null;

			debug("latestMenuItemsList: " + latestMenuItemsList.toXMLString());
			return latestMenuItemsList;
		}

		// getters & setters
		public function get layersConfigurations(): ArrayCollection
		{
			return ma_layersConfigurations;
		}

		override protected function debug(str: String): void
		{
//			if (debugConsole)
//				debugConsole.print(str, 'Info', 'LayerConfigurationManager');
//			trace("LayerConfigurationManager: " + str);
		}
	}
}
