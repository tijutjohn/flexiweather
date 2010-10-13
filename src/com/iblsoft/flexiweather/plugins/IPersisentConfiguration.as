package com.iblsoft.flexiweather.plugins
{
	import com.iblsoft.flexiweather.utils.Storage;
	
	public interface IPersisentConfiguration extends IAbility
	{
		function getStorageID(): String;
		function serializePersistentConfiguration(config: Storage): void;
		function setPersisentConfigurationManager(manager: IPersisentConfigurationManager): void;
		
	}
}