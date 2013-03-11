package com.iblsoft.flexiweather.ogc.multiview.synchronization
{
	import com.iblsoft.flexiweather.ogc.InteractiveLayerMSBase;
	import com.iblsoft.flexiweather.ogc.configuration.layers.WMSLayerConfiguration;
	import com.iblsoft.flexiweather.widgets.InteractiveLayer;
	import com.iblsoft.flexiweather.widgets.InteractiveLayerMap;
	import com.iblsoft.flexiweather.widgets.InteractiveWidget;
	
	import mx.collections.ArrayCollection;

	public class MapLayersPropertiesSynchronizator extends SynchronizatorBase
	{
		public function MapLayersPropertiesSynchronizator()
		{
			super();
		}
		
		override public function synchronizeWidgets(synchronizeFromWidget: InteractiveWidget, widgetsForSynchronisation: ArrayCollection, preferredSelectedIndex: int = -1): void
		{
			var widgetsForSynchronizing: Array = [];
			
			var ilm: InteractiveLayerMap = synchronizeFromWidget.interactiveLayerMap;
			for each (var widget: InteractiveWidget in widgetsForSynchronisation)
			{
				if (widget.id != synchronizeFromWidget.id)
				{
					var currILM: InteractiveLayerMap = widget.interactiveLayerMap;
					
					var totalLayers: int = widget.interactiveLayerMap.layers.length;
					for (var i: int = 0; i < totalLayers; i++)
					{
						var currLayer: InteractiveLayer = currILM.getLayerAt(i);
						var synchLayer: InteractiveLayer = ilm.getLayerAt(i);
						
						if (synchLayer.alpha != currLayer.alpha)
							currLayer.alpha = synchLayer.alpha;
						
						if (synchLayer.visible != currLayer.visible)
							currLayer.visible = synchLayer.visible;
						
						if (synchLayer is InteractiveLayerMSBase)
						{
							var synchLayerMSBase: InteractiveLayerMSBase = synchLayer as InteractiveLayerMSBase;
							var currLayerMSBase: InteractiveLayerMSBase = currLayer as InteractiveLayerMSBase;
							
							if (synchLayerMSBase.synchroniseLevel != currLayerMSBase.synchroniseLevel)
								currLayerMSBase.synchroniseLevel = synchLayerMSBase.synchroniseLevel;
							
							if (!currLayerMSBase.synchroniseLevel)
							{
								//check level
								var currLayerWmsConfig: WMSLayerConfiguration = currLayerMSBase.configuration as WMSLayerConfiguration;
								var synchLayerWmsConfig: WMSLayerConfiguration = synchLayerMSBase.configuration as WMSLayerConfiguration;
								
								if (currLayerWmsConfig.dimensionVerticalLevelName && synchLayerWmsConfig.dimensionVerticalLevelName)
								{
									var currLevel: String = currLayerMSBase.getWMSDimensionValue(currLayerWmsConfig.dimensionVerticalLevelName);
									var synchLevel: String = synchLayerMSBase.getWMSDimensionValue(synchLayerWmsConfig.dimensionVerticalLevelName);
										
									if (currLevel !=synchLevel)
									{
										currLayerMSBase.setWMSDimensionValue(currLayerWmsConfig.dimensionVerticalLevelName, synchLevel);
										currLayerMSBase.refresh(false);
									}
								}
							}
							
						}
					}
				}
			}
			
			
			checkIfSynchronizationIsDone();
		}
	}
}