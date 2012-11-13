package com.iblsoft.flexiweather.ogc.multiview.synchronization
{
	import com.iblsoft.flexiweather.ogc.BBox;
	import com.iblsoft.flexiweather.widgets.InteractiveWidget;
	
	import flash.utils.clearTimeout;
	import flash.utils.setTimeout;
	
	import mx.collections.ArrayCollection;
	
	public class AreaSynchronizator implements ISynchronizator
	{
		private var _areaChangeTimeout: Number;
		
		public function get willSynchronisePrimaryLayer(): Boolean
		{
			return false;
		}
		
		public function set viewData(data: Array): void
		{
			// Area synchronizator does not need any data, so it's nothing done here
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
			return '';
		}
		
		public function AreaSynchronizator()
		{
		}
		
		public function synchronizeWidgets(synchronizeFromWidget: InteractiveWidget, widgetsForSynchronisation: ArrayCollection, preferredSelectedIndex: int = -1):void
		{
			
			if (_areaChangeTimeout > 0)
			{
				clearTimeout(_areaChangeTimeout);
			}
			
			
			var crs: String = synchronizeFromWidget.getCRS();
			var viewBBox: BBox = synchronizeFromWidget.getViewBBox();
			
			var cnt: int = 1;
			trace("\n\n AreaSynchronizator synchronizeWidgets CRS: " + crs + " vievBBox: " + viewBBox.toBBOXString());
			for each (var widget: InteractiveWidget in widgetsForSynchronisation)
			{
				if (widget.id != synchronizeFromWidget.id)
				{
					setTimeout(updateWidgetArea, cnt * 2300, widget, crs, viewBBox);
//					cnt++;
				}
			}
			_areaChangeTimeout = setTimeout(changeAreaAfterDelay, cnt * 2350, synchronizeFromWidget, widgetsForSynchronisation);
		}
		
		private function updateWidgetArea(widget: InteractiveWidget, crs: String, viewBBox: BBox): void
		{
			trace("\tAreaSynchronizator for " + widget + " CRS: " + crs + " vievBBox: " + viewBBox.toBBOXString());
			widget.setCRS(crs, false);
			widget.setViewBBox(viewBBox, false);
		}
		
		private function changeAreaAfterDelay(synchronizeFromWidget: InteractiveWidget, widgetsForSynchronisation: ArrayCollection): void
		{
			clearTimeout(_areaChangeTimeout);
			_areaChangeTimeout = 0;
			
			trace("\n\nAreaSynchronizator changeAreaAfterDelay by " + synchronizeFromWidget.name);
			
			var crs: String = synchronizeFromWidget.getCRS();
			var viewBBox: BBox = synchronizeFromWidget.getViewBBox();
			
			for each (var widget: InteractiveWidget in widgetsForSynchronisation)
			{
				if (widget.id != synchronizeFromWidget.id)
				{
					if (widget.getCRS() != crs)
					{
						widget.setCRS(crs, false);
					}
					
					if (!widget.getViewBBox().equals(viewBBox))
					{
						trace("\tAreaSynchronizator change viewBBox from " + widget.getViewBBox().toBBOXString() + " TO " + viewBBox.toBBOXString());
						widget.setViewBBox(viewBBox, true);
					}
				}
			}
		}
		
		public function getSynchronisedVariables():Array
		{
			return [];
		}
		public function hasSynchronisedVariable(s_variableId: String): Boolean
		{
			return false;
		}
	}
}