package com.iblsoft.flexiweather.ogc.kml.managers
{
	import com.iblsoft.flexiweather.ogc.kml.events.KMLParsingStatusEvent;
	import com.iblsoft.flexiweather.ogc.kml.features.KMLFeature;
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
						trace("check KML Feature async parsing");
						var kmlFeature: KMLFeature = obj.obj as KMLFeature;
						kmlFeature.addEventListener(KMLParsingStatusEvent.FEATURE_PARSING_FAILED, redispatchKMLFeatureParsingStatus, false, 0, true);
						kmlFeature.addEventListener(KMLParsingStatusEvent.FEATURE_PARSING_PARTIALLY_SUCCESFULL, redispatchKMLFeatureParsingStatus, false, 0, true);
						kmlFeature.addEventListener(KMLParsingStatusEvent.FEATURE_PARSING_SUCCESFULL, redispatchKMLFeatureParsingStatus, false, 0, true);
					} else {
						trace("KML Feature async parsing, not KMLFeature");
					}
					delete _presence[obj.obj];
					(obj.callback as Function).apply(null, obj.arguments);
				}
			}
		}
		
		private function redispatchKMLFeatureParsingStatus(event: KMLParsingStatusEvent): void
		{
			dispatchEvent(event);
		}
	}
}
