package com.iblsoft.flexiweather.ogc.multiview.synchronization
{
	import com.iblsoft.flexiweather.ogc.InteractiveLayerMSBase;
	import com.iblsoft.flexiweather.ogc.configuration.layers.WMSLayerConfiguration;
	import com.iblsoft.flexiweather.widgets.InteractiveWidget;
	
	import mx.collections.ArrayCollection;

	public class GlobalVariablesSynchronizator extends SynchronizatorBase
	{
		public var synchronizeFrame: Boolean;
		public var synchronizeRun: Boolean;
		public var synchronizeLevel: Boolean;
		
		public function GlobalVariablesSynchronizator()
		{
			super();
		}
		
		override public function synchronizeWidgets(synchronizeFromWidget: InteractiveWidget, widgetsForSynchronisation: ArrayCollection, preferredSelectedIndex: int = -1): void
		{
			var widgetsForSynchronizing: Array = [];
			
			var globalFrameForSynchronization: Date = synchronizeFromWidget.frame;
			var globalRunForSynchronisation: Date = synchronizeFromWidget.interactiveLayerMap.run;
			var globalLevelForSynchronisation: String = synchronizeFromWidget.interactiveLayerMap.level;

			if (!synchronizeFrame)
				globalFrameForSynchronization = null;
			if (!synchronizeRun)
				globalRunForSynchronisation = null;
			if (!synchronizeLevel)
				globalLevelForSynchronisation = null;
			
			if (!globalFrameForSynchronization && !globalRunForSynchronisation && !globalLevelForSynchronisation)
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
					
					if (globalRunForSynchronisation)
					{
						var widgetRun: Date = widget.interactiveLayerMap.run;
						if (widgetRun != globalRunForSynchronisation)
						{
							listenToWidgetSynchronization(widget);
							obj.run = true;
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
					
					if (obj.frame || obj.level || obj.run)
					{
						widgetsForSynchronizing.push(obj);
					}
				}
			}
			
			//2nd pass, change frames
			for each (obj in widgetsForSynchronizing)
			{
				widget = obj.widget as InteractiveWidget;
				
				if (obj.frame)
					widget.interactiveLayerMap.setFrame(globalFrameForSynchronization);
				if (obj.run)
					widget.interactiveLayerMap.setRun(globalRunForSynchronisation);
				if (obj.level)
					widget.interactiveLayerMap.setLevel(globalLevelForSynchronisation);
				
			}
			
			checkIfSynchronizationIsDone();
		}
	}
}