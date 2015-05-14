package com.iblsoft.flexiweather.ogc.editable.featureEditor.data
{
	import com.iblsoft.flexiweather.utils.DateUtils;
	import com.iblsoft.flexiweather.utils.Serializable;
	import com.iblsoft.flexiweather.utils.Storage;

	import flash.events.Event;
	import flash.events.EventDispatcher;

	public class FeatureEditorProduct extends EventDispatcher implements Serializable
	{
		public var name: String;
		public var serviceURL: String;

		/**
		 * date, timeOffset and forecast are jus helper variables when you want to use this class for product + run + forecast
		 */
		public var date: Date;
		public var timeOffset: int;
		public var forecast: int;

		[Bindable (event="labelChanged")]
		public function get label(): String
		{
			return name + " | " + date + " offset: " + timeOffset + " forecast: " + forecast;
		}

		public function FeatureEditorProduct()
		{
			timeOffset = 0;
			forecast = 0;
			date = new Date();
			date.setHours(0,0,0,0);
		}

		public function refresh(): void
		{
			dispatchEvent(new Event("labelChanged"));
		}

		public function serialize(storage:Storage):void
		{
			name = storage.serializeString("name", name);
			var url: String = storage.serializeString("service-url", serviceURL);
			if (url && url.length > 0)
			{
				serviceURL = url;
			}
		}


		public function getBaseTime(): Date
		{
			if(date == null)
				return new Date(uint(new Date().time) / 3600 * 3600)

			return getBaseTimeFunction(date, timeOffset);
		}

		private function getBaseTimeFunction(dateLocal: Date, timeOffset: int): Date
		{
			var date: Date = new Date(Date.UTC(dateLocal.fullYear, dateLocal.month, dateLocal.date));
			date.time += Number(timeOffset) * 1000.0;
			return date;
		}

		public function getValidity(): Date
		{
			return getValidityFunction(forecast, getBaseTime());
		}

		protected function getValidityFunction(forecastTime: int, runDate: Date): Date
		{
			return new Date(runDate.time + Number(forecastTime) * 1000.0);
		}

		override public function toString(): String
		{
			var d1: Date = date;
			if (d1)
			{
				d1.setHours(0,0,0,0);
				d1.setTime(d1.getTime() + timeOffset * 1000);

				var _formattedString: String = name + " > " + DateUtils.strftime(d1, '%H:%M %d.%m.%Y', false) + "  +" + forecast / 3600 + 'h';

				return  _formattedString;
			}
			return '';
		}

		public function clone(): FeatureEditorProduct
		{
			var product: FeatureEditorProduct = new FeatureEditorProduct();
			product.name = name;
			product.serviceURL = serviceURL;
			if (date)
				product.date = new Date(date.fullYear, date.month, date.date, 0,0,0,0);
			product.timeOffset = timeOffset;
			product.forecast = forecast;

			return product;
		}
	}
}