package com.iblsoft.flexiweather.ogc.multiview.synchronization
{
	import com.iblsoft.flexiweather.events.InteractiveWidgetEvent;
	import com.iblsoft.flexiweather.ogc.InteractiveLayerMSBase;
	import com.iblsoft.flexiweather.ogc.SynchronisedVariableChangeEvent;
	import com.iblsoft.flexiweather.ogc.data.GlobalVariable;
	import com.iblsoft.flexiweather.ogc.multiview.data.MultiViewConfiguration;
	import com.iblsoft.flexiweather.ogc.multiview.data.SynchronizationChangeType;
	import com.iblsoft.flexiweather.plugins.IConsole;
	import com.iblsoft.flexiweather.widgets.InteractiveLayer;
	import com.iblsoft.flexiweather.widgets.InteractiveLayerMap;
	import com.iblsoft.flexiweather.widgets.InteractiveWidget;
	
	import flash.events.DataEvent;
	import flash.events.EventDispatcher;
	import flash.utils.Dictionary;
	
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
		private var _frameStep: int;

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
			_frameStep = 0;
			if (data)
			{
				if (data[0] == null || data[1] == null)
					_frameStep = 0;
				else
					_frameStep = data[1].data - data[0].data;
			}
			
		}

		override public function get labelString(): String
		{
			return "<frame format='%H:%M %d.%m.%Y' tz='UTC'/>";
		}

		public function FrameSynchronizator()
		{
			super();
			
			timeDifference = -1;
			
			registerChangeType(SynchronizationChangeType.GLOBAL_FRAME_CHANGED);
		}

		private function debug(str: String, type: String = "Info", tag: String = "FrameSynchronizator"): void
		{
			if (debugConsole)
				debugConsole.print(str, type, tag);
//			trace(tag + "| " + type + "| " + str);
		}
		
		private var tempDataDictionary: Dictionary = new Dictionary();

		private function get framesTimeDifferencesSet(): Boolean
		{
			if (_frameStep <= 0)
				return false;
			
			return true
		}

		private var _lastSynchronizedFrame: Date;
		
		override public function initializeSynchronizator(): void
		{
			super.initializeSynchronizator();
			
			_lastSynchronizedFrame = null;
		}
		
		override public function isSynchronizedFor(synchronizedDate: Date): Boolean
		{
			if (!synchronizedDate)
				return false;
			
			if (mb_synchronizatorInvalid)
				return false;
			
			var bNeeded: Boolean = false; 
			bNeeded = bNeeded || (_lastSynchronizedFrame == null);
			bNeeded = bNeeded || (_lastSynchronizedFrame != null && _lastSynchronizedFrame.time != synchronizedDate.time);
			debug("FrameSychronizator isSynchronizedFor [" + synchronizedDate + "] -> " + bNeeded + " _lastSynchronizedFrame: " + _lastSynchronizedFrame);
			
			return !bNeeded;
		}
		
		override public function synchronizeWidgets(synchronizeFromWidget: InteractiveWidget, widgetsForSynchronisation: ArrayCollection, preferredSelectedIndex: int = -1): void
		{
			var synchronizedWidgetFrame: Date = synchronizeFromWidget.frame;
			
			if (preferredSelectedIndex > -1)
			{
				synchronizeFromWidget = widgetsForSynchronisation.getItemAt(preferredSelectedIndex) as InteractiveWidget;
			}
			
			debug("\n******************* FrameSychronizator synchronizeWidgets for " + synchronizedWidgetFrame, 'Info', 'FrameSychronizator');
			if (!isSynchronizedFor(synchronizedWidgetFrame))
			{
				debug("\n******************* FrameSychronizator synchronizeWidgets for " + synchronizeFromWidget.id, 'Info', 'FrameSychronizator');
				var primaryLayer: InteractiveLayerMSBase = synchronizeFromWidget.interactiveLayerMap.getPrimaryLayer();
				if (primaryLayer)
				{
					var synchronizeFromWidgetPosition: uint = getWidgetPosition(synchronizeFromWidget, widgetsForSynchronisation);
					debug("FrameSychronizator synchronizeFromWidgetPosition " + synchronizeFromWidgetPosition + " framesTimeDifferencesSet: " + framesTimeDifferencesSet, 'Info', 'FrameSychronizator');
					if (!framesTimeDifferencesSet)
					{
						//make frame synchronisation as frames go 
						synchronizeFramesSequentialy(synchronizeFromWidget, widgetsForSynchronisation, preferredSelectedIndex);
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
						var total: int = widgetsForSynchronisation.length;
						
						var frames: Array = getFrames(primaryLayer, synchronizedWidgetFrame, synchronizeFromWidgetPosition, total);
						
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
							cnt = 0;
							var i: int;
							var frame: Date;
							
							var widgetsForSynchronizing: Array = [];
							
							/**
							 * synchronization needs to be done in 2 steps, otherwise events of changing frames could come before all widgets will call frame change
							 * 
							 * 1st step - add listeners for events, which will be dispatched on frame changed
							 * 2nd step - call methods for changing frame
							 * 
							 */
							
							for (i = 0; i < total; i++)
							{
								var widget: InteractiveWidget = widgetsForSynchronisation.getItemAt(i) as InteractiveWidget;
								
								widget.addEventListener(InteractiveWidgetEvent.WIDGET_CHANGED, onWidgetChanged, false, 0, true);
								
								frame = frames[i] as Date;
								if (frame)
								{
									var currWidgetFrame: Date = widget.interactiveLayerMap.frame; 
									if (!currWidgetFrame || (currWidgetFrame && currWidgetFrame.time != frame.time))
									{
										debug("Going to synchronise frame: " + frame.toTimeString() + " for widget: " + widget.id, 'Info', 'FrameSychronizator');
										
										listenToWidgetSynchronization(widget);
										widgetsForSynchronizing.push( {frame: frame, widget: widget } );
									} else {
										debug("Do not synchronise (same frames) frame: " + frame.toTimeString() + " for widget: " + widget.id, 'Info', 'FrameSychronizator');
										if (currWidgetFrame)
											dataForWidgetAvailable(widget);
										
									}
								}
								else
								{
									dataForWidgetUnvailable(widget);
								}
								cnt++;
							}
							
							//2nd pass, change frames
							delayedSynchronization(widgetsForSynchronizing);
							
							checkIfSynchronizationIsDone();
						}
					}
	
					_lastSynchronizedFrame = synchronizedWidgetFrame;
					mb_synchronizatorInvalid = false;
					debug("FramSynchronisator synchronizeWidgets _lastSynchronizedFrame: " + _lastSynchronizedFrame + "\n*******************\n");
				}
				else
				{
					tempDataDictionary[synchronizeFromWidget.interactiveLayerMap] = {widget: synchronizeFromWidget, widgets: widgetsForSynchronisation, prefferedSelectedIndex: preferredSelectedIndex};
					//wait for primary layer
					synchronizeFromWidget.interactiveLayerMap.addEventListener(InteractiveLayerMap.PRIMARY_LAYER_CHANGED, waitForPrimaryLayer);
				}
			} else {
				debug("FrameSychronizator synchronizeWidgets not needed for " + synchronizedWidgetFrame, 'Info', 'FrameSychronizator');
				checkIfSynchronizationIsDone();
			}
		}
		
		private function delayedSynchronization(widgetsForSynchronizing: Array): void
		{
			var frame: Date;
			var widget: InteractiveWidget;
			
			for each (var obj: Object in widgetsForSynchronizing)
			{
				frame = obj.frame as Date;
				widget = obj.widget as InteractiveWidget;
				
				widget.interactiveLayerMap.setFrame(frame);
				dataForWidgetAvailable(widget);
			}
		}
		
		private function waitForPrimaryLayer(event: DataEvent): void
		{
			if (tempDataDictionary)
			{
				var ilm: InteractiveLayerMap = event.target as InteractiveLayerMap; 
				var tempData: Object = tempDataDictionary[ilm];
				
				if (tempData)
				{
					var synchronizeFromWidget: InteractiveWidget = tempData.widget as InteractiveWidget;
					synchronizeFromWidget.interactiveLayerMap.removeEventListener(InteractiveLayerMap.PRIMARY_LAYER_CHANGED, waitForPrimaryLayer);
					synchronizeWidgets(synchronizeFromWidget, tempData.widgets as ArrayCollection, tempData.prefferedSelectedIndex as int);
				}
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
					
					var synchronizeFrame: Boolean;
					
					for each (var layer: InteractiveLayer in layers)
					{
						if (layer is InteractiveLayerMSBase)
						{
							var synchroVars: Array = (layer as InteractiveLayerMSBase).getSynchronisedVariables();
							for each (var s_synchroVarName: String in synchroVars)
							{
								switch (s_synchroVarName.toLowerCase())
								{
									case GlobalVariable.FRAME:
										synchronizeFrame = true;
										break;
								}
							}
						}
					}
					
					if (synchronizeFrame)
						dataForWidgetAvailable(widget);
					else
						dataForWidgetUnvailable(widget);
				}
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
		private function getFrames(primaryLayer: InteractiveLayerMSBase, currFrame: Date, synchronizeFromWidgetPosition: uint, totalWidgets: int): Array
		{
			var frames: Array = primaryLayer.getSynchronisedVariableValuesList(GlobalVariable.FRAME);
			var currFramePosition: int = getFramePosition(currFrame, frames);
			
			//get values
			var synchronisedFrames: Array = [];
			
			for (var i: int = 0; i < totalWidgets; i++)
			{
				var timeDifference: int = _frameStep * (i - synchronizeFromWidgetPosition);
				var newDate: Date = getFrameWithTimeDifference(frames, currFrame, timeDifference);
				synchronisedFrames.push(newDate);
			}
			return synchronisedFrames;
		}

		private function synchronizeFramesSequentialy(synchronizeFromWidget: InteractiveWidget, widgetsForSynchronisation: ArrayCollection, preferredSelectedIndex: int = -1): void
		{
			var primaryLayer: InteractiveLayerMSBase = synchronizeFromWidget.interactiveLayerMap.getPrimaryLayer();
			if (primaryLayer)
			{
//				var variables: Array = primaryLayer.getSynchronisedVariables();
				var frames: Array = primaryLayer.getSynchronisedVariableValuesList(GlobalVariable.FRAME);
				var synchronizeFromWidgetPosition: int = getWidgetPosition(synchronizeFromWidget, widgetsForSynchronisation);
				var currFrame: Date = primaryLayer.getSynchronisedVariableValue(GlobalVariable.FRAME) as Date;
				var currFramePosition: int = getFramePosition(currFrame, frames);
//				if (currFrame)
//					debug("FrameSynchronizator synchronizeFramesSequentialy: curr frame: " + currFrame.toTimeString() + " currFramePosition: " + currFramePosition);
				if (currFramePosition > 0)
				{
					var sliceFrom: int = Math.max(0, currFramePosition - synchronizeFromWidgetPosition);
					var sliceTo: int = frames.length;
					frames = frames.slice(sliceFrom, sliceTo);
					
					currFramePosition -= sliceFrom;
//					debug("FrameSynchronizator synchronizeFramesSequentialy: sliceFrom: " + sliceFrom + " sliceTo: " + sliceTo);
				}
				if (synchronizeFromWidgetPosition > -1)
				{
					var cnt: int = 0;
					var total: int = widgetsForSynchronisation.length;
					
					var widgetsForSynchronizing: Array = [];
					
					for (var i: int = 0; i < total; i++)
					{
						var widget: InteractiveWidget = widgetsForSynchronisation.getItemAt(i) as InteractiveWidget;
						if (widget.id != synchronizeFromWidget.id)
						{
							var framePos: int = i - synchronizeFromWidgetPosition + currFramePosition;
//							debug("\t FrameSynchronizator synchronizeFramesSequentialy: widget: " + widget.id + " framePos: " + framePos);
							if (framePos >= 0)
							{
								var frame: Date = getFrame(framePos, frames);
								if (frame)
								{
									var bSynchronizeWidget: Boolean = false;
									
									var currWidgetPrimaryLayer: InteractiveLayerMSBase = widget.interactiveLayerMap.getPrimaryLayer();
									if (currWidgetPrimaryLayer)
									{
										var currWidgetFrame: Date = currWidgetPrimaryLayer.getSynchronisedVariableValue(GlobalVariable.FRAME) as Date;
										if (!widget.enabled || (currWidgetFrame && currWidgetFrame.time != frame.time))
										{
											bSynchronizeWidget = true;		
										}
									} else {
										bSynchronizeWidget = false;
										
										//wait for primary layer
										tempDataDictionary[widget.interactiveLayerMap] = {widget: widget, widgets: widgetsForSynchronisation, prefferedSelectedIndex: preferredSelectedIndex};
										synchronizeFromWidget.interactiveLayerMap.addEventListener(InteractiveLayerMap.PRIMARY_LAYER_CHANGED, waitForPrimaryLayer);
										continue;
									}
										
									if (bSynchronizeWidget)
									{
//										debug("\t FrameSynchronizator synchronizeFramesSequentialy: widget: " + widget.id + " framePos: " + framePos + " frame: " + frame.toTimeString());
										
										listenToWidgetSynchronization(widget);
										widgetsForSynchronizing.push( {frame: frame, widget: widget } );
									} else {
										debug("\t FrameSynchronizator synchronizeFramesSequentialy: widget: " + widget.id + " frame: " + frame.toTimeString() + " is already set");										
									}
									
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
					
					//2nd pass, change frames
					delayedSynchronization(widgetsForSynchronizing);
					
				}
			}
			
			checkIfSynchronizationIsDone();
			
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
//				debug("\t\t getFramePosition currFrame: " + currFrame + " compare to: " + frame);
				if (currFrame.time == frame.time)
				{
//					debug("\t\t getFramePosition position is: " + cnt);
					return cnt;
				}
				cnt++;
			}
				debug("\t\t getFramePosition position is: -1");
			return -1;
		}

		private function debugWidgetsIDs(synchronizeFromWidget: InteractiveWidget, widgetsForSynchronisation: ArrayCollection): void
		{
			return;
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
