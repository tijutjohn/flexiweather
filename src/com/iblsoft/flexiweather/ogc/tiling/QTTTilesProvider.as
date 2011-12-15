package com.iblsoft.flexiweather.ogc.tiling
{
	import com.iblsoft.flexiweather.net.events.UniURLLoaderErrorEvent;
	import com.iblsoft.flexiweather.net.events.UniURLLoaderEvent;
	import com.iblsoft.flexiweather.net.loaders.UniURLLoader;
	import com.iblsoft.flexiweather.ogc.net.loaders.WMSImageLoader;
	
	import flash.display.Bitmap;
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
					var m_loader: WMSImageLoader = new WMSImageLoader();
					m_loader.addEventListener(UniURLLoaderEvent.DATA_LOADED, onDataLoaded);
					m_loader.addEventListener(ProgressEvent.PROGRESS, onDataProgress);
					m_loader.addEventListener(UniURLLoaderErrorEvent.DATA_LOAD_FAILED, onDataLoadFailed);						
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
			var tileRequested: QTTTileRequest = event.associatedData.tileRequest as QTTTileRequest;
			
			_callbackTileLoaded(Bitmap(event.result), tileRequested, tileRequested.tileIndex, tileAssociatedData);
		}
		
		protected function onDataLoadFailed(event: UniURLLoaderErrorEvent): void
		{
			var tileAssociatedData: Object = event.associatedData.associatedData;
			var tileRequested: QTTTileRequest = event.associatedData.tileRequest as QTTTileRequest;
			
			_callbackTileLoadFailed(tileRequested.tileIndex, tileAssociatedData);
		}
	}
}