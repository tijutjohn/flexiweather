package com.iblsoft.flexiweather.ogc.kml.managers
{
	import com.iblsoft.flexiweather.utils.AsyncManager;

	public class KMLParserManager extends AsyncManager
	{
		public function KMLParserManager(name: String = '')
		{
			super(name);
		}

		override public function addCall(obj: Object, callback: Function, arguments: Array): void
		{
			_presence[obj] = true;
			_stack.push({obj: obj, callback: callback, arguments: arguments});
		}
	}
}
