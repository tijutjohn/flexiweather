package com.iblsoft.flexiweather.ogc.configuration.data
{
	public class TimeCreationMethod
	{
		static public const TIME: String = 'time';
		static public const RUN_FORECAST: String = 'run-forecast';
		static public const REFERENCE_TIME_TIME: String = 'reference-time-time';

		static public const LABEL_TIME: String = 'TIME';
		static public const LABEL_RUN_FORECAST: String = 'RUN + FORECAST';
		static public const LABEL_REFERENCE_TIME_TIME: String = 'REFERENCE_TIME + TIME';

		static public function timeMethodAccordingFromDimensions(runDimension: String, forecastDimension: String): String
		{
			if (runDimension)
				runDimension = runDimension.toLowerCase();
			if (forecastDimension)
				forecastDimension = forecastDimension.toLowerCase();

			if (!runDimension && forecastDimension == 'time')
				return TIME;
			if (runDimension == 'reference_time' && forecastDimension == 'time')
				return REFERENCE_TIME_TIME;
			if (runDimension == 'run' && forecastDimension == 'forecast')
				return RUN_FORECAST;

			return RUN_FORECAST;
		}
	}
}