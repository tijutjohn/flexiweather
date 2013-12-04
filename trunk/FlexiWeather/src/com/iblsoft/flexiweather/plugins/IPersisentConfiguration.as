package com.iblsoft.flexiweather.plugins
{
	import com.iblsoft.flexiweather.utils.Storage;

	public interface IPersisentConfiguration extends IAbility
	{
		function getPersistentConfigurationId(): String;
		function serializePersistentConfiguration(storage: Storage): void;
		function setPersisentConfigurationManager(manager: IPersisentConfigurationManager): void;
	}
}
