package com.iblsoft.flexiweather.ogc.tiling
{
	import com.iblsoft.flexiweather.utils.UniURLLoader;
	import com.iblsoft.flexiweather.utils.UniURLLoaderEvent;
	
	import flash.events.ProgressEvent;

	public class QTTTilesProvider implements ITilesProvider
	{
		private var _callbackTileLoaded: Function;
		private var _callbackTileLoadFailed: Function;
		
		public function QTTTilesProvider()
		{
		}
		
		/**
		 * Function is responsible for loading tiles and call callback function on tile load finish.
		 *  
		 * @param tilesIndices Array of QTTTileRequest items
		 * @param callbackTileLoaded Callback which will be called, when tile load succesfuly finished
		 * @param callbackTileLoadFailed Callback, which will be called, when tile loading failed
		 * 
		 */	
		public function getTiles(tilesIndices: Array, callbackTileLoaded: Function, callbackTileLoadFailed: Function): void
		{
			if (tilesIndices && tilesIndices.length > 0)
			{
				_callbackTileLoaded = callbackTileLoaded;
				_callbackTileLoadFailed = callbackTileLoadFailed;
				
				for each (var data: QTTTileRequest in tilesIndices)
				{
					var customAssociatedData: Object = {associatedData: data.associatedData, tileRequest: data};
					var m_loader: UniURLLoader = new UniURLLoader();
					m_loader.addEventListener(UniURLLoader.DATA_LOADED, onDataLoaded);
					m_loader.addEventListener(ProgressEvent.PROGRESS, onDataProgress);
					m_loader.addEventListener(UniURLLoader.DATA_LOAD_FAILED, onDataLoadFailed);						
					m_loader.load(data.request, customAssociatedData, data.jobName);
				}
			}
		}
		
		protected function onDataProgress(event: ProgressEvent): void
		{
			//			trace(this + " onDataProgress: " + event.bytesLoaded + " / " + event.bytesTotal);
		}
		
		protected function onDataLoaded(event: UniURLLoaderEvent): void
		{
			var tileAssociatedData: Object = event.associatedData.associatedData;
			var tileRequested: QTTTileRequest = event.associatedData.tileReqest as QTTTileRequest;
			
			_callbackTileLoaded(tileRequested.tileIndex, tileAssociatedData);
		}
		
		protected function onDataLoadFailed(event: UniURLLoaderEvent): void
		{
			var tileAssociatedData: Object = event.associatedData.associatedData;
			var tileRequested: QTTTileRequest = event.associatedData.tileReqest as QTTTileRequest;
			
			_callbackTileLoadFailed(tileRequested.tileIndex, tileAssociatedData);
		}
	}
}