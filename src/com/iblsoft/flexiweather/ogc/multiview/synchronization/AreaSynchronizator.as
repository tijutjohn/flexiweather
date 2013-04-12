package com.iblsoft.flexiweather.ogc.multiview.synchronization
{
	import com.iblsoft.flexiweather.events.InteractiveWidgetEvent;
	import com.iblsoft.flexiweather.ogc.BBox;
	import com.iblsoft.flexiweather.ogc.InteractiveLayerMSBase;
	import com.iblsoft.flexiweather.ogc.multiview.data.MultiViewConfiguration;
	import com.iblsoft.flexiweather.widgets.InteractiveWidget;
	
	import flash.events.EventDispatcher;
	import flash.utils.Dictionary;
	import flash.utils.clearTimeout;
	import flash.utils.getTimer;
	import flash.utils.setTimeout;
	
	import mx.collections.ArrayCollection;

	public class AreaSynchronizator extends SynchronizatorBase implements ISynchronizator
	{
		private var _areaChangeTimeout: Number;

		private var _oldCRS: String;
		private var _oldViewBBox: BBox;
		
		private var _doAreaDelayTime: int;
		private var _delayTime: int;
		
		private var _widgetDictionary: Dictionary;
		
		public function AreaSynchronizator()
		{
			_delayTime = 2000;
			_doAreaDelayTime = 0;
			
			_widgetDictionary = new Dictionary();
		}

		override public function synchronizeWidgets(synchronizeFromWidget: InteractiveWidget, widgetsForSynchronisation: ArrayCollection, preferredSelectedIndex: int = -1): void
		{
			var crs: String = synchronizeFromWidget.getCRS();
			var viewBBox: BBox = synchronizeFromWidget.getViewBBox();
			
			if (_oldCRS && _oldViewBBox && crs == _oldCRS && viewBBox.equals(_oldViewBBox))
			{
				debug("\n\n AreaSynchronizator DO NOT synchronizeWidgets CRS: " + crs + " vievBBox: " + viewBBox.toBBOXString());
				return;
			}
			
			_oldCRS = crs;
			_oldViewBBox = viewBBox;
			
//			if (_areaChangeTimeout > 0)
//			{
//				clearTimeout(_areaChangeTimeout);
//			}
//			
//			debug("\n\n AreaSynchronizator synchronizeWidgets CRS: " + crs + " vievBBox: " + viewBBox.toBBOXString());
//			_areaChangeTimeout = setTimeout(changeAreaAfterDelay, 2000, synchronizeFromWidget, widgetsForSynchronisation);
			
			var timeDifference: Number = getTimer() - _doAreaDelayTime;
			if (timeDifference > _delayTime)
			{
				changeAreaAfterDelay(synchronizeFromWidget, widgetsForSynchronisation, true);
			} else {
				
				changeAreaAfterDelay(synchronizeFromWidget, widgetsForSynchronisation, false);
				
				if (_areaChangeTimeout > 0)
					clearTimeout(_areaChangeTimeout);
				
				var timeToNextPan: Number = _delayTime - timeDifference;
				_areaChangeTimeout = setTimeout(areaTimeoutFinished, timeToNextPan, synchronizeFromWidget, widgetsForSynchronisation);
			}
		}

		private function areaTimeoutFinished(synchronizeFromWidget: InteractiveWidget, widgetsForSynchronisation: ArrayCollection): void
		{
			clearTimeout(_areaChangeTimeout);
			_areaChangeTimeout = 0;
			
			changeAreaAfterDelay(synchronizeFromWidget, widgetsForSynchronisation, true);
			
		}
		private function changeAreaAfterDelay(synchronizeFromWidget: InteractiveWidget, widgetsForSynchronisation: ArrayCollection, bFinalChange: Boolean = true): void
		{
			debug("\n\nAreaSynchronizator changeAreaAfterDelay by " + synchronizeFromWidget.name + " bFinalChange: " + bFinalChange);
			
			
			/**
			 * synchronization needs to be done in 2 steps, otherwise events of changing area could come before all widgets will call aras change
			 * 
			 * 1st step - add listeners for events, which will be dispatched on area changed
			 * 2nd step - call methods for changing area
			 * 
			 */
			
			var crs: String = synchronizeFromWidget.getCRS();
			var extentBBox: BBox = synchronizeFromWidget.getExtentBBox();
			var viewBBox: BBox = synchronizeFromWidget.getViewBBox();
			
			var widgetsForSynchronizing: Array = [];
			
			for each (var widget: InteractiveWidget in widgetsForSynchronisation)
			{
				if (widget.id != synchronizeFromWidget.id)
				{
					var wc: WidgetChanges;
					
					var changeCRS: Boolean = widget.getCRS() != crs;
					var changeExtentBBox: Boolean = !widget.getExtentBBox().equals(extentBBox);
					var changeViewBBox: Boolean = !widget.getViewBBox().equals(viewBBox);
					
					debug("Widget [" + widget.id + "] " + widget.getViewBBox().toBBOXString() + " synchronized view bbox: " + viewBBox.toBBOXString());
					debug("Widget [" + widget.id + "] changeCRS: " + changeCRS + " changeExtentBBox: " + changeExtentBBox + " changeViewBBox: " + changeViewBBox);
					
					if (changeCRS || changeExtentBBox || changeViewBBox)
					{
						listenToWidgetSynchronization(widget);
						
						var widgetChanges: WidgetChanges = new WidgetChanges();
						
						widgetChanges.widget = widget;
						widgetChanges.changeCRS = changeCRS;
						widgetChanges.changeExtentBBox = changeExtentBBox;
						widgetChanges.changeViewBBox = changeViewBBox;
						
						
						if (!bFinalChange)
						{
							//if this is not final change, we need to remember what was changed and in case there is no change when this will be calling as final change, we need to add it to synchronization aray
							if (!_widgetDictionary[widget])
								_widgetDictionary[widget] = new WidgetChanges(); 
							
							wc = _widgetDictionary[widget] as WidgetChanges;
							
							wc.widget = widget;
							wc.changeCRS = wc.changeCRS || changeCRS;
							wc.changeExtentBBox = wc.changeExtentBBox || changeExtentBBox;
							wc.changeViewBBox = wc.changeViewBBox || changeViewBBox;
						} else {
							if (_widgetDictionary[widget])
							{
								wc = _widgetDictionary[widget] as WidgetChanges;
								
								widgetChanges.changeCRS = wc.changeCRS || widgetChanges.changeCRS;
								widgetChanges.changeExtentBBox = wc.changeExtentBBox || widgetChanges.changeExtentBBox;
								widgetChanges.changeViewBBox = wc.changeViewBBox || widgetChanges.changeViewBBox;
								
								delete _widgetDictionary[widget];
							}
						}
						
						widgetsForSynchronizing.push( widgetChanges );
					
					} else {
						
						//if there are no changes, we need to check if there were changes when it was not fnal change
						if (_widgetDictionary[widget])
						{
							wc = _widgetDictionary[widget] as WidgetChanges;
							
							if (wc.changeCRS || wc.changeExtentBBox || wc.changeViewBBox)
							{
								listenToWidgetSynchronization(widget);
								widgetsForSynchronizing.push(wc);
							}
						}
					}
				}
//				else
//				{
//					debug("\tAreaSynchronizator [" + widget.id + "] changeAreaAfterDelay |  do not synchornize widget, it's widget which we synchronize from ");
//				}
			}
			
			
			//2nd pass, change frames
			for each (var obj: WidgetChanges in widgetsForSynchronizing)
			{
				changeCRS = obj.changeCRS as Boolean;
				changeViewBBox = obj.changeViewBBox as Boolean
				changeExtentBBox = obj.changeExtentBBox as Boolean
				widget = obj.widget as InteractiveWidget;
				
				if (changeCRS)
				{
//					debug("\tAreaSynchronizator [" + widget.id + "] changeAreaAfterDelay | change CRS to " + crs);
					//if view box is not changed, CRS must be set as final
					var changeCRSNow: Boolean = !changeViewBBox && !changeExtentBBox && bFinalChange;
					widget.setCRS(crs, changeCRSNow);
				}
				if (changeExtentBBox)
				{
					var changeExtentBBoxNow: Boolean = !changeViewBBox && bFinalChange;
					widget.setExtentBBoxRaw(extentBBox.xMin, extentBBox.yMin, extentBBox.xMax, extentBBox.yMax, changeExtentBBoxNow);
				}
				if (changeViewBBox)
				{
//					debug("\tAreaSynchronizator [" + widget.id + "] changeAreaAfterDelay |  change viewBBox from " + widget.getViewBBox().toBBOXString() + " TO " + viewBBox.toBBOXString());
					widget.setViewBBox(viewBBox, bFinalChange);
				}
				
				
			}
			
			if (bFinalChange)
				_doAreaDelayTime = getTimer();
			
			checkIfSynchronizationIsDone();
		}
		
		override protected function listenToWidgetSynchronization(widget: InteractiveWidget): void
		{
			md_synchronisationDictionary[widget] = widget.id;
//			debug("[" + widget.id + "] listenToWidgetSynchronization");
			widget.addEventListener(InteractiveWidgetEvent.AREA_CHANGED, onAreaSychronisationDone);
		}
		
		private function onAreaSychronisationDone(event: InteractiveWidgetEvent): void
		{
			var widget: InteractiveWidget = event.target as InteractiveWidget;
			if (widget)
			{
//				debug("[" + widget.id + "] onAreaSychronisationDone");
				delete md_synchronisationDictionary[widget];
				widget.removeEventListener(InteractiveWidgetEvent.AREA_CHANGED, onAreaSychronisationDone);
				checkIfSynchronizationIsDone();
			}
		}

		private function debug(str: String, type: String = "Info", tag: String = "AreaSynchronizator"): void
		{
//			trace(tag + "| " + type + "| " + str);
		}
	}
}
import com.iblsoft.flexiweather.widgets.InteractiveWidget;

class WidgetChanges {
	
	public var changeCRS: Boolean;
	public var changeViewBBox: Boolean;
	public var changeExtentBBox: Boolean;
	public var widget: InteractiveWidget;
}