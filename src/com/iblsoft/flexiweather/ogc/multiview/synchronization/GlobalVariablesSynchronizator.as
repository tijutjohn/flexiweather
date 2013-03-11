package com.iblsoft.flexiweather.ogc.multiview.synchronization
{
	import com.iblsoft.flexiweather.ogc.InteractiveLayerMSBase;
	import com.iblsoft.flexiweather.ogc.configuration.layers.WMSLayerConfiguration;
	import com.iblsoft.flexiweather.widgets.InteractiveWidget;
	
	import mx.collections.ArrayCollection;

	public class GlobalVariablesSynchronizator extends SynchronizatorBase
	{
		public var synchronizeFrame: Boolean;
		public var synchronizeLevel: Boolean;
		
		public function GlobalVariablesSynchronizator()
		{
			super();
		}
		
		override public function synchronizeWidgets(synchronizeFromWidget: InteractiveWidget, widgetsForSynchronisation: ArrayCollection, preferredSelectedIndex: int = -1): void
		{
			var widgetsForSynchronizing: Array = [];
			
			var globalFrameForSynchronization: Date = synchronizeFromWidget.frame;
			var globalLevelForSynchronisation: String = synchronizeFromWidget.interactiveLayerMap.level;

			if (!synchronizeFrame)
				globalFrameForSynchronization = null;
			if (!synchronizeLevel)
				globalLevelForSynchronisation = null;
			
			if (!globalFrameForSynchronization && !globalLevelForSynchronisation)
				return;
			
			for each (var widget: InteractiveWidget in widgetsForSynchronisation)
			{
				if (widget.id != synchronizeFromWidget.id)
				{
					var obj: Object = { widget: widget };
					if (globalFrameForSynchronization)
					{
						if (!widget.frame || (widget.frame && widget.frame.time != globalFrameForSynchronization.time))
						{
							listenToWidgetSynchronization(widget);
							obj.frame = true;
							
						}
					}
					
					if (globalLevelForSynchronisation)
					{
						var widgetLevel: String = widget.interactiveLayerMap.level;
						if (widgetLevel != globalLevelForSynchronisation)
						{
							listenToWidgetSynchronization(widget);
							obj.level = true;
						}
					}
					
					if (obj.frame || obj.level)
					{
						widgetsForSynchronizing.push(obj);
					}
					
//					var layers: ArrayCollection = widget.interactiveLayerMap.layers;
//					
//					for each (var layer: InteractiveLayerMSBase in layers)
//					{
//						if (layer && layer.synchroniseLevel)
//						{
//							var config: WMSLayerConfiguration = layer.configuration as WMSLayerConfiguration;
//						
//							var level: String = layer.getWMSDimensionValue(config.dimensionVerticalLevelName) as String;
//						
//						}
//					}
				}
			}
			
			//2nd pass, change frames
			for each (obj in widgetsForSynchronizing)
			{
				widget = obj.widget as InteractiveWidget;
				
				if (obj.frame)
					widget.interactiveLayerMap.setFrame(globalFrameForSynchronization);
				if (obj.level)
					widget.interactiveLayerMap.setLevel(globalLevelForSynchronisation);
				
			}
			
			checkIfSynchronizationIsDone();
		}
	}
}