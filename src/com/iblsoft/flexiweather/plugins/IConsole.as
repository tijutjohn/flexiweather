package com.iblsoft.flexiweather.plugins
{
	public interface IConsole
	{
		function setConsoleManager(consoleManager: IConsoleManager): void;
		function getConsole(): Object;
		function show(): void;
		function hide(): void;
	}
}