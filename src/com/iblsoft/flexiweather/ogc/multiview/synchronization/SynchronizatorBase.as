package com.iblsoft.flexiweather.ogc.multiview.synchronization
{
	import com.iblsoft.flexiweather.ogc.multiview.data.MultiViewConfiguration;
	import com.iblsoft.flexiweather.widgets.InteractiveWidget;
	
	import flash.events.Event;
	import flash.events.EventDispatcher;
	
	import mx.collections.ArrayCollection;
	
	public class SynchronizatorBase extends EventDispatcher implements ISynchronizator
	{
		public function SynchronizatorBase()
		{
			_synchronizatorInvalid = true;
		}
		
		protected var _synchronizatorInvalid: Boolean;
		
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
	}
}