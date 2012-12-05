package com.iblsoft.flexiweather.ogc.multiview.synchronization
{
	import com.iblsoft.flexiweather.ogc.BBox;
	import com.iblsoft.flexiweather.ogc.multiview.data.MultiViewConfiguration;
	import com.iblsoft.flexiweather.widgets.InteractiveWidget;
	
	import flash.events.EventDispatcher;
	import flash.utils.clearTimeout;
	import flash.utils.setTimeout;
	
	import mx.collections.ArrayCollection;

	public class AreaSynchronizator extends EventDispatcher implements ISynchronizator
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
		
		public function synchronizeWidgets(synchronizeFromWidget: InteractiveWidget, widgetsForSynchronisation: ArrayCollection, preferredSelectedIndex: int = -1): void
		{
			if (_areaChangeTimeout > 0)
			{
				clearTimeout(_areaChangeTimeout);
			}
			var crs: String = synchronizeFromWidget.getCRS();
			var viewBBox: BBox = synchronizeFromWidget.getViewBBox();
			debug("\n\n AreaSynchronizator synchronizeWidgets CRS: " + crs + " vievBBox: " + viewBBox.toBBOXString());
			_areaChangeTimeout = setTimeout(changeAreaAfterDelay, 2000, synchronizeFromWidget, widgetsForSynchronisation);
		}

		private function changeAreaAfterDelay(synchronizeFromWidget: InteractiveWidget, widgetsForSynchronisation: ArrayCollection): void
		{
			clearTimeout(_areaChangeTimeout);
			_areaChangeTimeout = 0;
			debug("\n\nAreaSynchronizator changeAreaAfterDelay by " + synchronizeFromWidget.name);
			var crs: String = synchronizeFromWidget.getCRS();
			var viewBBox: BBox = synchronizeFromWidget.getViewBBox();
			for each (var widget: InteractiveWidget in widgetsForSynchronisation)
			{
				if (widget.id != synchronizeFromWidget.id)
				{
					debug("Widget [" + widget.id + "] " + widget.getViewBBox().toBBOXString() + " synchronized view bbox: " + viewBBox.toBBOXString());
					var changeCRS: Boolean = widget.getCRS() != crs;
					var changeViewBBox: Boolean = !widget.getViewBBox().equals(viewBBox);
					if (changeCRS)
					{
						debug("\tAreaSynchronizator [" + widget.id + "] changeAreaAfterDelay | change CRS to " + crs);
						//if view box is not changed, CRS must be set as final
						widget.setCRS(crs, !changeViewBBox);
					}
					else
					{
						debug("\tAreaSynchronizator [" + widget.id + "] changeAreaAfterDelay |  NOT changing CRS, CRSs are same");
					}
					if (changeViewBBox)
					{
						debug("\tAreaSynchronizator [" + widget.id + "] changeAreaAfterDelay |  change viewBBox from " + widget.getViewBBox().toBBOXString() + " TO " + viewBBox.toBBOXString());
						widget.setViewBBox(viewBBox, true);
					}
					else
					{
						debug("\tAreaSynchronizator [" + widget.id + "] changeAreaAfterDelay |  NOT changing viewBBox, view boxes are same");
					}
				}
				else
				{
					debug("\tAreaSynchronizator [" + widget.id + "] changeAreaAfterDelay |  do not synchornize widget, it's widget which we synchronize from ");
				}
			}
		}

		public function getSynchronisedVariables(): Array
		{
			return [];
		}

		public function hasSynchronisedVariable(s_variableId: String): Boolean
		{
			return false;
		}
		
		private function debug(str: String, type: String = "Info", tag: String = "AreaSynchronizator"): void
		{
			//			trace(tag + "| " + type + "| " + str);
		}
	}
}
