package com.iblsoft.flexiweather.ogc.multiview.synchronization
{
	import com.iblsoft.flexiweather.ogc.InteractiveLayerMSBase;
	import com.iblsoft.flexiweather.widgets.InteractiveWidget;
	
	import mx.collections.ArrayCollection;
	import mx.utils.ArrayUtil;
	
	public class MapSynchronizator implements ISynchronizator
	{
		private var timeDifference: Number = 3;
		
		public function get labelString(): String
		{
			return "<frame format='%H:%M %d.%m.%Y' tz='UTC'/>";
		}
		public function MapSynchronizator()
		{
		}
		
		public function synchronizeWidgets(synchronizeFromWidget:InteractiveWidget, widgetsForSynchronisation:ArrayCollection):void
		{
//			trace("\nFrameSychronizator synchronizeWidgets");
			var primaryLayer: InteractiveLayerMSBase = synchronizeFromWidget.interactiveLayerMap.getPrimaryLayer();
			if (primaryLayer)
			{
				var variables: Array = primaryLayer.getSynchronisedVariables();
				var frames: Array = primaryLayer.getSynchronisedVariableValuesList('frame');
			
				var synchronizeFromWidgetPosition: int = getWidgetPosition(synchronizeFromWidget, widgetsForSynchronisation);
				
				var currFrame: Date = primaryLayer.getSynchronisedVariableValue('frame') as Date;
				var currFramePosition: int = getFramePosition(currFrame, frames);
				
//				trace("curr frame: " + currFrame.toTimeString() + " currFramePosition: " + currFramePosition);
				if (currFramePosition > 0)
					frames = frames.slice(Math.max(0, currFramePosition - synchronizeFromWidgetPosition), frames.length);
				
				
				if (synchronizeFromWidgetPosition > -1)
				{
					var cnt: int = 0;
					var total: int = widgetsForSynchronisation.length;
					for (var i: int = 0; i < total; i++)
					{
						var widget: InteractiveWidget = widgetsForSynchronisation.getItemAt(i) as InteractiveWidget;
						if (widget.id != synchronizeFromWidget.id)
						{
							var framePos: int =  i- synchronizeFromWidgetPosition + currFramePosition;
							if (framePos >= 0)
							{
								var frame: Date = getFrame(cnt, frames);
								if (frame)
								{
//									trace("FrameSynchronizator synchroniseWidWidgets syncWidget["+synchronizeFromWidgetPosition+"] setFrame: " + frame.toTimeString() + " for widget: " + widget.id + " i: " + i + " currFrame: " + currFramePosition + " framePos: " + framePos);
									widget.interactiveLayerMap.setFrame(frame);
	//								var currPrimaryLayer: InteractiveLayerMSBase = widget.interactiveLayerMap.getPrimaryLayer();
									
	//								if (currPrimaryLayer)
	//								{
	//									currPrimaryLayer.se('frame', frame);
	//								}
								}
							}
						}
						cnt++;
					}
				}
			}
		}
		
		private function noDataForWidget(widget: InteractiveWidget): void
	 	{
		 
	 	}
		
		private function getFrame(position: int, frames: Array): Date
		{
			var cnt: int = 0;
			for each (var frame: Date in frames)
			{
				if (cnt == position)
				{
					return frame;
				}
				cnt++;
			}
			return null;
		}
		private function getFramePosition(frame: Date, frames: Array): int
		{
			var cnt: int = 0;
			for each (var currFrame: Date in frames)
			{
				if (currFrame.time == frame.time)
				{
					return cnt;
				}
				cnt++;
			}
			return -1;
		}
		private function getWidgetPosition(synchronizeFromWidget:InteractiveWidget, widgetsForSynchronisation:ArrayCollection): int
		{
			var cnt: int = 0;
			for each (var widget: InteractiveWidget in widgetsForSynchronisation)
			{
				if (widget.id == synchronizeFromWidget.id)
				{
					return cnt;
				}
				cnt++;
			}
			return -1;
		}
		
		public function getSynchronisedVariables():Array
		{
			return ['frame'];
		}
		
		public function hasSynchronisedVariable(s_variableId: String): Boolean
		{
			return s_variableId == 'frame';
		}
	}
}