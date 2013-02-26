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
		public function SynchronizatorBase()
		{
			_synchronizatorInvalid = true;
			initializeSynchronizator();
		}
		
		protected var _synchronizatorInvalid: Boolean;
		
		public function initializeSynchronizator(): void
		{
			_synchronisationDictionary = new Dictionary();
		}
	
		public function invalidateSynchronizator():void
		{
			_synchronizatorInvalid = true;
		}
		
		
		public function isSynchronizedFor(synchronizedDate: Date): Boolean
		{
			return _synchronizatorInvalid;
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
		
		
		protected var _synchronisationDictionary: Dictionary;
		
		protected function listenToWidgetSynchronization(widget: InteractiveWidget): void
		{
			var primaryLayer: InteractiveLayerMSBase = widget.interactiveLayerMap.primaryLayer;
			if (primaryLayer)
			{
				_synchronisationDictionary[primaryLayer] = primaryLayer.container.id;
				primaryLayer.addEventListener(SynchronisedVariableChangeEvent.SYNCHRONISED_VARIABLE_DOMAIN_CHANGED, onSychronisationDone);
				primaryLayer.addEventListener(SynchronisedVariableChangeEvent.SYNCHRONISED_VARIABLE_CHANGED, onSychronisationDone);
			}
		}
		
		protected function onSychronisationDone(event: SynchronisedVariableChangeEvent): void
		{
			var layer: InteractiveLayerMSBase = event.target as InteractiveLayerMSBase;
			if (layer)
			{
				delete _synchronisationDictionary[layer];
				layer.removeEventListener(SynchronisedVariableChangeEvent.SYNCHRONISED_VARIABLE_DOMAIN_CHANGED, onSychronisationDone);
				layer.removeEventListener(SynchronisedVariableChangeEvent.SYNCHRONISED_VARIABLE_CHANGED, onSychronisationDone);
				checkIfSynchronizationIsDone();
			}
		}
		
		protected function checkIfSynchronizationIsDone(): void
		{
			for (var layer: * in _synchronisationDictionary)
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