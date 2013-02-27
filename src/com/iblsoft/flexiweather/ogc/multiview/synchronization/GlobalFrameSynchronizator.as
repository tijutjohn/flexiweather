package com.iblsoft.flexiweather.ogc.multiview.synchronization
{
	import com.iblsoft.flexiweather.widgets.InteractiveWidget;
	
	import mx.collections.ArrayCollection;

	public class GlobalFrameSynchronizator extends SynchronizatorBase
	{
		public function GlobalFrameSynchronizator()
		{
			super();
		}
		
		override public function synchronizeWidgets(synchronizeFromWidget: InteractiveWidget, widgetsForSynchronisation: ArrayCollection, preferredSelectedIndex: int = -1): void
		{
			var widgetsForSynchronizing: Array = [];
			
			var frame: Date = synchronizeFromWidget.frame;
			
			for each (var widget: InteractiveWidget in widgetsForSynchronisation)
			{
				if (widget.id != synchronizeFromWidget.id)
				{
					if (widget.frame.time != frame.time)
					{
						listenToWidgetSynchronization(widget);
						widgetsForSynchronizing.push( { widget: widget } );
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