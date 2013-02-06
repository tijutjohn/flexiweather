package com.iblsoft.flexiweather.ogc.multiview.synchronization
{
	import com.iblsoft.flexiweather.ogc.InteractiveLayerMSBase;
	import com.iblsoft.flexiweather.ogc.data.GlobalVariable;
	import com.iblsoft.flexiweather.ogc.multiview.data.MultiViewConfiguration;
	import com.iblsoft.flexiweather.plugins.IConsole;
	import com.iblsoft.flexiweather.widgets.InteractiveLayerMap;
	import com.iblsoft.flexiweather.widgets.InteractiveWidget;
	
	import flash.events.DataEvent;
	import flash.events.EventDispatcher;
	
	import mx.collections.ArrayCollection;
	import mx.utils.ArrayUtil;

	public class FrameSynchronizator extends SynchronizatorBase implements ISynchronizator
	{
		public static var debugConsole: IConsole;
		private var _timeDifference: Number;

		[Bindable]
		public function get timeDifference(): Number
		{
			return _timeDifference;
		}

		public function set timeDifference(value: Number): void
		{
			_timeDifference = value;
		}

		override public function get willSynchronisePrimaryLayer(): Boolean
		{
			return true;
		}
		private var _frameDistances: Array;

		override public function set customData(data: Object): void
		{
			if (data && data.hasOwnProperty("timeDifference"))
				timeDifference = data.timeDifference;
		}

		override public function get customData(): Object
		{
			return {timeDifference: timeDifference};
		}

		override public function set viewData(data: Array): void
		{
			// Frame synchronizator does not need any data, so it's nothing done here
			_frameDistances = data;
		}

		override public function get labelString(): String
		{
			return "<frame format='%H:%M %d.%m.%Y' tz='UTC'/>";
		}

		public function FrameSynchronizator()
		{
			timeDifference = -1;
		}

		private function debug(str: String, type: String = "Info", tag: String = "FrameSynchronizator"): void
		{
			if (debugConsole)
				debugConsole.print(str, type, tag);
			//trace(tag + "| " + type + "| " + str);
		}
		private var tempData: Object;

		private function get framesTimeDifferencesSet(): Boolean
		{
			if (!_frameDistances)
				return false;
			if (_frameDistances.length > 0)
			{
				for each (var dateObj: Object in _frameDistances)
				{
					if (dateObj)
						return true;
				}
			}
			return false
		}

		private var _lastSynchronizedFrame: Date;
		
		override public function isSynchronizedFor(synchronizedDate: Date): Boolean
		{
			if (!synchronizedDate)
				return false;
			
			var bNeeded: Boolean = false; 
			bNeeded = bNeeded || (_lastSynchronizedFrame == null);
			bNeeded = bNeeded || (_lastSynchronizedFrame != null && _lastSynchronizedFrame.time != synchronizedDate.time);
			debug("FrameSychronizator isSynchronizedFor [" + synchronizedDate + "] -> " + bNeeded + " _lastSynchronizedFrame: " + _lastSynchronizedFrame);
			
			return bNeeded;
		}
		
		override public function synchronizeWidgets(synchronizeFromWidget: InteractiveWidget, widgetsForSynchronisation: ArrayCollection, preferredSelectedIndex: int = -1): void
		{
			var synchronizedWidgetFrame: Date = synchronizeFromWidget.frame;
			
			if (!isSynchronizedFor(frame))
			{
				debug("FrameSychronizator synchronizeWidgets for " + synchronizeFromWidget.id, 'Info', 'FrameSychronizator');
				var primaryLayer: InteractiveLayerMSBase = synchronizeFromWidget.interactiveLayerMap.getPrimaryLayer();
				if (primaryLayer)
				{
					var synchronizeFromWidgetPosition: uint = getWidgetPosition(synchronizeFromWidget, widgetsForSynchronisation);
					debug("FrameSychronizator synchronizeFromWidgetPosition " + synchronizeFromWidgetPosition + " framesTimeDifferencesSet: " + framesTimeDifferencesSet, 'Info', 'FrameSychronizator');
					if (!framesTimeDifferencesSet)
					{
						//make frame synchronisation as frames go 
						synchronizeFramesSequentialy(synchronizeFromWidget, widgetsForSynchronisation);
					}
					else
					{
	//					var variables: Array = primaryLayer.getSynchronisedVariables();
	//					var frames: Array = primaryLayer.getSynchronisedVariableValuesList(GlobalVariable.FRAME);
	//				
	//					
	//					var currFrame: Date = primaryLayer.getSynchronisedVariableValue(GlobalVariable.FRAME) as Date;
	//					var currFramePosition: int = getFramePosition(currFrame, frames);
	//					
	//					if (currFramePosition > 0)
	//						frames = frames.slice(Math.max(0, currFramePosition - synchronizeFromWidgetPosition), frames.length);
						var cnt: int = 0;
						var frames: Array = getFrames(primaryLayer, synchronizeFromWidgetPosition);
						debug("FramSynchronisator frames: " + frames.length + " selected index: " + preferredSelectedIndex);
						for each (var date: Date in frames)
						{
							if (date)
								debug("\t frame[" + cnt + "] = " + date.toTimeString());
							else
								debug("\t frame[" + cnt + "] = NULL");
							cnt++;
						}
						if (synchronizeFromWidgetPosition > -1)
						{
							cnt = 0
							var total: int = widgetsForSynchronisation.length;
							for (var i: int = 0; i < total; i++)
							{
								var widget: InteractiveWidget = widgetsForSynchronisation.getItemAt(i) as InteractiveWidget;
	//							if (widget.id != synchronizeFromWidget.id)
								var frame: Date = frames[i] as Date;
								if (frame)
								{
									if (widget.interactiveLayerMap.frame && widget.interactiveLayerMap.frame.time != frame.time)
									{
										debug("Going to synchronise frame: " + frame.toTimeString() + " for widget: " + widget.id, 'Info', 'FrameSychronizator');
										widget.interactiveLayerMap.setFrame(frame);
										dataForWidgetAvailable(widget);
									} else {
										debug("Do not synchronise (same frames) frame: " + frame.toTimeString() + " for widget: " + widget.id, 'Info', 'FrameSychronizator');
										
									}
								}
								else
								{
									dataForWidgetUnvailable(widget);
								}
								cnt++;
							}
						}
					}
	
					_lastSynchronizedFrame = synchronizedWidgetFrame;
					_synchronizatorInvalid = false;
					debug("FramSynchronisator _lastSynchronizedFrame: " + _lastSynchronizedFrame);
				}
				else
				{
					tempData = {widget: synchronizeFromWidget, widgets: widgetsForSynchronisation, prefferedSelectedIndex: preferredSelectedIndex};
					//wait for primary layer
					synchronizeFromWidget.interactiveLayerMap.addEventListener(InteractiveLayerMap.PRIMARY_LAYER_CHANGED, waitForPrimaryLayer);
				}
			} else {
				debug("FrameSychronizator synchronizeWidgets not needed for " + synchronizedWidgetFrame, 'Info', 'FrameSychronizator');
			}
		}

		private function waitForPrimaryLayer(event: DataEvent): void
		{
			if (tempData)
			{
				var synchronizeFromWidget: InteractiveWidget = tempData.widget as InteractiveWidget;
				synchronizeFromWidget.interactiveLayerMap.removeEventListener(InteractiveLayerMap.PRIMARY_LAYER_CHANGED, waitForPrimaryLayer);
				synchronizeWidgets(synchronizeFromWidget, tempData.widgets as ArrayCollection, tempData.prefferedSelectedIndex as int);
			}
		}

		/**
		 * Return frames (Date) arary of needed frames for synchronisation
		 *
		 * @param primaryLayer
		 * @param synchronizeFromWidgetPosition
		 * @return
		 *
		 */
		private function getFrames(primaryLayer: InteractiveLayerMSBase, synchronizeFromWidgetPosition: uint): Array
		{
			var frames: Array = primaryLayer.getSynchronisedVariableValuesList(GlobalVariable.FRAME);
			var currFrame: Date = primaryLayer.getSynchronisedVariableValue(GlobalVariable.FRAME) as Date;
			var currFramePosition: int = getFramePosition(currFrame, frames);
			
//			trace("getFrames currFrame: " + currFrame);
//			trace("getFrames currFramePosition: " + currFramePosition + " synchronizeFromWidgetPosition: " + synchronizeFromWidgetPosition);
			
			//update string values (+0h, +3h, +6h, +9h, +12h) to int values (0,3,6,9,12)
			//_frameDistance is array of frame distance as int values (+0h, +3h, +6h, +9h, +12h  etc)
			var updatedFrameDistances: Array = _frameDistances; //updateFrameDistances(synchronizeFromWidgetPosition);
			//get values
			var total: int = updatedFrameDistances.length;
			var synchronisedFrames: Array = [];
			for (var i: int = 0; i < total; i++)
			{
//				trace("\t getFrames updatedFrameDistances["+i+"]: " + (updatedFrameDistances[i] as Object).label);
				if (updatedFrameDistances[i])
				{
					var newDate: Date = getFrameWithTimeDifference(frames, currFrame, updatedFrameDistances[i].data as int);
//					trace("\t getFrames newDate["+i+"]: " + newDate);
					synchronisedFrames.push(newDate);
				}
				else
				{
					synchronisedFrames.push(null);
				}
			}
			return synchronisedFrames;
		}

		/*
		private function updateFrameDistancesToInts(): void
		{
			if (_frameDistances.length > 0 && _frameDistances[0] != null)
			{
				var total: int = _frameDistances.length;
				var updatedDistances: Array = [];
				for (var i: int = 0; i < total; i++)
				{
					var value: Object = _frameDistances[i];
//					trace("\t updateFrameDistancesToInts _frameDistances["+i+"]: " + _frameDistances[i]);
					if (value is int || value == null)
					{
						updatedDistances.push(value);
					}
					else if (value is String)
					{
						var strValue: String = value as String;
						var strValue2: String = strValue.substring(1, strValue.length - 1);
						var newValue: int = parseInt(strValue2, 10);
						trace("\t updateFrameDistancesToInts ["+i+"] newValue: " + newValue);
						updatedDistances.push(newValue);
					}
				}
				_frameDistances = updatedDistances;
			}
		}
*/
		
			/*
		private function updateFrameDistances(synchronizeFromWidgetPosition: uint): Array
		{
			//now, it's not needed to update frameDistances anymore, because they are correctle set from synchronizator popup
			return _frameDistances;
			if (synchronizeFromWidgetPosition == 0)
				return _frameDistances;
			if (_frameDistances.length > 1 && _frameDistances[0] != null)
			{
				var value1: int = _frameDistances[0].data as int;
				var value2: int = _frameDistances[1].data as int;
				var step: int = value2 - value1;
				var total: int = _frameDistances.length;
				var newDistances: Array = [];
				var updatedDistance: int = step * synchronizeFromWidgetPosition;
				trace("\t updateFrameDistances updatedDistance: " + updatedDistance);
				for (var i: int = 0; i < total; i++)
				{
					trace("\t updateFrameDistances _frameDistances["+i+"] newValue: " + _frameDistances[i]);
					if (_frameDistances[i])
					{
						var currentValue: int = _frameDistances[i].data - updatedDistance;
						trace("\t updateFrameDistances _frameDistances["+i+"] currentValue: " + currentValue);
						newDistances.push({data: currentValue, label: "+" + currentValue + "h"});
					}
					else
					{
						newDistances.push(null);
					}
				}
				return newDistances;
			}
			return _frameDistances;
		}
			*/

		private function synchronizeFramesSequentialy(synchronizeFromWidget: InteractiveWidget, widgetsForSynchronisation: ArrayCollection): void
		{
			var primaryLayer: InteractiveLayerMSBase = synchronizeFromWidget.interactiveLayerMap.getPrimaryLayer();
			if (primaryLayer)
			{
				var variables: Array = primaryLayer.getSynchronisedVariables();
				var frames: Array = primaryLayer.getSynchronisedVariableValuesList(GlobalVariable.FRAME);
				var synchronizeFromWidgetPosition: int = getWidgetPosition(synchronizeFromWidget, widgetsForSynchronisation);
				var currFrame: Date = primaryLayer.getSynchronisedVariableValue(GlobalVariable.FRAME) as Date;
				var currFramePosition: int = getFramePosition(currFrame, frames);
				debug("FrameSynchronizator synchronizeFramesSequentialy: curr frame: " + currFrame.toTimeString() + " currFramePosition: " + currFramePosition);
				if (currFramePosition > 0)
				{
					var sliceFrom: int = Math.max(0, currFramePosition - synchronizeFromWidgetPosition);
					var sliceTo: int = frames.length;
					frames = frames.slice(sliceFrom, sliceTo);
					debug("FrameSynchronizator synchronizeFramesSequentialy: sliceFrom: " + sliceFrom + " sliceTo: " + sliceTo);
				}
				if (synchronizeFromWidgetPosition > -1)
				{
					var cnt: int = 0;
					var total: int = widgetsForSynchronisation.length;
					for (var i: int = 0; i < total; i++)
					{
						var widget: InteractiveWidget = widgetsForSynchronisation.getItemAt(i) as InteractiveWidget;
						if (widget.id != synchronizeFromWidget.id)
						{
							var framePos: int = i - synchronizeFromWidgetPosition + currFramePosition;
							debug("\t FrameSynchronizator synchronizeFramesSequentialy: widget: " + widget.id + " framePos: " + framePos);
							if (framePos >= 0)
							{
								var frame: Date = getFrame(framePos, frames);
								if (frame)
								{
									debug("\t FrameSynchronizator synchronizeFramesSequentialy: widget: " + widget.id + " framePos: " + framePos + " frame: " + frame.toTimeString());
									widget.interactiveLayerMap.setFrame(frame);
									dataForWidgetAvailable(widget);
								}
								else
								{
									dataForWidgetUnvailable(widget);
								}
							}
							else
							{
								dataForWidgetUnvailable(widget);
							}
						}
						cnt++;
					}
				}
			}
		}

		private function dataForWidgetAvailable(widget: InteractiveWidget): void
		{
//			debug("\t FrameSynchronizator dataForWidgetAvailable " + widget.id);
			widget.enabled = true;
		}

		private function dataForWidgetUnvailable(widget: InteractiveWidget): void
		{
//			debug("\t FrameSynchronizator dataForWidgetUnvailable" + widget.id);
			widget.enabled = false;
		}

		private function getFrameWithTimeDifference(frames: Array, currentFrame: Date, timeDifference: int): Date
		{
			var hourConst: int = 1000 * 60 * 60;
			for each (var frame: Date in frames)
			{
				var diff: Number = (frame.time - currentFrame.time) / hourConst;
				if (diff == timeDifference)
				{
					return frame;
				}
			}
			return null;
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
				debug("\t\t getFramePosition currFrame: " + currFrame + " compare to: " + frame);
				if (currFrame.time == frame.time)
				{
					debug("\t\t getFramePosition position is: " + cnt);
					return cnt;
				}
				cnt++;
			}
					debug("\t\t getFramePosition position is: -1");
			return -1;
		}

		private function debugWidgetsIDs(synchronizeFromWidget: InteractiveWidget, widgetsForSynchronisation: ArrayCollection): void
		{
			var cnt: int = 0;
			for each (var widget: InteractiveWidget in widgetsForSynchronisation)
			{
				debug("debugWidgetsIDs cnt: " + cnt + " widget: " + widget.id + " synchronizeFromWidget.id: " + synchronizeFromWidget.id + " frame: " + widget.frame);
				cnt++;
			}
		}
		private function getWidgetPosition(synchronizeFromWidget: InteractiveWidget, widgetsForSynchronisation: ArrayCollection): int
		{
			debugWidgetsIDs(synchronizeFromWidget, widgetsForSynchronisation);
			var cnt: int = 0;
			for each (var widget: InteractiveWidget in widgetsForSynchronisation)
			{
//				debug("\t\t getWidgetPosition currWidget: " + widget.id + " compare to synchronizeFromWidget: " + synchronizeFromWidget.id);
				if (widget.id == synchronizeFromWidget.id)
				{
//					debug("\t\t getWidgetPosition return: " + cnt);
					return cnt;
				}
				cnt++;
			}
//				debug("\t\t getWidgetPosition return: -1") ;
			return -1;
		}

		override public function getSynchronisedVariables(): Array
		{
			return [GlobalVariable.FRAME];
		}

		override public function hasSynchronisedVariable(s_variableId: String): Boolean
		{
			return s_variableId == GlobalVariable.FRAME;
		}
	}
}
