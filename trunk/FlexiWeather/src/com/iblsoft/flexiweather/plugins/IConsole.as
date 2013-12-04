package com.iblsoft.flexiweather.plugins
{

	public interface IConsole
	{
		function setConsoleManager(consoleManager: IConsoleManager): void;
		function getConsole(): Object;
		function print(str: String, type: String = 'Info', tag: String = 'tag'): void;
		function show(): void;
		function hide(): void;
	}
}
