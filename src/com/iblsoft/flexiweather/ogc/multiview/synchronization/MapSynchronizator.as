package com.iblsoft.flexiweather.ogc.multiview.synchronization
{
	import com.iblsoft.flexiweather.ogc.InteractiveLayerMSBase;
	import com.iblsoft.flexiweather.ogc.data.GlobalVariable;
	import com.iblsoft.flexiweather.ogc.multiview.data.MultiViewConfiguration;
	import com.iblsoft.flexiweather.widgets.InteractiveWidget;
	
	import flash.events.EventDispatcher;
	import flash.utils.Dictionary;
	
	import mx.collections.ArrayCollection;
	import mx.utils.ArrayUtil;
	
	public class MapSynchronizator extends EventDispatcher implements ISynchronizator
	{

		protected var _widgetsMapDictionary: Dictionary = new Dictionary();
		
		public function get willSynchronisePrimaryLayer(): Boolean
		{
			return false;
		}
		
		public function set viewData(data: Array): void
		{
			// Map synchronizator does not need any data, so it's nothing done here
		}
		
		public function set customData(data: Object): void
		{
			
		}
		
		public function get customData(): Object
		{
			return {};
		}
		
		public function get labelString(): String
		{
			return "<frame format='%H:%M %d.%m.%Y' tz='UTC'/>";
		}
		public function MapSynchronizator()
		{
		}
		
		public function canCreateMap(iw: InteractiveWidget): Boolean
		{
			return false;
		}
		
		public function createMap(iw: InteractiveWidget): void
		{
			
		}
		
		public function updateMapAction(iw: InteractiveWidget, position: int, configuration: MultiViewConfiguration): void
		{
			if (configuration && configuration.synchronizators && configuration.synchronizators.length > 0)
			{
				if (configuration.customData && configuration.customData.hasOwnProperty('dataProvider'))
				{
					var dp: ArrayCollection = configuration.customData.dataProvider as ArrayCollection;
					if (dp && dp.length > 0 && dp.length > position)
					{
						var synchronizator: ISynchronizator = configuration.synchronizators[0] as ISynchronizator;
						if (synchronizator is MapSynchronizator)
						{
							var mapSynchronizator: MapSynchronizator = synchronizator as MapSynchronizator;
							var obj: Object = dp.getItemAt(position) as Object;
							if (obj && obj.hasOwnProperty('fullPath'))
							{
								var fullPath: String = (dp.getItemAt(position) as Object).fullPath;
								_widgetsMapDictionary[iw] = {action: 'loadMap', path: fullPath}
								return;
							}
						}
					}
				}
			}
			_widgetsMapDictionary[iw] = {action: 'copyMap'};
		}
			
		public function synchronizeWidgets(synchronizeFromWidget:InteractiveWidget, widgetsForSynchronisation:ArrayCollection, preferredSelectedIndex: int = -1):void
		{
//			trace("\nFrameSychronizator synchronizeWidgets");
			var primaryLayer: InteractiveLayerMSBase = synchronizeFromWidget.interactiveLayerMap.getPrimaryLayer();
			if (primaryLayer)
			{
				var variables: Array = primaryLayer.getSynchronisedVariables();
				var frames: Array = primaryLayer.getSynchronisedVariableValuesList(GlobalVariable.FRAME);
			
				var synchronizeFromWidgetPosition: int = getWidgetPosition(synchronizeFromWidget, widgetsForSynchronisation);
				
				var currFrame: Date = primaryLayer.getSynchronisedVariableValue(GlobalVariable.FRAME) as Date;
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
	//									currPrimaryLayer.se(GlobalVariable.FRAME, frame);
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
			return [GlobalVariable.FRAME];
		}
		
		public function hasSynchronisedVariable(s_variableId: String): Boolean
		{
			return s_variableId == GlobalVariable.FRAME;
		}
	}
}