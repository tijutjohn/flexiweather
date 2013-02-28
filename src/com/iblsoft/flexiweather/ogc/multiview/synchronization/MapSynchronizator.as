package com.iblsoft.flexiweather.ogc.multiview.synchronization
{
	import com.iblsoft.flexiweather.ogc.InteractiveLayerMSBase;
	import com.iblsoft.flexiweather.ogc.data.GlobalVariable;
	import com.iblsoft.flexiweather.ogc.multiview.data.MultiViewConfiguration;
	import com.iblsoft.flexiweather.ogc.multiview.data.SynchronizationChangeType;
	import com.iblsoft.flexiweather.widgets.InteractiveWidget;
	
	import flash.events.EventDispatcher;
	import flash.utils.Dictionary;
	
	import mx.collections.ArrayCollection;
	import mx.utils.ArrayUtil;
	
	public class MapSynchronizator extends SynchronizatorBase implements ISynchronizator
	{
		protected var _widgetsMapDictionary: Dictionary = new Dictionary();
		
		override public function get labelString(): String
		{
			return "<mapName/>";
		}
		public function MapSynchronizator()
		{
			super();
			
			registerChangeType(SynchronizationChangeType.MAP_LAYER_ADDED);
			registerChangeType(SynchronizationChangeType.MAP_LAYER_REMOVED);
			registerChangeType(SynchronizationChangeType.MAP_CHANGED);
			registerChangeType(SynchronizationChangeType.WMS_STYLE_CHANGED);
			registerChangeType(SynchronizationChangeType.ALPHA_CHANGED);
			registerChangeType(SynchronizationChangeType.VISIBILITY_CHANGED);
		}
		
		override public function updateMapAction(iw: InteractiveWidget, position: int, configuration: MultiViewConfiguration): void
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
			
		override public function synchronizeWidgets(synchronizeFromWidget:InteractiveWidget, widgetsForSynchronisation:ArrayCollection, preferredSelectedIndex: int = -1):void
		{
			//there is no synchronizing needed for this syncrhonizator, all is done by AreaSynchronizator anf GlobalFrameSynchronizator
			
			var cnt: int = 0;
			var total: int = widgetsForSynchronisation.length;
			for (var i: int = 0; i < total; i++)
			{
				var widget: InteractiveWidget = widgetsForSynchronisation.getItemAt(i) as InteractiveWidget;
				var widgetMapObject: Object = _widgetsMapDictionary[widget];
				if (!widgetMapObject)
				{
					dataForWidgetUnvailable(widget);
				} else {
					dataForWidgetAvailable(widget);
				}
			}
			
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
		
		override public function getSynchronisedVariables():Array
		{
			return [GlobalVariable.FRAME];
		}
		
		override public function hasSynchronisedVariable(s_variableId: String): Boolean
		{
			return false;
		}
	}
}