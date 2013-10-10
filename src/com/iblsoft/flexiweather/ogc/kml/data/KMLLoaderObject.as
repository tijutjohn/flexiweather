package com.iblsoft.flexiweather.ogc.kml.data
{
	import com.iblsoft.flexiweather.ogc.kml.InteractiveLayerKML;
	import com.iblsoft.flexiweather.ogc.kml.configuration.KMLLayerConfiguration;
	import mx.binding.utils.ChangeWatcher;

	public class KMLLoaderObject
	{
		private var _url: String;
		
		/**
		 * One of KMLType constants 
		 */		
		private var _type: String;
		private var _configuration: KMLLayerConfiguration;
		public var layer: InteractiveLayerKML;
		public var dataProviderWatcher: ChangeWatcher;

		public function KMLLoaderObject(url: String, type: String, configuration: KMLLayerConfiguration)
		{
			_url = url;
			_type = type;
			_configuration = configuration;
		}



		public function get url(): String
		{
			return _url;
		}

		public function get type(): String
		{
			return _type;
		}

		public function set type(value:String):void
		{
			_type = value;
		}

		public function get configuration(): KMLLayerConfiguration
		{
			return _configuration;
		}
	}
}
