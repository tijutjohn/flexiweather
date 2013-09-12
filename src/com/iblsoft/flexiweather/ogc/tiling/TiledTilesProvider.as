package com.iblsoft.flexiweather.ogc.tiling
{
	import com.iblsoft.flexiweather.net.events.UniURLLoaderErrorEvent;
	import com.iblsoft.flexiweather.net.events.UniURLLoaderEvent;
	import com.iblsoft.flexiweather.net.loaders.UniURLLoader;
	import com.iblsoft.flexiweather.ogc.cache.WMSTileCache;
	import com.iblsoft.flexiweather.ogc.data.viewProperties.TiledTileViewProperties;
	import com.iblsoft.flexiweather.ogc.data.viewProperties.TiledViewProperties;
	import com.iblsoft.flexiweather.ogc.net.loaders.WMSImageLoader;
	
	import flash.display.Bitmap;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.ProgressEvent;
	import flash.net.URLRequest;
	import flash.utils.Dictionary;
	
	import mx.collections.ArrayCollection;

	[Event(name="allTilesLoaded", type="flash.events.Event")]
	public class TiledTilesProvider extends EventDispatcher implements ITilesProvider
	{
		public static const ALL_TILES_LOADED: String = 'allTilesLoaded';
		
//		private var _callbackTileLoaded: Function;
//		private var _callbackTileLoadFailed: Function;

		private var ma_freeLoaders: Array;
		private var md_loadersRequests: Dictionary;
		private var ma_tilesBuffer: Array;
		
		private var m_tiledCached: WMSTileCache;
		
		public function TiledTilesProvider(tiledCache: WMSTileCache)
		{
			ma_tilesBuffer = [];
			ma_freeLoaders = [];
			md_loadersRequests = new Dictionary();
			
			m_tiledCached = tiledCache;
			
			createLoaders();
		}

		public function destroy(): void
		{
		}

		private function destroyLoader(tileLoader: TileLoader): void
		{
			var m_loader: WMSImageLoader = tileLoader.loader;
			m_loader.removeEventListener(UniURLLoaderEvent.DATA_LOADED, onDataLoaded);
			m_loader.removeEventListener(ProgressEvent.PROGRESS, onDataProgress);
			m_loader.removeEventListener(UniURLLoaderErrorEvent.DATA_LOAD_FAILED, onDataLoadFailed);
			
			delete md_loadersRequests[m_loader];
			var pos: int = ma_freeLoaders.indexOf(m_loader);
			if (pos >= 0)
				ma_freeLoaders.splice(pos,1);
		}
		private function createLoader(): void
		{
			var m_loader: WMSImageLoader = new WMSImageLoader();
			m_loader.addEventListener(UniURLLoaderEvent.DATA_LOADED, onDataLoaded);
			m_loader.addEventListener(ProgressEvent.PROGRESS, onDataProgress);
			m_loader.addEventListener(UniURLLoaderErrorEvent.DATA_LOAD_FAILED, onDataLoadFailed);
			
			md_loadersRequests[m_loader] = new TileLoader(m_loader);
			ma_freeLoaders.push(m_loader);
			
			var cnt: int = 0;
			for each (var tileLoader: TileLoader in md_loadersRequests)
				cnt++;
		}
		private function createLoaders(): void
		{
			for (var i: int = 0; i < 5; i++)
			{
				createLoader();
			}
		}
		private function releaseLoader(loader: WMSImageLoader): void
		{
			if (md_loadersRequests[loader])
			{
				var tileLoader: TileLoader = md_loadersRequests[loader] as TileLoader;
				tileLoader.data = null;
				destroyLoader(tileLoader);
				createLoader();
			}
//			ma_freeLoaders.push(loader);
		}
		private function getFreeLoader(): WMSImageLoader
		{
			if (ma_freeLoaders.length > 0)
			{
				return ma_freeLoaders.shift();
			}
			return null;
			
		}
		public function cancel(): void
		{
			//cancel all requests;
			ma_tilesBuffer = [];
			
			var tilesRequests: Array = [];
			for each (var tileLoader: TileLoader in md_loadersRequests)
			{
				var data: TiledTileRequest = tileLoader.data;
				tilesRequests.push(tileLoader);
			}
			cancelPreviousRequests(tilesRequests);
		}
		
//		private var _cancelledRequests: Array = [];
		private function cancelPreviousRequests(tilesRequests: Array): void
		{
			
/*			
			_tilesToBeLoaded -= ma_tilesBuffer.length;
			_tilesTotal -= ma_tilesBuffer.length;
			
			ma_tilesBuffer = [];
			
			for each (var tileLoader: TileLoader in md_loadersRequests)
			{
				if (tileLoader.isLoading)
				{
					var request: URLRequest = tileLoader.request;
					var loader: WMSImageLoader = tileLoader.loader;
					
					var loadingRequest: TiledTileRequest = tileLoader.data;
					trace("Cancel request: " + loadingRequest);
//					if (loadingRequest)
//					{
//						_cancelledRequests.push(loadingRequest);
//					}
					
					tileLoader.cancelled = true;
					
					m_tiledCached.cacheItemLoadingCanceled(loadingRequest.qttTileViewProperties);
					loader.cancel(request);
					
					releaseLoader(loader);
				}
			}
*/


			for each (var data: TiledTileRequest in tilesRequests)
			{
				var itemCacheKey: String = m_tiledCached.getItemCacheKey(data.qttTileViewProperties);
				var itemRemoved: Boolean = false;
				
				//find if tile request is waiting in tile buffer and remove it
				for (var i: int = 0; i < ma_tilesBuffer.length; i++)
				{
					var bufferRequest: TiledTileRequest = ma_tilesBuffer[i] as TiledTileRequest;
					var bufferItemCacheKey: String = m_tiledCached.getItemCacheKey(bufferRequest.qttTileViewProperties);
					if (bufferItemCacheKey == itemCacheKey)
					{
						ma_tilesBuffer.splice(i, 1);
						
						_tilesToBeLoaded--;
						_tilesTotal++;
						
						itemRemoved = true;
						
						break;
					}
				}
				
				if (!itemRemoved)
				{
					
					for each (var tileLoader: TileLoader in md_loadersRequests)
					{
						var loadingRequest: TiledTileRequest = tileLoader.data;
						if (loadingRequest)
						{
							var tileViewProperties: TiledTileViewProperties = loadingRequest.qttTileViewProperties
							
							var loadingItemCacheKey: String = m_tiledCached.getItemCacheKey(tileViewProperties);
							if (loadingItemCacheKey == itemCacheKey)
							{
								//cancel load
								if (tileLoader.isLoading)
								{
									
									m_tiledCached.cacheItemLoadingCanceled( tileViewProperties );
									
									var request: URLRequest = tileLoader.request;
									var loader: WMSImageLoader = tileLoader.loader;
									
									loader.cancel(request);
									
									releaseLoader(loader);
									
									_tilesToBeLoaded--;
									_tilesTotal++;
									itemRemoved = true;
									break;
								}
							}
						}
					}
				}
/*				
				if (itemRemoved)
				{
					trace(this + " cancel previous request: " + data);
				} else {
					trace(this + " request was not removed: " + data);
				}
*/				
			}
		}
		
		private var _tilesTotal: int;
		private var _tilesToBeLoaded: int;
		/**
		 * Function is responsible for loading tiles and call callback function on tile load finish.
		 *
		 * @param tilesIndices Array of QTTTileRequest items
		 * @param callbackTileLoaded Callback which will be called, when tile load succesfuly finished
		 * @param callbackTileLoadFailed Callback, which will be called, when tile loading failed
		 * @param tileCache
		 *
		 */
		public function getTiles(tilesRequests: Array, callbackTileLoaded: Function, callbackTileLoadFailed: Function): void
		{
			if (tilesRequests && tilesRequests.length > 0)
			{
//				trace("\n\n***************************************************************");
//				trace(this + " getTiles: " + (tilesRequests[0] as TiledTileRequest).qttTileViewProperties.qttViewProperties.validity);
				cancelPreviousRequests(tilesRequests);
				
//				_tilesTotal = tilesIndices.length;
//				_tilesToBeLoaded = tilesIndices.length;
				
//				_callbackTileLoaded = callbackTileLoaded;
//				_callbackTileLoadFailed = callbackTileLoadFailed;
				for each (var data: TiledTileRequest in tilesRequests)
				{
					_tilesTotal++;
					_tilesToBeLoaded++;
					
					data.callbackTileLoaded = callbackTileLoaded;
					data.callbackTileLoadFailed = callbackTileLoadFailed;
					
					var m_loader: WMSImageLoader = getFreeLoader();
					if (m_loader)
					{
						loadTile(data, m_loader);
					} else {
						waitForFreeLoader(data);
					}
				}
				
//				trace("***************************************************************\n\n");
			}
		}
		
		private function loadTile(data: TiledTileRequest, loader: WMSImageLoader): void
		{
			var customAssociatedData: Object = {tileRequest: data};
			var request: URLRequest = data.qttTileViewProperties.url;
			
//			trace(this + "loadTile: " + data.qttTileViewProperties.tileIndex);
			(md_loadersRequests[loader] as TileLoader).data = data;
			
			loader.load(request, customAssociatedData, data.jobName);
		}

		private function loadNextTile(): void
		{
			if (ma_tilesBuffer.length > 0)
			{
				var m_loader: WMSImageLoader = getFreeLoader();
				if (m_loader) {
					var data: TiledTileRequest = ma_tilesBuffer.shift();
					loadTile(data, m_loader);
				}
			} else {
				if (tilesLoading == 0)
				{
//					trace("all tiles loaded");
					_tilesTotal = 0;
					_tilesToBeLoaded = 0;
				}
			}
		}
		
		private function notifyAllTilesAreLoaded(): void
		{
			dispatchEvent(new Event(ALL_TILES_LOADED));
		}
		private function get tilesLoading(): int
		{
			var total: int = ma_tilesBuffer.length;
			for each (var tileLoader: TileLoader in md_loadersRequests)
			{
				if (tileLoader.isLoading)
				{
					total++;
				}
			}
			return total;
		}
		private function waitForFreeLoader(data: TiledTileRequest): void
		{
			ma_tilesBuffer.push(data);
		}
		
		private function removeEventListeners(m_loader: WMSImageLoader): void
		{
			m_loader.removeEventListener(UniURLLoaderEvent.DATA_LOADED, onDataLoaded);
			m_loader.removeEventListener(ProgressEvent.PROGRESS, onDataProgress);
			m_loader.removeEventListener(UniURLLoaderErrorEvent.DATA_LOAD_FAILED, onDataLoadFailed);
		}

		protected function onDataProgress(event: ProgressEvent): void
		{
		}

//		private function isRequestCancelled(tileRequested: TiledTileRequest): Boolean
//		{
//			var total: int = _cancelledRequests.length;
//			for (var i: int = 0; i < total; i++)
//			{
//				var currRequest: TiledTileRequest = _cancelledRequests[i] as TiledTileRequest;
//				if (currRequest == tileRequested)
//				{
//					trace("This request was cancelled");
//					_cancelledRequests.splice(i, 1);
//					return true;
//				}
//			}
//			return false;
//		}
		
		private function getTileLoader(loader: WMSImageLoader): TileLoader
		{
			if (md_loadersRequests[loader])
			{
				var tileLoader: TileLoader = md_loadersRequests[loader] as TileLoader;
				return tileLoader;
			}
			return null;
		}
		protected function onDataLoaded(event: UniURLLoaderEvent): void
		{
			_tilesToBeLoaded--;
			
			
			var m_loader: WMSImageLoader = event.target as WMSImageLoader;
			
			var tileLoader: TileLoader = getTileLoader(m_loader);
			var isRequetCancelled: Boolean;
			
			if (tileLoader)
				isRequetCancelled = tileLoader.cancelled;
			
//			removeEventListeners(m_loader);
			var tileRequested: TiledTileRequest = event.associatedData.tileRequest as TiledTileRequest;
			
			if (!isRequetCancelled)
				tileRequested.callbackTileLoaded(Bitmap(event.result), tileRequested, tileRequested.qttTileViewProperties.tileIndex);
			else 
				trace("TiledTilesProvider   onDataLoaded: request was cancelled!");
			releaseLoader(m_loader);
			loadNextTile();
		}

		protected function onDataLoadFailed(event: UniURLLoaderErrorEvent): void
		{
			var m_loader: WMSImageLoader = event.target as WMSImageLoader;
//			removeEventListeners(m_loader);
			var tileAssociatedData: Object = event.associatedData.associatedData;
			var tileRequested: TiledTileRequest = event.associatedData.tileRequest as TiledTileRequest;
			
			var tileLoader: TileLoader = getTileLoader(m_loader);
			var isRequetCancelled: Boolean;
			
			if (tileLoader)
				isRequetCancelled = tileLoader.cancelled;

			
			if (!isRequetCancelled)
			{
				if (tileAssociatedData)
					tileAssociatedData.errorResult = event.result;
				else
					tileAssociatedData = {errorResult: event.result};
				tileRequested.callbackTileLoadFailed(tileRequested, tileAssociatedData);
			} else {
				trace("TiledTilesProvider   onDataLoadFailed: request was cancelled!");
			}
			
			releaseLoader(m_loader);
			loadNextTile();
		}
		
		override public function toString(): String
		{
			return "TiledTilesProvider: needs load : " + _tilesToBeLoaded + " tiles from " + _tilesTotal + " tile total.";
		}
		
	}
}
import com.iblsoft.flexiweather.ogc.net.loaders.WMSImageLoader;
import com.iblsoft.flexiweather.ogc.tiling.TiledTileRequest;

import flash.net.URLRequest;

class TileLoader {

	public var cancelled: Boolean;
	
	private var _loader: WMSImageLoader;
	public function get loader(): WMSImageLoader
	{
		return _loader;
	}
	
	public var data: TiledTileRequest;
	public function get isLoading(): Boolean
	{
		return data != null;	
	}
	public function get request(): URLRequest
	{
		if (data && data.qttTileViewProperties && data.qttTileViewProperties.url)
		{
			return data.qttTileViewProperties.url;
		}
		return null;
	}
	
	
	public function TileLoader(loader: WMSImageLoader)
	{
		_loader = loader;	
	}
}