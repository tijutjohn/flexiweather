package com.iblsoft.flexiweather.ogc.multiview.synchronization
{
	import com.iblsoft.flexiweather.ogc.ISynchronisedObject;
	import com.iblsoft.flexiweather.widgets.InteractiveWidget;
	
	import mx.collections.ArrayCollection;

	public interface ISynchronizator
	{
		function synchronizeWidgets(synchronizeFromWidget: InteractiveWidget, widgetsForSynchronisation: ArrayCollection): void;
		function get labelString():String;
		function getSynchronisedVariables():Array;
		function hasSynchronisedVariable(s_variableId: String): Boolean;
	}
}