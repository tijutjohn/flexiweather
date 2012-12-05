package com.iblsoft.flexiweather.ogc.multiview.synchronization
{
	import com.iblsoft.flexiweather.ogc.InteractiveLayerMSBase;
	import com.iblsoft.flexiweather.ogc.data.GlobalVariable;
	import com.iblsoft.flexiweather.ogc.data.GlobalVariableValue;
	import com.iblsoft.flexiweather.ogc.multiview.data.MultiViewConfiguration;
	import com.iblsoft.flexiweather.widgets.InteractiveWidget;
	
	import flash.events.EventDispatcher;
	
	import mx.collections.ArrayCollection;
	import mx.utils.ArrayUtil;
	
	public class LevelSynchronizator extends EventDispatcher implements ISynchronizator
	{
		public function get labelString(): String
		{
			return '<level/>';
		}
		
		private var _levelValues: Array;
		
		public function get willSynchronisePrimaryLayer(): Boolean
		{
			return true;
		}
		
		public function set viewData(data: Array): void
		{
			_levelValues = data;
		}
		
		public function set customData(data: Object): void
		{
			
		}
		
		public function get customData(): Object
		{
			return {};
		}
		
		public function LevelSynchronizator()
		{
			trace("new LevelSynchronizator");
		}
		
		private function getLevelValue(position: int): void
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
			
		}
		
		/*
		public function synchronizeWidgets(synchronizeFromWidget:InteractiveWidget, widgetsForSynchronisation:ArrayCollection):void
		{
			trace("\nLevelSychronizator synchronizeWidgets");
			var primaryLayer: InteractiveLayerMSBase = synchronizeFromWidget.interactiveLayerMap.getPrimaryLayer();
			if (primaryLayer)
			{
				var variables: Array = primaryLayer.getSynchronisedVariables();
				var levels: Array = primaryLayer.getSynchronisedVariableValuesList(GlobalVariable.LEVEL);
			
				var synchronizeFromWidgetPosition: int = getWidgetPosition(synchronizeFromWidget, widgetsForSynchronisation);
				
				var currLevel: String = primaryLayer.getSynchronisedVariableValue(GlobalVariable.LEVEL) as String;
				var currLevelPosition: int = getLevelPosition(currLevel, levels);
				
				trace("curr level: " + currLevel + " currLevelPosition: " + currLevelPosition);
				if (currLevelPosition > 0)
					levels = levels.slice(Math.max(0, currLevelPosition - synchronizeFromWidgetPosition), levels.length);
				
				
				if (synchronizeFromWidgetPosition > -1)
				{
					var cnt: int = 0;
					var total: int = widgetsForSynchronisation.length;
					for (var i: int = 0; i < total; i++)
					{
						var widget: InteractiveWidget = widgetsForSynchronisation.getItemAt(i) as InteractiveWidget;
						if (widget.id != synchronizeFromWidget.id)
						{
							var levelPos: int =  i- synchronizeFromWidgetPosition + currLevelPosition;
							if (levelPos >= 0)
							{
								var level: String = getLevel(cnt, levels);
								if (level)
								{
									trace("LevelSychronizator synchroniseWidWidgets syncWidget["+synchronizeFromWidgetPosition+"] setLevel: " + level + " for widget: " + widget.id + " i: " + i + " currLevel: " + currLevelPosition + " levelPos: " + levelPos);
									widget.interactiveLayerMap.setLevel(level);
								}
							}
						}
						cnt++;
					}
				}
			}
		}
		*/
		
		public function synchronizeWidgets(synchronizeFromWidget:InteractiveWidget, widgetsForSynchronisation:ArrayCollection, preferredSelectedIndex: int = -1):void
		{
			trace("\nLevelSychronizator synchronizeWidgets");
			if (_levelValues)
			{
				var levels: Array = _levelValues;
			
				var synchronizeFromWidgetPosition: int = getWidgetPosition(synchronizeFromWidget, widgetsForSynchronisation);
				
				if (synchronizeFromWidgetPosition > -1)
				{
					var cnt: int = 0;
					var total: int = widgetsForSynchronisation.length;
					if (total != _levelValues.length)
						trace("LevelSynchronisation => widget count != _levelValues count");
					
					for (var i: int = 0; i < total; i++)
					{
						var widget: InteractiveWidget = widgetsForSynchronisation.getItemAt(i) as InteractiveWidget;
//						if (widget.id != synchronizeFromWidget.id)
//						{
							if (_levelValues.length > cnt && _levelValues[cnt])
							{
								var levelObject: Object = _levelValues[cnt] as Object;
								if (levelObject && levelObject.hasOwnProperty('level') && levelObject.level is GlobalVariableValue)
								{
									var level: String = (levelObject.level as GlobalVariableValue).label;
									if (level)
									{
										if (widget.interactiveLayerMap.level != level)
										{
											trace("LevelSychronizator synchroniseWidWidgets syncWidget["+synchronizeFromWidgetPosition+"] setLevel: " + level + " for widget: " + widget.id + " i: " + i);
											widget.interactiveLayerMap.setLevel(level);
										} else {
											trace("LevelSychronizator synchroniseWidWidgets level fro widget ["+cnt+"] is already set to " + level + " Do not do anything!");
										}
										
									}
								}
							}
//						}
						cnt++;
					}
				}
			}
		}
		
		
		private function getLevel(position: int, levels: Array):  String
		{
			var cnt: int = 0;
			for each (var level: Object in levels)
			{
				if (cnt == position)
				{
					return level.data as String;
				}
				cnt++;
			}
			return null;
		}
		private function getLevelPosition(level: String, levels: Array): int
		{
			var cnt: int = 0;
			for each (var currLevel: Object in levels)
			{
				if (currLevel.data == level)
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
			return [GlobalVariable.LEVEL];
		}
		
		public function hasSynchronisedVariable(s_variableId: String): Boolean
		{
			return s_variableId == GlobalVariable.LEVEL;
		}
	}
}