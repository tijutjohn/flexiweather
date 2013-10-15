package com.iblsoft.flexiweather.ogc.configuration.services
{
	import com.iblsoft.flexiweather.ogc.WMSLayerGroup;
	import com.iblsoft.flexiweather.utils.AsyncManager;
	
	public class WMSServiceParsingManager extends AsyncManager
	{
		public var xml: XML;
		public var defaultLayer: WMSLayerGroup;
		
		public function WMSServiceParsingManager(name:String)
		{
			super(name);
		}
		
		override public function addCall(obj: Object, callback: Function, arguments: Array): void
		{
			if (!_presence[obj])
			{
				_presence[obj] = true;
				_stack.push({obj: obj, callback: callback, arguments: arguments});
			}
		}
		
		override protected function tick(): void
		{
			trace("WMSServiceParsingManager stack: " + _stack.length);
			super.tick();
		}
	}
}