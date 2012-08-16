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
		
		public function get labelString(): String
		{
			return '';
		}
		
		public function AreaSynchronizator()
		{
		}
		
		public function synchronizeWidgets(synchronizeFromWidget: InteractiveWidget, widgetsForSynchronisation: ArrayCollection):void
		{
			
			if (_areaChangeTimeout > 0)
			{
				clearTimeout(_areaChangeTimeout);
			}
			
			_areaChangeTimeout = setTimeout(changeAreaAfterDelay, 200, synchronizeFromWidget, widgetsForSynchronisation);
			
			var crs: String = synchronizeFromWidget.getCRS();
			var viewBBox: BBox = synchronizeFromWidget.getViewBBox();
			
			for each (var widget: InteractiveWidget in widgetsForSynchronisation)
			{
				if (widget.id != synchronizeFromWidget.id)
				{
					widget.setCRS(crs, false);
					widget.setViewBBox(viewBBox, false);
				}
			}
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
						trace("AreaSynchronizator change viewBBox from " + widget.getViewBBox().toBBOXString() + " TO " + viewBBox.toBBOXString());
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