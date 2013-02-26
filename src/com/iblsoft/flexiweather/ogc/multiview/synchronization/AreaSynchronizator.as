package com.iblsoft.flexiweather.ogc.multiview.synchronization
{
	import com.iblsoft.flexiweather.events.InteractiveWidgetEvent;
	import com.iblsoft.flexiweather.ogc.BBox;
	import com.iblsoft.flexiweather.ogc.InteractiveLayerMSBase;
	import com.iblsoft.flexiweather.ogc.multiview.data.MultiViewConfiguration;
	import com.iblsoft.flexiweather.widgets.InteractiveWidget;
	
	import flash.events.EventDispatcher;
	import flash.utils.clearTimeout;
	import flash.utils.setTimeout;
	
	import mx.collections.ArrayCollection;

	public class AreaSynchronizator extends SynchronizatorBase implements ISynchronizator
	{
		private var _areaChangeTimeout: Number;

		public function AreaSynchronizator()
		{
		}

		override public function synchronizeWidgets(synchronizeFromWidget: InteractiveWidget, widgetsForSynchronisation: ArrayCollection, preferredSelectedIndex: int = -1): void
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
			
			
			/**
			 * synchronization needs to be done in 2 steps, otherwise events of changing area could come before all widgets will call aras change
			 * 
			 * 1st step - add listeners for events, which will be dispatched on area changed
			 * 2nd step - call methods for changing area
			 * 
			 */
			
			var crs: String = synchronizeFromWidget.getCRS();
			var viewBBox: BBox = synchronizeFromWidget.getViewBBox();
			
			var widgetsForSynchronizing: Array = [];
			
			for each (var widget: InteractiveWidget in widgetsForSynchronisation)
			{
				if (widget.id != synchronizeFromWidget.id)
				{
//					debug("Widget [" + widget.id + "] " + widget.getViewBBox().toBBOXString() + " synchronized view bbox: " + viewBBox.toBBOXString());
					var changeCRS: Boolean = widget.getCRS() != crs;
					var changeViewBBox: Boolean = !widget.getViewBBox().equals(viewBBox);
					
					if (changeCRS || changeViewBBox)
					{
						listenToWidgetSynchronization(widget);
						widgetsForSynchronizing.push( {changeCRS: changeCRS, changeViewBBox: changeViewBBox, widget: widget } );
					}
				}
//				else
//				{
//					debug("\tAreaSynchronizator [" + widget.id + "] changeAreaAfterDelay |  do not synchornize widget, it's widget which we synchronize from ");
//				}
			}
			
			//2nd pass, change frames
			for each (var obj: Object in widgetsForSynchronizing)
			{
				changeCRS = obj.changeCRS as Boolean;
				changeViewBBox = obj.changeViewBBox as Boolean
				widget = obj.widget as InteractiveWidget;
				
				if (changeCRS)
				{
//					debug("\tAreaSynchronizator [" + widget.id + "] changeAreaAfterDelay | change CRS to " + crs);
					//if view box is not changed, CRS must be set as final
					widget.setCRS(crs, !changeViewBBox);
				}
//				else
//				{
//					debug("\tAreaSynchronizator [" + widget.id + "] changeAreaAfterDelay |  NOT changing CRS, CRSs are same");
//				}
				if (changeViewBBox)
				{
//					debug("\tAreaSynchronizator [" + widget.id + "] changeAreaAfterDelay |  change viewBBox from " + widget.getViewBBox().toBBOXString() + " TO " + viewBBox.toBBOXString());
					widget.setViewBBox(viewBBox, true);
				}
//				else
//				{
//					debug("\tAreaSynchronizator [" + widget.id + "] changeAreaAfterDelay |  NOT changing viewBBox, view boxes are same");
//				}
				
			}
			
			checkIfSynchronizationIsDone();
		}
		
		override protected function listenToWidgetSynchronization(widget: InteractiveWidget): void
		{
			_synchronisationDictionary[widget] = widget.id;
//			debug("[" + widget.id + "] listenToWidgetSynchronization");
			widget.addEventListener(InteractiveWidgetEvent.AREA_CHANGED, onAreaSychronisationDone);
		}
		
		private function onAreaSychronisationDone(event: InteractiveWidgetEvent): void
		{
			var widget: InteractiveWidget = event.target as InteractiveWidget;
			if (widget)
			{
//				debug("[" + widget.id + "] onAreaSychronisationDone");
				delete _synchronisationDictionary[widget];
				widget.removeEventListener(InteractiveWidgetEvent.AREA_CHANGED, onAreaSychronisationDone);
				checkIfSynchronizationIsDone();
			}
		}

		private function debug(str: String, type: String = "Info", tag: String = "AreaSynchronizator"): void
		{
			//trace(tag + "| " + type + "| " + str);
		}
	}
}
