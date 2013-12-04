package com.iblsoft.flexiweather.ogc
{

	public interface ISynchronisedObject
	{
		/**
		 * Returns list (array) of synchronise-able variable specifying objects.
		 * @return Empty array if no synchronised variables are available.
		 */
		function getSynchronisedVariables(): Array;
		/** Checks whether object can be synchronised with variable s_variableId. */
		function hasSynchronisedVariable(s_variableId: String): Boolean;
		/**
		 * Returns value of synchronised variable s_variableId.
		 * @return	null if s_variableId is unknown or its value is not available.
		 **/
		function getSynchronisedVariableValue(s_variableId: String): Object;
		/**
		 * Returns array of all possible values for synchronised variable s_variableId.
		 * @return	null if s_variableId is unknown.
		 */
		function getSynchronisedVariableValuesList(s_variableId: String): Array;
		
		/** Update layer object configuration so that variable s_variableId has value s_value. */
		function synchroniseWith(s_variableId: String, value: Object): String;
		
		/** Special refresh method, which refresha synchronizable layer and ask for new data. */		
		function refreshForSynchronisation(b_force: Boolean): void;
		
		/** Return information if object is primary layer */
		function isPrimaryLayer(): Boolean;
		
		/** Return information if object is ready for synchronisation */
		function get isReadyForSynchronisation(): Boolean;
		
		function get synchroniseRun(): Boolean;
		function set synchroniseRun(value: Boolean): void;
		
		function get synchroniseLevel(): Boolean;
		function set synchroniseLevel(value: Boolean): void;
	}
}
