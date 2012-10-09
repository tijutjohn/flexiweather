package com.iblsoft.flexiweather.widgets
{
	import com.iblsoft.flexiweather.events.InteractiveLayerEvent;
	import com.iblsoft.flexiweather.events.InteractiveLayerProgressEvent;
	import com.iblsoft.flexiweather.net.events.UniURLLoaderErrorEvent;
	import com.iblsoft.flexiweather.net.events.UniURLLoaderEvent;
	import com.iblsoft.flexiweather.net.loaders.UniURLLoader;
	import com.iblsoft.flexiweather.ogc.ExceptionUtils;
	import com.iblsoft.flexiweather.ogc.net.loaders.WMSImageLoader;
	
	import flash.events.Event;
	import flash.events.ProgressEvent;
	
	import mx.events.DynamicEvent;

	[Event (name="loadingStarted", type="com.iblsoft.flexiweather.events.InteractiveLayerEvent")]
	[Event (name="loadingFinished", type="com.iblsoft.flexiweather.events.InteractiveLayerEvent")]
	[Event (name="loadingError", type="com.iblsoft.flexiweather.events.InteractiveLayerEvent")]
	[Event (name="operationNotSupported", type="com.iblsoft.flexiweather.events.InteractiveLayerEvent")]
	[Event (name="progress", type="com.iblsoft.flexiweather.events.InteractiveLayerProgressEvent")]
	
	[Event (name="statusChanged", type="flash.events.Event")]
	
	public class InteractiveDataLayer extends InteractiveLayer
	{
		/**
		 *
		 *  @eventType operationNotSupported
		 *  
		 *  @langversion 3.0
		 *  @playerversion Flash 9
		 *  @playerversion AIR 1.1
		 *  @productversion Flex 3
		 */
		public static const OPERATION_NOT_SUPPORTED: String = 'operationNotSupported';
		
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
		 *  @eventType preloadingStarted
		 *  
		 *  @langversion 3.0
		 *  @playerversion Flash 9
		 *  @playerversion AIR 1.1
		 *  @productversion Flex 3
		 */
		public static const PRELOADING_STARTED: String = 'preloadingStarted';

		/**
		 *
		 *  @eventType preloadingFinished
		 *  
		 *  @langversion 3.0
		 *  @playerversion Flash 9
		 *  @playerversion AIR 1.1
		 *  @productversion Flex 3
		 */
		public static const PRELOADING_FINISHED: String = 'preloadingFinished';
		
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
		 * STATE_LOADING_DATA
		 */		
		public static const STATE_LOADING_DATA: String = 'loading data';
		
		/**
		 * STATE_DATA_LOADED.
		 */		
		public static const STATE_DATA_LOADED: String = 'data loaded';
		
		/**
		 * STATE_NO_DATA_AVAILABLE.
		 */		
		public static const STATE_NO_DATA_AVAILABLE: String = 'no data available';

		/**
		 * Layer state where some of data are loaded, but some data are not loaded because of error. E.g. Loading 50 tiles, but some tiles are not loaded (no returned from server).
		 * Also IOErrors belong here.
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
		[Inspectable (enumeration="empty,loading data,no data available,data loaded with errors")]
		public function get status(): String
		{		
			return _status;
		}
		
		protected var m_loader: WMSImageLoader = new WMSImageLoader();
		
		public function InteractiveDataLayer(container:InteractiveWidget = null)
		{
			super(container);
		}
			
		
		override protected function initializeLayer():void
		{
			super.initializeLayer();
			setStatus(STATE_EMPTY);
			
			m_loader.addEventListener(UniURLLoaderEvent.DATA_LOADED, onDataLoaded);
			m_loader.addEventListener(ProgressEvent.PROGRESS, onDataProgress);
			m_loader.addEventListener(UniURLLoaderErrorEvent.DATA_LOAD_FAILED, onDataLoadFailed);
		}
		
		override public function destroy():void
		{
			super.destroy();
			
			if (m_loader)
			{
				m_loader.destroy();
				m_loader.removeEventListener(UniURLLoaderEvent.DATA_LOADED, onDataLoaded);
				m_loader.removeEventListener(ProgressEvent.PROGRESS, onDataProgress);
				m_loader.removeEventListener(UniURLLoaderErrorEvent.DATA_LOAD_FAILED, onDataLoadFailed);
			}			
			m_loader = null;
			
		}
		
		private var _invalidateDataFlag: Boolean;
		public function set invalidateDataFlag(value:Boolean):void
		{
			_invalidateDataFlag = value;
		}
		
		private var _invalidateDataForceUpdateFlag: Boolean;
		
		/**
		 * Invalidation function for <code>updateData</code> function. It works exactly as invalidateProperties, invalidateSize or invalidateDisplayList.
		 * You can call as many times as you want invalidateData function and updateData will be called just once each frame (if neeeded) 
		 * @param b_forceUpdate
		 * 
		 */
		public function invalidateData(b_forceUpdate: Boolean): void
		{
			invalidateDataFlag = true;
			_invalidateDataForceUpdateFlag = _invalidateDataForceUpdateFlag || b_forceUpdate;
//			trace("**** invalidateData _invalidateDataForceUpdateFlag: " + _invalidateDataForceUpdateFlag + " (b_forceUpdate = " + b_forceUpdate + ") ["+this+"]");
			invalidateProperties();
		}
		
		protected function updateData(b_forceUpdate: Boolean): void
		{
		}
		
		
		override protected function commitProperties():void
		{
			super.commitProperties();
			
//			trace("*** commitProperties _invalidateDataForceUpdateFlag: " + _invalidateDataForceUpdateFlag + " ["+this+"]");
			if (_invalidateDataFlag)
			{
				updateData(_invalidateDataForceUpdateFlag);
				invalidateDataFlag = false;
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
			dispatchEvent(new Event(STATUS_CHANGED));
		}
		
		/**
		 * Dispatch <code>InteractiveDataLayer.LOADING_START</code> event. If you need to dispatch more properties inside event, override this method in your class. 
		 * 
		 */		
		protected function notifyLoadingStart(bubbles: Boolean = true): void
		{
			setStatus(STATE_LOADING_DATA);
			
			var event: InteractiveLayerEvent = new InteractiveLayerEvent(LOADING_STARTED, bubbles);
			event.interactiveLayer = this;
			dispatchEvent(event);
		}
		
		/**
		 * Dispatch <code>InteractiveDataLayer.LOADING_FINISHED</code> event. If you need to dispatch more properties inside event, override this method in your class. 
		 * 
		 */		
		protected function notifyLoadingFinished(bubbles: Boolean = true): void
		{
			if (_status != STATE_DATA_LOADED_WITH_ERRORS)
				setStatus(STATE_DATA_LOADED);
			
			var event: InteractiveLayerEvent = new InteractiveLayerEvent(LOADING_FINISHED, bubbles);
			event.interactiveLayer = this;
			dispatchEvent(event);
		}
		
		/**
		 * Dispatch <code>InteractiveDataLayer.LOADING_ERROR</code> event. If you need to dispatch more properties inside event, override this method in your class. 
		 * 
		 */		
		protected function notifyLoadingError(): void
		{
			setStatus(STATE_DATA_LOADED_WITH_ERRORS);
			
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
		}
		
		protected function onDataLoadFailed(event: UniURLLoaderErrorEvent): void
		{
			notifyLoadingError();
		}
		
		/**
		 * Dispatch <code>InteractiveDataLayer.OPERATION_NOT_SUPPORTED</code> event. 
		 * 
		 */		
		protected function notifyOperationNotSupported(): void
		{
			setStatus(STATE_DATA_LOADED_WITH_ERRORS);
			
			var event: InteractiveLayerEvent = new InteractiveLayerEvent(OPERATION_NOT_SUPPORTED, true)
			event.interactiveLayer = this;
			dispatchEvent(event);
			
		}
		
		public function get dataLoader(): WMSImageLoader
		{ return m_loader; } 
	}
}