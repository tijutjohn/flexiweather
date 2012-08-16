package com.iblsoft.flexiweather.ogc.multiview.synchronization
{
	import com.iblsoft.flexiweather.ogc.InteractiveLayerMSBase;
	import com.iblsoft.flexiweather.widgets.InteractiveWidget;
	
	import mx.collections.ArrayCollection;
	import mx.utils.ArrayUtil;
	
	public class LevelSynchronizator implements ISynchronizator
	{
		public function get labelString(): String
		{
			return '<level/>';
		}
		
		public function LevelSynchronizator()
		{
		}
		
		public function synchronizeWidgets(synchronizeFromWidget:InteractiveWidget, widgetsForSynchronisation:ArrayCollection):void
		{
			trace("\nLevelSychronizator synchronizeWidgets");
			var primaryLayer: InteractiveLayerMSBase = synchronizeFromWidget.interactiveLayerMap.getPrimaryLayer();
			if (primaryLayer)
			{
				var variables: Array = primaryLayer.getSynchronisedVariables();
				var levels: Array = primaryLayer.getSynchronisedVariableValuesList('level');
			
				var synchronizeFromWidgetPosition: int = getWidgetPosition(synchronizeFromWidget, widgetsForSynchronisation);
				
				var currLevel: String = primaryLayer.getSynchronisedVariableValue('level') as String;
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
			return ['level'];
		}
		
		public function hasSynchronisedVariable(s_variableId: String): Boolean
		{
			return s_variableId == 'level';
		}
	}
}