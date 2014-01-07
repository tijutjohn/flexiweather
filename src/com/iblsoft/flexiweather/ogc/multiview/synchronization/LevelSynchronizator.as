package com.iblsoft.flexiweather.ogc.multiview.synchronization
{
	import com.iblsoft.flexiweather.events.InteractiveWidgetEvent;
	import com.iblsoft.flexiweather.ogc.InteractiveLayerMSBase;
	import com.iblsoft.flexiweather.ogc.SynchronisationRole;
	import com.iblsoft.flexiweather.ogc.SynchronisedVariableChangeEvent;
	import com.iblsoft.flexiweather.ogc.data.GlobalVariable;
	import com.iblsoft.flexiweather.ogc.data.GlobalVariableValue;
	import com.iblsoft.flexiweather.ogc.multiview.data.MultiViewConfiguration;
	import com.iblsoft.flexiweather.ogc.multiview.data.SynchronizationChangeType;
	import com.iblsoft.flexiweather.widgets.InteractiveLayer;
	import com.iblsoft.flexiweather.widgets.InteractiveWidget;
	
	import flash.events.EventDispatcher;
	import flash.utils.Dictionary;
	
	import mx.collections.ArrayCollection;
	import mx.utils.ArrayUtil;
	
	public class LevelSynchronizator extends SynchronizatorBase implements ISynchronizator
	{
		override public function get labelString(): String
		{
			return '<level/>';
		}
		
		private var _levelValues: Array;
		private var _widgetDictionary: Dictionary;
		
		
		override public function get willSynchronisePrimaryLayer(): Boolean
		{
			return true;
		}
		
		override public function set viewData(data: Array): void
		{
			_levelValues = data;
		}
		
		
		public function LevelSynchronizator()
		{
			super();
			
			_widgetDictionary = new Dictionary(true);
			
			registerChangeType(SynchronizationChangeType.GLOBAL_LEVEL_CHANGED);
		}
		
		private function getLevelValue(position: int): void
		{
			
		}
		
		override public function updateMapAction(widget: InteractiveWidget, position: int, configuration: MultiViewConfiguration): void
		{
			var infoObject: Object = _widgetDictionary[widget];
			if (infoObject)
			{
//				var position: int = infoObject.position;
				//update level at this position
				var oldObj: Object = _levelValues[position];
				
				_levelValues[position] = configuration.viewData[position]; 
			}
			
		}
		
		override public function synchronizeWidgets(synchronizeFromWidget:InteractiveWidget, widgetsForSynchronisation:ArrayCollection, preferredSelectedIndex: int = -1):void
		{
			if (_levelValues)
			{
				var levels: Array = _levelValues;
				
				if (preferredSelectedIndex > -1)
				{
					synchronizeFromWidget = widgetsForSynchronisation.getItemAt(preferredSelectedIndex) as InteractiveWidget;
				}
			
				var synchronizeFromWidgetPosition: int = getWidgetPosition(synchronizeFromWidget, widgetsForSynchronisation);
				
				var bGlobalLevelChange: Boolean = true;
				
				_widgetDictionary = new Dictionary(true);
				
				if (synchronizeFromWidgetPosition > -1)
				{
					var cnt: int = 0;
					var total: int = widgetsForSynchronisation.length;
					
					var widgetsForSynchronizing: Array = [];
					
					var level: String;
					
					for (var i: int = 0; i < total; i++)
					{
						var widget: InteractiveWidget = widgetsForSynchronisation.getItemAt(i) as InteractiveWidget;
						var hasSynchronizableLevel: Boolean = hasLevelSynchronizable(widget);
//						if (widget.id != synchronizeFromWidget.id)
//						{
						
						widget.addEventListener(InteractiveWidgetEvent.WIDGET_CHANGED, onWidgetChanged, false, 0, true);
						
						
						if (hasSynchronizableLevel)
						{
							if (_levelValues.length > cnt && _levelValues[cnt])
							{
								var levelObject: Object = _levelValues[cnt] as Object;
								
								_widgetDictionary[widget] = {widget: widget, position: i, levelObject: levelObject};
								
								if (levelObject && levelObject.hasOwnProperty('level') && levelObject.level is GlobalVariableValue)
								{
									level = (levelObject.level as GlobalVariableValue).label;
									if (level)
									{
										if (widget.interactiveLayerMap.level != level)
										{
											listenToWidgetSynchronization(widget);
											widgetsForSynchronizing.push( {level: level, widget: widget } );
										} else {
											trace("LevelSychronizator synchroniseWidWidgets level fro widget ["+cnt+"] is already set to " + level + " Do not do anything!");
											dataForWidgetAvailable(widget);
										}
										
									}
								}
							}
						} else {
							dataForWidgetUnvailable(widget);
						}
						cnt++;
					}
					
					//2nd pass, change frames
					for each (var obj: Object in widgetsForSynchronizing)
					{
						level = obj.level as String;
						widget = obj.widget as InteractiveWidget;
						
//						widget.interactiveLayerMap.globalVariablesManager.level = level;
						widget.interactiveLayerMap.setLevel(level, true);
						dataForWidgetAvailable(widget);
						
					}
					checkIfSynchronizationIsDone();
				}
			} else {
				checkIfSynchronizationIsDone();
			}
		}
		
		private function onWidgetChanged(event: InteractiveWidgetEvent): void
		{
			switch (event.changeDescription)
			{
				case SynchronizationChangeType.SYNCHRONIZE_LEVEL_CHANGED:
				case SynchronizationChangeType.SYNCHRONIZE_RUN_CHANGED:
				case SynchronizationChangeType.MAP_CHANGED:
				case SynchronizationChangeType.MAP_LAYER_ADDED:
				case SynchronizationChangeType.MAP_LAYER_REMOVED:
				{
					var widget: InteractiveWidget = event.target as InteractiveWidget;
					var layers: ArrayCollection = widget.interactiveLayerMap.layers;
					
					var synchronizeLevel: Boolean = false;
					
					for each (var layer: InteractiveLayerMSBase in layers)
					{
						if (layer && layer.synchroniseLevel)
						{
							synchronizeLevel = true;
							break;
						}
					}
					
					if (synchronizeLevel)
						dataForWidgetAvailable(widget);
					else
						dataForWidgetUnvailable(widget);
				}
			}
		}
		
		private function hasLevelSynchronizable(widget: InteractiveWidget): Boolean
		{
			var layers: ArrayCollection = widget.interactiveLayerMap.layers;
			for each (var layer: InteractiveLayer in layers)
			{
				if (layer is InteractiveLayerMSBase)
				{
					var synchroVars: Array = (layer as InteractiveLayerMSBase).getSynchronisedVariables();
					for each (var s_synchroVarName: String in synchroVars)
					{
						switch (s_synchroVarName.toLowerCase())
						{
							//							case GlobalVariable.FRAME:
							//								bFrameSynchronizable = true;
							//								break;
							case GlobalVariable.LEVEL:
								//synchronise level must be switchd on
								if ((layer as InteractiveLayerMSBase).synchroniseLevel)
									return true;
								break;
						}
					}
				}
			}
			return false;
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
		
		override public function getSynchronisedVariables():Array
		{
			return [GlobalVariable.LEVEL];
		}
		
		override public function hasSynchronisedVariable(s_variableId: String): Boolean
		{
			return s_variableId == GlobalVariable.LEVEL;
		}
	}
}