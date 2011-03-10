package com.iblsoft.flexiweather.ogc
{
	import com.iblsoft.flexiweather.utils.Duration;
	import com.iblsoft.flexiweather.utils.ISO8601Parser;
	
	import flash.utils.getTimer;
	
	public class WMSDimension
	{
		internal var ms_name: String;
		internal var ma_values: Array;
		internal var ms_units: String;
		internal var ms_default: String;
		protected static var sm_dateTimeParser: ISO8601Parser = new ISO8601Parser();
		
		public function WMSDimension(xml: XML, wms: Namespace, version: Version)
		{
			ms_name = xml.@name;
			// in WMS 1.3.0 dimension values are inside of <Dimension> element
			ms_units = xml.@units;
			if(!version.isLessThan(1, 3, 0))
				loadExtent(xml, wms, version);
		}
		
		public function equals(other: WMSDimension): Boolean
		{
			if(other == null)
				return false;
			if(ms_name != other.ms_name)
				return false;
			if(ms_units != other.ms_units)
				return false;
			if(ma_values.length != other.ma_values.length)
				return false;
			for(var i: int = 0; i < ma_values.length; ++i) {
				if(ma_values[i] != other.ma_values[i])
					return false;
			} 
			if(ms_default != other.ms_default)
				return false;
			return true;
		}

		public function loadExtent(xml: XML, wms: Namespace, version: Version): void
		{
//			var time: Number = getTimer();
			
			var s: String = String(xml);
			var arr: Array = s.split(",");
			
//			trace("loadExtent " + xml.@name + " default: " + xml.@default + " items: " + arr.length);
			ms_default = xml.@default;
			// TODO: strip white spaces
			ma_values = [];
			for each(var s_value: String in arr) {
				// Strip white spaces to workaround " , " separation used in
				// http://openmetoc.met.no/metoc/metocwms?request=GetCapabilities&VERSION=1.1.1 
				s_value = s_value.replace(/\s+\Z/, '').replace(/\A\s+/, '');
				stringValueToObjects(ma_values, s_value, ms_units);
			}
		}
		
		protected static function stringValueToObjects(
				a_values: Array,
				s_value: String, s_units: String): void
		{
			var s_label: String = s_value;
			var data: Object = s_value;
			if(s_units != null)
				s_units = s_units.toUpperCase(); 
			// Unit date_time is used at http://openmetoc.met.no/metoc/metocwms?request=GetCapabilities&VERSION=1.1.1 
			if(s_units == "ISO8601" || s_units == "DATE_TIME") {
				if(sm_dateTimeParser.looksLikeDuration(s_value)) {
					try {
						data = sm_dateTimeParser.parseDuration(s_value);
						s_label = (data as Duration).toHoursString();
						// fall down...
					}
					catch(e: Error) {
					}
				} else {
					try {
						if(s_value.indexOf("/") >= 0) {
							// encycle all options
							var a_bits: Array = s_value.split("/", 3);
							if(a_bits.length == 3) {
								
								var f_from: Number = sm_dateTimeParser.parseDateTime(a_bits[0]).time;
								var f_to: Number = sm_dateTimeParser.parseDateTime(a_bits[1]).time;
								var f_step: Number = sm_dateTimeParser.parseDuration(a_bits[2]).milisecondsTotal;
								if(f_from <= f_to && f_step > 0) {
									if((f_to - f_from) / f_step > 1000) {
										// HACK: Reduce number of step to "last" 1000 in the past
										var f_currentTime: Number = new Date().time;
										if(f_to > f_currentTime)
											f_to = f_from + int((f_currentTime - f_from) / f_step) * f_step;
										f_from = Math.max(f_from, f_to - f_step * 1000);
									}
									for(var f: Number = f_from; f < f_to; f += f_step) {
										data = new Date();
										(data as Date).time = f;
										s_label = (data as Date).toUTCString();
										a_values.push({
												label: s_label,
												value: ISO8601Parser.dateToString(data as Date),
												data: data});
									}
								}
								return;
							}
							// else - TODO: range?						
						}
						else {
							data = sm_dateTimeParser.parseDateTime(s_value);
							s_label = (data as Date).toUTCString();
							// fall down...
						}
					}
					catch(e: Error) {
					}
				}
			}
			else {
				if(s_value.indexOf("/") >= 0) {
					// encycle all options
					var a_numBits: Array = s_value.split("/", 3);
					if(a_numBits.length > 1) {
						var f_numFrom: Number = Number(a_numBits[0]); 
						var f_numTo: Number = Number(a_numBits[1]);
						if(!isNaN(f_numFrom) && !isNaN(f_numTo)) {
							var f_numStep: Number = 1; // HACK:
							if(a_numBits.length > 2)
								f_numStep = Number(a_numBits[2]);
							if(f_numStep < 0)
								f_numStep = -f_numStep;
							if(f_numFrom > f_numTo) {
								var f_numSwap: Number = f_numFrom;
								f_numFrom = f_numTo;
								f_numTo = f_numSwap;
							} 
							if(f_numStep == 0)
								f_numStep = 1; // HACK:  
							while((f_numTo - f_numFrom) / f_numStep > 1000) {
								f_numStep *= 10.0;
							}
							var f_num: Number;
							for(f_num = f_numFrom; f_num < f_numTo; f_num += f_numStep) {
								a_values.push({label: String(f_num), value: String(f_num), data: f_num});
							}
							if(f_numFrom != f_numTo) {
								a_values.push({label: String(f_numTo), value: String(f_numTo), data: f_numTo});
							}
							return;
						}
					}
				}
			}
			// default operation
			a_values.push({label: s_label, value: s_value, data: data});
		}
		
		public static function stringValueToObject(s_value: String, s_units: String): Object
		{
			var a: Array = [];
			stringValueToObjects(a, s_value, s_units);
			if(a.length > 0)
				return a[0];
			return null;
		}

		public function get name(): String
		{ return ms_name; }

		public function get values(): Array
		{ return ma_values; }
	}
}