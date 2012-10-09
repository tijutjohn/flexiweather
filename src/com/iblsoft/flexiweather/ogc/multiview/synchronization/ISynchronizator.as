package com.iblsoft.flexiweather.ogc.multiview.synchronization
{
	import com.iblsoft.flexiweather.ogc.ISynchronisedObject;
	import com.iblsoft.flexiweather.widgets.InteractiveWidget;
	
	import mx.collections.ArrayCollection;

	public interface ISynchronizator
	{
		function synchronizeWidgets(synchronizeFromWidget: InteractiveWidget, widgetsForSynchronisation: ArrayCollection): void;
		function get labelString():String;
		function set viewData(data: Array): void;
		
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