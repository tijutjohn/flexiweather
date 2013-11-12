package com.iblsoft.flexiweather.ogc.multiview.synchronization
{
	import com.iblsoft.flexiweather.ogc.InteractiveLayerMSBase;
	import com.iblsoft.flexiweather.ogc.configuration.MapTimelineConfiguration;
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
			var ilmTimelineConfiguration: MapTimelineConfiguration = ilm.timelineConfiguration;
			
			var currLayerWmsConfig: WMSLayerConfiguration;
			var synchLayerWmsConfig: WMSLayerConfiguration;
			
			for each (var widget: InteractiveWidget in widgetsForSynchronisation)
			{
				if (widget.id != synchronizeFromWidget.id)
				{
					var currILM: InteractiveLayerMap = widget.interactiveLayerMap;
					var currILMTimelineConfiguration: MapTimelineConfiguration = currILM.timelineConfiguration;
					
					//synchronize animator setting
					ilmTimelineConfiguration.copyConfiguration(currILMTimelineConfiguration);
							
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
							
							// check synchronization of global RUN
							if (synchLayerMSBase.synchroniseRun != currLayerMSBase.synchroniseRun)
								currLayerMSBase.synchroniseRun = synchLayerMSBase.synchroniseRun;
							
							
//							if (!currLayerMSBase.synchroniseRun)
							if (currLayerMSBase.synchroniseRun)
							{
								//check run
								currLayerWmsConfig = currLayerMSBase.configuration as WMSLayerConfiguration;
								synchLayerWmsConfig = synchLayerMSBase.configuration as WMSLayerConfiguration;
								
								if (currLayerWmsConfig.dimensionRunName && synchLayerWmsConfig.dimensionRunName)
								{
									var currRun: String = currLayerMSBase.getWMSDimensionValue(currLayerWmsConfig.dimensionRunName);
									var synchRun: String = synchLayerMSBase.getWMSDimensionValue(synchLayerWmsConfig.dimensionRunName);
									
									if (currRun != synchRun)
									{
										currLayerMSBase.setWMSDimensionValue(currLayerWmsConfig.dimensionRunName, synchRun);
										currLayerMSBase.refresh(false);
									}
								}
							}
							
							// check synchronization of global LEVEL
							if (synchLayerMSBase.synchroniseLevel != currLayerMSBase.synchroniseLevel)
								currLayerMSBase.synchroniseLevel = synchLayerMSBase.synchroniseLevel;
							
//							if (!currLayerMSBase.synchroniseLevel)
							if (currLayerMSBase.synchroniseLevel)
							{
								//check level
								currLayerWmsConfig = currLayerMSBase.configuration as WMSLayerConfiguration;
								synchLayerWmsConfig = synchLayerMSBase.configuration as WMSLayerConfiguration;
								
								if (currLayerWmsConfig.dimensionVerticalLevelName && synchLayerWmsConfig.dimensionVerticalLevelName)
								{
									var currLevel: String = currLayerMSBase.getWMSDimensionValue(currLayerWmsConfig.dimensionVerticalLevelName);
									var synchLevel: String = synchLayerMSBase.getWMSDimensionValue(synchLayerWmsConfig.dimensionVerticalLevelName);
										
									if (currLevel != synchLevel)
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