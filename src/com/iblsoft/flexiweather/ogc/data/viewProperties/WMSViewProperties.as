package com.iblsoft.flexiweather.ogc.data.viewProperties
{
	import com.iblsoft.flexiweather.events.InteractiveLayerWMSEvent;
	import com.iblsoft.flexiweather.events.WMSViewPropertiesEvent;
	import com.iblsoft.flexiweather.ogc.BBox;
	import com.iblsoft.flexiweather.ogc.InteractiveLayerMSBase;
	import com.iblsoft.flexiweather.ogc.InteractiveLayerWMS;
	import com.iblsoft.flexiweather.ogc.SynchronisedVariableChangeEvent;
	import com.iblsoft.flexiweather.ogc.WMSDimension;
	import com.iblsoft.flexiweather.ogc.WMSLayer;
	import com.iblsoft.flexiweather.ogc.configuration.layers.interfaces.ILayerConfiguration;
	import com.iblsoft.flexiweather.ogc.configuration.layers.interfaces.IWMSLayerConfiguration;
	import com.iblsoft.flexiweather.ogc.data.GlobalVariable;
	import com.iblsoft.flexiweather.ogc.data.ImagePart;
	import com.iblsoft.flexiweather.utils.ArrayUtils;
	import com.iblsoft.flexiweather.utils.Duration;
	import com.iblsoft.flexiweather.utils.ISO8601Parser;
	import com.iblsoft.flexiweather.utils.Serializable;
	import com.iblsoft.flexiweather.utils.Storage;
	
	import flash.display.Bitmap;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.net.URLRequest;
	import flash.net.URLVariables;
	import flash.utils.Dictionary;
	
	import mx.collections.ArrayCollection;

	public class WMSViewProperties extends EventDispatcher implements IViewProperties, Serializable
	{
		
		//left and right time frame for animation synchronization (in minutes)
		public static const FRAMES_SYNCHRONIZATION_LEFT_TIME_FRAME: int = 150; //2 hours and 30 minutes
		public static const FRAMES_SYNCHRONIZATION_RIGHT_TIME_FRAME: int = 150; //2 hours and 30 minutes
		
		/**
		 * this is just debug variable. Do not use it for implementation purpose, can be removed anytime.
		 */
		public var parentLayer: InteractiveLayerMSBase;
		public var name: String;
		private var _m_cfg: IWMSLayerConfiguration;
		protected var md_dimensionValues: Dictionary = new Dictionary();
		protected var md_customParameters: Dictionary = new Dictionary();
		protected var ma_subLayerStyleNames: Array = [];
		protected var ma_imageParts: ArrayCollection = new ArrayCollection(); // of ImagePart

		public function get m_cfg(): IWMSLayerConfiguration
		{
			return _m_cfg;
		}

		public function set m_cfg(value: IWMSLayerConfiguration): void
		{
			_m_cfg = value;
		}

		public function get imageParts(): ArrayCollection
		{
			return ma_imageParts;
		}
		/**
		 * Bitmap image holder for legend
		 */
		protected var m_legendImage: Bitmap = null;

		public function set legendImage(bmp: Bitmap): void
		{
			m_legendImage = bmp;
		}

		public function get legendImage(): Bitmap
		{
			return m_legendImage;
		}
		public var crs: String;
		private var _viewBBox: BBox;

		public function getViewBBox(): BBox
		{
			return _viewBBox
		}

		public function setViewBBox(bbox: BBox): void
		{
			_viewBBox = bbox;
		}
		private var m_url: URLRequest;

		public function get url(): URLRequest
		{
			return m_url
		}

		public function set url(value: URLRequest): void
		{
			m_url = value;
		}
		private var _validity: Date;

		public function get validity(): Date
		{
			return _validity;
		}

		public function setValidityTime(validity: Date): void
		{
			_validity = validity;
		}

		public function get dimensions(): Array
		{
			var dimNames: Array = getWMSDimensionsNames();
			if (dimNames && dimNames.length > 0)
			{
				var ret: Array = [];
				for each (var dimName: String in dimNames)
				{
					var value: Object = getWMSDimensionValue(dimName);
					if (value)
						ret.push({name: dimName, value: value});
					else
						ret.push({name: dimName, value: null});
				}
				return ret;
			}
			return null;
		}

		public function WMSViewProperties()
		{
		}

		public function destroy(): void
		{
			m_cfg = null;
			md_dimensionValues = null;
			md_customParameters = null;
			ma_subLayerStyleNames = null;
			if (ma_imageParts && ma_imageParts.length > 0)
			{
				for each (var imagePart: ImagePart in ma_imageParts)
					imagePart.destroy();
			}
			ma_imageParts = null;
			if (m_legendImage && m_legendImage.bitmapData)
			{
				m_legendImage.bitmapData.dispose();
			}
			m_legendImage = null;
			_viewBBox = null;
			m_url = null;
			_validity = null;
		}

		public function addImagePart(imagePart: ImagePart): void
		{
			ma_imageParts.addItem(imagePart);
		}

		public function setConfiguration(cfg: ILayerConfiguration): void
		{
			if (cfg is IWMSLayerConfiguration)
				m_cfg = cfg as IWMSLayerConfiguration;
		}

		public function serialize(storage: Storage): void
		{
			//super.serialize(storage);
			var s_dimName: String;
			var styleName: String;
			if (storage.isLoading())
			{
				styleName = storage.serializeString("style-name", name);
				if (styleName)
					setWMSStyleName(0, styleName);
				for each (s_dimName in getWMSDimensionsNames())
				{
					var level: String = storage.serializeString(s_dimName, null, null);
					if (level)
						setWMSDimensionValue('ELEVATION', level);
				}
			}
			else
			{
				styleName = getWMSStyleName(0);
				if (styleName)
					storage.serializeString("style-name", styleName, null);
				for each (s_dimName in getWMSDimensionsNames())
				{
					if (s_dimName.toLowerCase() == 'elevation')
						storage.serializeString(GlobalVariable.LEVEL, getWMSDimensionValue(s_dimName), null);
				}
			}
		}

		/**
		 * Return true is viewProperties is same
		 *
		 * @param viewProperties
		 * @return
		 *
		 */
		public function equals(viewProperties: WMSViewProperties): Boolean
		{
			var currDimNames: Array = getWMSDimensionsNames();
			var dimNames: Array = viewProperties.getWMSDimensionsNames();
			if (!dimNames || !currDimNames)
				return false;
			if (dimNames && currDimNames && dimNames.length != currDimNames.length)
				return false;
			//check dimensions names
			dimNames.sort();
			currDimNames.sort();
			var total: int = dimNames.length;
			for (var i: int = 0; i < total; i++)
			{
				var dimName: String = dimNames[i] as String;
				var currDimName: String = currDimNames[i] as String;
				if (dimName != currDimName)
					return false;
				var dimValue: Object = getWMSDimensionValue(dimName);
				var currDimValue: Object = viewProperties.getWMSDimensionValue(dimName);
				if (dimValue != currDimValue)
					return false;
			}
			return true;
		}

		public function setWMSDimensionValue(s_dimName: String, s_value: String): void
		{
			//FIXME clearing legend cache must be moved to layer
//			if (m_cfg.mb_legendIsDimensionDependant)
//			{
//				clearLegendCache();
//			}
			if (s_value != null)
				md_dimensionValues[s_dimName] = s_value;
			else
				delete md_dimensionValues[s_dimName];
			var wvpe: WMSViewPropertiesEvent = new WMSViewPropertiesEvent(WMSViewPropertiesEvent.WMS_DIMENSION_VALUE_SET);
			wvpe.dimension = s_dimName;
			wvpe.value = s_value;
			notifyEvent(wvpe);
		}

		private function isSupportedDimension(s_dimName: String): Boolean
		{
			s_dimName = s_dimName.toLowerCase();
			for (var currDimName: String in md_dimensionValues)
			{
				var currDimNameLowerCase: String = currDimName.toLowerCase();
				if (currDimNameLowerCase == s_dimName)
					return true;
			}
			return false;
		}
		private function getWMSDimensionValueInsensitive(s_dimName: String,
				 b_returnDefault: Boolean = false): String
		{
			if (isSupportedDimension(s_dimName)) {
				var s_dimNameLowerCase: String = s_dimName.toLowerCase();
				for (var currDimName: String in md_dimensionValues)
				{
					var currDimNameLowerCase: String = currDimName.toLowerCase();
					if (currDimNameLowerCase == s_dimNameLowerCase)
						return md_dimensionValues[currDimName];
				}
			}
			else
			{
				if (b_returnDefault)
					return getWMSDimensionDefaultValue(s_dimName);
				return null;
			}
			return null;
		}
		public function getWMSDimensionValue(s_dimName: String,
				b_returnDefault: Boolean = false): String
		{
			return getWMSDimensionValueInsensitive(s_dimName, b_returnDefault);
		}

		public function supportWMSDimension(s_dimName: String): Boolean
		{
			var a_dimNames: Array = [];
			for each (var layer: WMSLayer in getWMSLayers())
			{
				for each (var dim: WMSDimension in layer.dimensions)
				{
					if (dim.name == s_dimName)
						return true;
				}
			}
			return false;
		}

		public function getWMSLayers(): Array
		{
			if (m_cfg)
			{
				var a: Array = [];
				for each (var s_layerName: String in m_cfg.layerNames)
				{
					var layer: WMSLayer = m_cfg.service.getLayerByName(s_layerName);
					if (layer != null)
						a.push(layer);
				}
				return a;
			}
			return [];
		}

		public function getWMSDimensionsNames(): Array
		{
			var wmsLayers: Array = getWMSLayers();
			var a_dimNames: Array = [];
			for each (var layer: WMSLayer in wmsLayers)
			{
				for each (var dim: WMSDimension in layer.dimensions)
				{
					if (a_dimNames.indexOf(dim.name) < 0)
						a_dimNames.push(dim.name);
				}
			}
			return a_dimNames;
		}

		// returns null is no such dimension exist
		public function getWMSDimensionUnitsName(s_dimName: String): String
		{
			var s_units: String = null;
			var b_anyDimensionFound: Boolean = false;
			for each (var layer: WMSLayer in getWMSLayers())
			{
				for each (var dim: WMSDimension in layer.dimensions)
				{
					if (dim.name.toLowerCase() != s_dimName.toLowerCase())
						continue;
					if (dim.units == null)
						continue;
					b_anyDimensionFound = true;
					if (s_units == null)
						s_units = dim.units;
					else
					{
						if (dim.units != s_units)
							return "mixed units";
					}
				}
			}
			if (b_anyDimensionFound && s_units == null)
				return "no units";
			return s_units;
		}

		// returns null is no such dimension exist
		public function getWMSDimensionDefaultValue(s_dimName: String): String
		{
			var s_defaultValue: String = null;
			var b_anyDimensionFound: Boolean = false;
			var wmsLayers: Array = getWMSLayers();
			for each (var layer: WMSLayer in wmsLayers)
			{
				for each (var dim: WMSDimension in layer.dimensions)
				{
					if (dim.name.toLowerCase() != s_dimName.toLowerCase())
						continue;
					if (dim.units == null)
						continue;
					b_anyDimensionFound = true;
					if (s_defaultValue == null)
						s_defaultValue = dim.defaultValue;
					else
					{
						if (dim.defaultValue != s_defaultValue)
							return "mixed values";
					}
				}
			}
			if (b_anyDimensionFound && s_defaultValue == null)
				return "";
			return s_defaultValue;
		}

		// returns null is no such dimension exist
		public function getWMSDimensionsValues(s_dimName: String, b_intersection: Boolean = true): Array
		{
			var a_dimValues: Array;
			var wmsLayers: Array = getWMSLayers();
			for each (var layer: WMSLayer in wmsLayers)
			{
				for each (var dim: WMSDimension in layer.dimensions)
				{
					if (dim.name.toLowerCase() != s_dimName.toLowerCase())
						continue;
					if (a_dimValues == null)
						a_dimValues = dim.values;
					else
					{
						if (b_intersection)
							a_dimValues = ArrayUtils.intersectedArrays(a_dimValues, dim.values);
						else
							ArrayUtils.unionArrays(a_dimValues, dim.values);
					}
				}
			}
			return a_dimValues;
		}

		/**
		 * It returns date from RUN and FORECAST set for this layer
		 * @return
		 *
		 */
		public function getWMSCurrentDate(): Date
		{
			var run: String = getWMSDimensionValue('RUN');
			var forecast: String = getWMSDimensionValue('FORECAST');
			return new Date();
		}

		public function getWMSStyleListString(): String
		{
			var s: String = "";
			var total: int = m_cfg.layerNames.length;
			if (ma_subLayerStyleNames)
			{
				for (var i_subLayer: uint = 0; i_subLayer < total; ++i_subLayer)
				{
					if (i_subLayer > 0)
						s += ",";
					if (i_subLayer in ma_subLayerStyleNames)
						s += ma_subLayerStyleNames[i_subLayer];
					else if (i_subLayer in m_cfg.styleNames)
						s += m_cfg.styleNames[i_subLayer];
				}
			}
			return s;
		}

		/**
		 * For each WMS sub-layer, returns array of objects having .name and .label properties
		 * or null if the sub-layer doesn't have any styles. This is bound together
		 * into one final array having that many items as is the number of WMS sub-layers.
		 **/
		public function getWMSStyles(): Array
		{
			var b_foundAnyStyle: Boolean = false;
			var a_styles: Array = [];
			for each (var layer: WMSLayer in getWMSLayers())
			{
				var a_layerStyles: Array = [];
				for each (var style: Object in layer.styles)
				{
					b_foundAnyStyle = true;
					a_layerStyles.push({
								label: style.title != null ? (style.title + " (" + style.name + ")") : style.name,
								title: style.title != null ? style.title : style.name,
								name: style.name
							});
				}
				a_styles.push(a_layerStyles.length > 0 ? a_layerStyles : null);
			}
			return b_foundAnyStyle ? a_styles : null;
		}

		public function getWMSStyleName(i_subLayer: uint): String
		{
			if (i_subLayer in ma_subLayerStyleNames)
				return ma_subLayerStyleNames[i_subLayer];
			else
				return null;
		}

		public function getWMSStyleObject(i_subLayer: uint, s_styleName: String = ''): Object
		{
			if (m_cfg && m_cfg.layerConfigurations)
			{
				var layer: WMSLayer = m_cfg.layerConfigurations[i_subLayer] as WMSLayer;
				if (layer && layer.styles && layer.styles.length > 0)
				{
					if (s_styleName == '')
						return layer.styles[0];
					else
					{
						for each (var styleObj: Object in layer.styles)
						{
							if (styleObj.name == s_styleName)
								return styleObj;
						}
					}
				}
			}
			return null;
		}

		public function getWMSEffectiveStyleName(i_subLayer: uint): String
		{
			var s_styleName: String = getWMSStyleName(i_subLayer);
			if (s_styleName == null)
			{
				var layer: WMSLayer = m_cfg.layerConfigurations[i_subLayer] as WMSLayer;
				if (layer && layer.styles && layer.styles.length > 0)
				{
					return layer.styles[0].name;
				}
			}
			return null;
		}

		public function setWMSStyleName(i_subLayer: uint, s_styleName: String): void
		{
			//FIXME moved clear legend cache to layer
//			clearLegendCache();
			if (s_styleName != null)
				ma_subLayerStyleNames[i_subLayer] = s_styleName;
			else
				delete ma_subLayerStyleNames[i_subLayer];
			dispatchEvent(new InteractiveLayerWMSEvent(InteractiveLayerWMSEvent.WMS_STYLE_CHANGED, true));
		}

		public function setWMSCustomParameter(s_parameter: String, s_value: String): void
		{
			if (s_value != null)
				md_customParameters[s_parameter] = s_value;
			else
				delete md_customParameters[s_parameter];
		}

		/**
		 * Populates URLRequest with dimension values.
		 **/
		public function updateDimensionsInURLRequest(url: URLRequest): void
		{
			for (var s_dimName: String in md_dimensionValues)
			{
				if (url.data == null)
					url.data = new URLVariables();
				url.data[m_cfg.dimensionToParameterName(s_dimName)] = md_dimensionValues[s_dimName];
			}
		}

		/**
		 * Populates URLRequest with custom parameter values.
		 **/
		public function updateCustomParametersInURLRequest(url: URLRequest): void
		{
			for (var s_parameter: String in md_customParameters)
			{
				if (url.data == null)
					url.data = new URLVariables();
				url.data[s_parameter] = md_customParameters[s_parameter];
			}
		}

		// ISynchronisedObject implementation
		public function getSynchronisedVariables(): Array
		{
			var a: Array = [];
			if (m_cfg.dimensionTimeName != null
					|| (m_cfg.dimensionRunName != null && m_cfg.dimensionForecastName != null))
				a.push(GlobalVariable.FRAME);
			if (m_cfg.dimensionRunName != null)
				a.push("run");
			if (m_cfg.dimensionVerticalLevelName != null)
				a.push(GlobalVariable.LEVEL);
			return a;
		}

		public function hasSynchronisedVariable(s_variableId: String): Boolean
		{
			if (s_variableId == GlobalVariable.FRAME)
			{
				if (m_cfg.dimensionTimeName != null)
				{
					return true;
				}
				else if (m_cfg.dimensionRunName != null && m_cfg.dimensionForecastName != null)
				{
					return true;
				}
			}
			if (s_variableId == GlobalVariable.LEVEL)
			{
				if (m_cfg.dimensionVerticalLevelName != null)
				{
					return true;
				}
			}
			return false;
		}

		public function getSynchronisedVariableValue(s_variableId: String): Object
		{
			if (s_variableId == GlobalVariable.FRAME)
			{
				if (m_cfg.dimensionTimeName != null)
				{
					return ISO8601Parser.stringToDate(getWMSDimensionValue(m_cfg.dimensionTimeName, true));
				}
				else if (m_cfg.dimensionRunName != null && m_cfg.dimensionForecastName != null)
				{
					var run: Date = ISO8601Parser.stringToDate(
							getWMSDimensionValue(m_cfg.dimensionRunName, true));
					var forecast: Duration = ISO8601Parser.stringToDuration(
							getWMSDimensionValue(m_cfg.dimensionForecastName, true));
					if (run != null && forecast != null)
						return new Date(run.time + forecast.milisecondsTotal);
					return null;
				}
			}
			if (s_variableId == GlobalVariable.LEVEL)
			{
				if (m_cfg.dimensionVerticalLevelName != null)
				{
					return (getWMSDimensionValue(m_cfg.dimensionVerticalLevelName, true));
				}
			}
			return null;
		}

		public function getSynchronisedVariableValuesList(s_variableId: String): Array
		{
			if (s_variableId == GlobalVariable.LEVEL)
			{
				if (m_cfg.dimensionVerticalLevelName != null)
				{
					var l_levels: Array = getWMSDimensionsValues(m_cfg.dimensionVerticalLevelName);
					return l_levels;
				}
			}
			else if (s_variableId == GlobalVariable.FRAME)
			{
				if (m_cfg.dimensionTimeName != null)
				{
					var l_times: Array = getWMSDimensionsValues(m_cfg.dimensionTimeName);
					var l_resultTimes: Array = [];
					for each (var time: Object in l_times)
					{
						if (time.data is Date)
						{
							l_resultTimes.push(time.data);
						}
						else
						{
							trace("PROBLEM: InteractiveLayerMSBase getSynchronisedVariableValuesList time.data is not Date: " + time.data);
						}
					}
					//sort forecast by Date
					if (l_resultTimes && l_resultTimes.length > 0)
					{
						//sort Duration
						l_resultTimes.sort(sortDates);
					}
					return l_resultTimes;
				}
				else if (m_cfg.dimensionRunName != null && m_cfg.dimensionForecastName != null)
				{
					var run: Date = ISO8601Parser.stringToDate(getWMSDimensionValue(m_cfg.dimensionRunName, true));
					if (run == null)
						return [];
					var l_forecasts: Array = getWMSDimensionsValues(m_cfg.dimensionForecastName);
					var l_resultForecasts: Array = [];
					for each (var forecast: Object in l_forecasts)
					{
						if (forecast && (forecast.data is Duration))
						{
							l_resultForecasts.push(new Date(run.time + Duration(forecast.data).milisecondsTotal));
						}
						else
						{
							trace("PROBLEM: InteractiveLayerMSBase getSynchronisedVariableValuesList forecast.data is not Number: " + forecast.data);
						}
					}
					//sort forecast by Duration
					if (l_forecasts && l_forecasts.length > 0)
					{
						//sort Duration
						l_forecasts.sort(sortDurations);
					}
					return l_resultForecasts;
				}
				else
					return [];
			}
			return null;
		}

		public function exactlySynchroniseWith(s_variableId: String, value: Object): Boolean
		{
			var of: Object;
			var ofExactForecast: Object = null;
			if (s_variableId == GlobalVariable.LEVEL)
			{
				if (m_cfg.dimensionVerticalLevelName != null)
				{
					var level: String = value as String;
					var l_levels: Array = getWMSDimensionsValues(m_cfg.dimensionVerticalLevelName);
					ofExactForecast = null;
					for each (of in l_levels)
					{
						if (of && of.data && (of.data as String) == level)
						{
							ofExactForecast = of;
							break;
						}
					}
					if (ofExactForecast != null)
					{
						setWMSDimensionValue(m_cfg.dimensionVerticalLevelName, ofExactForecast.data as String);
						dispatchSynchronizedVariableChangeEvent(new SynchronisedVariableChangeEvent(
								SynchronisedVariableChangeEvent.SYNCHRONISED_VARIABLE_CHANGED, GlobalVariable.LEVEL));
						return true;
					}
				}
			}
			if (s_variableId == GlobalVariable.FRAME)
			{
				if (m_cfg.dimensionTimeName != null)
				{
					var frame: Date = value as Date;
					// TODO: interpolation vs. find nearest value?
					var l_times: Array = getWMSDimensionsValues(m_cfg.dimensionTimeName);
					ofExactForecast = null;
					for each (of in l_times)
					{
						if (of && of.data && (of.data as Date).time == frame.time)
						{
							ofExactForecast = of;
							break;
						}
					}
					if (ofExactForecast != null)
					{
						setWMSDimensionValue(m_cfg.dimensionTimeName, ISO8601Parser.dateToString(ofExactForecast.data as Date));
						dispatchSynchronizedVariableChangeEvent(new SynchronisedVariableChangeEvent(
								SynchronisedVariableChangeEvent.SYNCHRONISED_VARIABLE_CHANGED, GlobalVariable.FRAME));
						return true;
					}
				}
				else if (m_cfg.dimensionRunName != null && m_cfg.dimensionForecastName != null)
				{
					var run: Date = ISO8601Parser.stringToDate(
							getWMSDimensionValue(m_cfg.dimensionRunName, true));
					var forecast: Duration = new Duration(((value as Date).time - run.time) / 1000.0);
					var l_forecasts: Array = getWMSDimensionsValues(m_cfg.dimensionForecastName);
					ofExactForecast = null;
					for each (of in l_forecasts)
					{
						if (of && of.data && Duration(of.data).secondsTotal == forecast.secondsTotal)
						{
							ofExactForecast = of;
							break;
						}
					}
					if (ofExactForecast != null)
					{
						setWMSDimensionValue(m_cfg.dimensionForecastName, ofExactForecast.value);
						dispatchSynchronizedVariableChangeEvent(new SynchronisedVariableChangeEvent(
								SynchronisedVariableChangeEvent.SYNCHRONISED_VARIABLE_CHANGED, GlobalVariable.FRAME, false));
						return true;
					}
				}
			}
			return false;
		}

		public function synchroniseWith(s_variableId: String, value: Object): Boolean
		{
			var a: Array
			if (s_variableId == GlobalVariable.LEVEL)
			{
				if (!exactlySynchroniseWith(s_variableId, value))
				{
					a = getSynchronisedVariableValuesList(s_variableId);
					var bestLevel: String;
					var requiredLevel: String = value as String;
//					var leftDist: Number = 1000 * 60 * 60 * 3;
//					var rightDist: Number = 1000 * 60 * 60 * 3;
					for each (var level: Object in a)
					{
						if (level.data == requiredLevel)
						{
							bestLevel = level.data as String;
						}
					}
					if (!bestLevel)
						return false;
					return exactlySynchroniseWith(s_variableId, bestLevel);
				}
			}
			if (s_variableId == GlobalVariable.FRAME)
			{
				if (!exactlySynchroniseWith(s_variableId, value))
				{
					a = getSynchronisedVariableValuesList(s_variableId);
					var best: Date = null;
					var required: Date = value as Date;
					var requiredTime: Number = required.time;
					//TODO here is frame synchronisation done, if you want to change left and right time frame, you can set it here
					var leftDist: Number = 1000 * 60 * FRAMES_SYNCHRONIZATION_LEFT_TIME_FRAME;
					var rightDist: Number = 1000 * 60 * FRAMES_SYNCHRONIZATION_RIGHT_TIME_FRAME;
					for each (var i: Date in a)
					{
						if (i.time >= requiredTime - leftDist && i.time <= requiredTime + rightDist)
						{
							if (best == null || Math.abs(best.time - requiredTime) > Math.abs(i.time - requiredTime))
								best = i;
						}
					}
					if (best == null)
						return false;
					return exactlySynchroniseWith(s_variableId, best);
				}
			}
			return exactlySynchroniseWith(s_variableId, value);
		}

		private function dispatchSynchronizedVariableChangeEvent(event: SynchronisedVariableChangeEvent): void
		{
			dispatchEvent(event);
		}

		public static function sortDates(obj1: Object, obj2: Object): int
		{
			var date1: Date = obj1 as Date;
			var date2: Date = obj2 as Date;
			if (date1 && date2)
			{
				var dSec1: Number = date1.time;
				var dSec2: Number = date2.time;
				if (dSec1 > dSec2)
				{
					return 1;
				}
				else
				{
					if (dSec1 < dSec2)
						return -1;
				}
			}
			return 0;
		}

		public static function sortDurations(obj1: Object, obj2: Object): int
		{
			var duration1: Duration = obj1.data as Duration;
			var duration2: Duration = obj2.data as Duration;
			if (duration1 && duration2)
			{
				var dSec1: Number = duration1.secondsTotal;
				var dSec2: Number = duration2.secondsTotal;
				if (dSec1 > dSec2)
				{
					return 1;
				}
				else
				{
					if (dSec1 < dSec2)
						return -1;
				}
			}
			return 0;
		}

		/******************************************************************************************
		 *
		 * 	Legends part
		 *
		 ******************************************************************************************/
		public function clone(): IViewProperties
		{
			var newViewProperties: WMSViewProperties = new WMSViewProperties();
			newViewProperties.setConfiguration(m_cfg);
			newViewProperties.crs = crs;
			newViewProperties.setViewBBox(_viewBBox);
			var styleName: String = getWMSStyleName(0)
			newViewProperties.setWMSStyleName(0, styleName);
			//clone all dimensions
			var dimNames: Array = getWMSDimensionsNames();
			for each (var dimName: String in dimNames)
			{
				var value: String = getWMSDimensionValue(dimName);
				newViewProperties.setWMSDimensionValue(dimName, value);
			}
			return newViewProperties;
		}

		private function notifyEvent(event: Event): void
		{
			dispatchEvent(event);
		}
	}
}
