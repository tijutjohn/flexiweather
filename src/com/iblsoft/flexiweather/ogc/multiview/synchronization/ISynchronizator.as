package com.iblsoft.flexiweather.ogc.multiview.synchronization
{
	import com.iblsoft.flexiweather.ogc.ISynchronisedObject;
	import com.iblsoft.flexiweather.widgets.InteractiveWidget;
	
	import mx.collections.ArrayCollection;

	public interface ISynchronizator
	{
		function synchronizeWidgets(synchronizeFromWidget: InteractiveWidget, widgetsForSynchronisation: ArrayCollection, preferredSelectedIndex: int = -1): void;
		function get labelString():String;
		function set viewData(data: Array): void;
		function set customData(data: Object): void;
		function get customData(): Object;
		
		/**
		 * Return true if synchronisator will synchronise primary layer 
		 * @return 
		 * 
		 */		
		function get willSynchronisePrimaryLayer(): Boolean;
		
		function getSynchronisedVariables():Array;
		function hasSynchronisedVariable(s_variableId: String): Boolean;
	}
}