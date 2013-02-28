package com.iblsoft.flexiweather.ogc.multiview.synchronization
{
	import com.iblsoft.flexiweather.ogc.InteractiveLayerMSBase;
	import com.iblsoft.flexiweather.ogc.SynchronisedVariableChangeEvent;
	import com.iblsoft.flexiweather.ogc.multiview.data.MultiViewConfiguration;
	import com.iblsoft.flexiweather.ogc.multiview.synchronization.events.SynchronisationEvent;
	import com.iblsoft.flexiweather.widgets.InteractiveLayerLabel;
	import com.iblsoft.flexiweather.widgets.InteractiveWidget;
	
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.utils.Dictionary;
	
	import mx.collections.ArrayCollection;
	
	public class SynchronizatorBase extends EventDispatcher implements ISynchronizator
	{
		private var ma_supportedChangeTypes: Array;
		protected var md_synchronisationDictionary: Dictionary;
		protected var mb_synchronizatorInvalid: Boolean;
		
		public function SynchronizatorBase()
		{
			mb_synchronizatorInvalid = true;
			ma_supportedChangeTypes = [];
			initializeSynchronizator();
		}
		
		
		public function initializeSynchronizator(): void
		{
			md_synchronisationDictionary = new Dictionary();
			ma_supportedChangeTypes
		}
	
		public function invalidateSynchronizator():void
		{
			mb_synchronizatorInvalid = true;
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
		
		public function synchronizeWidgets(synchronizeFromWidget:InteractiveWidget, widgetsForSynchronisation:ArrayCollection, preferredSelectedIndex:int=-1):void
		{
		}
		
		public function notifySynchronizationDone(): void
		{
			dispatchEvent(new SynchronisationEvent(SynchronisationEvent.SYNCHRONISATION_DONE, true));
		}
		
		
		
		
		protected function listenToWidgetSynchronization(widget: InteractiveWidget): void
		{
			var primaryLayer: InteractiveLayerMSBase = widget.interactiveLayerMap.primaryLayer;
			if (primaryLayer)
			{
				md_synchronisationDictionary[primaryLayer] = primaryLayer.container.id;
				primaryLayer.addEventListener(SynchronisedVariableChangeEvent.SYNCHRONISED_VARIABLE_DOMAIN_CHANGED, onSychronisationDone);
				primaryLayer.addEventListener(SynchronisedVariableChangeEvent.SYNCHRONISED_VARIABLE_CHANGED, onSychronisationDone);
			}
		}
		
		protected function onSychronisationDone(event: SynchronisedVariableChangeEvent): void
		{
			var layer: InteractiveLayerMSBase = event.target as InteractiveLayerMSBase;
			if (layer)
			{
				delete md_synchronisationDictionary[layer];
				layer.removeEventListener(SynchronisedVariableChangeEvent.SYNCHRONISED_VARIABLE_DOMAIN_CHANGED, onSychronisationDone);
				layer.removeEventListener(SynchronisedVariableChangeEvent.SYNCHRONISED_VARIABLE_CHANGED, onSychronisationDone);
				checkIfSynchronizationIsDone();
			}
		}
		
		protected function checkIfSynchronizationIsDone(): void
		{
			for (var layer: * in md_synchronisationDictionary)
			{
				if (layer)
					return;
			}
			
			//there is no layer in dictionary, so synchronisation is done
			notifySynchronizationDone();
		}
		
		public function get labelString():String
		{
			return '';
		}
		
		public function set viewData(data:Array):void
		{
		}
		
		public function set customData(data: Object): void
		{
			
		}
		
		public function get customData(): Object
		{
			return {};
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
		}
		
		protected function dataForWidgetUnvailable(widget: InteractiveWidget): void
		{
			widget.enabled = false;
			var labelLayer: InteractiveLayerLabel = widget.getLayerByType(InteractiveLayerLabel) as InteractiveLayerLabel;
			if (labelLayer)
				labelLayer.invalidateDynamicPart();
		}
	}
}