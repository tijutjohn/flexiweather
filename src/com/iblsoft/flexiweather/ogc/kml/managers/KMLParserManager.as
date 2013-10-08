package com.iblsoft.flexiweather.ogc.kml.managers
{
	import com.iblsoft.flexiweather.ogc.kml.events.KMLEvent;
	import com.iblsoft.flexiweather.ogc.kml.events.KMLParsingStatusEvent;
	import com.iblsoft.flexiweather.ogc.kml.features.KMLFeature;
	import com.iblsoft.flexiweather.utils.AsyncManager;

	[Event(name="parsingProgress", type="com.iblsoft.flexiweather.ogc.kml.events.KMLEvent")]
	public class KMLParserManager extends AsyncManager
	{
		private var _totalCalls: int;
		private var _parsedCalls: int;
		public function KMLParserManager(name: String = '')
		{
			super(name);
			_totalCalls = 0;
			_parsedCalls = 0;
		}

		override public function addCall(obj: Object, callback: Function, arguments: Array): void
		{
			_presence[obj] = true;
			_stack.push({obj: obj, callback: callback, arguments: arguments});
			_totalCalls++;
		}
		
		override protected function tick(): void
		{
			if (_stack.length == 0)
			{
				stop();
				notifyEmpty();
				return;
			}
			var total: int = Math.min(_stack.length, maxCallsPerTick);
			if (total > 0)
			{
				for (var i: int = 0; i < total; i++)
				{
					var obj: Object = _stack.shift();
					if (obj.obj is KMLFeature)
					{
						//trace("check KML Feature async parsing");
						var kmlFeature: KMLFeature = obj.obj as KMLFeature;
						kmlFeature.addEventListener(KMLParsingStatusEvent.FEATURE_PARSING_FAILED, redispatchKMLFeatureParsingStatus, false, 0, true);
						kmlFeature.addEventListener(KMLParsingStatusEvent.FEATURE_PARSING_PARTIALLY_SUCCESFULL, redispatchKMLFeatureParsingStatus, false, 0, true);
						kmlFeature.addEventListener(KMLParsingStatusEvent.FEATURE_PARSING_SUCCESFULL, redispatchKMLFeatureParsingStatus, false, 0, true);
					} else {
						trace("KML Feature async parsing, not KMLFeature");
					}
					
					_parsedCalls++;
					notifyProgress();
					delete _presence[obj.obj];
					(obj.callback as Function).apply(null, obj.arguments);
				}
			}
		}
		
		private function notifyProgress(): void
		{
			var ke: KMLEvent = new KMLEvent(KMLEvent.PARSING_PROGRESS, true);
			ke.progress = _parsedCalls / _totalCalls * 100;
			dispatchEvent(ke);
			
			//trace("KMLParserManager progress + " + _parsedCalls + " / " + _totalCalls);
		}
		private function redispatchKMLFeatureParsingStatus(event: KMLParsingStatusEvent): void
		{
			dispatchEvent(event);
		}
	}
}
