package com.iblsoft.flexiweather.plugins
{
	// Supporting interface for IAction's management
	public interface IActionManager
	{
		function setActionEnabled(s_id: String, b_enable: Boolean = true): void;
	}
}