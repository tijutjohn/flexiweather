package com.iblsoft.utils
{
	import com.furusystems.dconsole2.DConsole;
	import com.furusystems.dconsole2.IConsole;
	import com.iblsoft.flexiweather.plugins.IConsole;
	import com.iblsoft.flexiweather.plugins.IConsoleManager;

	public class CustomDebugConsole implements com.iblsoft.flexiweather.plugins.IConsole
	{
		private var m_console: com.furusystems.dconsole2.IConsole;

		public function CustomDebugConsole()
		{
		}

		public function print(str: String, type: String = 'Info', tag: String = 'tag'): void
		{
			m_console.print(str, type, tag);
		}

		public function getConsole(): Object
		{
			if (!m_console)
				m_console = DConsole.console;
			return m_console;
		}

		public function setConsoleManager(consoleManager: IConsoleManager): void
		{
		}

		public function show(): void
		{
			if (m_console)
				m_console.show();
		}

		public function hide(): void
		{
			if (m_console)
				m_console.hide();
		}
	}
}
