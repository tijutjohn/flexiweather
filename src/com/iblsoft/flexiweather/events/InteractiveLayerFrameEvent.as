package com.iblsoft.flexiweather.events
{
	import com.iblsoft.flexiweather.ogc.InteractiveLayerMSBase;
	import com.iblsoft.flexiweather.widgets.InteractiveLayer;
	
	import flash.events.Event;
	
	public class InteractiveLayerFrameEvent extends Event
	{
		/**
		 * Dispatch when selected frame in layer is changed 
		 */		
		public static const FRAME_SELECTION_CHANGED: String = "frameSelectionChanged";
		
		public var layer: InteractiveLayerMSBase;
		public var selectedFrame: Date;
		public var previousSelectedFrame: Date;
		
		public function InteractiveLayerFrameEvent(type:String, layer: InteractiveLayerMSBase, selectedFrame: Date, previousSelectedFrame: Date, bubbles:Boolean=false, cancelable:Boolean=false)
		{
			super(type, bubbles, cancelable);
			
			this.layer = layer;
			this.selectedFrame = selectedFrame;
			this.previousSelectedFrame = previousSelectedFrame;
		}
		
		override public function clone():Event
		{
			var ilfe: InteractiveLayerFrameEvent = new InteractiveLayerFrameEvent(type, layer, selectedFrame, previousSelectedFrame, bubbles, cancelable);
			return ilfe;
		}
	}
}