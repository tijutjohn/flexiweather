package com.iblsoft.flexiweather.ogc.multiview.synchronization
{
	import com.iblsoft.flexiweather.ogc.multiview.synchronization.FrameSynchronizator;
	import com.iblsoft.flexiweather.ogc.multiview.synchronization.ISynchronizator;
	import com.iblsoft.flexiweather.ogc.multiview.synchronization.LevelSynchronizator;
	import com.iblsoft.flexiweather.ogc.multiview.synchronization.MapSynchronizator;
	import com.iblsoft.flexiweather.ogc.multiview.synchronization.SynchronizatorBase;
	import com.iblsoft.flexiweather.utils.Serializable;
	import com.iblsoft.flexiweather.utils.Storage;
	
	import flash.utils.getDefinitionByName;
	import flash.utils.getQualifiedClassName;

	public class SynchronizatorWrapper implements Serializable
	{
		public var synchronizator: SynchronizatorBase;
		
		public function SynchronizatorWrapper(synchronizator: SynchronizatorBase = null)
		{
			this.synchronizator = synchronizator;
		}	
		
		public function getSynchronizatorInstanceByClassName(className: String): ISynchronizator
		{
			var classReference:Class = getDefinitionByName(className) as Class;
			
			var synchronizatorInstance: ISynchronizator;
			
			try {
				synchronizatorInstance = new classReference();
			} catch (error: Error) {
				trace("SynchronizatorWrapper: Cannot convert '" + className + "' to Synchronizator");
			}
			
			return synchronizatorInstance;
		}
		
		public function serialize(storage: Storage): void
		{
			if (storage.isLoading())
			{
				var s_synchronizatorType: String = storage.serializeString("synchronizator-type", null);
				var s_synchronizatorClassName: String = storage.serializeString("synchronizator-class", null);
				
				if (s_synchronizatorClassName)
				{
					synchronizator = getSynchronizatorInstanceByClassName(s_synchronizatorClassName) as SynchronizatorBase;
				} else {
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
					storage.serializeString("synchronizator-class", getQualifiedClassName(synchronizator), null);
					(synchronizator as Serializable).serialize(storage);
				}
			}
		}
	}
}