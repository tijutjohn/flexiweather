package com.iblsoft.flexiweather.events
{
	import com.iblsoft.flexiweather.ogc.tiling.TileIndex;
	import flash.events.Event;

	public class InteractiveLayerQTTEvent extends Event
	{
		public static const ZOOM_LEVEL_CHANGED: String = 'zoomLevelChanged';
		public static const TILE_LOADING_STARTED: String = 'tileLoadingStarted';
		public static const TILE_LOADED_FINISHED: String = 'tileLoadedFinished';
		public static const TILES_LOADING_STARTED: String = 'tilesLoadingStarted';
		public static const TILES_LOADED_FINISHED: String = 'tilesLoadedFinished';
		public var tileIndex: TileIndex;
		public var zoomLevel: String;

		public function InteractiveLayerQTTEvent(type: String, bubbles: Boolean = false, cancelable: Boolean = false)
		{
			super(type, bubbles, cancelable);
		}
	}
}
