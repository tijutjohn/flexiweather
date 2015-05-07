package com.iblsoft.flexiweather.ogc.multiview.synchronization
{
	import com.iblsoft.flexiweather.ogc.InteractiveLayerMSBase;
	import com.iblsoft.flexiweather.ogc.SynchronisedVariableChangeEvent;
	import com.iblsoft.flexiweather.ogc.multiview.data.MultiViewConfiguration;
	import com.iblsoft.flexiweather.ogc.multiview.data.MultiViewCustomData;
	import com.iblsoft.flexiweather.ogc.multiview.data.MultiViewViewData;
	import com.iblsoft.flexiweather.ogc.multiview.synchronization.events.SynchronisationEvent;
	import com.iblsoft.flexiweather.utils.Serializable;
	import com.iblsoft.flexiweather.utils.Storage;
	import com.iblsoft.flexiweather.widgets.InteractiveLayer;
	import com.iblsoft.flexiweather.widgets.InteractiveLayerLabel;
	import com.iblsoft.flexiweather.widgets.InteractiveLayerMap;
	import com.iblsoft.flexiweather.widgets.InteractiveWidget;

	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.utils.Dictionary;

	import mx.collections.ArrayCollection;

	public class SynchronizatorBase extends EventDispatcher implements ISynchronizator, Serializable
	{
		private var ma_supportedChangeTypes: Array;
		protected var md_synchronisationDictionary: Dictionary;
		protected var mb_synchronizatorInvalid: Boolean;

		public var type: String;

		public function get viewHasOwnGlobalVariable(): Boolean
		{
			return false;
		}

		public function SynchronizatorBase()
		{
			mb_synchronizatorInvalid = true;
			ma_supportedChangeTypes = [];
			initializeSynchronizator();
		}


		public function initializeSynchronizator(): void
		{
			md_synchronisationDictionary = new Dictionary();
		}

		public function invalidateSynchronizator():void
		{
			mb_synchronizatorInvalid = true;
		}

		public function closeSynchronizator(): void
		{
			for (var layer: * in md_synchronisationDictionary)
			{
				if (layer)
				{
					removeListenersOnSynchronisationDone(layer);
				}
			}
		}

		public function isSynchronizedFor(synchronizedDate: Date): Boolean
		{
			return mb_synchronizatorInvalid;
		}

		public function canCreateMap(iw:InteractiveWidget):Boolean
		{
			return false;
		}

		public function createMap(iw:InteractiveWidget):void
		{
		}

		public function updateMapAction(iw:InteractiveWidget, position:int, configuration:MultiViewConfiguration):void
		{
		}

		public function synchronizeWidgets(synchronizeFromWidget:InteractiveWidget, widgetsForSynchronisation:ArrayCollection, preferredSelectedIndex:int=-1, mainSynchronizator: ISynchronizator = null):void
		{
		}

		public function notifySynchronizationDone(): void
		{
			trace("notifySynchronizationDone");
			dispatchEvent(new SynchronisationEvent(SynchronisationEvent.SYNCHRONISATION_DONE, true));
		}




		protected function listenToWidgetSynchronization(widget: InteractiveWidget): void
		{
			var primaryLayer: InteractiveLayerMSBase = widget.interactiveLayerMap.primaryLayer;
			if (primaryLayer)
			{
				var bFound: Boolean = false;
				for each (var layer: InteractiveLayer in widget.interactiveLayerMap.layers)
				{
					layer.addEventListener(SynchronisedVariableChangeEvent.SYNCHRONISED_VARIABLE_NOT_SYNCRONISED, onSychronisationProblem);
//					trace("\tlistenToWidgetSynchronization["+primaryLayer.layerID+"]: layer" + layer.layerID);
					if (layer.layerID == primaryLayer.layerID)
						bFound = true;

				}
				if (!bFound)
				{
					trace("PRIMARY LAYER WAS NOT FOUND");
				}
				md_synchronisationDictionary[primaryLayer] = primaryLayer.container.id;
				trace("listenToWidgetSynchronization ADDING LAYER ["+primaryLayer.layerID+"] map: " + (primaryLayer.parent as InteractiveLayerMap).mapID);
				primaryLayer.addEventListener(SynchronisedVariableChangeEvent.SYNCHRONISED_VARIABLE_DOMAIN_CHANGED, onSychronisationDone);
				primaryLayer.addEventListener(SynchronisedVariableChangeEvent.SYNCHRONISED_VARIABLE_CHANGED, onSychronisationDone);
			}
		}

		protected function onSychronisationProblem(event: SynchronisedVariableChangeEvent): void
		{
			//for now do same as if synchronisation is correct
			trace("Problem with synchronisation: " + event.variableId);
			var ilm: InteractiveLayerMap = (event.target as InteractiveLayerMSBase).parent as InteractiveLayerMap;
			for each (var layer: InteractiveLayer in ilm.layers)
			{
				layer.removeEventListener(SynchronisedVariableChangeEvent.SYNCHRONISED_VARIABLE_NOT_SYNCRONISED, onSychronisationProblem);
			}

//			onSychronisationDone(event);

			var primaryLayer: InteractiveLayerMSBase = ilm.getPrimaryLayer();
			if (primaryLayer)
			{
				trace("onSychronisationDone2 layer: " + primaryLayer.name + " id: " + primaryLayer.layerID);
				removeListenersOnSynchronisationDone(primaryLayer);
				checkIfSynchronizationIsDone();
			}

		}

		protected function onSychronisationDone(event: SynchronisedVariableChangeEvent): void
		{
			var layer: InteractiveLayerMSBase = event.target as InteractiveLayerMSBase;
			if (layer)
			{
				trace("onSychronisationDone layer: " + layer.name + " id: " + layer.layerID);
				removeListenersOnSynchronisationDone(layer);
				checkIfSynchronizationIsDone();
			}
		}

		private function removeListenersOnSynchronisationDone(layer: InteractiveLayerMSBase): void
		{
			delete md_synchronisationDictionary[layer];
			trace("removeListenersOnSynchronisationDone: "+ layer.layerID + " map: " + (layer.parent as InteractiveLayerMap).mapID);
			layer.removeEventListener(SynchronisedVariableChangeEvent.SYNCHRONISED_VARIABLE_DOMAIN_CHANGED, onSychronisationDone);
			layer.removeEventListener(SynchronisedVariableChangeEvent.SYNCHRONISED_VARIABLE_CHANGED, onSychronisationDone);
		}

		protected function checkIfSynchronizationIsDone(): void
		{
			var layersCount: int = 0;
			for (var layer: * in md_synchronisationDictionary)
			{
				if (layer)
					layersCount++;
			}

			if (layersCount)
			{
				trace("checkIfSynchronizationIsDone not finished: still layers: "+ layersCount);
				return;
			}

			trace("checkIfSynchronizationIsDone FINISHED ");
			//there is no layer in dictionary, so synchronisation is done
			notifySynchronizationDone();
		}

		public function get labelString():String
		{
			return '';
		}

		public function set viewData(data: MultiViewViewData):void
		{
		}

		public function set customData(data: MultiViewCustomData): void
		{

		}

		public function get customData(): MultiViewCustomData
		{
			return new MultiViewCustomData();
		}

		public function get willSynchronisePrimaryLayer():Boolean
		{
			return false;
		}

		public function getSynchronisedVariables(): Array
		{
			return [];
		}

		protected function registerChangeType(s_changeType: String): void
		{
			if (ma_supportedChangeTypes.indexOf(s_changeType) < 0)
				ma_supportedChangeTypes.push(s_changeType);
		}

		protected function unregisterChangeType(s_changeType: String): void
		{
			var pos: int = ma_supportedChangeTypes.indexOf(s_changeType);
			if (pos > -1)
			{
				ma_supportedChangeTypes.splice(pos, 1);
			}

		}

		public function isSynchronisingChangeType(s_changeType: String): Boolean
		{
			if (ma_supportedChangeTypes && ma_supportedChangeTypes.length > 0)
			{
				for each (var currChangeType: String in ma_supportedChangeTypes)
				{
					if (currChangeType == s_changeType)
					{
						return true;
					}
				}
			}
			return false;
		}

		public function hasSynchronisedVariable(s_variableId:String):Boolean
		{
			return false;
		}

		protected function dataForWidgetAvailable(widget: InteractiveWidget): void
		{
			widget.enabled = true;
			var labelLayer: InteractiveLayerLabel = widget.getLayerByType(InteractiveLayerLabel) as InteractiveLayerLabel;
			if (labelLayer)
				labelLayer.invalidateDynamicPart();
		}

		protected function dataForWidgetUnvailable(widget: InteractiveWidget): void
		{
			widget.enabled = false;
			var labelLayer: InteractiveLayerLabel = widget.getLayerByType(InteractiveLayerLabel) as InteractiveLayerLabel;
			if (labelLayer)
				labelLayer.invalidateDynamicPart();
		}

		public function getLayersWaitingForSynchronisation(): Array
		{
			var retArray: Array = []
			if (md_synchronisationDictionary)
			{
				for (var layer: *  in md_synchronisationDictionary)
				{
					retArray.push(layer);
				}
			}
			return retArray;
		}

		public function serialize(storage:Storage):void
		{

		}


		public function get displayLegends():Boolean
		{
			return true;
		}

	}
}