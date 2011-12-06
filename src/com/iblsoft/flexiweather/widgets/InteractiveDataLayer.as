package com.iblsoft.flexiweather.widgets
{
	import com.iblsoft.flexiweather.events.InteractiveLayerEvent;
	import com.iblsoft.flexiweather.events.InteractiveLayerProgressEvent;
	import com.iblsoft.flexiweather.ogc.ExceptionUtils;
	import com.iblsoft.flexiweather.utils.UniURLLoader;
	import com.iblsoft.flexiweather.utils.UniURLLoaderEvent;
	
	import flash.events.Event;
	import flash.events.ProgressEvent;

	[Event (name="statusChanged", type="flash.events.Event")]
	public class InteractiveDataLayer extends InteractiveLayer
	{
		/**
		 *
		 *  @eventType progress
		 *  
		 *  @langversion 3.0
		 *  @playerversion Flash 9
		 *  @playerversion AIR 1.1
		 *  @productversion Flex 3
		 */
		public static const PROGRESS: String = 'progress';
		
		/**
		 *
		 *  @eventType loadingStarted
		 *  
		 *  @langversion 3.0
		 *  @playerversion Flash 9
		 *  @playerversion AIR 1.1
		 *  @productversion Flex 3
		 */
		public static const LOADING_STARTED: String = 'loadingStarted';
		
		/**
		 *
		 *  @eventType loadingFinished
		 *  
		 *  @langversion 3.0
		 *  @playerversion Flash 9
		 *  @playerversion AIR 1.1
		 *  @productversion Flex 3
		 */
		public static const LOADING_FINISHED: String = 'loadingFinished';
		
		/**
		 *
		 *  @eventType loadingError
		 *  
		 *  @langversion 3.0
		 *  @playerversion Flash 9
		 *  @playerversion AIR 1.1
		 *  @productversion Flex 3
		 */
		public static const LOADING_ERROR: String = 'loadingError';
		
		
		/**
		 *
		 *  @eventType statusChanged
		 *  
		 *  @langversion 3.0
		 *  @playerversion Flash 9
		 *  @playerversion AIR 1.1
		 *  @productversion Flex 3
		 */
		public static const STATUS_CHANGED: String = 'statusChanged';
		
		/**
		 * Empty layer state. This state is default, when <code>InteractiveDataLayer</code> is created
		 */		
		public static const STATE_EMPTY: String = 'empty';
		
		/**
		 * Loading data layer state. It is set on LOADING_STARTED event.
		 */		
		public static const STATE_LOADING_DATA: String = 'loading data';
		
		/**
		 * Loading data layer state. It is set on LOADING_FINISHED event.
		 */		
		public static const STATE_DATA_LOADED: String = 'data loaded';

		/**
		 * Data error layer state. It is set when IOError occurs.
		 */		
		public static const STATE_DATA_ERROR: String = 'data error';
		
		/**
		 * Layer state where some of data are loaded, but some data are not loaded because of error. E.g. Loading 50 tiles, but some tiles are not loaded (no returned from server).
		 * You need to dispatch this state in your custom class which extends <code>InteractiveDataLayer</code>
		 */		
		public static const STATE_DATA_LOADED_WITH_ERRORS: String = 'data loaded with errors';
		
		/**
		 * 	Available in state: <code>InteractiveDataLayer.STATE_DATA_LOADED_WITH_ERRORS</code> or <code>InteractiveDataLayer.STATE_DATA_ERROR</code>. 
		 */		
		public var errorText: String;		
		private var _status: String;
		
		/**
		 * Status of InteractiveDataLayer. This layer except dispatching events also set current status of layer. 
		 * You can check status anytime and find out, what is the current state of layers. 
		 * @return 
		 * 
		 */		
		[Bindable (event="statusChanged")]
		public function get status(): String
		{		
			return _status;
		}
		
		protected var m_loader: UniURLLoader = new UniURLLoader();
		
		public function InteractiveDataLayer(container:InteractiveWidget)
		{
			super(container);
			
			setStatus(STATE_EMPTY);
			
			m_loader.addEventListener(UniURLLoader.DATA_LOADED, onDataLoaded);
			m_loader.addEventListener(ProgressEvent.PROGRESS, onDataProgress);
			m_loader.addEventListener(UniURLLoader.DATA_LOAD_FAILED, onDataLoadFailed);
		}
		
		private var _invalidateDataFlag: Boolean;
		private var _invalidateDataForceUpdateFlag: Boolean;
		
		/**
		 * Invalidation function for <code>updateData</code> function. It works exactly as invalidateProperties, invalidateSize or invalidateDisplayList.
		 * You can call as many times as you want invalidateData function and updateData will be called just once each frame (if neeeded) 
		 * @param b_forceUpdate
		 * 
		 */
		public function invalidateData(b_forceUpdate: Boolean): void
		{
			_invalidateDataFlag = true;
			_invalidateDataForceUpdateFlag = _invalidateDataForceUpdateFlag || b_forceUpdate;
			invalidateProperties();
		}
		
		
		protected function updateData(b_forceUpdate: Boolean): void
		{
		}
		
		
		override protected function commitProperties():void
		{
			super.commitProperties();
			
			if (_invalidateDataFlag)
			{
				updateData(_invalidateDataForceUpdateFlag);
				_invalidateDataFlag = false;
			}
			_invalidateDataForceUpdateFlag = false;
		}
		
		/*****************************************************************************************************************
		 * 
		 * 													Status functionality
		 * 
		 ****************************************************************************************************************/
		protected function setStatus(newStatus: String): void
		{
			_status = newStatus;
			dispatchEvent(new Event("statusChanged"));
		}
		
		/**
		 * Dispatch <code>InteractiveDataLayer.LOADING_START</code> event. If you need to dispatch more properties inside event, override this method in your class. 
		 * 
		 */		
		protected function notifyLoadingStart(): void
		{
			setStatus(STATE_LOADING_DATA);
			
			var event: InteractiveLayerEvent = new InteractiveLayerEvent(LOADING_STARTED, true);
			event.interactiveLayer = this;
			dispatchEvent(event);
		}
		
		/**
		 * Dispatch <code>InteractiveDataLayer.LOADING_FINISHED</code> event. If you need to dispatch more properties inside event, override this method in your class. 
		 * 
		 */		
		protected function notifyLoadingFinished(): void
		{
			setStatus(STATE_DATA_LOADED);
			
			var event: InteractiveLayerEvent = new InteractiveLayerEvent(LOADING_FINISHED, true);
			event.interactiveLayer = this;
			dispatchEvent(event);
		}
		
		/**
		 * Dispatch <code>InteractiveDataLayer.LOADING_ERROR</code> event. If you need to dispatch more properties inside event, override this method in your class. 
		 * 
		 */		
		protected function notifyLoadingError(): void
		{
			setStatus(STATE_DATA_ERROR);
			
			var event: InteractiveLayerEvent = new InteractiveLayerEvent(LOADING_ERROR, true);
			event.interactiveLayer = this;
			dispatchEvent(event);
		}
		
		/**
		 * Dispatch <code>InteractiveDataLayer.PROGRESS</code> event. 
		 * If you need to dispatch more properties inside event, override this method in your class. 
		 * 
		 */		
		protected function notifyProgress(loaded: int, total: int, units: String): void
		{
			var event: InteractiveLayerProgressEvent = new InteractiveLayerProgressEvent(PROGRESS, true);
			event.interactiveLayer = this;
			event.loaded = loaded;
			event.total = total;
			event.units = units;
			event.progress = 100 * loaded / total;
			dispatchEvent(event);
			
		}
		
		
		
		protected function onDataProgress(event: ProgressEvent): void
		{
//			trace(this + " onDataProgress: " + event.bytesLoaded + " / " + event.bytesTotal);
			notifyProgress(event.bytesLoaded, event.bytesTotal, InteractiveLayerProgressEvent.UNIT_BYTES);
		}
		
		// Event handlers
		protected function onDataLoaded(event: UniURLLoaderEvent): void
		{
			notifyLoadingFinished();
			
//			var ile: InteractiveLayerEvent = new InteractiveLayerEvent(InteractiveLayerEvent.LAYER_LOADED, true);
//			ile.interactiveLayer = this;
//			dispatchEvent(ile);
		}
		
		protected function onDataLoadFailed(event: UniURLLoaderEvent): void
		{
			notifyLoadingError();
		}
		
		public function get dataLoader(): UniURLLoader
		{ return m_loader; } 
	}
}