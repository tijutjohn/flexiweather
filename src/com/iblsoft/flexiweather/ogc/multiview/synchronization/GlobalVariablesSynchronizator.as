package com.iblsoft.flexiweather.ogc.multiview.synchronization
{
	import com.iblsoft.flexiweather.ogc.InteractiveLayerMSBase;
	import com.iblsoft.flexiweather.ogc.configuration.layers.WMSLayerConfiguration;
	import com.iblsoft.flexiweather.widgets.InteractiveWidget;
	
	import mx.collections.ArrayCollection;

	public class GlobalVariablesSynchronizator extends SynchronizatorBase
	{
		public function GlobalVariablesSynchronizator()
		{
			super();
		}
		
		override public function synchronizeWidgets(synchronizeFromWidget: InteractiveWidget, widgetsForSynchronisation: ArrayCollection, preferredSelectedIndex: int = -1): void
		{
			var widgetsForSynchronizing: Array = [];
			
			var frame: Date = synchronizeFromWidget.frame;
			if (!frame)
				return;
			
			var level: String = synchronizeFromWidget.interactiveLayerMap.level;
			
			for each (var widget: InteractiveWidget in widgetsForSynchronisation)
			{
				if (widget.id != synchronizeFromWidget.id)
				{
					var obj: Object = { widget: widget };
					if (!widget.frame || (widget.frame && widget.frame.time != frame.time))
					{
						listenToWidgetSynchronization(widget);
						obj.frame = true;
						widgetsForSynchronizing.push(obj);
					}
					var layers: ArrayCollection = widget.interactiveLayerMap.layers;
					
					for each (var layer: InteractiveLayerMSBase in layers)
					{
						if (layer && layer.synchroniseLevel)
						{
							var config: WMSLayerConfiguration = layer.configuration as WMSLayerConfiguration;
						
							var levelObj: Object = layer.getWMSDimensionValue(config.dimensionVerticalLevelName);
						
//							if (layer.level  frame.time))
//							{
//								listenToWidgetSynchronization(widget);
//								obj.frame = true;
//							}
						}
					}
				}
			}
			
			//2nd pass, change frames
			for each (var obj: Object in widgetsForSynchronizing)
			{
				widget = obj.widget as InteractiveWidget;
				
				widget.interactiveLayerMap.setFrame(frame);
				
			}
			
			checkIfSynchronizationIsDone();
		}
	}
}