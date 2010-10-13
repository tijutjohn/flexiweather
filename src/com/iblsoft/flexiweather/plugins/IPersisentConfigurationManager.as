package com.iblsoft.flexiweather.plugins
{
	import com.iblsoft.flexiweather.utils.Storage;
	
	public interface IPersisentConfigurationManager
	{
		function forceConfigurationLoad(): void;
		function forceConfigurationSave(storage: Storage = null): void;
		function forceConfigurationReset(): void;
	}
}