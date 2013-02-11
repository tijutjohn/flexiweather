package com.iblsoft.flexiweather.ogc.tiling
{
	import com.iblsoft.flexiweather.net.events.UniURLLoaderErrorEvent;
	import com.iblsoft.flexiweather.net.events.UniURLLoaderEvent;
	import com.iblsoft.flexiweather.net.loaders.UniURLLoader;
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
		
		private var _callbackTileLoaded: Function;
		private var _callbackTileLoadFailed: Function;

		private var ma_freeLoaders: Array;
		private var md_loadersRequests: Dictionary;
		private var ma_tilesBuffer: Array;
		
		public function TiledTilesProvider()
		{
			ma_tilesBuffer = [];
			ma_freeLoaders = [];
			md_loadersRequests = new Dictionary();
			createLoaders();
		}

		public function destroy(): void
		{
		}

		private function createLoaders(): void
		{
			for (var i: int = 0; i < 5; i++)
			{
				var m_loader: WMSImageLoader = new WMSImageLoader();
				m_loader.addEventListener(UniURLLoaderEvent.DATA_LOADED, onDataLoaded);
				m_loader.addEventListener(ProgressEvent.PROGRESS, onDataProgress);
				m_loader.addEventListener(UniURLLoaderErrorEvent.DATA_LOAD_FAILED, onDataLoadFailed);
				
				md_loadersRequests[m_loader] = new TileLoader(m_loader);
				ma_freeLoaders.push(m_loader);
			}
		}
		private function releaseLoader(loader: WMSImageLoader): void
		{
			if (md_loadersRequests[loader])
			{
				var tileLoader: TileLoader = md_loadersRequests[loader] as TileLoader;
				tileLoader.data = null;
			}
			ma_freeLoaders.push(loader);
		}
		private function getFreeLoader(): WMSImageLoader
		{
			if (ma_freeLoaders.length > 0)
			{
				return ma_freeLoaders.shift();
			}
			return null;
			
		}
		
		private function cancelPreviousRequests(): void
		{
			ma_tilesBuffer = [];
			
			for each (var tileLoader: TileLoader in md_loadersRequests)
			{
				if (tileLoader.isLoading)
				{
					var request: URLRequest = tileLoader.request;
					var loader: WMSImageLoader = tileLoader.loader;
					
					loader.cancel(request);
					
					releaseLoader(loader);
				}
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
		 *
		 */
		public function getTiles(tilesIndices: Array, callbackTileLoaded: Function, callbackTileLoadFailed: Function): void
		{
			if (tilesIndices && tilesIndices.length > 0)
			{
				
				cancelPreviousRequests();
				
				_tilesTotal = tilesIndices.length;
				_tilesToBeLoaded = tilesIndices.length;
				
				_callbackTileLoaded = callbackTileLoaded;
				_callbackTileLoadFailed = callbackTileLoadFailed;
				for each (var data: TiledTileRequest in tilesIndices)
				{
					var m_loader: WMSImageLoader = getFreeLoader();
					if (m_loader)
					{
						loadTile(data, m_loader);
					} else {
						waitForFreeLoader(data);
					}
				}
			}
		}
		
		private function loadTile(data: TiledTileRequest, loader: WMSImageLoader): void
		{
			var customAssociatedData: Object = {tileRequest: data};
			var request: URLRequest = data.qttTileViewProperties.url;
			
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
					trace("all tiles loaded");
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

		protected function onDataLoaded(event: UniURLLoaderEvent): void
		{
			_tilesToBeLoaded--;
			
//			trace("TiledTilesProvider onDataLoaded: " + _tilesToBeLoaded + " from " + _tilesTotal);
			
			var m_loader: WMSImageLoader = event.target as WMSImageLoader;
//			removeEventListeners(m_loader);
			var tileRequested: TiledTileRequest = event.associatedData.tileRequest as TiledTileRequest;
			_callbackTileLoaded(Bitmap(event.result), tileRequested, tileRequested.qttTileViewProperties.tileIndex);
			
			releaseLoader(m_loader);
			loadNextTile();
		}

		protected function onDataLoadFailed(event: UniURLLoaderErrorEvent): void
		{
			var m_loader: WMSImageLoader = event.target as WMSImageLoader;
//			removeEventListeners(m_loader);
			var tileAssociatedData: Object = event.associatedData.associatedData;
			var tileRequested: TiledTileRequest = event.associatedData.tileRequest as TiledTileRequest;
			if (tileAssociatedData)
				tileAssociatedData.errorResult = event.result;
			else
				tileAssociatedData = {errorResult: event.result};
			_callbackTileLoadFailed(tileRequested, tileAssociatedData);
			
			releaseLoader(m_loader);
			loadNextTile();
		}
	}
}
import com.iblsoft.flexiweather.ogc.net.loaders.WMSImageLoader;
import com.iblsoft.flexiweather.ogc.tiling.TiledTileRequest;

import flash.net.URLRequest;

class TileLoader {

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