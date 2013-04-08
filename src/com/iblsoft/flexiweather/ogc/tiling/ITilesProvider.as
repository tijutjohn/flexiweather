package com.iblsoft.flexiweather.ogc.tiling
{
	public interface ITilesProvider
	{
		/**
		 * Function is responsible for loading tiles and call callback function on tile load finish.
		 *
		 * @param tilesIndices Array of QTTTileRequest items
		 * @param callbackTileLoaded Callback which will be called, when tile load succesfuly finished
		 * @param callbackTileLoadFailed Callback, which will be called, when tile loading failed
		 *
		 */
		function getTiles(tilesIndices: Array, callbackTileLoaded: Function, callbackTileLoadFailed: Function): void;
		function cancel(): void;
		function destroy(): void;
	}
}
