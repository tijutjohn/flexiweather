package com.iblsoft.flexiweather.ogc.multiview.data
{
	import com.iblsoft.flexiweather.ogc.multiview.synchronization.SynchronizatorBase;
	import com.iblsoft.flexiweather.utils.Serializable;
	import com.iblsoft.flexiweather.utils.Storage;
	
	import mx.collections.ArrayCollection;

	public class MultiViewConfiguration implements Serializable
	{
		public var rows: int;
		public var columns: int;
		
		private var _synchronizators: Array;
		
		/**
		 *  Data information for each view, if needed 
		 */		
		private var _viewData: MultiViewViewData;
		
		private var _customData: MultiViewCustomData;
		
		public function MultiViewConfiguration()
		{
		}



		public function get synchronizators():Array
		{
			return _synchronizators;
		}

		public function set synchronizators(value:Array):void
		{
			_synchronizators = value;
		}

		public function get viewData(): MultiViewViewData
		{
			return _viewData;
		}

		public function set viewData(value: MultiViewViewData):void
		{
			_viewData = value;
		}

		/**
		 * In this object custom data can be stored, e.g. frame sychronisator can store timeStep here 
		 */
		public function get customData(): MultiViewCustomData
		{
			return _customData;
		}

		/**
		 * @private
		 */
		public function set customData(value: MultiViewCustomData):void
		{
			_customData = value;
		}

		public function serialize(storage:Storage):void
		{
			rows = storage.serializeInt('rows', rows);
			columns = storage.serializeInt('columns', columns);
			
			var wrappers: Array;
			var wrapper: SynchronizatorWrapper;
			var synchronizator: SynchronizatorBase;
			
			if (storage.isStoring())
			{
				if (_customData)
					storage.serialize('custom-data', _customData);
			
				if (_viewData)
					storage.serialize('view-data', _viewData);
				
				if (_synchronizators)
				{
					//create wrapper collection
					wrappers = new Array();
					for each (synchronizator in _synchronizators)
					{
						wrapper = new SynchronizatorWrapper(synchronizator);
						wrappers.push(wrapper);
					}
					storage.serializeNonpersistentArray("synchronizator", wrappers, SynchronizatorWrapper);
					
				}
			} else {
				if (!_customData)
					_customData = new MultiViewCustomData();
				if (!_viewData)
					_viewData = new MultiViewViewData();
				if (!_synchronizators)
					_synchronizators = new Array();
				
				try {
					storage.serialize('custom-data', _customData);
				} catch (e: Error) {
					trace("MultiViewConfiguration serialize loading: cannot find custom-data");
				}
					
				try {
					storage.serialize('view-data', _viewData);
				} catch (e: Error) {
					trace("MultiViewConfiguration serialize loading: cannot find view-data");
				}
				
				wrappers = new Array();
				
				try {
					storage.serializeNonpersistentArray("synchronizator", wrappers, SynchronizatorWrapper);
					if (wrappers.length > 0)
					{
						var total: int = wrappers.length - 1;
						for (var i: int = total; i >= 0; i--)
						{
							wrapper = wrappers[i] as SynchronizatorWrapper;
							synchronizator = wrapper.synchronizator;
							_synchronizators.push(synchronizator);
						}
					}
				} catch (e: Error) {
					trace("MultiViewConfiguration serialize loading: problem parsing synchronizators");
				}
				
			}
		}
		
	}
}
import com.iblsoft.flexiweather.ogc.multiview.synchronization.FrameSynchronizator;
import com.iblsoft.flexiweather.ogc.multiview.synchronization.LevelSynchronizator;
import com.iblsoft.flexiweather.ogc.multiview.synchronization.MapSynchronizator;
import com.iblsoft.flexiweather.ogc.multiview.synchronization.SynchronizatorBase;
import com.iblsoft.flexiweather.utils.Serializable;
import com.iblsoft.flexiweather.utils.Storage;

class SynchronizatorWrapper implements Serializable
{
	public var synchronizator: SynchronizatorBase;
	
	public function SynchronizatorWrapper(synchronizator: SynchronizatorBase)
	{
		this.synchronizator = synchronizator;
	}
	
	public function serialize(storage: Storage): void
	{
		if (storage.isLoading())
		{
			var s_synchronizatorType: String = storage.serializeString("synchronizator-type", null);
			
			switch (s_synchronizatorType)
			{
				case "frame-synchronizator":
					synchronizator = new FrameSynchronizator();
					break;
				case "level-synchronizator":
					synchronizator = new LevelSynchronizator();
					break;
				case "map-synchronizator":
					synchronizator = new MapSynchronizator();
					break;
			}
			
			if (synchronizator is Serializable)
			{
				(synchronizator as Serializable).serialize(storage);
			}
		}
		else
		{
			if (synchronizator is Serializable)
			{
				storage.serializeString("synchronizator-type", synchronizator.type, null);
				(synchronizator as Serializable).serialize(storage);
			}
		}
	}
}