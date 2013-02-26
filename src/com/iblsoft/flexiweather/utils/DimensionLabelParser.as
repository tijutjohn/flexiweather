package com.iblsoft.flexiweather.utils
{
	import com.iblsoft.flexiweather.ogc.InteractiveLayerMSBase;
	import com.iblsoft.flexiweather.ogc.WMSDimension;
	import com.iblsoft.flexiweather.ogc.data.GlobalVariable;
	import com.iblsoft.flexiweather.widgets.InteractiveLayerComposer;
	import com.iblsoft.flexiweather.widgets.InteractiveLayerMap;
	import flash.utils.Dictionary;

	public class DimensionLabelParser
	{
		public function DimensionLabelParser()
		{
		}

		public function parseLabel(label: String, layerMap: InteractiveLayerMap): String
		{
			if (layerMap && !layerMap.visible)
				return 'No data';
			if (label && label.indexOf('<') >= 0)
			{
				label = label.split('%lt;').join('<');
				label = label.split('%gt;').join('>');
				var startIndices: Array = [];
				var endIndices: Array = [];
				var index: int = 0;
				var pos: int;
				do
				{
					pos = label.indexOf('<', index);
					if (pos >= index)
					{
						startIndices.push(pos);
						index = pos + 1;
					}
				} while (pos > -1)
				index = 0;
				do
				{
					pos = label.indexOf('/>', index);
					if (pos >= index)
					{
						endIndices.push(pos);
						index = pos + 1;
					}
				} while (pos > -1)
				if (startIndices.length != endIndices.length)
				{
					//outputText.text = "problem with parsing";
				}
				else
				{
					pos = 0;
					var output: String = '';
					for (var i: int = 0; i < startIndices.length; i++)
					{
						var start: int = startIndices[i];
						var end: int = endIndices[i];
						var tagString: String = label.substring(start, end + 2);
						var tag: XML = new XML(tagString);
						var tagName: String = tag.name();
						var attributes: XMLList = tag.attributes();
						var attrs: Dictionary = new Dictionary();
						for each (var attrXML: XML in attributes)
						{
							var attributeName: String = attrXML.name();
							var attributeValue: String = attrXML.valueOf();
							attrs[attributeName] = attributeValue;
						}
						var replacedString: String;
						var layerID: String = attrs['layer'];
						var format: String = attrs['format'];
						var useUTC: Boolean = true;
						if (attrs['tz'])
							useUTC = (attrs['tz'] as String).toLowerCase() == 'utc';
						if (tagName.toLowerCase() == 'mapname')
						{
							replacedString = layerMap.mapName;
						} else if (tagName.toLowerCase() == GlobalVariable.FRAME)
						{
							//run + forecast
							var run: Object = getWMSDimensionValue(layerMap, layerID, 'RUN');
							var forecast: Object = getWMSDimensionValue(layerMap, layerID, 'FORECAST');
							var time: Object = getWMSDimensionValue(layerMap, layerID, 'TIME');
							if (run && forecast)
							{
								var runDate: Date = run.data as Date
								var forecastDuration: Duration = forecast.data as Duration;
								runDate = new Date(runDate.time + forecastDuration.milisecondsTotal);
								run.data = runDate
								replacedString = formatWMSDimensionValue(run, format, useUTC);
							} else if (time)
							{
								replacedString = formatWMSDimensionValue(time, format, useUTC);
							}
						}
						else if (tagName.toLowerCase() == GlobalVariable.LEVEL)
						{
							var elevation: Object = getWMSDimensionValue(layerMap, layerID, 'ELEVATION');
							if (elevation)
							{
								var level: String = elevation.data as String;
								replacedString = formatWMSDimensionValue(level, format, useUTC);
							}
						}
						else
							replacedString = formatWMSDimensionValue(getWMSDimensionValue(layerMap, layerID, tagName.toUpperCase()), format, useUTC);
						if (start > pos)
						{
							output += label.substring(pos, start);
							output += replacedString;
						}
						else
							output += replacedString;
						pos = end + 2;
					}
					if (pos < label.length)
						output += label.substring(pos, label.length);
					label = output;
				}
			}
			if (label == "null")
				label = "";
			return label;
		}

		private function formatWMSDimensionValue(value: Object, dateFormat: String = null, useUTC: Boolean = true): String
		{
			var valueString: String;
			if (value && value.hasOwnProperty('data') && value.data is Date && dateFormat && dateFormat.length > 0)
				valueString = DateUtils.strftime(value.data, dateFormat, useUTC);
			else if (value && value.hasOwnProperty('label'))
				valueString = value.label;
			else
				valueString = value as String;
			return valueString;
		}

		private function getWMSDimensionValue(layerComposer: InteractiveLayerMap, interactiveLayerType: String, dimensionName: String): Object
		{
			var interactiveLayer: InteractiveLayerMSBase;
			if (interactiveLayerType)
				interactiveLayer = layerComposer.getLayerByID(interactiveLayerType) as InteractiveLayerMSBase;
			else
				interactiveLayer = layerComposer.getPrimaryLayer() as InteractiveLayerMSBase;
			if (interactiveLayer)
			{
				var value: String = interactiveLayer.getWMSDimensionValue(dimensionName, true);
				if (value)
				{
					var valueObject: Object = WMSDimension.stringValueToObject(value, interactiveLayer.getWMSDimensionUnitsName(dimensionName));
					return valueObject;
				}
			}
			return '';
		}
	}
}
