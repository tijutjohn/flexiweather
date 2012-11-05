package com.iblsoft.flexiweather.ogc.tiling
{
	import com.iblsoft.flexiweather.net.events.UniURLLoaderErrorEvent;
	import com.iblsoft.flexiweather.net.events.UniURLLoaderEvent;
	import com.iblsoft.flexiweather.net.loaders.UniURLLoader;
	import com.iblsoft.flexiweather.ogc.net.loaders.WMSImageLoader;
	import flash.display.Bitmap;
	import flash.events.ProgressEvent;
	import flash.net.URLRequest;

	public class TiledTilesProvider implements ITilesProvider
	{
		private var _callbackTileLoaded: Function;
		private var _callbackTileLoadFailed: Function;

		public function TiledTilesProvider()
		{
		}

		public function destroy(): void
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
				for each (var data: TiledTileRequest in tilesIndices)
				{
					var customAssociatedData: Object = {tileRequest: data};
					var request: URLRequest = data.qttTileViewProperties.url;
					var m_loader: WMSImageLoader = new WMSImageLoader();
					m_loader.addEventListener(UniURLLoaderEvent.DATA_LOADED, onDataLoaded);
					m_loader.addEventListener(ProgressEvent.PROGRESS, onDataProgress);
					m_loader.addEventListener(UniURLLoaderErrorEvent.DATA_LOAD_FAILED, onDataLoadFailed);
					m_loader.load(request, customAssociatedData, data.jobName);
				}
			}
		}

		private function removeEventListeners(m_loader: WMSImageLoader): void
		{
			m_loader.removeEventListener(UniURLLoaderEvent.DATA_LOADED, onDataLoaded);
			m_loader.removeEventListener(ProgressEvent.PROGRESS, onDataProgress);
			m_loader.removeEventListener(UniURLLoaderErrorEvent.DATA_LOAD_FAILED, onDataLoadFailed);
		}

		protected function onDataProgress(event: ProgressEvent): void
		{
			//			trace(this + " onDataProgress: " + event.bytesLoaded + " / " + event.bytesTotal);
		}

		protected function onDataLoaded(event: UniURLLoaderEvent): void
		{
			var m_loader: WMSImageLoader = event.target as WMSImageLoader;
			removeEventListeners(m_loader);
			var tileRequested: TiledTileRequest = event.associatedData.tileRequest as TiledTileRequest;
			_callbackTileLoaded(Bitmap(event.result), tileRequested, tileRequested.qttTileViewProperties.tileIndex);
		}

		protected function onDataLoadFailed(event: UniURLLoaderErrorEvent): void
		{
			var m_loader: WMSImageLoader = event.target as WMSImageLoader;
			removeEventListeners(m_loader);
			var tileAssociatedData: Object = event.associatedData.associatedData;
			var tileRequested: TiledTileRequest = event.associatedData.tileRequest as TiledTileRequest;
			if (tileAssociatedData)
				tileAssociatedData.errorResult = event.result;
			else
				tileAssociatedData = {errorResult: event.result};
			_callbackTileLoadFailed(tileRequested, tileAssociatedData);
		}
	}
}
