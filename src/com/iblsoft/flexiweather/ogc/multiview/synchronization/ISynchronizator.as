package com.iblsoft.flexiweather.ogc.multiview.synchronization
{
	import com.iblsoft.flexiweather.ogc.ISynchronisedObject;
	import com.iblsoft.flexiweather.ogc.multiview.data.MultiViewConfiguration;
	import com.iblsoft.flexiweather.ogc.multiview.data.MultiViewCustomData;
	import com.iblsoft.flexiweather.ogc.multiview.data.MultiViewViewData;
	import com.iblsoft.flexiweather.widgets.InteractiveWidget;

	import flash.events.IEventDispatcher;

	import mx.collections.ArrayCollection;

	public interface ISynchronizator extends IEventDispatcher
	{
		function initializeSynchronizator(): void;

		function invalidateSynchronizator(): void;

		function closeSynchronizator(): void;

		function isSynchronizedFor(synchronizedDate: Date): Boolean;
		function canCreateMap(iw: InteractiveWidget): Boolean;
		function get displayLegends(): Boolean;
		function get viewHasOwnGlobalVariable(): Boolean;
		function createMap(iw: InteractiveWidget): void;

		function updateMapAction(iw: InteractiveWidget, position: int, configuration: MultiViewConfiguration): void;

		function synchronizeWidgets(synchronizeFromWidget: InteractiveWidget, widgetsForSynchronisation: ArrayCollection, preferredSelectedIndex: int = -1): void;
		function notifySynchronizationDone(): void;
		function get labelString():String;
		function set viewData(data: MultiViewViewData): void;
		function set customData(data: MultiViewCustomData): void;
		function get customData(): MultiViewCustomData;

		/**
		 * Return true if synchronisator will synchronise primary layer
		 * @return
		 *
		 */
		function get willSynchronisePrimaryLayer(): Boolean;

		function isSynchronisingChangeType(s_changeType: String): Boolean;

		function getSynchronisedVariables():Array;
		function hasSynchronisedVariable(s_variableId: String): Boolean;

		//debug methods
		function getLayersWaitingForSynchronisation(): Array;
	}
}