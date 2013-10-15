package com.iblsoft.flexiweather.ogc
{
	import com.iblsoft.flexiweather.ogc.configuration.services.WMSServiceParsingManager;
	import com.iblsoft.flexiweather.ogc.data.GlobalVariableValue;
	import com.iblsoft.flexiweather.utils.Duration;
	import com.iblsoft.flexiweather.utils.ISO8601Parser;
	
	import flash.utils.getTimer;

	public class WMSDimension extends GetCapabilitiesXMLItem
	{
		private var ma_values: Array;
		private var ms_units: String;
		private var ms_default: String;
		
		/**
		 * String representing values of dimensions as found in the GetCapabilities document.
		 * It will be parsed if the values getter is invoked.
		 **/
		private var ms_values: String = null;
		private var mb_valuesHaveToBeParsed: Boolean = true;
		protected static var sm_dateTimeParser: ISO8601Parser = new ISO8601Parser();

		public function WMSDimension(xml: XML, wms: Namespace, version: Version)
		{
			super(xml, wms, version);
			
			// in WMS 1.3.0 dimension values are inside of <Dimension> element
			ms_units = xml.@units;
			ms_name = xml.@name;
		}
		
//		override public function initialize(): void
//		{
//			super.initialize();
//		}			
		
		override public function parse(parsingManager: WMSServiceParsingManager = null): void
		{
			super.parse();
			
			// in WMS < 1.3.0, dimension values are inside of <Extent> element
			// having the same @name as the <Dimension> element
			if (m_version.isLessThan(1, 3, 0))
			{
				for each (var elemExtent: XML in m_itemXML.wms::Extent)
				{
					if (elemExtent.@name == name)
					{
						loadExtent(elemExtent, wms, m_version);
						break;
					}
				}
			} else {
				//parse WMS1.3.0 dimension
				loadExtent(m_itemXML, wms, m_version);
			}
			
			
		}

		public function destroy(): void
		{
			if (ma_values && ma_values.length > 0)
				ma_values = null;
			//			sm_dateTimeParser = null;
		}

		public function equals(other: WMSDimension): Boolean
		{
			if (other == null)
				return false;
			if (ms_name != other.ms_name)
				return false;
			if (ms_units != other.ms_units)
				return false;
			if (ms_values != other.ms_values)
				return false;
			if (ms_default != other.ms_default)
				return false;
			return true;
		}

		public function loadExtent(xml: XML, wms: Namespace, version: Version): void
		{
			ms_default = xml.@default;
			var s: String = String(xml);
			if (ms_values == null)
				ms_values = s;
			else
			{
				ms_values += ",";
				ms_values + s;
			}
			mb_valuesHaveToBeParsed = true;
		}

		private function parseData(): void
		{
			if (!mb_isParsed)
				parse();
			
			var arr: Array = ms_values == null ? [] : ms_values.split(",");
			ma_values = [];
			for each (var s_value: String in arr)
			{
				// Strip white spaces to workaround " , " separation used in
				// http://openmetoc.met.no/metoc/metocwms?request=GetCapabilities&VERSION=1.1.1 
				s_value = s_value.replace(/\s+\Z/, '').replace(/\A\s+/, '');
				stringValueToObjects(ma_values, s_value, ms_units);
			}
			mb_valuesHaveToBeParsed = false;
		}

		protected static function stringValueToObjects(
				a_values: Array,
				s_value: String, s_units: String): void
		{
			var gvv: GlobalVariableValue;
			var s_label: String = s_value;
			var data: Object = s_value;
			if (s_units != null)
				s_units = s_units.toUpperCase();
			// Unit date_time is used at http://openmetoc.met.no/metoc/metocwms?request=GetCapabilities&VERSION=1.1.1 
			if (s_units == "ISO8601" || s_units == "DATE_TIME")
			{
				if (sm_dateTimeParser.looksLikeDuration(s_value))
				{
					try
					{
						data = sm_dateTimeParser.parseDuration(s_value);
						s_label = (data as Duration).toHoursString();
							// fall down...
					}
					catch (e: Error)
					{
					}
				}
				else
				{
					try
					{
						if (s_value.indexOf("/") >= 0)
						{
							// encycle all options
							var a_bits: Array = s_value.split("/", 3);
							if (a_bits.length == 3)
							{
								var f_from: Number = sm_dateTimeParser.parseDateTime(a_bits[0]).time;
								var f_to: Number = sm_dateTimeParser.parseDateTime(a_bits[1]).time;
								var f_step: Number = sm_dateTimeParser.parseDuration(a_bits[2]).milisecondsTotal;
								if (f_from <= f_to && f_step > 0)
								{
									if ((f_to - f_from) / f_step > 1000)
									{
										// HACK: Reduce number of step to "last" 1000 in the past
										var f_currentTime: Number = new Date().time;
										if (f_to > f_currentTime)
											f_to = f_from + int((f_currentTime - f_from) / f_step) * f_step;
										f_from = Math.max(f_from, f_to - f_step * 1000);
									}
									for (var f: Number = f_from; f < f_to; f += f_step)
									{
										data = new Date();
										(data as Date).time = f;
										s_label = (data as Date).toUTCString();
										gvv = new GlobalVariableValue();
										gvv.label = s_label;
										gvv.value = ISO8601Parser.dateToString(data as Date);
										gvv.data = data;
										a_values.push(gvv);
									}
								}
								return;
							}
								// else - TODO: range?						
						}
						else
						{
							data = sm_dateTimeParser.parseDateTime(s_value);
							s_label = (data as Date).toUTCString();
								// fall down...
						}
					}
					catch (e: Error)
					{
					}
				}
			}
			else
			{
				if (s_value.indexOf("/") >= 0)
				{
					// encycle all options
					var a_numBits: Array = s_value.split("/", 3);
					if (a_numBits.length > 1)
					{
						var f_numFrom: Number = Number(a_numBits[0]);
						var f_numTo: Number = Number(a_numBits[1]);
						if (!isNaN(f_numFrom) && !isNaN(f_numTo))
						{
							var f_numStep: Number = 1; // HACK:
							if (a_numBits.length > 2)
								f_numStep = Number(a_numBits[2]);
							if (f_numStep < 0)
								f_numStep = -f_numStep;
							if (f_numFrom > f_numTo)
							{
								var f_numSwap: Number = f_numFrom;
								f_numFrom = f_numTo;
								f_numTo = f_numSwap;
							}
							if (f_numStep == 0)
								f_numStep = 1; // HACK:  
							while ((f_numTo - f_numFrom) / f_numStep > 1000)
							{
								f_numStep *= 10.0;
							}
							var f_num: Number;
							for (f_num = f_numFrom; f_num < f_numTo; f_num += f_numStep)
							{
								gvv = new GlobalVariableValue();
								gvv.label = String(f_num);
								gvv.value = String(f_num);
								gvv.data = f_num;
								a_values.push(gvv);
							}
							if (f_numFrom != f_numTo)
							{
								gvv = new GlobalVariableValue();
								gvv.label = String(f_numTo);
								gvv.value = String(f_numTo);
								gvv.data = f_numTo;
								a_values.push(gvv);
							}
							return;
						}
					}
				}
			}
			// default operation
			gvv = new GlobalVariableValue();
			gvv.label = s_label;
			gvv.value = s_value;
			gvv.data = data;
			a_values.push(gvv);
		}

		public static function stringValueToObject(s_value: String, s_units: String): Object
		{
			var a: Array = [];
			stringValueToObjects(a, s_value, s_units);
			if (a.length > 0)
				return a[0];
			return null;
		}

		public function get values(): Array
		{
			if (mb_valuesHaveToBeParsed)
				parseData();
			return ma_values;
		}

		public function get units(): String
		{
			return ms_units;
		}

		public function get defaultValue(): String
		{
			if (mb_valuesHaveToBeParsed)
				parseData();
			return ms_default;
		}
	}
}
