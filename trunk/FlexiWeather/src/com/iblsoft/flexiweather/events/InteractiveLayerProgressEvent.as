package com.iblsoft.flexiweather.events
{
	import com.iblsoft.flexiweather.widgets.InteractiveLayer;
	import flash.events.Event;

	public class InteractiveLayerProgressEvent extends Event
	{
		public static const UNIT_BYTES: String = 'bytes';
		public static const UNIT_TILES: String = 'tiles';
		public var interactiveLayer: InteractiveLayer;
		public var loaded: int;
		public var total: int;
		/**
		 * Progress in percentage
		 */
		public var progress: Number;
		/**
		 * Units type. One of constant starting with UNIT_.
		 * Tiles layer dispatch progress with loaded tiles / total tiles,
		 * and layer with simple image dispatched progress of loaded bytes / total bytes of image
		 */
		public var units: String;

		public function InteractiveLayerProgressEvent(type: String, bubbles: Boolean = false, cancelable: Boolean = false)
		{
			super(type, bubbles, cancelable);
		}
	}
}
